class Semester {
  final String id;
  final String name;
  final bool isCurrent;
  final String createdAt;

  Semester({
    required this.id,
    required this.name,
    this.isCurrent = false,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_current': isCurrent ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Semester.fromMap(Map<String, dynamic> map) {
    return Semester(
      id: map['id'] as String,
      name: map['name'] as String,
      isCurrent: (map['is_current'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }
}
