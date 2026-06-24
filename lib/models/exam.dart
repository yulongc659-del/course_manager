class Exam {
  final String id;
  final String courseId;
  final String name;
  final String date;
  final String time;
  final String location;
  final String notes;
  final String createdAt;
  final String updatedAt;

  Exam({
    required this.id,
    required this.courseId,
    required this.name,
    required this.date,
    this.time = '',
    this.location = '',
    this.notes = '',
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'date': date,
      'time': time,
      'location': location,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      name: map['name'] as String,
      date: map['date'] as String,
      time: map['time'] as String? ?? '',
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
