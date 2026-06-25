import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/homework.dart';
import '../../models/course.dart';
import '../../services/homework_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';
import '../../components/glass_card.dart';
import '../../components/glass_navbar.dart';
import '../../components/glass_segment.dart';

class HomeworkListPage extends StatefulWidget {
  const HomeworkListPage({super.key});

  @override
  State<HomeworkListPage> createState() => _HomeworkListPageState();
}

class _HomeworkListPageState extends State<HomeworkListPage> {
  final _hwService = HomeworkService();
  final _courseService = CourseService();

  List<Homework> _homeworks = [];
  Map<String, Course> _courseMap = {};
  int _filterIndex = 0;
  String _searchQuery = '';
  bool _searchMode = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final semester = await SemesterService().getCurrent();
    if (semester == null) return;
    final courses = await _courseService.getBySemester(semester.id);
    final map = <String, Course>{};
    for (final c in courses) map[c.id] = c;
    final hws = await _hwService.getAll();
    if (mounted) setState(() { _courseMap = map; _homeworks = hws; _cachedFiltered = null; });
  }

  List<Homework>? _cachedFiltered;

  Future<void> _toggleComplete(Homework hw) async {
    await _hwService.toggleComplete(hw.id);
    final idx = _homeworks.indexWhere((h) => h.id == hw.id);
    if (idx < 0) return;
    final updated = Homework(
      id: hw.id, courseId: hw.courseId, title: hw.title,
      dueDate: hw.dueDate, notes: hw.notes, isCompleted: !hw.isCompleted,
    );
    _homeworks[idx] = updated;
    _cachedFiltered = null;
    if (mounted) setState(() {});
  }

  List<Homework> get _filtered {
    if (_cachedFiltered != null) return _cachedFiltered!;
    var list = _homeworks;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((h) => h.title.toLowerCase().contains(q)).toList();
    }
    if (_filterIndex == 1) list = list.where((h) => !h.isCompleted).toList();
    else if (_filterIndex == 2) list = list.where((h) => h.isCompleted).toList();
    _cachedFiltered = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            GlassLargeTitle(
              title: '作业',
              actions: [
                GlassNavAction(
                  icon: CupertinoIcons.add_circled,
                  onTap: () async {
                    final result = await Navigator.pushNamed(context, '/homework/edit');
                    if (result == true) _loadData();
                  },
                ),
                GlassNavAction(
                  icon: _searchMode ? CupertinoIcons.xmark : CupertinoIcons.search,
                  onTap: () => setState(() { _searchMode = !_searchMode; _searchQuery = ''; _searchController.clear(); }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassSegment<int>(
                groupValue: _filterIndex,
                children: const {
                  0: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('全部')),
                  1: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('未完成')),
                  2: Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('已完成')),
                },
                onValueChanged: (v) => setState(() { _filterIndex = v; _cachedFiltered = null; }),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return GlassEmptyState(
        icon: CupertinoIcons.doc_text,
        message: _filterIndex == 2 ? '还没有已完成的作业' : '暂无作业',
        hint: _filterIndex != 2 ? '点击右上角 ⊕ 添加作业' : null,
      );
    }

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 1)));

    final expired = _filtered.where((h) => h.dueDate.compareTo(todayStr) < 0 && !h.isCompleted).toList();
    final todayList = _filtered.where((h) => h.dueDate == todayStr && !h.isCompleted).toList();
    final tomorrowList = _filtered.where((h) => h.dueDate == tomorrowStr && !h.isCompleted).toList();
    final later = _filtered.where((h) => h.dueDate.compareTo(tomorrowStr) > 0 || h.isCompleted).toList();

    final sections = <_HwSection>[];
    if (expired.isNotEmpty) sections.add(_HwSection('已过期', CupertinoColors.systemRed, expired));
    if (todayList.isNotEmpty) sections.add(_HwSection('今天截止', CupertinoColors.systemOrange, todayList));
    if (tomorrowList.isNotEmpty) sections.add(_HwSection('明天截止', CupertinoColors.systemOrange, tomorrowList));
    if (later.isNotEmpty) sections.add(_HwSection('之后', null, later));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: sections.map((s) => _buildSection(s)).toList(),
    );
  }

  Widget _buildSection(_HwSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(section.title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: section.color ?? CupertinoColors.systemGrey)),
        ),
        ...section.items.map((hw) {
          final course = _courseMap[hw.courseId];
          final isExpired = hw.dueDate.compareTo(DateFormat('yyyy-MM-dd').format(DateTime.now())) < 0 && !hw.isCompleted;
          return CupertinoContextMenu(
            actions: [CupertinoContextMenuAction(isDestructiveAction: true, child: const Text('删除'),
                onPressed: () async {
                  await _hwService.delete(hw.id);
                  _homeworks.removeWhere((h) => h.id == hw.id);
                  _cachedFiltered = null;
                  setState(() {});
                })],
            child: GlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () async {
                final r = await Navigator.pushNamed(context, '/homework/edit', arguments: hw);
                if (r == true) _loadData();
              },
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleComplete(hw),
                    child: Icon(
                      hw.isCompleted ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                      size: 22,
                      color: hw.isCompleted ? CupertinoColors.systemGreen :
                          isExpired ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw.title, style: TextStyle(fontSize: 15,
                            decoration: hw.isCompleted ? TextDecoration.lineThrough : null,
                            color: hw.isCompleted ? CupertinoColors.systemGrey :
                                isExpired ? CupertinoColors.systemRed : null)),
                        Text('${course?.name ?? ''}  ${hw.dueDate}',
                            style: TextStyle(fontSize: 13,
                                color: isExpired ? CupertinoColors.systemRed : CupertinoColors.systemGrey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _HwSection {
  final String title;
  final Color? color;
  final List<Homework> items;
  _HwSection(this.title, this.color, this.items);
}
