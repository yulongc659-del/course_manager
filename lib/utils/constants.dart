import 'dart:ui';
import '../design_system/colors.dart';

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

Color courseColor(int index) => AppColors.courseColor(index);
