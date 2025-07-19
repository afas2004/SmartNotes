import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/providers/notes_provider.dart';
import 'package:smartnotes/providers/theme_provider.dart';
import 'package:smartnotes/note_detail_page.dart';
import 'package:smartnotes/calendar_page.dart';
import 'package:smartnotes/homepage.dart';
import 'package:intl/intl.dart'; // Add this import for DateFormat

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
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

  Widget _buildNoteCard(Note note, BuildContext context, bool isDarkMode) {
    // Extract the first image path if it exists in the content
    String? imagePath;
    if (note.content != null && note.content!.contains('[IMAGE:')) {
      final regex = RegExp(r'\[IMAGE:([^\]]+)\]');
      final match = regex.firstMatch(note.content!);
      if (match != null) {
        imagePath = match.group(1);
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? Colors.grey[800] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailPage(
                title: note.title,
                description: note.content ?? '',
                isNewNote: false,
                noteId: note.id,
                createdAt: note.createdAt,
                folder: note.folder,
                imageUrl: note.imageUrl,
                imageLocalPath: note.imageLocalPath,
              ),
            ),
          );
          if (shouldRefresh == true && mounted) {
            _loadNotes();
          }
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 100,
            maxHeight: 220, // Adjust this value based on your needs
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                if (note.imageUrl != null || note.imageLocalPath != null || imagePath != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: note.imageUrl != null
                          ? Image.network(
                              note.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
                            )
                          : (note.imageLocalPath != null
                              ? Image.file(
                                  File(note.imageLocalPath!),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
                                )
                              : (imagePath != null
                                  ? Image.file(
                                      File(imagePath),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildImageErrorPlaceholder(),
                                    )
                                  : Container())),
                    ),
                  ),

                // Title and content section
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
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
                      Flexible(
                        child: Text(
                          note.content?.replaceAll(RegExp(r'\[IMAGE:[^\]]+\]'), '') ?? '',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
        title: Text(
          'Notes',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.folder_outlined, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotesPage()),
            ),
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
          Container(
            height: 5,
            color: Colors.yellow.shade200,
          ),
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, provider, child) {
                // Remove isLoading check since we're not using it
                if (provider.notes.isEmpty) {
                  return Center(
                    child: Text(
                      'No notes available',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: provider.notes.length,
                    itemBuilder: (context, index) {
                      return _buildNoteCard(provider.notes[index], context, isDarkMode);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
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
        child: const Icon(Icons.edit, color: Colors.black, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}