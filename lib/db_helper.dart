import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smartnotes.db');
    debugPrint('Database path: $path'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    )
  ''');

  await db.execute('''
    CREATE TABLE note_tags (
      note_id INTEGER,
      tag_id INTEGER,
      FOREIGN KEY (note_id) REFERENCES notes(id),
      FOREIGN KEY (tag_id) REFERENCES tags(id),
      PRIMARY KEY (note_id, tag_id)
    )
  ''');
  debugPrint('Notes table created.');
}

// NOTES CRUD
  Future<int> insertNote(Map<String, dynamic> note) async {
  final dbClient = await db;
  return await dbClient.insert('notes', note);
}

Future<List<Map<String, dynamic>>> getNotes() async {
  final dbClient = await db;
  return await dbClient.query('notes', orderBy: 'created_at DESC');
}

Future<int> updateNote(int id, Map<String, dynamic> note) async {
  final dbClient = await db;
  return await dbClient.update('notes', note, where: 'id = ?', whereArgs: [id]);
}

Future<int> deleteNote(int id) async {
  final dbClient = await db;
  return await dbClient.delete('notes', where: 'id = ?', whereArgs: [id]);
}

// TAGS CRUD
Future<int> insertTag(String name) async {
  final dbClient = await db;
  return await dbClient.insert('tags', {'name': name});
}

Future<List<Map<String, dynamic>>> getTags() async {
  final dbClient = await db;
  return await dbClient.query('tags', orderBy: 'name ASC');
}

// NOTE_TAGS
Future<void> addTagToNote(int noteId, int tagId) async {
  final dbClient = await db;
  await dbClient.insert('note_tags', {'note_id': noteId, 'tag_id': tagId});
}

Future<List<Map<String, dynamic>>> getTagsForNote(int noteId) async {
  final dbClient = await db;
  return await dbClient.rawQuery('''
    SELECT tags.* FROM tags
    INNER JOIN note_tags ON tags.id = note_tags.tag_id
    WHERE note_tags.note_id = ?
  ''', [noteId]);
}

}