import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

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
      version: 2, // IMPORTANT: Increment version for schema changes!
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade callback
    );
  }

  Future _onCreate(Database db, int version) async {
    debugPrint('Creating database tables...');
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,       -- Added for Firebase Auth integration
        title TEXT NOT NULL,
        content TEXT,
        folder TEXT,
        imageLocalPath TEXT,        -- Added for local image paths
        imageUrl TEXT,              -- Added for network image URLs
        audioUrl TEXT,              -- Added for audio URLs/paths
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
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE, -- Added ON DELETE CASCADE
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,   -- Added ON DELETE CASCADE
        PRIMARY KEY (note_id, tag_id)
      )
    ''');
    // Also add the tasks table if you want to manage tasks in this DB
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,       -- Added for Firebase Auth integration
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0, -- 0 for false, 1 for true
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    debugPrint('Database tables created: notes, tags, note_tags, tasks.');
  }

  // Migration logic for adding new columns to an existing database
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion...');
    if (oldVersion < 2) {
      // Add new columns to the notes table
      await db.execute("ALTER TABLE notes ADD COLUMN userId TEXT");
      await db.execute("ALTER TABLE notes ADD COLUMN imageLocalPath TEXT");
      await db.execute("ALTER TABLE notes ADD COLUMN imageUrl TEXT");
      await db.execute("ALTER TABLE notes ADD COLUMN audioUrl TEXT");
      debugPrint('Added userId, imageLocalPath, imageUrl, audioUrl to notes table.');

      // Update existing notes to have a default userId (important for existing data)
      // You might want to assign a 'dummy' user ID or handle this more gracefully
      // For simplicity, we'll assign a placeholder. In a real app, you'd migrate
      // existing notes to the first user who logs in, or prompt the user.
      await db.execute("UPDATE notes SET userId = 'migrated_user' WHERE userId IS NULL");
      // Ensure userId is NOT NULL after migration
      // This step might require dropping and recreating the table if SQLite version doesn't support ALTER COLUMN NOT NULL
      // For simplicity, we'll assume it's okay to leave it nullable for migrated rows
      // or that you'll handle it in your application logic.
      // If you need it NOT NULL, you'd typically:
      // 1. Create a new table with the correct schema
      // 2. Copy data from old to new table
      // 3. Drop old table, rename new table

      // Add the tasks table if it didn't exist in old version
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
      debugPrint('Tasks table ensured to exist.');

      // Add ON DELETE CASCADE to foreign keys for better data integrity
      // This requires dropping and recreating tables, or manually handling deletions
      // For simplicity in an upgrade, we'll just log it as a potential improvement.
      debugPrint('Consider adding ON DELETE CASCADE to note_tags foreign keys for future versions.');
    }
    // Add more migration steps for future versions if needed (e.g., if newVersion becomes 3)
    debugPrint('Database upgrade complete.');
  }

  // --- NOTES CRUD ---

  // Insert a note, now requiring userId
  Future<int> insertNote(Map<String, dynamic> note) async {
    final dbClient = await db;
    // Ensure userId is present before inserting
    if (!note.containsKey('userId') || note['userId'] == null) {
      throw ArgumentError('userId is required for inserting a note.');
    }
    return await dbClient.insert('notes', note);
  }

  // Get notes for a specific userId
  Future<List<Map<String, dynamic>>> getNotes(String userId, {int? limit}) async {
    final dbClient = await db;
    return await dbClient.query(
      'notes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC', // Order by updated_at for recent notes
      limit: limit,
    );
  }

  // Update a note, ensuring it belongs to the userId
  Future<int> updateNote(int id, String userId, Map<String, dynamic> note) async {
    final dbClient = await db;
    return await dbClient.update(
      'notes',
      note,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // Delete a note, ensuring it belongs to the userId
  Future<int> deleteNote(int id, String userId) async {
    final dbClient = await db;
    return await dbClient.delete(
      'notes',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  // --- TASKS CRUD ---
  // (Adding basic CRUD for tasks, similar to notes)

  Future<int> insertTask(Map<String, dynamic> task) async {
    final dbClient = await db;
    if (!task.containsKey('userId') || task['userId'] == null) {
      throw ArgumentError('userId is required for inserting a task.');
    }
    return await dbClient.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasks(String userId, {int? limit}) async {
    final dbClient = await db;
    return await dbClient.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC', // Order by created_at for tasks
      limit: limit,
    );
  }

  Future<int> updateTask(int id, String userId, Map<String, dynamic> task) async {
    final dbClient = await db;
    return await dbClient.update(
      'tasks',
      task,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<int> deleteTask(int id, String userId) async {
    final dbClient = await db;
    return await dbClient.delete(
      'tasks',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }


  // --- TAGS CRUD (No changes needed for userId here, as tags are typically global or linked via note_tags) ---
  Future<int> insertTag(String name) async {
    final dbClient = await db;
    return await dbClient.insert('tags', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore); // Ignore if tag already exists
  }

  Future<List<Map<String, dynamic>>> getTags() async {
    final dbClient = await db;
    return await dbClient.query('tags', orderBy: 'name ASC');
  }

  // NOTE_TAGS
  Future<void> addTagToNote(int noteId, int tagId) async {
    final dbClient = await db;
    await dbClient.insert('note_tags', {'note_id': noteId, 'tag_id': tagId}, conflictAlgorithm: ConflictAlgorithm.replace); // Use replace to avoid duplicates
  }

  Future<List<Map<String, dynamic>>> getTagsForNote(int noteId) async {
    final dbClient = await db;
    return await dbClient.rawQuery('''
      SELECT tags.* FROM tags
      INNER JOIN note_tags ON tags.id = note_tags.tag_id
      WHERE note_tags.note_id = ?
    ''', [noteId]);
  }

  // Get notes by folder
  Future<List<Map<String, dynamic>>> getNotesByFolder(String userId, String folderName) async {
    final dbClient = await db;
    return await dbClient.query(
      'notes',
      where: 'userId = ? AND folder = ?',
      whereArgs: [userId, folderName],
      orderBy: 'updated_at DESC',
    );
  }

  // Get notes by tag
  Future<List<Map<String, dynamic>>> getNotesByTag(String userId, int tagId) async {
    final dbClient = await db;
    return await dbClient.rawQuery('''
      SELECT notes.* FROM notes
      INNER JOIN note_tags ON notes.id = note_tags.note_id
      WHERE notes.userId = ? AND note_tags.tag_id = ?
      ORDER BY notes.updated_at DESC
    ''', [userId, tagId]);
  }
}