import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/exam.dart';
import '../../models/course.dart';
import '../../services/exam_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';

class ExamFormPage extends StatefulWidget {
  const ExamFormPage({super.key});

  @override
  State<ExamFormPage> createState() => _ExamFormPageState();
}

class _ExamFormPageState extends State<ExamFormPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  final _examService = ExamService();
  List<Course> _courses = [];
  Course? _selectedCourse;
  DateTime _date = DateTime.now().add(const Duration(days: 30));
  DateTime _time = DateTime(2024, 1, 1, 9, 0);
  bool _isEditing = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Exam) {
        _editingId = args.id;
        _isEditing = true;
        _nameController.text = args.name;
        _locationController.text = args.location;
        _notesController.text = args.notes;
        _date = DateFormat('yyyy-MM-dd').parse(args.date);
        if (args.time.isNotEmpty) {
          final parts = args.time.split(':');
          _time = DateTime(2024, 1, 1,
              int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0);
        }
      }
      _loadCourses();
    });
  }

  Future<void> _loadCourses() async {
    final semester = await SemesterService().getCurrent();
    if (semester == null) return;
    final courses = await CourseService().getBySemester(semester.id);
    if (mounted) {
      setState(() {
        _courses = courses;
        _selectedCourse ??= courses.isNotEmpty ? courses.first : null;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('提示'),
          content: Text('请输入考试名称'),
          actions: [CupertinoDialogAction(child: Text('确定'))],
        ),
      );
      return;
    }
    if (_selectedCourse == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final timeStr = DateFormat('HH:mm').format(_time);

    if (_isEditing && _editingId != null) {
      await _examService.update(Exam(
        id: _editingId!,
        courseId: _selectedCourse!.id,
        name: _nameController.text.trim(),
        date: dateStr,
        time: timeStr,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      ));
    } else {
      await _examService.create(Exam(
        id: '',
        courseId: _selectedCourse!.id,
        name: _nameController.text.trim(),
        date: dateStr,
        time: timeStr,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      ));
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除考试'),
        content: const Text('确定要删除这项考试吗？'),
        actions: [
          CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.pop(context, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('删除'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed == true && _editingId != null) {
      await _examService.delete(_editingId!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_date);
    final timeStr = DateFormat('HH:mm').format(_time);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? '编辑考试' : '添加考试'),
        trailing: GestureDetector(
          onTap: _save,
          child: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('保存', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CupertinoTextField(
              controller: _nameController,
              placeholder: '考试名称',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
              child: Row(
                children: [
                  const Text('关联课程', style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (_) => Container(
                          height: 260,
                          decoration: BoxDecoration(
                            color: isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemBackground,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 36,
                            onSelectedItemChanged: (i) => setState(() => _selectedCourse = _courses[i]),
                            children: _courses.map((c) => Center(child: Text(c.name))).toList(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedCourse?.name ?? '选择课程', style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_down, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => SizedBox(
                    height: 260,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: _date,
                      onDateTimeChanged: (d) => setState(() => _date = d),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CupertinoColors.systemGrey6,
                ),
                child: Row(
                  children: [
                    const Text('考试日期', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text(dateStr, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_down, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => SizedBox(
                    height: 260,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: _time,
                      onDateTimeChanged: (d) => setState(() => _time = d),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CupertinoColors.systemGrey6,
                ),
                child: Row(
                  children: [
                    const Text('考试时间', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text(timeStr, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_down, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _locationController,
              placeholder: '地点',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _notesController,
              placeholder: '备注',
              maxLines: 3,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _delete,
                  child: const Text('删除此考试',
                      style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
