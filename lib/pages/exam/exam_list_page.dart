import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/exam.dart';
import '../../models/course.dart';
import '../../services/exam_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';
import '../../widgets/countdown_card.dart';

class ExamListPage extends StatefulWidget {
  const ExamListPage({super.key});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  final _examService = ExamService();
  final _courseService = CourseService();

  List<Exam> _exams = [];
  Map<String, Course> _courseMap = {};
  bool _showExpired = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final semester = await SemesterService().getCurrent();
    if (semester == null) return;
    final courses = await _courseService.getBySemester(semester.id);
    final map = <String, Course>{};
    for (final c in courses) map[c.id] = c;
    final exams = await _examService.getAll();
    if (mounted) setState(() { _courseMap = map; _exams = exams; });
  }

  List<Exam> get _upcoming =>
      _exams.where((e) => e.date.compareTo(DateFormat('yyyy-MM-dd').format(DateTime.now())) >= 0).toList();
  List<Exam> get _expired =>
      _exams.where((e) => e.date.compareTo(DateFormat('yyyy-MM-dd').format(DateTime.now())) < 0).toList();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: _exams.isEmpty ? _buildEmpty() : _buildContent(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('考试',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
              ),
              GestureDetector(
                onTap: () async {
                  final r = await Navigator.pushNamed(context, '/exam/edit');
                  if (r == true) _loadData();
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(CupertinoIcons.add_circled, size: 22, color: CupertinoColors.systemBlue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.clock, size: 56,
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text('暂无考试',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey.withValues(alpha: 0.6))),
                const SizedBox(height: 6),
                const Text('点击右上角 ⊕ 添加考试',
                    style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text('考试',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ),
              GestureDetector(
                onTap: () async {
                  final r = await Navigator.pushNamed(context, '/exam/edit');
                  if (r == true) _loadData();
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(CupertinoIcons.add_circled, size: 22, color: CupertinoColors.systemBlue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('即将到来', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._upcoming.map((exam) => CountdownCard(exam: exam, course: _courseMap[exam.courseId],
            onTap: () async {
              final r = await Navigator.pushNamed(context, '/exam/edit', arguments: exam);
              if (r == true) _loadData();
            })),
        if (_expired.isNotEmpty) ...[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _showExpired = !_showExpired),
            child: Row(
              children: [
                Text('已结束 (${_expired.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CupertinoColors.systemGrey)),
                const Spacer(),
                Icon(_showExpired ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    size: 16, color: CupertinoColors.systemGrey),
              ],
            ),
          ),
          if (_showExpired) ...[
            const SizedBox(height: 12),
            ..._expired.map((exam) => CountdownCard(exam: exam, course: _courseMap[exam.courseId],
                onTap: () async {
                  final r = await Navigator.pushNamed(context, '/exam/edit', arguments: exam);
                  if (r == true) _loadData();
                })),
          ],
        ],
        const SizedBox(height: 80),
      ],
    );
  }
}
