// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase User
import 'package:provider/provider.dart'; // For Provider
import 'package:audioplayers/audioplayers.dart'; // For Audio playback
import 'dart:io'; // For File.fromUri (used with Image.file)

// Local imports for models and services
import 'package:my_awesome_notes_app/models/note.dart';
import 'package:my_awesome_notes_app/models/task.dart';
import 'package:my_awesome_notes_app/db_helper.dart'; // Your custom DB Helper
import 'package:my_awesome_notes_app/services/auth_service.dart'; // Your Auth Service

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
      // debugPrint('No user ID available, cannot load data.');
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
      // debugPrint('Data loaded for user: $_currentUserId');
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
          title: 'My First Note (Image)',
          content: 'This is a sample note with a network image.',
          folder: 'General',
          imageUrl: 'https://placehold.co/150x100/FFDDC1/000000?text=Note+IMG', // Example network image
          imageLocalPath: null,
          audioUrl: null,
          createdAt: DateTime.now().subtract(Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(Duration(hours: 3)),
        ).toMap(),
      );
      await _dbHelper.insertNote(
        Note(
          userId: userId,
          title: 'Audio Recording Idea',
          content: 'Remember to record the meeting minutes for the new project.',
          folder: 'Work',
          imageUrl: null,
          imageLocalPath: null,
          // IMPORTANT: Replace with a valid, accessible audio URL for testing.
          // For local audio, you'd need to record/save it first.
          audioUrl: 'https://www2.cs.uic.edu/~iokaz/CS342/audio/beep.wav', // Example dummy audio URL
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
          title: 'Complete Flutter Auth Integration',
          isCompleted: false,
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          updatedAt: DateTime.now().subtract(Duration(days: 3)),
        ).toMap(),
      );
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Plan new feature for Notes App',
          isCompleted: false,
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          updatedAt: DateTime.now().subtract(Duration(days: 2)),
        ).toMap(),
      );
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Call John about meeting',
          isCompleted: true,
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          updatedAt: DateTime.now().subtract(Duration(days: 1)),
        ).toMap(),
      );
      await _dbHelper.insertTask(
        Task(
          userId: userId,
          title: 'Go for a morning run',
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

  @override
  Widget build(BuildContext context) {
    // Get the User object from the Provider tree
    final user = Provider.of<User?>(context);
    // Ensure _currentUserId is always in sync with the authenticated user
    _currentUserId = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0CA), // Light yellow background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 0, // Remove default leading padding
        titleSpacing: 0, // Remove default title spacing
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Logout button
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () async {
                  await _auth.signOut();
                  // The Wrapper widget will automatically handle navigation back to AuthScreen
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully!')));
                },
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Navigate to All Notes/Folders page')));
              // TODO: Implement navigation to a screen showing all notes/folders, passing _currentUserId
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Navigate to Settings page')));
              // TODO: Implement navigation to settings page
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
                // Positioned Floating Action Button
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
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 0, // Assuming Home is the first item
        onTap: (index) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bottom Nav Item ${index} clicked!')));
          // TODO: Implement navigation based on index (e.g., to Calendar or Notes list)
        },
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD), // Light grey for selected home
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.home),
            ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined), // Or Icons.notes
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}

// Custom Widget for Note Card
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
    // Listen for changes in player state to update UI (e.g., icon)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          _playerState = state;
        });
      }
    });
    // Listen for completion to reset button
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
    _audioPlayer.dispose(); // Dispose the audio player to prevent memory leaks
    super.dispose();
  }

  // Handles playing, pausing, and resuming audio
  Future<void> _playAudio() async {
    if (widget.note.audioUrl == null) return;

    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else if (_playerState == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        Source audioSource;
        // Determine if it's a local file path or a network URL
        if (widget.note.audioUrl!.startsWith('http://') ||
            widget.note.audioUrl!.startsWith('https://')) {
          audioSource = UrlSource(widget.note.audioUrl!);
        } else {
          // Assuming local file paths are absolute and accessible
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
          _playerState = PlayerState.stopped; // Reset state on error
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
        width: 180, // Fixed width for horizontal scroll
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
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
                        File(widget.note.imageLocalPath!), // Load from local path
                        height: 90, // Adjusted image height
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 90,
                          color: Colors.grey[200],
                          child: const Center(child: Text('Local Image Error')),
                        ),
                      )
                    : Image.network(
                        widget.note.imageUrl!, // Load from network URL
                        height: 90, // Adjusted image height
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
                    widget.note.formattedDate, // Display formatted date
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Audio Play Button (if audio exists)
                  if (widget.note.audioUrl != null)
                    SizedBox(
                      width: double.infinity, // Make button take full width
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
                              : (_playerState == PlayerState.paused ? 'Resume Audio' : 'Play Audio'),
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

// Custom Widget for Task List Item
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tapped on task: ${task.title}')));
          // TODO: Navigate to task detail/edit page using task.id and task.userId
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // White background for the task bar
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: onChanged, // This will trigger setState in HomePage and update DB
                activeColor: Colors.black, // Color when checked
                checkColor: Colors.white, // Color of the checkmark
              ),
              Expanded(
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
              const SizedBox(width: 16), // Padding on the right
            ],
          ),
        ),
      ),
    );
  }
}