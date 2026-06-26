import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:table_calendar/table_calendar.dart' as tc;
import 'package:intl/intl.dart';
import '../../models/semester.dart';
import '../../models/course.dart';
import '../../services/semester_service.dart';
import '../../services/course_service.dart';
import '../../utils/constants.dart';
import '../../widgets/timetable_grid.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../services/widget_service.dart';
import '../../services/homework_service.dart';
import '../../services/exam_service.dart';
import '../../components/glass_card.dart';
import '../../components/glass_navbar.dart';
import '../../components/glass_dialog.dart';

enum TimetableView { grid, week, month }

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final _semesterService = SemesterService();
  final _courseService = CourseService();

  Semester? _currentSemester;
  List<Course> _courses = [];
  int _currentWeek = 1;
  TimetableView _view = TimetableView.grid;
  bool _loading = true;

  DateTime _focusedDay = DateTime.now();
  tc.CalendarFormat _calendarFormat = tc.CalendarFormat.week;

  bool _searchMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  Map<DateTime, List<Course>>? _cachedEvents;
  bool _eventsDirty = true;
  int _weekOffset = 0;

  bool _summaryLoading = false;

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
    final semester = await _semesterService.getCurrent();
    if (semester != null) {
      final courses = await _courseService.getBySemester(semester.id);
      final week = await _getCurrentWeek(semester);
      _weekOffset = await SettingsService.getWeekOffset();
      if (mounted) {
        setState(() {
          _currentSemester = semester;
          _courses = courses;
          _eventsDirty = true;
          _currentWeek = week;
          _loading = false;
        });
        _updateWidget();
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _calculateCurrentWeek(Semester semester) {
    final start = _getSemesterStart(semester.name);
    final now = DateTime.now();
    if (now.isBefore(start)) return 1;
    final offsetToMonday = start.weekday - DateTime.monday;
    final monday = start.subtract(Duration(days: offsetToMonday));
    final week = ((now.difference(monday).inDays) / 7).floor() + 1;
    return week.clamp(1, 20);
  }

  Future<int> _getCurrentWeek(Semester semester) async {
    final offset = await SettingsService.getWeekOffset();
    return (_calculateCurrentWeek(semester) + offset).clamp(1, 20);
  }

  DateTime _getSemesterStart(String name) {
    if (name.contains('春季')) return DateTime(DateTime.now().year, 3, 1);
    return DateTime(DateTime.now().year, 9, 1);
  }

  Future<void> _onSemesterChanged(Semester semester) async {
    await _semesterService.setCurrent(semester.id);
    final courses = await _courseService.getBySemester(semester.id);
    setState(() {
      _currentSemester = semester;
      _courses = courses;
      _eventsDirty = true;
    });
  }

  List<Course> get _weekCourses => _courses
      .where((c) => _currentWeek >= c.weekStart && _currentWeek <= c.weekEnd)
      .toList();

  List<Course> get _filteredCourses {
    final q = _searchQuery.toLowerCase();
    return _courses.where((c) =>
        c.name.toLowerCase().contains(q) || c.teacher.toLowerCase().contains(q)).toList();
  }

  Map<DateTime, List<Course>> get _calendarEvents {
    if (_eventsDirty || _cachedEvents == null) {
      _cachedEvents = <DateTime, List<Course>>{};
      for (final course in _courses) {
        for (int w = course.weekStart; w <= course.weekEnd; w++) {
          final date = _weekAndDayToDate(w, course.dayOfWeek);
          if (date != null) {
            final key = DateTime(date.year, date.month, date.day);
            _cachedEvents!.putIfAbsent(key, () => []).add(course);
          }
        }
      }
      _eventsDirty = false;
    }
    return _cachedEvents!;
  }

  DateTime? _weekAndDayToDate(int week, int dayOfWeek) {
    if (_currentSemester == null) return null;
    final start = _getSemesterStart(_currentSemester!.name);
    final offsetToMonday = start.weekday - DateTime.monday;
    final monday = start.subtract(Duration(days: offsetToMonday));
    final adjustedWeek = week - _weekOffset;
    return monday.add(Duration(days: (adjustedWeek - 1) * 7 + (dayOfWeek - 1)));
  }

  List<Course> _coursesForDay(DateTime day) =>
      _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CupertinoPageScaffold(
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final hasSearch = _searchQuery.isNotEmpty;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoTheme.of(context)
          .scaffoldBackgroundColor ?? CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: _currentSemester == null
            ? _buildEmpty('请先创建学期', icon: CupertinoIcons.exclamationmark_circle)
            : hasSearch
                ? _buildSearchResults()
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        if (_searchMode) _buildSearchBar() else
          GlassLargeTitle(
            title: '课表',
            subtitle: _currentSemester?.name,
            actions: [
            GlassNavAction(
              icon: CupertinoIcons.add_circled,
              onTap: _showAddMenu,
            ),
            GlassNavAction(
              icon: _searchMode ? CupertinoIcons.xmark : CupertinoIcons.search,
              onTap: () => setState(() {
                _searchMode = !_searchMode;
                _searchQuery = '';
                _searchController.clear();
              }),
            ),
            GlassNavAction(
              icon: CupertinoIcons.gear,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildViewToggle(),
        ),

        const SizedBox(height: 12),

        // Content
        if (_view == TimetableView.grid) ...[
          _buildWeekSelector(),
          const SizedBox(height: 8),
          _buildAiWeekButton(),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: _weekCourses.isEmpty
                ? _buildEmpty('本周没有课程',
                    icon: CupertinoIcons.calendar,
                    hint: '点击右上角 ⊕ 添加课程')
                : RepaintBoundary(
                    child: TimetableGrid(
                      courses: _weekCourses,
                      onCourseTap: (course) => Navigator.pushNamed(
                          context, '/course/detail', arguments: course.id),
                    ),
                  ),
            ),
          ),
        ] else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: _buildCalendar(),
            ),
          ),
      ],
    );
  }

  // Uses GlassNavAction from components

  Widget _buildWeekSelector() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < 0 && _currentWeek < 20) _currentWeek++;
        else if (details.primaryVelocity! > 0 && _currentWeek > 1) _currentWeek--;
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text('第 $_currentWeek 周',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _currentWeek > 1 ? () { _currentWeek--; setState(() {}); } : null,
              child: const Icon(CupertinoIcons.chevron_left, size: 18),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _currentWeek < 20 ? () { _currentWeek++; setState(() {}); } : null,
              child: const Icon(CupertinoIcons.chevron_right, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _viewButton(TimetableView.grid, CupertinoIcons.square_grid_2x2, isDark),
        const SizedBox(width: 4),
        _viewButton(TimetableView.week, CupertinoIcons.calendar, isDark),
        const SizedBox(width: 4),
        _viewButton(TimetableView.month, CupertinoIcons.calendar_circle, isDark),
      ],
    );
  }

  Widget _viewButton(TimetableView mode, IconData icon, bool isDark) {
    final selected = _view == mode;
    return GestureDetector(
      onTap: () {
        _calendarFormat = mode == TimetableView.month
            ? tc.CalendarFormat.month : tc.CalendarFormat.week;
        setState(() => _view = mode);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? CupertinoTheme.of(context).primaryColor
              : (isDark
                  ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.7)
                  : CupertinoColors.white.withValues(alpha: 0.7)),
          border: selected
              ? null
              : Border.all(color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey4, context).withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey4, context).withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 18,
            color: selected ? CupertinoColors.white : CupertinoColors.systemGrey),
      ),
    );
  }

  Widget _buildCalendar() {
    return Material(
      type: MaterialType.canvas,
      color: CupertinoTheme.of(context).brightness == Brightness.dark
          ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemBackground,
      child: Column(
        children: [
          tc.TableCalendar<Course>(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              tc.CalendarFormat.week: '周',
              tc.CalendarFormat.month: '月',
            },
            onFormatChanged: (f) => setState(() => _calendarFormat = f),
            selectedDayPredicate: (day) =>
                day.year == _focusedDay.year && day.month == _focusedDay.month && day.day == _focusedDay.day,
            onDaySelected: (selectedDay, _) => setState(() => _focusedDay = selectedDay),
            onPageChanged: (day) => setState(() => _focusedDay = day),
            eventLoader: (day) => _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [],
            calendarStyle: tc.CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 14),
              weekendTextStyle: const TextStyle(fontSize: 14),
            ),
            headerStyle: const tc.HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          Container(height: 1, color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey5, context)),
          Expanded(child: _buildDayDetail()),
        ],
      ),
    );
  }

  Widget _buildDayDetail() {
    final selectedEvents = _coursesForDay(_focusedDay);
    if (selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.calendar, size: 36, color: CupertinoColors.systemGrey),
            const SizedBox(height: 8),
            Text('${DateFormat('M月d日 EEEE', 'zh_CN').format(_focusedDay)} 无课程',
                style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text(DateFormat('M月d日 EEEE', 'zh_CN').format(_focusedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...selectedEvents.map((course) {
          final color = courseColor(course.color);
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () => Navigator.pushNamed(context, '/course/detail', arguments: course.id),
            child: Row(
              children: [
                Container(width: 4, height: 36,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      Text('${course.periodStart}-${course.periodEnd}节  ${course.classroom}',
                          style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, size: 14, color: CupertinoColors.systemGrey),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredCourses.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildEmpty('未找到匹配课程', icon: CupertinoIcons.search)),
        ],
      );
    }
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: _filteredCourses.map((course) {
              final color = courseColor(course.color);
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => Navigator.pushNamed(context, '/course/detail', arguments: course.id),
                child: Row(
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          Text(
                            '${course.teacher}  ${weekdayLabels[course.dayOfWeek - 1]} ${course.periodStart}-${course.periodEnd}节',
                            style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _updateWidget() {
    if (_currentSemester != null) {
      WidgetService.updateWidget(
        currentWeek: _currentWeek,
        semesterName: _currentSemester!.name,
        weekCourses: _weekCourses,
      );
    }
  }

  void _showAddMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('添加'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(context, '/course/edit');
              if (result == true) _loadData();
            },
            child: const Text('手动添加课程'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(context, '/import');
              if (result == true) _loadData();
            },
            child: const Text('导入课表'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              autofocus: true,
              placeholder: '搜索课程或老师...',
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() {
              _searchMode = false;
              _searchQuery = '';
              _searchController.clear();
            }),
            child: const Text('取消', style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiWeekButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _summaryLoading ? null : _generateWeekSummary,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemBlue.withValues(alpha: 0.08),
                CupertinoColors.systemPurple.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: CupertinoColors.systemBlue.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _summaryLoading ? CupertinoIcons.clock : CupertinoIcons.sparkles,
                size: 18,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 8),
              Text(
                _summaryLoading ? 'AI 正在生成...' : 'AI 生成第 $_currentWeek 周学习计划',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: CupertinoColors.systemBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateWeekSummary() async {
    setState(() => _summaryLoading = true);
    try {
      final hwService = HomeworkService();
      final examService = ExamService();
      final allHw = await hwService.getAll();
      final allExam = await examService.getAll();
      final hwText = allHw.map((h) => '${h.title}(${h.dueDate})').join('; ');
      final examText = allExam.map((e) => '${e.name}(${e.date})').join('; ');

      final summary = await AiService.summarizeWeek(
        _currentWeek,
        _weekCourses.map((c) => c.name).toList(),
        hwText,
        examText,
        '',
      );
      setState(() => _summaryLoading = false);
      if (mounted) _showSummarySheet(summary);
    } catch (e) {
      setState(() => _summaryLoading = false);
      if (mounted) {
        showGlassDialog(context: context, title: '生成失败', content: e.toString());
      }
    }
  }

  void _showSummarySheet(String summary) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).brightness == Brightness.dark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.systemGroupedBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 5,
                  decoration: BoxDecoration(color: CupertinoColors.systemGrey4, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Icon(CupertinoIcons.sparkles, size: 18, color: CupertinoColors.systemBlue),
                  const SizedBox(width: 6),
                  Text('第 $_currentWeek 周 AI 学习计划',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: CupertinoColors.systemGrey),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(summary, style: const TextStyle(fontSize: 14, height: 1.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(String message, {IconData icon = CupertinoIcons.calendar, String? hint}) {
    return GlassEmptyState(icon: icon, message: message, hint: hint);
  }
}
