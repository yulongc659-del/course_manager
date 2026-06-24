class Course {
  final String id;
  final String semesterId;
  final String name;
  final String teacher;
  final String classroom;
  final int dayOfWeek;
  final int periodStart;
  final int periodEnd;
  final int weekStart;
  final int weekEnd;
  final int color;
  final String createdAt;
  final String updatedAt;

  Course({
    required this.id,
    required this.semesterId,
    required this.name,
    this.teacher = '',
    this.classroom = '',
    required this.dayOfWeek,
    required this.periodStart,
    required this.periodEnd,
    required this.weekStart,
    required this.weekEnd,
    this.color = 0,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_id': semesterId,
      'name': name,
      'teacher': teacher,
      'classroom': classroom,
      'day_of_week': dayOfWeek,
      'period_start': periodStart,
      'period_end': periodEnd,
      'week_start': weekStart,
      'week_end': weekEnd,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      semesterId: map['semester_id'] as String,
      name: map['name'] as String,
      teacher: map['teacher'] as String? ?? '',
      classroom: map['classroom'] as String? ?? '',
      dayOfWeek: map['day_of_week'] as int,
      periodStart: map['period_start'] as int,
      periodEnd: map['period_end'] as int,
      weekStart: map['week_start'] as int,
      weekEnd: map['week_end'] as int,
      color: map['color'] as int? ?? 0,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
