// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase User
import 'package:provider/provider.dart'; // For Provider
import 'package:audioplayers/audioplayers.dart'; // For Audio playback
import 'dart:io'; // For File.fromUri (used with Image.file)

// Local imports for models and services
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/models/task.dart';
import 'package:smartnotes/db_helper.dart'; // Your custom DB Helper
import 'package:smartnotes/services/auth_service.dart'; // Your Auth Service

// Placeholder for other pages in BottomNavigationBar
// You'll need to create these files if they don't exist
import 'package:smartnotes/calendar_page.dart'; // Assuming this is your Calendar page
import 'package:smartnotes/notes_page.dart'; // Create a page for all notes

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> recentNotes = [];
  List<Task> recentTasks = [];
  final DBHelper _dbHelper = DBHelper(); // Use your DBHelper
  final AuthService _auth = AuthService();
  String? _currentUserId; // Stores the current authenticated user's ID
  int _selectedIndex = 0; // Current index for BottomNavigationBar (Home is 0)

  @override
  void initState() {
    super.initState();
    // Listen to Firebase Auth state changes
    _auth.user.listen((user) {
      if (user != null && user.uid != _currentUserId) {
        // User logged in or switched
        setState(() {
          _currentUserId = user.uid;
        });
        _loadData(); // Load data specific to this user
      } else if (user == null && _currentUserId != null) {
        // User logged out
        setState(() {
          _currentUserId = null;
          recentNotes = []; // Clear data on logout
          recentTasks = []; // Clear data on logout
        });
      }
    });
  }

  // Fetches recent notes and tasks from the database for the current user
  Future<void> _loadData() async {
    if (_currentUserId == null) {
      debugPrint('No user ID available, cannot load data.');
      return; // Do not load data if no user is logged in
    }

    // Add some initial dummy data if the database is empty for this user
    await _addInitialDummyDataIfEmpty(_currentUserId!);

    try {
      // Fetch notes for the current user
      final List<Map<String, dynamic>> noteMaps =
          await _dbHelper.getNotes(_currentUserId!, limit: 2);
      final List<Note> notes = noteMaps.map((map) => Note.fromMap(map)).toList();

      // Fetch tasks for the current user
      final List<Map<String, dynamic>> taskMaps =
          await _dbHelper.getTasks(_currentUserId!, limit: 4);
      final List<Task> tasks = taskMaps.map((map) => Task.fromMap(map)).toList();

      setState(() {
        recentNotes = notes;
        recentTasks = tasks;
      });
      debugPrint('Data loaded for user: $_currentUserId');
    } catch (e) {
      debugPrint('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  // This function populates the database with dummy data for a new user
  // or if their tables are empty. Remove or modify for production.
  Future<void> _addInitialDummyDataIfEmpty(String userId) async {
    // Check if user has any notes
    final existingNotes = await _dbHelper.getNotes(userId, limit: 1);
    if (existingNotes.isEmpty) {
      debugPrint('Adding initial dummy notes for user: $userId');
      await _dbHelper.insertNote(
        Note(
          userId: userId,
          title: 'Saya belajar abc...',
          content: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
          folder: 'Learning',
          imageUrl: 'https://placehold.co/150x100/FFDDC1/000000?text=ABC', // Matches image
          imageLocalPath: null,
          audioUrl: null,
          createdAt: DateTime.now().subtract(Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(Duration(hours: 3)),
        ).toMap(),
      );
      await _dbHelper.insertNote(
        Note(
          userId: userId,
          title: 'Saya belajar 123...',
          content: '12345678910',
          folder: 'Learning',
          imageUrl: 'https://placehold.co/150x100/FFDDC1/000000?text=123', // Matches image
          imageLocalPath: null,
          audioUrl: null,
          createdAt: DateTime.now().subtract(Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(Duration(hours: 1)),
        ).toMap(),
      );
      await _dbHelper.insertNote(
        Note(
          userId: userId,
          title: 'A Text-Only Note',
          content: 'Just some text here, no media attachments.',
          folder: 'Personal',
          imageUrl: null,
          imageLocalPath: null,
          audioUrl: null,
          createdAt: DateTime.now().subtract(Duration(minutes: 30)),
          updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
        ).toMap(),
      );
    }

    // Check if user has any tasks
    final existingTasks = await _dbHelper.getTasks(userId, limit: 1);
    if (existingTasks.isEmpty) {
      debugPrint('Adding initial dummy tasks for user: $userId');
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Buy groceries',
          isCompleted: false,
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          updatedAt: DateTime.now().subtract(Duration(days: 3)),
        ).toMap(),
      );
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Finish report',
          isCompleted: false,
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          updatedAt: DateTime.now().subtract(Duration(days: 2)),
        ).toMap(),
      );
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Call mom',
          isCompleted: true, // Example of a completed task
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          updatedAt: DateTime.now().subtract(Duration(days: 1)),
        ).toMap(),
      );
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Go for a run',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap(),
      );
    }
  }

  // Example function to add a new task
  Future<void> _addNewTask(String title) async {
    if (_currentUserId == null) return;
    final newTask = Task(
      userId: _currentUserId!,
      title: title,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dbHelper.insertTask(newTask.toMap());
    _loadData(); // Reload data to update UI
  }

  // Example function to add a new note
  Future<void> _addNewNote(String title, String? content,
      {String? folder, String? imageLocalPath, String? imageUrl, String? audioUrl}) async {
    if (_currentUserId == null) return;
    final newNote = Note(
      userId: _currentUserId!,
      title: title,
      content: content,
      folder: folder,
      imageLocalPath: imageLocalPath,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _dbHelper.insertNote(newNote.toMap());
    _loadData(); // Reload data to update UI
  }

  // Handles BottomNavigationBar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page
    if (index == 0) {
      // Home page (stay on this page)
    } else if (index == 1) {
      // Calendar page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CalendarTaskListPage()),
      );
    } else if (index == 2) {
      // Notes page (all notes list)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the User object from the Provider tree
    final user = Provider.of<User?>(context);
    // Ensure _currentUserId is always in sync with the authenticated user
    _currentUserId = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0CA), // Light yellow background from image
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to show background color
        elevation: 0, // No shadow
        toolbarHeight: 60, // Standard height
        // To match the image, we'll place the folder and settings icons directly in actions
        // The status bar icons (wifi, battery) are system-level and not part of AppBar directly.
        actions: [
          // Folder Icon
          IconButton(
            icon: const Icon(Icons.folder_outlined, color: Colors.black, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Navigate to All Notes/Folders page')));
              // TODO: Implement navigation to a screen showing all notes/folders
            },
          ),
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to Settings page')));
              // TODO: Implement navigation to settings page
            },
          ),
          // Logout button (optional, but good for auth flow)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black, size: 28),
            onPressed: () async {
              await _auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully!')));
            },
          ),
          const SizedBox(width: 16), // Padding on the right
        ],
      ),
      body: _currentUserId == null
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show loading while user ID is determined
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20), // Spacing from app bar

                      // Recent Notes Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Notes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('View all notes!')));
                              // TODO: Navigate to All Notes page, passing _currentUserId
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 220, // Increased height to accommodate date and buttons
                        child: recentNotes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No recent notes. Add one!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: recentNotes.length,
                                itemBuilder: (context, index) {
                                  final note = recentNotes[index];
                                  return NoteCard(note: note);
                                },
                              ),
                      ),
                      const SizedBox(height: 32),

                      // Recent Tasks Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Tasks',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('View all tasks!')));
                              // TODO: Navigate to All Tasks page, passing _currentUserId
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      recentTasks.isEmpty
                          ? const Center(
                              child: Text(
                                'No recent tasks. Add one!',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
                              itemCount: recentTasks.length,
                              itemBuilder: (context, index) {
                                final task = recentTasks[index];
                                return TaskListItem(
                                  task: task,
                                  onChanged: (bool? value) async {
                                    if (value != null) {
                                      setState(() {
                                        task.isCompleted = value;
                                        task.updatedAt = DateTime.now(); // Update timestamp
                                      });
                                      // Update task status in DB
                                      await _dbHelper.updateTask(
                                          task.id!, task.userId, task.toMap());
                                      // Optionally, reload data to ensure order is correct if sorting by updated_at
                                      // _loadData();
                                    }
                                  },
                                );
                              },
                            ),
                      const SizedBox(height: 100), // Space for FAB and Bottom NavBar
                    ],
                  ),
                ),
                // Positioned Floating Action Button (matches image)
                Positioned(
                  bottom: 100, // Adjust based on bottom nav bar height
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      // Show a dialog to choose adding note or task
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Add New...'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.edit_note),
                                  title: const Text('Add Note (with media example)'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Example of adding a note with random media
                                    final int random = DateTime.now().second;
                                    _addNewNote(
                                      'New FAB Note ${random}',
                                      'Content added via FAB at ${DateTime.now().toIso8601String().substring(11,19)}.',
                                      folder: 'Quick Add',
                                      imageUrl: random % 2 == 0
                                          ? 'https://placehold.co/150x100/00FFFF/000000?text=FAB_IMG_${random}'
                                          : null,
                                      audioUrl: random % 3 == 0
                                          ? 'https://www2.cs.uic.edu/~iokaz/CS342/audio/beep.wav' // Replace with your actual audio asset/URL
                                          : null,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.task_alt),
                                  title: const Text('Add Task'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addNewTask('New FAB Task ${DateTime.now().second}');
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    backgroundColor: const Color(0xFFF9DC5C), // Yellow color from image
                    child: const Icon(Icons.add, color: Colors.black, size: 30),
                    shape: const CircleBorder(), // Make it perfectly circular
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // White background for the bar
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black, // Unselected items are also black in the image
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Use the new handler
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        items: <BottomNavigationBarItem>[
          // Home Item (matches image style)
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedIndex == 0 ? const Color(0xFFDDDDDD) : Colors.transparent, // Light grey for selected home
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min, // To make column compact
                children: [
                  Icon(Icons.home, size: 30),
                  Text('Home', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            label: '', // Label is part of the column
          ),
          // Calendar Item (matches image style)
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedIndex == 1 ? const Color(0xFFDDDDDD) : Colors.transparent, // Light grey for selected calendar
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 30), // Changed to calendar_month for better match
                  Text('Calendar', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            label: '',
          ),
          // Notes Item (matches image style)
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedIndex == 2 ? const Color(0xFFDDDDDD) : Colors.transparent, // Light grey for selected notes
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notes, size: 30), // Changed to notes for better match
                  Text('Notes', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}

// Custom Widget for Note Card (remains mostly the same as previous response)
class NoteCard extends StatefulWidget {
  final Note note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.note.audioUrl == null) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        Source audioSource;
        if (widget.note.audioUrl!.startsWith('http://') ||
            widget.note.audioUrl!.startsWith('https://')) {
          audioSource = UrlSource(widget.note.audioUrl!);
        } else {
          audioSource = DeviceFileSource(widget.note.audioUrl!);
        }
        await _audioPlayer.play(audioSource);
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')));
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on note: ${widget.note.title}')));
        // TODO: Navigate to specific note detail page using widget.note.id and widget.note.userId
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview (if image exists)
            if (widget.note.imageLocalPath != null || widget.note.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                child: widget.note.imageLocalPath != null
                    ? Image.file(
                        File(widget.note.imageLocalPath!),
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 90,
                          color: Colors.grey[200],
                          child: const Center(child: Text('Local Image Error')),
                        ),
                      )
                    : Image.network(
                        widget.note.imageUrl!,
                        height: 90,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 90,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image_not_supported)),
                        ),
                      ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.note.formattedDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Audio Play Button (if audio exists)
                  if (widget.note.audioUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _playAudio,
                        icon: Icon(
                          _playerState == PlayerState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(
                          _playerState == PlayerState.playing
                              ? 'Pause Audio'
                              : (_playerState == PlayerState.paused ? 'Resume' : 'Play Audio'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
}

// Custom Widget for Task List Item (matches image style)
class TaskListItem extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onChanged;

  const TaskListItem({
    Key? key,
    required this.task,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Increased vertical padding
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped on task: ${task.title}')));
          // TODO: Navigate to task detail/edit page using task.id and task.userId
        },
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: onChanged, // This will trigger setState in HomePage and update DB
              activeColor: Colors.pink, // Checkbox color as per image
              checkColor: Colors.white,
            ),
            Expanded(
              child: Container(
                height: 40, // Fixed height as in image
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey[600] : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            // Edit Icon (matches image)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit task: ${task.title}')));
                // TODO: Handle edit task
              },
            ),
            // Delete Icon (matches image)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.pink, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete task: ${task.title}')));
                // TODO: Handle delete task
              },
            ),
          ],
        ),
      ),
    );
  }
}