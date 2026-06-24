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
import '../../widgets/glass.dart';

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

  // 缓存
  Map<DateTime, List<Course>>? _cachedEvents;
  bool _eventsDirty = true;

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
      if (mounted) {
        setState(() {
          _currentSemester = semester;
          _courses = courses;
          _eventsDirty = true;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
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

  List<Course> get _weekCourses {
    return _courses
        .where((c) =>
            _currentWeek >= c.weekStart && _currentWeek <= c.weekEnd)
        .toList();
  }

  List<Course> get _filteredCourses {
    final q = _searchQuery.toLowerCase();
    return _courses
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.teacher.toLowerCase().contains(q))
        .toList();
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
    final semesterDate = DateTime.parse(_currentSemester!.createdAt);
    int offsetToMonday = semesterDate.weekday - DateTime.monday;
    final monday = semesterDate.subtract(Duration(days: offsetToMonday));
    return monday.add(Duration(days: (week - 1) * 7 + (dayOfWeek - 1)));
  }

  List<Course> _coursesForDay(DateTime day) {
    return _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('课表')),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final hasSearch = _searchQuery.isNotEmpty;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: _searchMode
            ? CupertinoSearchTextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                autofocus: true,
              )
            : Text(_currentSemester?.name ?? '课程管理器'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/course/edit');
                if (result == true) _loadData();
              },
              child: const Icon(CupertinoIcons.add, size: 24),
            ),
            if (!_searchMode) ...[
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => setState(() {
                  _searchMode = !_searchMode;
                  _searchQuery = '';
                  _searchController.clear();
                }),
                child: const Icon(CupertinoIcons.search, size: 20),
              ),
            ] else
              GestureDetector(
                onTap: () => setState(() {
                  _searchMode = false;
                  _searchQuery = '';
                  _searchController.clear();
                }),
                child: const Icon(CupertinoIcons.clear, size: 20),
              ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/import');
                if (result == true) _loadData();
              },
              child: const Icon(CupertinoIcons.doc_on_clipboard, size: 20),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/settings'),
              child: const Icon(CupertinoIcons.gear, size: 20),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: _currentSemester == null
            ? Center(
                child: Text('请先创建学期',
                    style: TextStyle(color: CupertinoColors.systemGrey)),
              )
            : hasSearch
                ? _buildSearchResults()
                : Column(
                    children: [
                      _buildViewToggle(),
                      if (_view == TimetableView.grid) ...[
                        _buildWeekSelector(),
                        Expanded(
                          child: _weekCourses.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(CupertinoIcons.calendar,
                                          size: 48, color: CupertinoColors.systemGrey),
                                      const SizedBox(height: 8),
                                      Text('第 $_currentWeek 周没有课程',
                                          style: const TextStyle(
                                              color: CupertinoColors.systemGrey)),
                                    ],
                                  ),
                                )
                              : RepaintBoundary(
                                child: TimetableGrid(
                                  courses: _weekCourses,
                                  onCourseTap: (course) {
                                    Navigator.pushNamed(
                                      context,
                                      '/course/detail',
                                      arguments: course.id,
                                    );
                                  },
                                ),
                              ),
                        ),
                      ] else
                        Expanded(child: _buildCalendar()),
                    ],
                  ),
      ),
    );
  }

  Widget _buildWeekSelector() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < 0 && _currentWeek < 20) {
          setState(() => _currentWeek++);
        } else if (details.primaryVelocity! > 0 && _currentWeek > 1) {
          setState(() => _currentWeek--);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _currentWeek > 1
                  ? () => setState(() => _currentWeek--)
                  : null,
              child: const Icon(CupertinoIcons.chevron_left, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              '第 $_currentWeek 周',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _currentWeek < 20
                  ? () => setState(() => _currentWeek++)
                  : null,
              child: const Icon(CupertinoIcons.chevron_right, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CupertinoSegmentedControl<TimetableView>(
            groupValue: _view,
            children: const {
              TimetableView.grid: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Icon(CupertinoIcons.square_grid_2x2, size: 18),
              ),
              TimetableView.week: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Icon(CupertinoIcons.calendar, size: 18),
              ),
              TimetableView.month: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Icon(CupertinoIcons.calendar_circle, size: 18),
              ),
            },
            onValueChanged: (v) {
              if (v == null) return;
              setState(() {
                _view = v;
                _calendarFormat = v == TimetableView.month
                    ? tc.CalendarFormat.month
                    : tc.CalendarFormat.week;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final events = _calendarEvents;

    return Material(
      type: MaterialType.canvas,
      color: CupertinoTheme.of(context).brightness == Brightness.dark
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemBackground,
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
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          selectedDayPredicate: (day) =>
              day.year == _focusedDay.year &&
              day.month == _focusedDay.month &&
              day.day == _focusedDay.day,
          onDaySelected: (selectedDay, _) {
            setState(() => _focusedDay = selectedDay);
          },
          onPageChanged: (day) {
            setState(() => _focusedDay = day);
          },
          eventLoader: (day) {
            return events[DateTime(day.year, day.month, day.day)] ?? [];
          },
          calendarStyle: tc.CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            defaultTextStyle: const TextStyle(fontSize: 14),
            weekendTextStyle: const TextStyle(fontSize: 14),
          ),
          headerStyle: const tc.HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
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
            Icon(CupertinoIcons.calendar, size: 40, color: CupertinoColors.systemGrey),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('M月d日 EEEE', 'zh_CN').format(_focusedDay)} 无课程',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          DateFormat('M月d日 EEEE', 'zh_CN').format(_focusedDay),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...selectedEvents.map((course) {
          final color = courseColor(course.color);
          return GlassCard(
            onTap: () => Navigator.pushNamed(
                context, '/course/detail', arguments: course.id),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      Text(
                        '${course.periodStart}-${course.periodEnd}节  '
                        '${course.classroom.isNotEmpty ? course.classroom : ''}'
                        '${course.teacher.isNotEmpty ? '  ${course.teacher}' : ''}',
                        style: const TextStyle(
                            fontSize: 13, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    size: 16, color: CupertinoColors.systemGrey),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.search, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 8),
            const Text('未找到匹配课程',
                style: TextStyle(color: CupertinoColors.systemGrey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        final color = courseColor(course.color);
        return GlassCard(
          onTap: () => Navigator.pushNamed(
              context, '/course/detail', arguments: course.id),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    Text(
                      '${course.teacher}  '
                      '${weekdayLabels[course.dayOfWeek - 1]} '
                      '${course.periodStart}-${course.periodEnd}节',
                      style: const TextStyle(
                          fontSize: 13, color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
