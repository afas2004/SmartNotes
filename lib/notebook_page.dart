import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/providers/notes_provider.dart';
import 'note_detail_page.dart'; // Adjust 'your_app_name'
import 'calendar_page.dart'; // Import CalendarTaskListPage
import 'homepage.dart'; // Import HomePage

class NotesPage extends StatefulWidget { // Changed to StatefulWidget to manage _selectedIndex
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  // The selected index for this page's BottomNavigationBar
  // Notes is at index 2, so it's selected when this page is active.
  int _selectedIndex = 2;

  // Update _NotesPageState class
  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final provider = Provider.of<NotesProvider>(context, listen: false);
    await provider.loadNotes(userId);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page
    if (index == 0) {
      // Home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  HomePage()),
      );
    } else if (index == 1) {
      // Calendar page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  CalendarTaskListPage()),
      );
    }
    // If index is 2 (Notes), stay on this page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.folder, color: Colors.yellow),
          onPressed: () {
            // Handle folder icon
          },
        ),
        title: const Text(
          'Notes',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
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
            child: Consumer<NotesProvider>(
              builder: (context, provider, child) {
                if (provider.notes.isEmpty) {
                  return const Center(child: Text('No notes available.'));
                }

                // Group notes into pairs for the grid
                final notePairs = [];
                for (var i = 0; i < provider.notes.length; i += 2) {
                  if (i + 1 < provider.notes.length) {
                    notePairs.add([provider.notes[i], provider.notes[i + 1]]);
                  } else {
                    notePairs.add([provider.notes[i]]);
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children:
                        notePairs.map((pair) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildNoteCard(context, pair[0]),
                                ),
                                if (pair.length > 1) const SizedBox(width: 16),
                                if (pair.length > 1)
                                  Expanded(
                                    child: _buildNoteCard(context, pair[1]),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
              Provider.of<NotesProvider>(context, listen: false).loadNotes(userId);
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
      bottomNavigationBar: BottomNavigationBar( // Bottom nav bar for Notes page
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Column(
              children: [
                const Icon(Icons.home, size: 30),
                const Text('Home', style: TextStyle(fontSize: 12)),
              ],
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
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedIndex == 2 ? Colors.grey.shade300 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notes, size: 30),
                  const Text('Notes', style: TextStyle(fontSize: 12)),
                ],
              ),
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

  // Update _buildNoteCard to use Note model
  Widget _buildNoteCard(BuildContext context, Note note) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () async {
  final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteDetailPage(
                  title: note.title,
                  description: note.content ?? '',
                  isNewNote: false,
                  noteId: note.id, // Pass the note ID
                  createdAt: note.createdAt, // Pass creation date
                  folder: note.folder, // Pass if using folders
                  imageUrl: note.imageUrl, // Pass if using images
                  imageLocalPath: note.imageLocalPath, // Pass if using local images
                ),
              ),
            );
            if (shouldRefresh == true) {
              _loadNotes();
            }
          },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.imageUrl != null || note.imageLocalPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child:
                      note.imageUrl != null
                          ? Image.network(
                            note.imageUrl!,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                          : Image.file(
                            File(note.imageLocalPath!),
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                ),
              const SizedBox(height: 10),
              Text(
                note.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                note.content ?? '',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
