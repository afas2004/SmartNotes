// models/note.dart
class Note {
  final int? id;
  final String userId;
  final String title;
  final String? content;
  final String? folder;
  final String? imageLocalPath;
  final String? imageUrl;
  final String? audioUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    this.id,
    required this.userId,
    required this.title,
    this.content,
    this.folder,
    this.imageLocalPath,
    this.imageUrl,
    this.audioUrl,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'folder': folder,
      'imageLocalPath': imageLocalPath,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      content: map['content'],
      folder: map['folder'],
      imageLocalPath: map['imageLocalPath'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
