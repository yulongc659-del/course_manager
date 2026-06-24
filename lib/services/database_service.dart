import 'package:hive_flutter/hive_flutter.dart';

class DatabaseService {
  static Future<Box> get semesters async =>
      await Hive.openBox('semesters');

  static Future<Box> get courses async =>
      await Hive.openBox('courses');

  static Future<Box> get homeworks async =>
      await Hive.openBox('homeworks');

  static Future<Box> get exams async =>
      await Hive.openBox('exams');
}
