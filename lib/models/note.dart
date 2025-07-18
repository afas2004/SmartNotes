class Note {
  final int id;
  final String userId;
  final String title;
  final String? content;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    this.content,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      content: map['content'],
    );
  }
}