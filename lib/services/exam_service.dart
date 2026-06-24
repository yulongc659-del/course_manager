import '../models/exam.dart';
import 'database_service.dart';

class ExamService {
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<Exam> create(Exam exam) async {
    final box = await DatabaseService.exams;
    final id = _newId();
    final e = Exam(
      id: id,
      courseId: exam.courseId,
      name: exam.name,
      date: exam.date,
      time: exam.time,
      location: exam.location,
      notes: exam.notes,
    );
    await box.put(id, e.toMap());
    return e;
  }

  Future<List<Exam>> getAll() async {
    final box = await DatabaseService.exams;
    final result = <Exam>[];
    for (final entry in box.values) {
      result.add(Exam.fromMap(Map<String, dynamic>.from(entry as Map)));
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Future<List<Exam>> getByCourse(String courseId) async {
    final box = await DatabaseService.exams;
    final result = <Exam>[];
    for (final entry in box.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if (map['course_id'] == courseId) {
        result.add(Exam.fromMap(map));
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Future<void> update(Exam exam) async {
    final box = await DatabaseService.exams;
    await box.put(exam.id, exam.toMap());
  }

  Future<void> delete(String id) async {
    final box = await DatabaseService.exams;
    await box.delete(id);
  }
}
