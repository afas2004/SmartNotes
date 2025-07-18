class Task {
  final int id;
  final String userId;
  final String title;
  final bool isCompleted;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.isCompleted,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}