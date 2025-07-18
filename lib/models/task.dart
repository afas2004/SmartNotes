// models/task.dart
class Task {
  final int? id;
  final String userId;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  DateTime? dueDate;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    );
  }

  // In your Task model (models/task.dart)
  Task copyWith({
    int? id,
    String? userId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}