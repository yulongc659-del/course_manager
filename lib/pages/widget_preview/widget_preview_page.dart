import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../services/semester_service.dart';
import '../../services/course_service.dart';
import '../../services/settings_service.dart';
import '../../utils/constants.dart';
import '../../components/glass_card.dart';

class WidgetPreviewPage extends StatefulWidget {
  const WidgetPreviewPage({super.key});

  @override
  State<WidgetPreviewPage> createState() => _WidgetPreviewPageState();
}

class _WidgetPreviewPageState extends State<WidgetPreviewPage> {
  List<Course> _todayCourses = [];
  int _currentWeek = 1;
  String _semesterName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final semester = await SemesterService().getCurrent();
    if (semester != null) {
      final courses = await CourseService().getBySemester(semester.id);
      final now = DateTime.now();
      final today = now.weekday;

      // Calculate current week based on semester start
      final startMonth = semester.name.contains('春季') ? 3 : 9;
      final start = DateTime(now.year, startMonth, 1);
      final startMonday = start.subtract(Duration(days: start.weekday - DateTime.monday));
      final baseWeek = now.isBefore(startMonday)
          ? 1
          : ((now.difference(startMonday).inDays) / 7).floor() + 1;
      final offset = await SettingsService.getWeekOffset();
      final week = (baseWeek + offset).clamp(1, 20);

      // Get today's courses that fall in the current week
      final todayList = courses
          .where((c) =>
              c.dayOfWeek == today &&
              week >= c.weekStart &&
              week <= c.weekEnd)
          .toList()
        ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

      if (mounted) {
        setState(() {
          _todayCourses = todayList;
          _currentWeek = week.clamp(1, 20);
          _semesterName = semester.name;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Widget 预览')),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Widget 预览')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('小组件预览',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('以下模拟 iOS 主屏幕上的 Widget 效果',
                  style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
              const SizedBox(height: 24),

              // Small
              const Text('小尺寸 (2×2)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildSmallWidget(),
              const SizedBox(height: 32),

              // Medium
              const Text('中尺寸 (4×2)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildMediumWidget(),
              const SizedBox(height: 32),

              // Large
              const Text('大尺寸 (4×4)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildLargeWidget(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallWidget() {
    final nextClass = _findNextClass();
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).brightness == Brightness.dark
            ? CupertinoColors.darkBackgroundGray.withValues(alpha: 0.6)
            : CupertinoColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CupertinoColors.systemGrey5, width: 0.5),
        boxShadow: [
          BoxShadow(color: CupertinoColors.systemGrey4.withValues(alpha: 0.2), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_semesterName, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('W$_currentWeek',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: CupertinoColors.systemBlue)),
            ),
          ]),
          const Spacer(),
          if (nextClass != null) ...[
            const Text('下一节', style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
            const SizedBox(height: 6),
            Row(children: [
              Container(width: 4, height: 36,
                  decoration: BoxDecoration(
                    color: courseColor(nextClass.color),
                    borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nextClass.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    _getPeriodTime(nextClass.periodStart),
                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                ]),
              ),
            ]),
            const SizedBox(height: 6),
            if (nextClass.classroom.isNotEmpty)
              Row(children: [
                const Icon(CupertinoIcons.location, size: 12, color: CupertinoColors.systemGrey),
                const SizedBox(width: 4),
                Text(nextClass.classroom, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              ]),
          ] else ...[
            const Icon(CupertinoIcons.check_mark_circled_solid, size: 28, color: CupertinoColors.systemGreen),
            const SizedBox(height: 4),
            const Text('今日无课', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMediumWidget() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('今日课程', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('W$_currentWeek', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          Text(
            DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
            style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 10),
          if (_todayCourses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('今日无课程安排', style: TextStyle(color: CupertinoColors.systemGrey)),
              ),
            )
          else
            ..._todayCourses.take(4).map((c) {
              final color = courseColor(c.color);
              final timeKey = (c.periodStart - 1) ~/ 2;
              final time = timeKey < periodTimes.length ? periodTimes[timeKey] : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      Text(time,
                          style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${c.periodStart}-${c.periodEnd}节',
                        style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                    if (c.classroom.isNotEmpty)
                      Text(c.classroom, style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                  ]),
                ]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLargeWidget() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('今日课程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text(DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
                  style: const TextStyle(color: CupertinoColors.systemGrey)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('W$_currentWeek',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              Text('${_todayCourses.length}门',
                  style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
            ]),
          ]),
          if (_todayCourses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Icon(CupertinoIcons.check_mark_circled_solid, size: 48, color: CupertinoColors.systemGreen),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            Container(height: 0.5, color: CupertinoColors.systemGrey5),
            const SizedBox(height: 8),
            ..._todayCourses.asMap().entries.map((e) {
              final c = e.value;
              final color = courseColor(c.color);
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Row(children: [
                          Text('${c.periodStart}-${c.periodEnd}节',
                              style: const TextStyle(fontSize: 11)),
                          if (c.teacher.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(c.teacher,
                                style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey)),
                          ],
                        ]),
                      ]),
                    ),
                    Text(
                      periodTimes[(c.periodStart - 1) ~/ 2],
                      style: const TextStyle(fontSize: 11, color: CupertinoColors.systemGrey),
                    ),
                  ]),
                ),
                if (e.key < _todayCourses.length - 1)
                  Container(height: 0.5, color: CupertinoColors.systemGrey5),
              ]);
            }),
            const SizedBox(height: 12),
            Container(height: 0.5, color: CupertinoColors.systemGrey5),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(CupertinoIcons.sparkles, size: 14, color: CupertinoColors.systemBlue),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('打开 App 查看 AI 今日学习建议',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  String _getPeriodTime(int periodStart) {
    final idx = (periodStart - 1) ~/ 2;
    return idx < periodTimes.length ? periodTimes[idx] : '';
  }

  Course? _findNextClass() {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final c in _todayCourses) {
      // Get start time of this course in minutes
      final si = (c.periodStart - 1) ~/ 2;
      if (si >= periodTimes.length) continue;
      final startStr = periodTimes[si].split('-')[0]; // "08:30"
      final parts = startStr.split(':');
      final startMinutes = int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;

      if (startMinutes > nowMinutes) return c; // Future course found
    }
    // If no future course, return the first course (for display)
    if (_todayCourses.isNotEmpty && _todayCourses.first.periodStart > nowMinutes ~/ 60) {
      return _todayCourses.first;
    }
    return null;
  }
}
