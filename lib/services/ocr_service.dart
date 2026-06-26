import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OcrResult {
  final String name;
  final String teacher;
  final String classroom;
  final int dayOfWeek;
  final int periodStart;
  final int periodEnd;
  final int weekStart;
  final int weekEnd;

  OcrResult({
    required this.name,
    this.teacher = '',
    this.classroom = '',
    required this.dayOfWeek,
    required this.periodStart,
    required this.periodEnd,
    this.weekStart = 1,
    this.weekEnd = 16,
  });
}

class OcrService {
  static const _apiKey = 'ark-903d1fa5-01ae-48a4-bbd9-20fb64638395-a3bdf';
  static const _endpointId = 'ep-20260626133954-bfq4p';
  static const _baseUrl = 'https://ark.cn-beijing.volces.com/api/v3';

  static Future<List<OcrResult>> parseImage(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final prompt = '''请分析这张课程表截图，提取所有课程信息，返回 JSON 数组格式。

每门课程包含以下字段：
- name: 课程名称（字符串）
- teacher: 授课教师（字符串，可为空字符串）
- classroom: 教室/上课地点（字符串，可为空字符串）
- dayOfWeek: 星期几（整数 1-7，1=周一 2=周二 3=周三 4=周四 5=周五 6=周六 7=周日）
- periodStart: 起始节次（整数 1-12）
- periodEnd: 结束节次（整数 1-12）
- weekStart: 起始周数（整数，默认1）
- weekEnd: 结束周数（整数，默认16）

只返回 JSON 数组，不要其他文字。示例格式：
[{"name":"高等数学","teacher":"王老师","classroom":"A201","dayOfWeek":1,"periodStart":1,"periodEnd":2,"weekStart":1,"weekEnd":16}]''';

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _endpointId,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/png;base64,$base64Image'},
              },
              {'type': 'text', 'text': prompt},
            ],
          }
        ],
        'max_tokens': 4096,
        'temperature': 0.1,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? '请求失败: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    final jsonStart = content.indexOf('[');
    final jsonEnd = content.lastIndexOf(']') + 1;
    if (jsonStart == -1 || jsonEnd == 0) throw Exception('API 返回格式异常');

    final List<dynamic> list = jsonDecode(content.substring(jsonStart, jsonEnd));

    return list.map((item) {
      return OcrResult(
        name: item['name'] as String,
        teacher: (item['teacher'] as String?) ?? '',
        classroom: (item['classroom'] as String?) ?? '',
        dayOfWeek: item['dayOfWeek'] as int,
        periodStart: item['periodStart'] as int,
        periodEnd: item['periodEnd'] as int,
        weekStart: (item['weekStart'] as int?) ?? 1,
        weekEnd: (item['weekEnd'] as int?) ?? 16,
      );
    }).toList();
  }
}
