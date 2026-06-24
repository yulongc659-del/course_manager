import '../models/semester.dart';
import 'database_service.dart';

class SemesterService {
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<Semester> create(String name) async {
    final box = await DatabaseService.semesters;
    final isCurrent = box.isEmpty;
    final id = _newId();
    final semester = Semester(id: id, name: name, isCurrent: isCurrent);
    await box.put(id, semester.toMap());
    return semester;
  }

  Future<Semester?> getCurrent() async {
    final box = await DatabaseService.semesters;
    for (final entry in box.values) {
      final map = Map<String, dynamic>.from(entry as Map);
      if (map['is_current'] == 1) {
        return Semester.fromMap(map);
      }
    }
    return null;
  }

  Future<List<Semester>> getAll() async {
    final box = await DatabaseService.semesters;
    final result = <Semester>[];
    for (final entry in box.values) {
      result.add(Semester.fromMap(Map<String, dynamic>.from(entry as Map)));
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<void> setCurrent(String id) async {
    final box = await DatabaseService.semesters;
    for (final key in box.keys) {
      final map = Map<String, dynamic>.from(box.get(key) as Map);
      map['is_current'] = 0;
      await box.put(key, map);
    }
    final map = Map<String, dynamic>.from(box.get(id) as Map);
    map['is_current'] = 1;
    await box.put(id, map);
  }
}
