import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/course.dart';
import '../../services/import_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';
import '../../widgets/glass.dart';
import '../../utils/constants.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final _importService = ImportService();

  ImportResult? _result;
  String? _fileName;
  bool _loading = false;

  // JSON state
  final _jsonController = TextEditingController();
  JsonSchedule? _jsonSchedule;
  String? _jsonFileName;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _loading = true;
      _fileName = result.files.first.name;
    });

    try {
      final file = result.files.first;
      ImportResult parsed;
      if (file.extension?.toLowerCase() == 'csv') {
        final content = utf8.decode(file.bytes!, allowMalformed: true);
        parsed = await _importService.parseCsv(content);
      } else {
        parsed = await _importService.parseExcel(file.bytes!);
      }
      setState(() => _result = parsed);
    } catch (e) {
      if (mounted) _showError('解析失败', '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _jsonFileName = result.files.first.name;
      _loading = true;
    });

    try {
      final content = utf8.decode(result.files.first.bytes!, allowMalformed: true);
      final schedule = _importService.parseScheduleJson(content);
      if (schedule == null || schedule.courses.isEmpty) {
        if (mounted) _showError('解析失败', '无法识别 JSON 格式');
        return;
      }
      setState(() => _jsonSchedule = schedule);
    } catch (e) {
      if (mounted) _showError('解析失败', '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _doImport() async {
    if (_result == null) return;
    final semester = await SemesterService().getCurrent();
    if (semester == null) return;

    final mapping = _result!.columnMapping;
    final nameCol = mapping['name'];
    final teacherCol = mapping['teacher'];
    final classroomCol = mapping['classroom'];
    final dayCol = mapping['dayOfWeek'];
    final periodCol = mapping['period'];
    final weekCol = mapping['week'];

    if (nameCol == null || dayCol == null || periodCol == null) {
      if (mounted) _showError('缺少字段', '课程名、星期、节次不能为空');
      return;
    }

    final courseService = CourseService();
    int imported = 0;

    for (final row in _result!.rows) {
      final name = row.fields[nameCol]?.trim() ?? '';
      if (name.isEmpty) continue;
      final day = _importService.parseDayOfWeek(row.fields[dayCol] ?? '');
      if (day == null) continue;
      final period = _importService.parsePeriod(row.fields[periodCol] ?? '');
      if (period == null) continue;
      final week = weekCol != null
          ? _importService.parseWeek(row.fields[weekCol] ?? '')
          : (1, 16);

      await courseService.create(Course(
        id: '', semesterId: semester.id, name: name,
        teacher: teacherCol != null ? (row.fields[teacherCol] ?? '').trim() : '',
        classroom: classroomCol != null ? (row.fields[classroomCol] ?? '').trim() : '',
        dayOfWeek: day, periodStart: period.$1, periodEnd: period.$2,
        weekStart: week?.$1 ?? 1, weekEnd: week?.$2 ?? 16,
        color: imported % 8,
      ));
      imported++;
    }

    if (mounted) _showSuccess('成功导入 $imported 门课程');
  }

  void _parsePastedJson() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      _showError('请输入', '请先粘贴 JSON 课表代码');
      return;
    }
    final schedule = _importService.parseScheduleJson(text);
    if (schedule == null || schedule.courses.isEmpty) {
      _showError('解析失败', 'JSON 格式不正确');
      return;
    }
    setState(() {
      _jsonSchedule = schedule;
      _jsonFileName = '粘贴的 JSON';
    });
  }

  Future<void> _doJsonImport() async {
    if (_jsonSchedule == null) return;
    final semester = await SemesterService().getCurrent();
    if (semester == null) return;

    final courseService = CourseService();
    int imported = 0;

    for (final c in _jsonSchedule!.courses) {
      await courseService.create(Course(
        id: '', semesterId: semester.id, name: c.name,
        teacher: c.teacher,
        classroom: c.location,
        dayOfWeek: c.dayOfWeek, periodStart: c.periodStart, periodEnd: c.periodEnd,
        weekStart: c.weekStart, weekEnd: c.weekEnd,
        color: imported % 8,
      ));
      imported++;
    }

    if (mounted) _showSuccess('成功导入 $imported 门课程');
  }

  void _showError(String title, String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title), content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text('好'), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  void _showSuccess(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('导入完成'), content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text('好'), onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context, true);
        })],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('导入课表')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImportCard(
                icon: CupertinoIcons.table,
                title: 'Excel / CSV 文件',
                subtitle: '支持 .xlsx .xls .csv 格式，自动匹配列',
                onTap: _pickFile,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: CupertinoColors.systemGrey6,
                ),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _jsonController,
                      placeholder: '直接粘贴 JSON 课表代码...',
                      maxLines: 6,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        onPressed: _parsePastedJson,
                        child: const Text('解析 JSON', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildImportCard(
                icon: CupertinoIcons.doc_text,
                title: '选择 JSON 文件',
                subtitle: '或选择 .json 文件导入',
                onTap: _pickJson,
              ),
              const SizedBox(height: 10),
              _buildImportCard(
                icon: CupertinoIcons.camera,
                title: '拍照 OCR 识别',
                subtitle: 'iOS 版本中提供，设备端识别',
                onTap: null,
              ),

              if (_loading) ...[
                const SizedBox(height: 16),
                const Center(child: CupertinoActivityIndicator()),
              ],

              // Excel preview
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildMapping(),
                const SizedBox(height: 16),
                const Text('数据预览 (前 5 行)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildPreview(),
                const SizedBox(height: 24),
                CupertinoButton.filled(onPressed: _doImport, child: const Text('确认导入')),
              ],

              // JSON preview
              if (_jsonSchedule != null) ...[
                const SizedBox(height: 16),
                Text('识别到 ${_jsonSchedule!.courses.length} 门课程',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._jsonSchedule!.courses.asMap().entries.map((e) {
                  final c = e.value;
                  final color = courseColor(e.key % 8);
                  return GlassCard(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              Text(
                                '${weekdayLabels[c.dayOfWeek - 1]} '
                                '${c.periodStart}-${c.periodEnd}节  '
                                '第${c.weekStart}-${c.weekEnd}周  '
                                '${c.location.isNotEmpty ? c.location : ''}',
                                style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                CupertinoButton.filled(onPressed: _doJsonImport, child: const Text('确认导入')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: onTap != null
                    ? CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.1)
                    : CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22,
                  color: onTap != null ? CupertinoTheme.of(context).primaryColor : CupertinoColors.systemGrey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                ],
              ),
            ),
            Icon(
              onTap != null ? CupertinoIcons.chevron_right : CupertinoIcons.lock,
              size: 16, color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget _buildMapping() {
    if (_result == null) return const SizedBox.shrink();
    final mapping = _result!.columnMapping;
    final labels = {
      'name': '课程名', 'teacher': '教师', 'classroom': '教室',
      'dayOfWeek': '星期', 'period': '节次', 'week': '周数',
    };
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('字段映射', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...labels.entries.map((e) {
            final matched = mapping[e.key];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Text(e.value, style: const TextStyle(fontSize: 14))),
                  Icon(
                    matched != null ? CupertinoIcons.check_mark_circled : CupertinoIcons.xmark_circle,
                    size: 16,
                    color: matched != null ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(matched ?? '未识别',
                        style: TextStyle(fontSize: 13, color: matched != null ? null : CupertinoColors.systemRed)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_result == null) return const SizedBox.shrink();
    final headers = _result!.headers;
    final preview = _result!.rows.take(5).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Table(
            border: TableBorder.all(color: CupertinoColors.systemGrey5, width: 0.5),
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(
                decoration: BoxDecoration(color: CupertinoColors.systemGrey6),
                children: headers.map((h) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(h, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                )).toList(),
              ),
              ...preview.map((row) => TableRow(
                children: headers.map((h) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(row.fields[h] ?? '', style: const TextStyle(fontSize: 12)),
                )).toList(),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
