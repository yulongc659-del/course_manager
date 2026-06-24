import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/semester_service.dart';
import 'utils/notification_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeDateFormatting('zh_CN');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    await NotificationHelper.init();
  } catch (_) {}

  await _cleanOldData();

  final semesterService = SemesterService();
  final current = await semesterService.getCurrent();
  if (current == null) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    String name;
    if (month >= 2 && month <= 7) {
      name = '$year 春季学期';
    } else {
      name = '${month >= 9 ? year : year - 1}-${month >= 9 ? year + 1 : year} 秋季学期';
    }
    await semesterService.create(name);
  }

  runApp(const CourseManagerApp());
}

Future<void> _cleanOldData() async {
  try {
    final box = await Hive.openBox('semesters');
    if (box.isNotEmpty) {
      final first = box.values.first as Map;
      if (first['id'] is int) {
        await box.clear();
      }
    }
  } catch (_) {}
}
