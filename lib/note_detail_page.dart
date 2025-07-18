import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/models/note.dart'; // Ensure this path is correct for your project
import 'package:smartnotes/providers/notes_provider.dart'; // Ensure this path is correct for your project

class NoteDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final bool isNewNote;
  final int? noteId;
  final DateTime? createdAt;
  final String? folder;
  final String? imageUrl;
  final String? imageLocalPath;
  final String? initialText;

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
    this.initialText,
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
    _descriptionController = TextEditingController(
  text: widget.isNewNote && widget.initialText != null
      ? widget.initialText
      : widget.description,
);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to handle saving the note
  Future<void> _saveNote() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Handle case where user is not logged in (e.g., show a snackbar)
      print('User not logged in. Cannot save note.');
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);

    if (widget.isNewNote) {
      await provider.addNote(Note(
        userId: userId,
        title: _titleController.text,
        content: _descriptionController.text,
        createdAt: DateTime.now(),
        // Add other fields if needed, e.g., folder, imageUrl, imageLocalPath
      ));
    } else {
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

    // After saving, pop the page and indicate success
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), // Simple back arrow as per image
          onPressed: () {
            Navigator.pop(context); // Go back to the previous page
          },
        ),
        title: const Text( // Static "Create Note" as per the new image
          'Create Note',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false, // Align title to the left as per image
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black), // More options icon as per image
            onPressed: () {
              // TODO: Implement a dropdown menu or dialog for more options,
              // including a "Save" option that calls _saveNote().
              // For now, we'll call save directly for demonstration.
              _saveNote(); // Calling save directly for now.
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top yellow line removed as per new image
          Expanded(
            child: SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input Field (updated style based on image)
                  Container(
                    color: Colors.yellow.shade200, // Yellow background
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'TITLE', // Placeholder text
                        border: InputBorder.none, // No border
                        isDense: true, // Reduce vertical space
                        contentPadding: EdgeInsets.zero, // Remove default padding
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Increased spacing
                  // Description Input Field (updated hint text and no border)
                  TextField(
                    controller: _descriptionController,
                    maxLines: null, // Allows for multiline input
                    minLines: 1, // Start with at least one line
                    decoration: const InputDecoration(
                      hintText: 'I like turtles', // Example text as per image
                      border: InputBorder.none, // No border
                      isDense: true, // Reduce vertical space
                      contentPadding: EdgeInsets.zero, // Remove default padding
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20), // Spacing before image
                  // Actual Turtle Image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0), // Rounded corners for image
                      child: Image.network(
                        widget.imageUrl ?? 'http://googleusercontent.com/file_content/4', // Using the provided image URL
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: 300,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50), // Spacing before buttons
                ],
              ),
            ),
          ),
          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0), // Padding from bottom
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Add Photo Button
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_photo_alternate, color: Colors.black, size: 30),
                        onPressed: () {
                          // Handle add photo
                          print('Add Photo button pressed');
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('ADD PHOTO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                // Voice-to-Text Button
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.mic, color: Colors.black, size: 30),
                        onPressed: () {
                          // Handle voice-to-text
                          print('Voice-to-Text button pressed');
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('VOICE-TO-TEXT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
