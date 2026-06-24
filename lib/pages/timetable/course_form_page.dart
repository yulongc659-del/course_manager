import 'package:flutter/cupertino.dart';
import '../../models/course.dart';
import '../../models/semester.dart';
import '../../services/semester_service.dart';
import '../../services/course_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glass.dart';

class CourseFormPage extends StatefulWidget {
  const CourseFormPage({super.key});

  @override
  State<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends State<CourseFormPage> {
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();

  int _dayOfWeek = 1;
  int _periodStart = 1;
  int _periodEnd = 2;
  int _weekStart = 1;
  int _weekEnd = 16;
  int _color = 0;

  Course? _editingCourse;
  Semester? _semester;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Course) {
        _editingCourse = args;
        _isEditing = true;
        _nameController.text = args.name;
        _teacherController.text = args.teacher;
        _classroomController.text = args.classroom;
        _dayOfWeek = args.dayOfWeek;
        _periodStart = args.periodStart;
        _periodEnd = args.periodEnd;
        _weekStart = args.weekStart;
        _weekEnd = args.weekEnd;
        _color = args.color;
      }
      _loadSemester();
    });
  }

  Future<void> _loadSemester() async {
    final s = await SemesterService().getCurrent();
    if (mounted) setState(() => _semester = s);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('请输入课程名称'),
          actions: [
            CupertinoDialogAction(child: const Text('确定'), onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
      return;
    }
    if (_semester == null) return;

    final course = Course(
      id: _editingCourse?.id ?? '',
      semesterId: _semester!.id,
      name: _nameController.text.trim(),
      teacher: _teacherController.text.trim(),
      classroom: _classroomController.text.trim(),
      dayOfWeek: _dayOfWeek,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      weekStart: _weekStart,
      weekEnd: _weekEnd,
      color: _color,
      createdAt: _editingCourse?.createdAt,
    );

    if (_isEditing) {
      await CourseService().update(course);
    } else {
      await CourseService().create(course);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (_editingCourse == null) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除「${_editingCourse!.name}」吗？\n相关的作业和考试也会被删除。'),
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
    if (confirmed == true) {
      await CourseService().delete(_editingCourse!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = '${weekdayLabels[_dayOfWeek - 1]} '
        '${_periodStart}-${_periodEnd}节  第$_weekStart-${_weekEnd}周';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? '编辑课程' : '添加课程'),
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
              placeholder: '课程名称',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _teacherController,
              placeholder: '授课教师',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _classroomController,
              placeholder: '教室',
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: CupertinoColors.systemGrey6,
              ),
            ),
            const SizedBox(height: 16),
            _pickerRow('星期', _dayOfWeek, weekdayLabels,
                (v) => setState(() => _dayOfWeek = v)),
            _periodRow(),
            _weekRangeRow(),
            const SizedBox(height: 16),
            _colorPicker(),
            const SizedBox(height: 16),
            _buildPreview(preview),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              AppleButton(
                onPressed: _delete,
                child: const Text('删除此课程',
                    style: TextStyle(color: CupertinoColors.destructiveRed)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pickerRow(String label, int value, List<String> items, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 15))),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
              onPressed: () => _showPicker(label, value, items, onChanged),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(items[value - 1]),
                  const Icon(CupertinoIcons.chevron_down, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(String label, int value, List<String> items, ValueChanged<int> onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 240,
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).brightness == Brightness.dark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: CupertinoPicker(
          itemExtent: 36,
          onSelectedItemChanged: (i) => onChanged(i + 1),
          children: items.map((t) => Center(child: Text(t))).toList(),
        ),
      ),
    );
  }

  Widget _periodRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 80, child: Text('节次', style: TextStyle(fontSize: 15))),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).brightness == Brightness.dark
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.systemBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 36,
                      onSelectedItemChanged: (i) {
                        setState(() {
                          _periodStart = i + 1;
                          if (_periodEnd < i + 1) _periodEnd = i + 1;
                        });
                      },
                      children: List.generate(12, (i) =>
                          Center(child: Text('${i + 1}'))),
                    ),
                  ),
                );
              },
              child: Text('$_periodStart'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('到', style: TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).brightness == Brightness.dark
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.systemBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 36,
                      onSelectedItemChanged: (i) =>
                          setState(() => _periodEnd = i + 1),
                      children: List.generate(12, (i) {
                        final enabled = i + 1 >= _periodStart;
                        return Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: enabled ? null : CupertinoColors.systemGrey)));
                      }),
                    ),
                  ),
                );
              },
              child: Text('$_periodEnd'),
            ),
          ),
          const SizedBox(width: 4, child: Text('节')),
        ],
      ),
    );
  }

  Widget _weekRangeRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 80, child: Text('周数范围', style: TextStyle(fontSize: 15))),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).brightness == Brightness.dark
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.systemBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 36,
                      onSelectedItemChanged: (i) {
                        setState(() {
                          _weekStart = i + 1;
                          if (_weekEnd < i + 1) _weekEnd = i + 1;
                        });
                      },
                      children: List.generate(20, (i) =>
                          Center(child: Text('${i + 1}'))),
                    ),
                  ),
                );
              },
              child: Text('$_weekStart'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('到', style: TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (_) => Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).brightness == Brightness.dark
                          ? CupertinoColors.darkBackgroundGray
                          : CupertinoColors.systemBackground,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: CupertinoPicker(
                      itemExtent: 36,
                      onSelectedItemChanged: (i) =>
                          setState(() => _weekEnd = i + 1),
                      children: List.generate(20, (i) {
                        final enabled = i + 1 >= _weekStart;
                        return Center(
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: enabled ? null : CupertinoColors.systemGrey)));
                      }),
                    ),
                  ),
                );
              },
              child: Text('$_weekEnd'),
            ),
          ),
          const SizedBox(width: 4, child: Text('周')),
        ],
      ),
    );
  }

  Widget _colorPicker() {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('颜色', style: TextStyle(fontSize: 15))),
        ...List.generate(courseColors.length, (i) {
          final selected = _color == i;
          return GestureDetector(
            onTap: () => setState(() => _color = i),
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: courseColors[i],
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [BoxShadow(color: courseColors[i].withValues(alpha: 0.5), blurRadius: 6)]
                    : null,
              ),
              child: selected
                  ? const Icon(CupertinoIcons.check_mark, size: 14, color: CupertinoColors.white)
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPreview(String text) {
    final color = courseColor(_color);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
