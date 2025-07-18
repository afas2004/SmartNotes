import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/providers/notes_provider.dart';

class NoteDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final bool isNewNote;
  final int? noteId;
  final DateTime? createdAt;
  final String? folder;
  final String? imageUrl;
  final String? imageLocalPath;
  final String? initialText; // <--- ADDED THIS LINE

  const NoteDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.isNewNote,
    this.noteId,
    this.createdAt,
    this.folder,
    this.imageUrl,
    this.imageLocalPath,
    this.initialText, // <--- ADDED THIS LINE
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    // Use initialText if provided, otherwise use existing description or empty string
    _descriptionController = TextEditingController(
      text: widget.initialText ?? widget.description, // <--- MODIFIED THIS LINE
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: Text(
          widget.isNewNote ? 'New Note' : 'Edit Note',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.black),
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId == null) {
                // Optionally show a message if user is not logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in. Cannot save note.')),
                );
                return;
              }
              
              final provider = Provider.of<NotesProvider>(context, listen: false);
              
              if (widget.isNewNote) {
                await provider.addNote(Note(
                  userId: userId,
                  title: _titleController.text,
                  content: _descriptionController.text,
                  createdAt: DateTime.now(),
                ));
              } else {
                // Ensure noteId is not null for updates
                if (widget.noteId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Cannot update note without an ID.')),
                  );
                  return;
                }
                await provider.updateNote(
                  Note(
                    id: widget.noteId,
                    userId: userId,
                    title: _titleController.text,
                    content: _descriptionController.text,
                    createdAt: widget.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                    folder: widget.folder,
                    imageUrl: widget.imageUrl,
                    imageLocalPath: widget.imageLocalPath,
                  ),
                );
              }
              
              Navigator.pop(context, true); // Return true to indicate success
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Colors.yellow, width: 2.0),
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: null, // Allows for multiline input
                      expands: true, // Allows the text field to expand
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.yellow, width: 2.0),
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
