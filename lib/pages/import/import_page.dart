import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/course.dart';
import '../../services/import_service.dart';
import '../../services/course_service.dart';
import '../../services/semester_service.dart';
import '../../widgets/glass.dart';

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
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('解析失败'),
            content: Text('$e'),
            actions: [CupertinoDialogAction(child: const Text('好'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
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
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('缺少字段'),
          content: Text('课程名、星期、节次不能为空'),
          actions: [CupertinoDialogAction(child: Text('好'))],
        ),
      );
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
        id: '',
        semesterId: semester.id,
        name: name,
        teacher: teacherCol != null ? (row.fields[teacherCol] ?? '').trim() : '',
        classroom: classroomCol != null ? (row.fields[classroomCol] ?? '').trim() : '',
        dayOfWeek: day,
        periodStart: period.$1,
        periodEnd: period.$2,
        weekStart: week?.$1 ?? 1,
        weekEnd: week?.$2 ?? 16,
        color: imported % 8,
      ));
      imported++;
    }

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('导入完成'),
          content: Text('成功导入 $imported 门课程'),
          actions: [CupertinoDialogAction(child: const Text('好'), onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context, true);
          })],
        ),
      );
    }
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
              AppleButton(
                onPressed: _pickFile,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                    const SizedBox(width: 8),
                    const Text('选择 Excel 或 CSV 文件',
                        style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '支持 .xlsx / .xls / .csv 格式，自动识别字段映射。',
                style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 8),
                Text('已选择: $_fileName',
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                    textAlign: TextAlign.center),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CupertinoActivityIndicator()),
                ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildMapping(),
                const SizedBox(height: 16),
                const Text('数据预览 (前 5 行)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildPreview(),
                const SizedBox(height: 24),
                CupertinoButton.filled(
                  onPressed: _doImport,
                  child: const Text('确认导入'),
                ),
              ],
              const SizedBox(height: 40),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.camera, size: 32, color: CupertinoColors.systemGrey),
                      SizedBox(height: 8),
                      Text('拍照 OCR 识别将在 iOS 版本中提供',
                          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                        style: TextStyle(
                            fontSize: 13,
                            color: matched != null ? null : CupertinoColors.systemRed)),
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
                children: headers.map((h) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(h, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  );
                }).toList(),
              ),
              ...preview.map((row) {
                return TableRow(
                  children: headers.map((h) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(row.fields[h] ?? '', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
