import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/db_helper.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/models/task.dart';
import 'package:smartnotes/new_note_page.dart';
import 'package:smartnotes/providers/notes_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:intl/intl.dart';
import 'package:smartnotes/note_detail_page.dart';
import 'package:smartnotes/providers/theme_provider.dart';
import 'package:smartnotes/calendar_page.dart'; // Ensure calendar_page.dart is imported
import 'package:smartnotes/notebook_page.dart'; // Ensure notebook_page.dart is imported

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> recentNotes = [];
  List<Task> recentTasks = [];
  int _selectedIndex = 0;
  final DBHelper _dbHelper = DBHelper();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CalendarTaskListPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()), // Navigate to NotesPage
      );
    }
  }

  // Helper function to truncate text by word limit
  String _truncateText(String text, int wordLimit) {
    if (text.isEmpty) return '';
    List<String> words = text.split(' ');
    if (words.length > wordLimit) {
      return words.sublist(0, wordLimit).join(' ') + '...';
    }
    return text;
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
            icon: Icon(Icons.folder_outlined, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewNotePage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top yellow line
          Container(
            height: 5,
            color: Colors.yellow.shade200,
          ),
          Expanded(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                notification.disallowIndicator();
                return true;
              },
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                physics: const ClampingScrollPhysics(),
                header: ClassicHeader(
                  height: 60,
                  refreshStyle: RefreshStyle.Follow,
                  textStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  outerBuilder: (child) => Container(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to start
                      children: [
                        Text(
                          'Recent Notes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (recentNotes.isEmpty)
                          Text(
                            'No recent notes.',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          )
                        else
                          ...recentNotes.map(
                            (note) => Card( // Wrap notes in Card
                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    if (note.createdAt != null) // Display creation date
                                      Text(
                                        'Created: ${DateFormat.yMd().format(note.createdAt!)}',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _truncateText(note.content ?? '', 15), // Truncate note content
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Navigate to NoteDetailPage to view/edit this note
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
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          'Read More',
                                          style: TextStyle(
                                            color: Colors.blue.shade300,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                        const SizedBox(height: 8),
                        if (recentTasks.isEmpty)
                          Text(
                            'No recent tasks.',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                          )
                        else
                          ...recentTasks.map(
                            (task) => Card( // Wrap tasks in Card
                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _truncateText(task.title, 10), // Truncate task title
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isDarkMode ? Colors.white : Colors.black,
                                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          if (task.dueDate != null)
                                            Text(
                                              'Due: ${DateFormat.yMd().format(task.dueDate!)}',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: task.isCompleted ? Colors.green : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteDetailPage(
                title: '',
                description: '',
                isNewNote: true,
              ),
            ),
          );

          if (result == true && mounted) {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              await Provider.of<NotesProvider>(context, listen: false).refreshAllData(userId);
              await _loadData();
            }
          }
        },
        backgroundColor: Colors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 35),
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