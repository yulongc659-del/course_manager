import 'package:excel/excel.dart';

class ParsedRow {
  final Map<String, String> fields;
  ParsedRow(this.fields);
}

class ImportResult {
  final List<String> headers;
  final List<ParsedRow> rows;
  final Map<String, String?> columnMapping;

  ImportResult({
    required this.headers,
    required this.rows,
    required this.columnMapping,
  });
}

class ImportService {
  static const _namePatterns = [
    '课程名称', '课程名', '课程', '名称', 'name', 'course',
  ];
  static const _teacherPatterns = [
    '教师', '老师', '授课教师', '任课教师', 'teacher',
  ];
  static const _classroomPatterns = [
    '教室', '上课地点', '地点', 'classroom', 'location', 'room',
  ];
  static const _dayPatterns = [
    '星期', '周几', '星期几', '上课星期', 'day',
  ];
  static const _periodPatterns = [
    '节次', '时间', '上课时间', '节', 'period', 'time',
  ];
  static const _weekPatterns = [
    '周数', '周次', '上课周数', '教学周', 'week',
  ];

  Future<ImportResult> parseExcel(List<int> bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final rows = sheet.rows;

    if (rows.isEmpty) {
      throw Exception('文件为空');
    }

    final headers = <String>[];
    for (final cell in rows.first) {
      headers.add(cell?.value?.toString() ?? '');
    }

    final dataRows = <ParsedRow>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final fields = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        final value = j < row.length ? row[j]?.value?.toString() ?? '' : '';
        fields[headers[j]] = value;
      }
      dataRows.add(ParsedRow(fields));
    }

    final mapping = _autoDetect(headers);

    return ImportResult(
      headers: headers,
      rows: dataRows,
      columnMapping: mapping,
    );
  }

  Future<ImportResult> parseCsv(String content) async {
    final lines = content.split('\n');
    if (lines.isEmpty) throw Exception('文件为空');

    final headers = _splitCsvLine(lines.first);
    final dataRows = <ParsedRow>[];

    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      final fields = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        fields[headers[j]] = j < values.length ? values[j] : '';
      }
      dataRows.add(ParsedRow(fields));
    }

    final mapping = _autoDetect(headers);

    return ImportResult(
      headers: headers,
      rows: dataRows,
      columnMapping: mapping,
    );
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if ((ch == ',' || ch == '\t') && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  Map<String, String?> _autoDetect(List<String> headers) {
    final mapping = <String, String?>{};

    mapping['name'] = _match(headers, _namePatterns);
    mapping['teacher'] = _match(headers, _teacherPatterns);
    mapping['classroom'] = _match(headers, _classroomPatterns);
    mapping['dayOfWeek'] = _match(headers, _dayPatterns);
    mapping['period'] = _match(headers, _periodPatterns);
    mapping['week'] = _match(headers, _weekPatterns);

    return mapping;
  }

  String? _match(List<String> headers, List<String> patterns) {
    for (final header in headers) {
      final lower = header.trim().toLowerCase();
      for (final pattern in patterns) {
        if (lower.contains(pattern.toLowerCase())) {
          return header;
        }
      }
    }
    return null;
  }

  int? parseDayOfWeek(String text) {
    final t = text.trim();
    if (RegExp(r'^[1-7]$').hasMatch(t)) return int.parse(t);
    if (t.contains('一') || t.contains('1')) return 1;
    if (t.contains('二') || t.contains('2')) return 2;
    if (t.contains('三') || t.contains('3')) return 3;
    if (t.contains('四') || t.contains('4')) return 4;
    if (t.contains('五') || t.contains('5')) return 5;
    if (t.contains('六') || t.contains('6')) return 6;
    if (t.contains('日') || t.contains('天') || t.contains('7')) return 7;
    return null;
  }

  (int, int)? parsePeriod(String text) {
    final t = text.trim().replaceAll('节', '').replaceAll('第', '');
    final parts = t.split(RegExp(r'[,\-~，、]'));
    if (parts.length >= 2) {
      final s = int.tryParse(parts[0].trim());
      final e = int.tryParse(parts[1].trim());
      if (s != null && e != null) return (s, e);
    }
    final single = int.tryParse(t);
    if (single != null) return (single, single);
    return null;
  }

  (int, int)? parseWeek(String text) {
    final t = text.trim().replaceAll('周', '').replaceAll('第', '');
    final parts = t.split(RegExp(r'[,\-~，、]'));
    if (parts.length >= 2) {
      final s = int.tryParse(parts[0].trim());
      final e = int.tryParse(parts[1].trim());
      if (s != null && e != null) return (s, e);
    }
    final single = int.tryParse(t);
    if (single != null) return (single, single);
    return null;
  }
}
