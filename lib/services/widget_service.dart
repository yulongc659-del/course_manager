import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../utils/constants.dart';

class WidgetService {
  static const _channel = MethodChannel('com.course.manager/widget');
  static const _group = 'group.com.course.manager';

  static Future<void> updateWidget({
    required int currentWeek,
    required String semesterName,
    required List<Course> weekCourses,
    String aiTip = '',
  }) async {
    final now = DateTime.now();
    final today = now.weekday; // 1=Mon, 7=Sun
    final todayCourses = weekCourses
        .where((c) => c.dayOfWeek == today)
        .toList()
      ..sort((a, b) => a.periodStart.compareTo(b.periodStart));

    final data = {
      'currentWeek': currentWeek,
      'semesterName': semesterName,
      'todayDate': DateFormat('M月d日 EEEE', 'zh_CN').format(now),
      'todayCourseCount': todayCourses.length,
      'todayCourses': todayCourses.map((c) => {
        'name': c.name,
        'teacher': c.teacher,
        'classroom': c.classroom,
        'period': '${c.periodStart}-${c.periodEnd}节',
        'periodStart': c.periodStart,
        'time': _getPeriodTime(c.periodStart, c.periodEnd),
        'color': c.color,
      }).toList(),
      'nextClass': _findNextClass(todayCourses, now),
      'aiTip': aiTip,
    };

    try {
      await _channel.invokeMethod('updateWidget', {'data': jsonEncode(data)});
    } catch (_) {}
  }

  static Map<String, dynamic>? _findNextClass(
      List<Course> todayCourses, DateTime now) {
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final course in todayCourses) {
      final endIdx = course.periodEnd - 1;
      if (endIdx < periodTimes.length) {
        final endTime = periodTimes[endIdx].split('-')[1];
        if (timeStr.compareTo(endTime) < 0) {
          final startTime = periodTimes[(course.periodStart - 1) ~/ 2].split('-')[0];
          return {
            'name': course.name,
            'time': startTime,
            'classroom': course.classroom,
            'period': '${course.periodStart}-${course.periodEnd}节',
          };
        }
      }
    }
    return null;
  }

  static String _getPeriodTime(int start, int end) {
    final si = (start - 1) ~/ 2;
    final ei = (end - 1) ~/ 2;
    if (si >= periodTimes.length || ei >= periodTimes.length) return '';
    final startTime = periodTimes[si].split('-')[0];
    final endTime = periodTimes[ei].split('-')[1];
    return '$startTime-$endTime';
  }
}
