import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/homework.dart';
import '../../models/course.dart';
import '../../services/homework_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';
import '../../widgets/glass.dart';

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
    for (final c in courses) {
      map[c.id] = c;
    }
    final homeworks = await _hwService.getAll();
    if (mounted) {
      setState(() {
        _courseMap = map;
        _homeworks = homeworks;
      });
    }
  }

  List<Homework> get _filtered {
    var list = _homeworks;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((h) => h.title.toLowerCase().contains(q)).toList();
    }
    if (_filterIndex == 1) {
      list = list.where((h) => !h.isCompleted).toList();
    } else if (_filterIndex == 2) {
      list = list.where((h) => h.isCompleted).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: _searchMode
            ? CupertinoSearchTextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                autofocus: true,
              )
            : const Text('作业'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/homework/edit');
                if (result == true) _loadData();
              },
              child: const Icon(CupertinoIcons.add, size: 24),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchMode = !_searchMode;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Icon(
                _searchMode ? CupertinoIcons.clear : CupertinoIcons.search,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoSegmentedControl<int>(
                  groupValue: _filterIndex,
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('全部'),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('未完成'),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('已完成'),
                    ),
                  },
                  onValueChanged: (v) => setState(() => _filterIndex = v),
                ),
              ),
              Expanded(child: _buildList()),
            ],
          ),
        ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_text, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 8),
            Text(
              _filterIndex == 2 ? '还没有已完成的作业' : '暂无作业',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      );
    }

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 1)));

    final expired = _filtered
        .where((h) => h.dueDate.compareTo(todayStr) < 0 && !h.isCompleted).toList();
    final todayList = _filtered
        .where((h) => h.dueDate == todayStr && !h.isCompleted).toList();
    final tomorrowList = _filtered
        .where((h) => h.dueDate == tomorrowStr && !h.isCompleted).toList();
    final later = _filtered
        .where((h) => h.dueDate.compareTo(tomorrowStr) > 0 || h.isCompleted).toList();

    final sections = <_HwSection>[];
    if (expired.isNotEmpty) sections.add(_HwSection('已过期', CupertinoColors.systemRed, expired));
    if (todayList.isNotEmpty) sections.add(_HwSection('今天截止', CupertinoColors.systemOrange, todayList));
    if (tomorrowList.isNotEmpty) sections.add(_HwSection('明天截止', CupertinoColors.systemOrange, tomorrowList));
    if (later.isNotEmpty) sections.add(_HwSection('之后', null, later));

    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (_, i) => _buildSection(sections[i]),
    );
  }

  Widget _buildSection(_HwSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            section.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: section.color ?? CupertinoColors.systemGrey,
            ),
          ),
        ),
        ...section.items.map((hw) {
          final course = _courseMap[hw.courseId];
          final isExpired = hw.dueDate
              .compareTo(DateFormat('yyyy-MM-dd').format(DateTime.now())) < 0 && !hw.isCompleted;

          return CupertinoContextMenu(
            actions: [
              CupertinoContextMenuAction(
                isDestructiveAction: true,
                child: const Text('删除'),
                onPressed: () async {
                  await _hwService.delete(hw.id);
                  await _loadData();
                },
              ),
            ],
            child: GlassCard(
              onTap: () async {
                final result = await Navigator.pushNamed(
                    context, '/homework/edit', arguments: hw);
                if (result == true) _loadData();
              },
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _hwService.toggleComplete(hw.id);
                      await _loadData();
                    },
                    child: Icon(
                      hw.isCompleted
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color: hw.isCompleted
                          ? CupertinoColors.systemGreen
                          : isExpired
                              ? CupertinoColors.systemRed
                              : CupertinoColors.systemGrey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hw.title,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: hw.isCompleted ? TextDecoration.lineThrough : null,
                            color: hw.isCompleted
                                ? CupertinoColors.systemGrey
                                : isExpired
                                    ? CupertinoColors.systemRed
                                    : null,
                          ),
                        ),
                        Text(
                          '${course?.name ?? '未知课程'}  ${hw.dueDate}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isExpired ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey),
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
