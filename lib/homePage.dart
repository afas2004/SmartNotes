import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/db_helper.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/models/task.dart';
import 'package:smartnotes/new_note_page.dart';
import 'package:smartnotes/providers/notes_provider.dart';
import 'package:smartnotes/calendar_page.dart';
import 'package:smartnotes/notebook_page.dart';
import 'package:intl/intl.dart';
import 'package:smartnotes/note_detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> recentNotes = [];
  List<Task> recentTasks = [];
  int _selectedIndex = 0;
  final DBHelper _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CalendarTaskListPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/notebook');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Smart Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined), // Changed icon back to folder
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewNotePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Recent Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recentNotes.isEmpty)
              const Text('No recent notes.')
            else
              ...recentNotes.map((note) => ListTile(
                    title: Text(note.title),
                    subtitle: Text(note.content ?? ''),
                  )),
            const SizedBox(height: 24),
            const Text('Recent Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recentTasks.isEmpty)
              const Text('No recent tasks.')
            else
              ...recentTasks.map((task) => ListTile(
                    title: Text(task.title),
                    subtitle: task.dueDate != null
                        ? Text('Due: ${DateFormat.yMd().format(task.dueDate!)}')
                        : null,
                    trailing: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                    ),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteDetailPage(
                title: '',
                description: '',
                isNewNote: true,
              ),
            ),
          );
        },
        backgroundColor: Colors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedIndex == 0 ? Colors.grey.shade300 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, size: 30),
                  Text('Home', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                const Icon(Icons.calendar_month, size: 30),
                const Text('Calendar', style: TextStyle(fontSize: 12)),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                const Icon(Icons.notes, size: 30),
                const Text('Notes', style: TextStyle(fontSize: 12)),
              ],
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}