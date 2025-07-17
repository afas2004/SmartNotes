import 'package:flutter/material.dart';
import 'db_helper.dart';

class NotesPage extends StatefulWidget {
  static const String routeName = '/notes';

  const NotesPage({super.key});


  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> _notes = [];
  
  @override
  void initState() {
    super.initState();
    _addNote();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await DBHelper().getNotes();
      setState(() {
        _notes = notes;
      });
      debugPrint('Loaded notes: $_notes');
    } catch (e, stack) {
      debugPrint('Error loading notes: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _addNote() async {
    try {
      await DBHelper().insertNote({
        'title': 'New Note',
        'content': 'Type your content here',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      _loadNotes();
    } on Exception catch (e, stack) {
      debugPrint('Error adding note: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> _editNote(int id, String title, String content) async {
    await DBHelper().updateNote(id, {
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    });
    _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    await DBHelper().deleteNote(id);
    _loadNotes();
  }

  void _showEditDialog(Map<String, dynamic> note) {
    final titleController = TextEditingController(text: note['title']);
    final contentController = TextEditingController(text: note['content']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: contentController, decoration: InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _editNote(note['id'], titleController.text, contentController.text);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  debugPrint('Building NotesPage');
  return Scaffold(
    appBar: AppBar(
        title: const Text('Smart Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),

    body: _notes.isEmpty
        ? Center(child: Text('No notes found.'))
        : ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return ListTile(
                title: Text(note['title']),
                subtitle: Text(note['content'] ?? ''),
                onTap: () => _showEditDialog(note),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(note['id']),
                ),
              );
            },
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: _addNote,
      child: Icon(Icons.add),
    ),
  );
}

  void _showDeleteDialog(int noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () {
              _deleteNote(noteId);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}