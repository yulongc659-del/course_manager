import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../models/homework.dart';
import '../../models/course.dart';
import '../../services/homework_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';

class HomeworkFormPage extends StatefulWidget {
  const HomeworkFormPage({super.key});

  @override
  State<HomeworkFormPage> createState() => _HomeworkFormPageState();
}

class _HomeworkFormPageState extends State<HomeworkFormPage> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final _hwService = HomeworkService();
  List<Course> _courses = [];
  Course? _selectedCourse;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isEditing = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Homework) {
        _editingId = args.id;
        _isEditing = true;
        _titleController.text = args.title;
        _notesController.text = args.notes;
        _dueDate = DateFormat('yyyy-MM-dd').parse(args.dueDate);
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
        if (_isEditing && courses.isNotEmpty) {
          final args = ModalRoute.of(context)?.settings.arguments as Homework;
          _selectedCourse = courses.cast<Course?>().firstWhere(
                (c) => c!.id == args.courseId,
                orElse: () => courses.isNotEmpty ? courses.first : null,
              );
        } else {
          _selectedCourse = courses.isNotEmpty ? courses.first : null;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('提示'),
          content: Text('请输入作业标题'),
          actions: [CupertinoDialogAction(child: Text('确定'))],
        ),
      );
      return;
    }
    if (_selectedCourse == null) return;

    final dueStr = DateFormat('yyyy-MM-dd').format(_dueDate);

    if (_isEditing && _editingId != null) {
      await _hwService.update(Homework(
        id: _editingId!,
        courseId: _selectedCourse!.id,
        title: _titleController.text.trim(),
        dueDate: dueStr,
        notes: _notesController.text.trim(),
      ));
    } else {
      await _hwService.create(Homework(
        id: '',
        courseId: _selectedCourse!.id,
        title: _titleController.text.trim(),
        dueDate: dueStr,
        notes: _notesController.text.trim(),
      ));
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除作业'),
        content: const Text('确定要删除这项作业吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true && _editingId != null) {
      await _hwService.delete(_editingId!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_dueDate);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? '编辑作业' : '添加作业'),
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
              controller: _titleController,
              placeholder: '作业标题',
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
                            color: isDark
                                ? CupertinoColors.darkBackgroundGray
                                : CupertinoColors.systemBackground,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 36,
                            onSelectedItemChanged: (i) {
                              setState(() => _selectedCourse = _courses[i]);
                            },
                            children: _courses.map((c) =>
                                Center(child: Text(c.name))).toList(),
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedCourse?.name ?? '选择课程',
                            style: const TextStyle(fontSize: 15)),
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
                      initialDateTime: _dueDate,
                      onDateTimeChanged: (d) => setState(() => _dueDate = d),
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
                    const Text('截止日期', style: TextStyle(fontSize: 15)),
                    const Spacer(),
                    Text(dateStr, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.chevron_down, size: 14),
                  ],
                ),
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
                  child: const Text('删除此作业',
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
