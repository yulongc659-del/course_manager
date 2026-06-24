import '../models/course.dart';
import 'database_service.dart';

class CourseService {
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<Course> create(Course course) async {
    final box = await DatabaseService.courses;
    final id = _newId();
    final c = Course(
      id: id,
      semesterId: course.semesterId,
      name: course.name,
      teacher: course.teacher,
      classroom: course.classroom,
      dayOfWeek: course.dayOfWeek,
      periodStart: course.periodStart,
      periodEnd: course.periodEnd,
      weekStart: course.weekStart,
      weekEnd: course.weekEnd,
      color: course.color,
    );
    await box.put(id, c.toMap());
    return c;
  }

  Future<List<Course>> getBySemester(String semesterId) async {
    final box = await DatabaseService.courses;
    final result = <Course>[];
    for (final entry in box.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if (map['semester_id'] == semesterId) {
        result.add(Course.fromMap(map));
      }
    }
    result.sort(_sortByDayAndPeriod);
    return result;
  }

  Future<List<Course>> getByWeek(String semesterId, int week) async {
    final courses = await getBySemester(semesterId);
    return courses
        .where((c) => week >= c.weekStart && week <= c.weekEnd)
        .toList();
  }

  Future<void> update(Course course) async {
    final box = await DatabaseService.courses;
    await box.put(course.id, course.toMap());
  }

  Future<void> delete(String id) async {
    final box = await DatabaseService.courses;
    await box.delete(id);
    final hwBox = await DatabaseService.homeworks;
    final toDelete = <String>[];
    for (final key in hwBox.keys) {
      final map = Map<String, dynamic>.from(hwBox.get(key) as Map);
      if (map['course_id'] == id) toDelete.add(key);
    }
    for (final key in toDelete) {
      await hwBox.delete(key);
    }
    final examBox = await DatabaseService.exams;
    final exToDelete = <String>[];
    for (final key in examBox.keys) {
      final map = Map<String, dynamic>.from(examBox.get(key) as Map);
      if (map['course_id'] == id) exToDelete.add(key);
    }
    for (final key in exToDelete) {
      await examBox.delete(key);
    }
  }

  Future<Course?> getById(String id) async {
    final box = await DatabaseService.courses;
    final data = box.get(id);
    if (data == null) return null;
    return Course.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Course>> search(String query, String semesterId) async {
    final courses = await getBySemester(semesterId);
    final q = query.toLowerCase();
    return courses
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.teacher.toLowerCase().contains(q))
        .toList();
  }

  int _sortByDayAndPeriod(Course a, Course b) {
    if (a.dayOfWeek != b.dayOfWeek) {
      return a.dayOfWeek.compareTo(b.dayOfWeek);
    }
    return a.periodStart.compareTo(b.periodStart);
  }
}
