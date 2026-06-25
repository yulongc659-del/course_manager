import 'dart:ui';

const weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

const periodLabels = ['1-2节', '3-4节', '5-6节', '7-8节', '9-10节', '11-12节'];

const periodTimes = [
  '08:30-10:10',
  '10:30-12:10',
  '14:00-15:40',
  '16:00-17:40',
  '18:00-19:40',
  '20:00-21:40',
];

const courseColors = [
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
  Color(0xFF795548),
  Color(0xFF607D8B),
];

Color courseColor(int index) => courseColors[index % courseColors.length];
