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

  const NoteDetailPage({
  super.key,
  required this.title,
  required this.description,
  required this.isNewNote,
  this.noteId, // Add this
  this.createdAt, // Add this
  this.folder, // Add if using folders
  this.imageUrl, // Add if using images
  this.imageLocalPath, // Add if using local images
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
    _descriptionController = TextEditingController(text: widget.description);
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
              if (userId == null) return;
              
              final provider = Provider.of<NotesProvider>(context, listen: false);
              
              if (widget.isNewNote) {
                await provider.addNote(Note(
                  userId: userId,
                  title: _titleController.text,
                  content: _descriptionController.text,
                  createdAt: DateTime.now(),
                ));
              } else {
                await provider.updateNote(
                  Note(
                    id: widget.noteId, // You'll need to pass this from notebook_page
                    userId: userId,
                    title: _titleController.text,
                    content: _descriptionController.text,
                    createdAt: widget.createdAt ?? DateTime.now(), // Pass from notebook_page
                    updatedAt: DateTime.now(), // Set update timestamp
                    // Include other fields if needed:
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
