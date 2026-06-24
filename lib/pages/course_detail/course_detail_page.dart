import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../models/homework.dart';
import '../../models/exam.dart';
import '../../services/course_service.dart';
import '../../services/homework_service.dart';
import '../../services/exam_service.dart';
import '../../services/ai_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glass.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _courseService = CourseService();
  final _hwService = HomeworkService();
  final _examService = ExamService();

  Course? _course;
  List<Homework> _homeworks = [];
  List<Exam> _exams = [];
  bool _loading = true;

  String? _summary;
  bool _summaryLoading = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseId = ModalRoute.of(context)?.settings.arguments as String?;
      if (courseId != null) _loadData(courseId);
    });
  }

  Future<void> _loadData(String courseId) async {
    final course = await _courseService.getById(courseId);
    final hws = await _hwService.getByCourse(courseId);
    final exams = await _examService.getByCourse(courseId);
    final cached = await AiService.getCachedSummary(courseId);
    if (mounted) {
      setState(() {
        _course = course;
        _homeworks = hws;
        _exams = exams;
        _summary = cached;
        _loading = false;
      });
    }
  }

  Future<void> _generateSummary() async {
    if (_course == null) return;
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final summary = await AiService.summarizeCourse(_course!.name, _course!.id);
      setState(() {
        _summary = summary;
        _summaryLoading = false;
      });
    } catch (e) {
      setState(() {
        _summaryError = e.toString();
        _summaryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _course == null) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('课程详情')),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    final course = _course!;
    final color = courseColor(course.color);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(course.name),
        trailing: GestureDetector(
          onTap: () async {
            final result = await Navigator.pushNamed(
                context, '/course/edit', arguments: course);
            if (result == true) {
              if (mounted) Navigator.pop(context, true);
            }
          },
          child: const Icon(CupertinoIcons.pencil, size: 20),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(course.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (course.teacher.isNotEmpty)
                    _infoRow(CupertinoIcons.person, '授课教师', course.teacher),
                  if (course.classroom.isNotEmpty)
                    _infoRow(CupertinoIcons.location, '教室', course.classroom),
                  _infoRow(CupertinoIcons.time, '时间',
                      '${weekdayLabels[course.dayOfWeek - 1]} ${course.periodStart}-${course.periodEnd}节'),
                  _infoRow(CupertinoIcons.calendar, '周数',
                      '第 ${course.weekStart}-${course.weekEnd} 周'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAiSection(),
            const SizedBox(height: 16),
            const Text('关联作业',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_homeworks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('暂无作业', style: TextStyle(color: CupertinoColors.systemGrey)),
              )
            else
              ..._homeworks.map((hw) {
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                final isExpired = hw.dueDate.compareTo(today) < 0 && !hw.isCompleted;
                return GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        hw.isCompleted
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        size: 18,
                        color: hw.isCompleted
                            ? CupertinoColors.systemGreen
                            : isExpired
                                ? CupertinoColors.systemRed
                                : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hw.title,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: hw.isCompleted ? TextDecoration.lineThrough : null,
                            color: isExpired ? CupertinoColors.systemRed : null,
                          ),
                        ),
                      ),
                      Text(hw.dueDate,
                          style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? CupertinoColors.systemRed : CupertinoColors.systemGrey)),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                );
              }),
            const SizedBox(height: 16),
            const Text('关联考试',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_exams.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('暂无考试', style: TextStyle(color: CupertinoColors.systemGrey)),
              )
            else
              ..._exams.map((exam) {
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                final daysLeft = DateFormat('yyyy-MM-dd')
                    .parse(exam.date).difference(DateTime.now()).inDays;
                return GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        exam.date.compareTo(today) < 0
                            ? CupertinoIcons.check_mark_circled
                            : CupertinoIcons.clock,
                        size: 18,
                        color: exam.date.compareTo(today) < 0
                            ? CupertinoColors.systemGrey : CupertinoColors.systemOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exam.name, style: const TextStyle(fontSize: 14)),
                            Text('${exam.date} ${exam.time}  ${exam.location}',
                                style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey)),
                          ],
                        ),
                      ),
                      if (exam.date.compareTo(today) >= 0)
                        Text('$daysLeft 天',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: daysLeft <= 7 ? CupertinoColors.systemRed : CupertinoColors.systemGrey)),
                    ],
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.sparkles, size: 18),
              const SizedBox(width: 6),
              const Text('AI 总结',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_summary != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _generateSummary,
                  child: const Text('重新生成', style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_summaryLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(height: 6),
                    Text('AI 正在分析...', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_summaryError != null)
            Column(
              children: [
                Text('生成失败: $_summaryError',
                    style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 13)),
                const SizedBox(height: 6),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _generateSummary,
                  child: const Text('重试', style: TextStyle(fontSize: 13)),
                ),
              ],
            )
          else if (_summary != null)
            Text(_summary!, style: const TextStyle(fontSize: 14, height: 1.5))
          else
            Column(
              children: [
                const Text('使用 AI 分析课程内容，生成重点总结。',
                    style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
                const SizedBox(height: 8),
                CupertinoButton(
                  onPressed: _generateSummary,
                  child: const Text('生成 AI 总结'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: CupertinoColors.systemGrey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
