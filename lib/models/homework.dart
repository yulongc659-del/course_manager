class Homework {
  final String id;
  final String courseId;
  final String title;
  final String dueDate;
  final String notes;
  final bool isCompleted;
  final String createdAt;
  final String updatedAt;

  Homework({
    required this.id,
    required this.courseId,
    required this.title,
    required this.dueDate,
    this.notes = '',
    this.isCompleted = false,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'due_date': dueDate,
      'notes': notes,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Homework.fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      dueDate: map['due_date'] as String,
      notes: map['notes'] as String? ?? '',
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
