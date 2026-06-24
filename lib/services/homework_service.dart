import '../models/homework.dart';
import 'database_service.dart';

class HomeworkService {
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<Homework> create(Homework hw) async {
    final box = await DatabaseService.homeworks;
    final id = _newId();
    final h = Homework(
      id: id,
      courseId: hw.courseId,
      title: hw.title,
      dueDate: hw.dueDate,
      notes: hw.notes,
      isCompleted: false,
    );
    await box.put(id, h.toMap());
    return h;
  }

  Future<List<Homework>> getAll() async {
    final box = await DatabaseService.homeworks;
    final result = <Homework>[];
    for (final entry in box.values) {
      result.add(Homework.fromMap(Map<String, dynamic>.from(entry as Map)));
    }
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  Future<List<Homework>> getByCourse(String courseId) async {
    final box = await DatabaseService.homeworks;
    final result = <Homework>[];
    for (final entry in box.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if (map['course_id'] == courseId) {
        result.add(Homework.fromMap(map));
      }
    }
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  Future<void> update(Homework hw) async {
    final box = await DatabaseService.homeworks;
    await box.put(hw.id, hw.toMap());
  }

  Future<void> delete(String id) async {
    final box = await DatabaseService.homeworks;
    await box.delete(id);
  }

  Future<void> toggleComplete(String id) async {
    final box = await DatabaseService.homeworks;
    final data = box.get(id);
    if (data == null) return;
    final map = Map<String, dynamic>.from(data as Map);
    map['is_completed'] = map['is_completed'] == 1 ? 0 : 1;
    await box.put(id, map);
  }

  Future<List<Homework>> search(String query) async {
    final all = await getAll();
    final q = query.toLowerCase();
    return all.where((h) => h.title.toLowerCase().contains(q)).toList();
  }
}
