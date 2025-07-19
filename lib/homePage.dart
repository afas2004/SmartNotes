import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/db_helper.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/models/task.dart';
import 'package:smartnotes/providers/notes_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:intl/intl.dart';
import 'package:smartnotes/note_detail_page.dart';
import 'package:smartnotes/providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> recentNotes = [];
  List<Task> recentTasks = [];
  final DBHelper _dbHelper = DBHelper();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted) {
        _loadData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      Provider.of<NotesProvider>(context, listen: false).refreshAllData(userId);
    }
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final noteMaps = await _dbHelper.getNotes(userId, limit: 2);
    final taskMaps = await _dbHelper.getTasks(userId, limit: 4);

    if (mounted) {
      setState(() {
        recentNotes = noteMaps.map((e) => Note.fromMap(e)).toList();
        recentTasks = taskMaps.map((e) => Task.fromMap(e)).toList();
      });
    }
  }

  Future<void> _onRefresh() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await Provider.of<NotesProvider>(context, listen: false).refreshAllData(userId);
        await _loadData();
      }
    } catch (e) {
      print('Refresh error: $e');
    } finally {
      _refreshController.refreshCompleted();
    }
  }

  String _truncateText(String text, int wordLimit) {
    if (text.isEmpty) return '';
    List<String> words = text.split(' ');
    if (words.length > wordLimit) {
      return words.sublist(0, wordLimit).join(' ') + '...';
    }
    return text;
  }

  Widget _buildNoteCard(Note note, BuildContext context, bool isDarkMode) {
    String? imagePath = _extractImagePath(note.content);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(
                noteId: note.id,
                title: note.title,
                description: note.content ?? '',
                isNewNote: false,
                createdAt: note.createdAt,
                folder: note.folder,
                imageUrl: note.imageUrl,
                imageLocalPath: note.imageLocalPath,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagePath != null || note.imageUrl != null || note.imageLocalPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: note.imageUrl != null
                        ? Image.network(
                            note.imageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : note.imageLocalPath != null
                            ? Image.file(
                                File(note.imageLocalPath!),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : imagePath != null
                                ? Image.file(
                                    File(imagePath),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(),
                  ),
                ),
              Text(
                note.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(note.createdAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                note.content?.replaceAll(RegExp(r'\[IMAGE:[^\]]+\]'), '') ?? '',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _extractImagePath(String? content) {
    if (content == null || !content.contains('[IMAGE:')) return null;
    final regex = RegExp(r'\[IMAGE:([^\]]+)\]');
    final match = regex.firstMatch(content);
    return match?.group(1);
  }

  Widget _buildTaskCard(Task task, BuildContext context, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isCompleted
                              ? (isDarkMode ? Colors.green : Colors.green[700])
                              : (isDarkMode ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'Smart Notes',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: ClassicHeader(
          height: 60,
          refreshStyle: RefreshStyle.Follow,
          textStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top yellow line
              Container(
                height: 5,
                color: Colors.yellow.shade200,
              ),
              const SizedBox(height: 16),
              Text(
                'Recent Notes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              if (recentNotes.isEmpty)
                Text(
                  'No recent notes.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                )
              else
                ...recentNotes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildNoteCard(note, context, isDarkMode),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Recent Tasks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              if (recentTasks.isEmpty)
                Text(
                  'No recent tasks.',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                )
              else
                ...recentTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTaskCard(task, context, isDarkMode),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabOpen)
            FloatingActionButton(
              heroTag: 'ocr_fab',
              mini: true,
              onPressed: () {
                setState(() => _isFabOpen = false);
                Navigator.pushNamed(context, '/scan');
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.document_scanner, color: Colors.white),
            ),
          if (_isFabOpen)
            const SizedBox(height: 8),
          if (_isFabOpen)
            FloatingActionButton(
              heroTag: 'note_fab',
              mini: true,
              onPressed: () {
                setState(() => _isFabOpen = false);
                Navigator.pushNamed(
                  context,
                  '/note_detail',
                  arguments: {
                    'title': '',
                    'description': '',
                    'isNewNote': true,
                  },
                );
              },
              backgroundColor: Colors.yellow,
              child: const Icon(Icons.note_add, color: Colors.black),
            ),
          FloatingActionButton(
            heroTag: 'main_fab',
            onPressed: () {
              setState(() => _isFabOpen = !_isFabOpen);
            },
            backgroundColor: Colors.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: AnimatedRotation(
              turns: _isFabOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add, color: Colors.black, size: 35),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}