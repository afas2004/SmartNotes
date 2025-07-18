// providers/notes_provider.dart
import 'package:flutter/material.dart';
import 'package:smartnotes/db_helper.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/models/task.dart';

class NotesProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<Note> _notes = [];
  List<Task> _tasks = [];

  List<Note> get notes => _notes;
  List<Task> get tasks => _tasks;

  Future<void> loadNotes(String userId) async {
    _notes = (await _dbHelper.getNotes(userId)).map((e) => Note.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> loadTasks(String userId) async {
    _tasks = (await _dbHelper.getTasks(userId)).map((e) => Task.fromMap(e)).toList();
    notifyListeners();
  }

  Future<int> addNote(Note note) async {
    final id = await _dbHelper.insertNote(note.toMap());
    await loadNotes(note.userId);
    return id;
  }

  Future<int> updateNote(Note note) async {
    final result = await _dbHelper.updateNote(note.id!, note.userId, note.toMap());
    await loadNotes(note.userId);
    return result;
  }

  Future<int> deleteNote(int id, String userId) async {
    final result = await _dbHelper.deleteNote(id, userId);
    await loadNotes(userId);
    return result;
  }

  Future<int> addTask(Task task) async {
    final id = await _dbHelper.insertTask(task.toMap());
    await loadTasks(task.userId);
    return id;
  }

  Future<int> updateTask(Task task) async {
    final result = await _dbHelper.updateTask(task.id!, task.userId, task.toMap());
    await loadTasks(task.userId);
    return result;
  }

  Future<int> deleteTask(int id, String userId) async {
    final result = await _dbHelper.deleteTask(id, userId);
    await loadTasks(userId);
    return result;
  }

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == date.year &&
          task.dueDate!.month == date.month &&
          task.dueDate!.day == date.day;
    }).toList();
  }

    // In your NotesProvider class
  Future<void> refreshAllData(String userId) async {
    await loadNotes(userId);
    await loadTasks(userId);
    notifyListeners();
  }

  Future<void> addTaskAndRefresh(Task task) async {
    await addTask(task);
    notifyListeners();
  }

  Future<void> updateTaskAndRefresh(Task task) async {
    await updateTask(task);
    notifyListeners();
  }
}