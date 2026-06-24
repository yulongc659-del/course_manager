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
    for (final c in courses) {
      map[c.id] = c;
    }
    final exams = await _examService.getAll();
    if (mounted) {
      setState(() {
        _courseMap = map;
        _exams = exams;
      });
    }
  }

  List<Exam> get _upcoming {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _exams.where((e) => e.date.compareTo(today) >= 0).toList();
  }

  List<Exam> get _expired {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _exams.where((e) => e.date.compareTo(today) < 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('考试'),
        trailing: GestureDetector(
          onTap: () async {
            final result = await Navigator.pushNamed(context, '/exam/edit');
            if (result == true) _loadData();
          },
          child: const Icon(CupertinoIcons.add, size: 24),
        ),
      ),
      child: SafeArea(
        child: _exams.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.clock, size: 48, color: CupertinoColors.systemGrey),
                    const SizedBox(height: 8),
                    const Text('暂无考试', style: TextStyle(color: CupertinoColors.systemGrey)),
                  ],
                ),
              )
            : ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text('即将到来',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    ..._upcoming.map((exam) => CountdownCard(
                          exam: exam,
                          course: _courseMap[exam.courseId],
                          onTap: () async {
                            final result = await Navigator.pushNamed(
                                context, '/exam/edit', arguments: exam);
                            if (result == true) _loadData();
                          },
                        )),
                    if (_expired.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showExpired = !_showExpired),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Text('已结束 (${_expired.length})',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.systemGrey)),
                              const Spacer(),
                              Icon(
                                _showExpired ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                color: CupertinoColors.systemGrey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showExpired)
                        ..._expired.map((exam) => CountdownCard(
                              exam: exam,
                              course: _courseMap[exam.courseId],
                              onTap: () async {
                                final result = await Navigator.pushNamed(
                                    context, '/exam/edit', arguments: exam);
                                if (result == true) _loadData();
                              },
                            )),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }
}
