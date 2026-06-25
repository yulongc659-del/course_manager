import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_service.dart';
import 'course_service.dart';
import 'homework_service.dart';
import 'exam_service.dart';

class AiService {
  static Future<Box> get _cache async =>
      await Hive.openBox('ai_summaries');

  static Future<String?> getCachedSummary(String courseId) async {
    final box = await _cache;
    return box.get(courseId) as String?;
  }

  static Future<void> saveSummary(String courseId, String summary) async {
    final box = await _cache;
    await box.put(courseId, summary);
  }

  static Future<String> summarizeCourse(
    String courseName,
    String courseId,
  ) async {
    final cached = await getCachedSummary(courseId);
    if (cached != null && cached.isNotEmpty) return cached;

    final apiKey = await SettingsService.getApiKey();
    if (apiKey.isEmpty) {
      throw Exception('请先在设置中配置 DeepSeek API Key');
    }

    final baseUrl = await SettingsService.getBaseUrl();

    // Collect context about the course
    final homeworks = await HomeworkService().getByCourse(courseId);
    final exams = await ExamService().getByCourse(courseId);
    final course = await CourseService().getById(courseId);

    final hwText = homeworks.map((h) => '- ${h.title} (截止: ${h.dueDate})').join('\n');
    final examText = exams.map((e) => '- ${e.name} (${e.date} ${e.time})').join('\n');

    final prompt = '''你是一位大学课程助教。请根据以下课程信息，生成一份结构化的课程重点总结。

课程名称：$courseName
${course != null ? '''
授课教师：${course.teacher}
教室：${course.classroom}
时间：${_weekdayName(course.dayOfWeek)} ${course.periodStart}-${course.periodEnd}节
周数：第${course.weekStart}-${course.weekEnd}周
''' : ''}

作业列表：
${hwText.isNotEmpty ? hwText : '(暂无作业)'}

考试列表：
${examText.isNotEmpty ? examText : '(暂无考试)'}

请按以下格式输出：
## 📋 课程概述
(1-2句话概括课程)

## 📖 重点内容
- **知识点1**：说明
- **知识点2**：说明

## ✏️ 作业要点
(基于现有作业的提示和注意事项)

## 📝 考试备考建议
(备考策略和重点复习方向)''';

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 2048,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? '请求失败: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final summary = data['choices'][0]['message']['content'] as String;
    await saveSummary(courseId, summary);
    return summary;
  }

  static Future<String?> getCachedWeeklySummary(String key) async {
    final box = await _cache;
    return box.get(key) as String?;
  }

  static Future<void> saveWeeklySummary(String key, String summary) async {
    final box = await _cache;
    await box.put(key, summary);
  }

  static Future<String> summarizeWeek(int week, List<String> courseNames,
      String hwSummary, String examSummary, String courseServiceSummary) async {
    final apiKey = await SettingsService.getApiKey();
    if (apiKey.isEmpty) throw Exception('请先在设置中配置 API Key');
    final baseUrl = await SettingsService.getBaseUrl();

    final prompt = '''你是大学学习助手。根据第 $week 周的课程和任务，生成周总结和学习计划。

本周课程：
${courseNames.join('、')}

作业：
${hwSummary.isNotEmpty ? hwSummary : '无作业'}

考试：
${examSummary.isNotEmpty ? examSummary : '无考试'}

请按格式输出：
## 📅 第 $week 周学习计划

### 📚 课程重点
(按天列出每天课程重点)

### ✏️ 作业任务
(本周需完成的作业清单)

### ⏰ 时间安排建议
(每天的时间分配建议)

### 💡 复习重点
(结合考试安排的复习建议)''';

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [{'role': 'user', 'content': prompt}],
        'max_tokens': 2048,
        'temperature': 0.7,
      }),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? '请求失败');
    }
    return jsonDecode(response.body)['choices'][0]['message']['content'];
  }

  static String _weekdayName(int day) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[day];
  }
}
