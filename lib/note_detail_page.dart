import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartnotes/models/note.dart'; // Ensure this path is correct for your project
import 'package:smartnotes/providers/notes_provider.dart'; // Ensure this path is correct for your project
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw; 

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
  int _cursorPosition = 0;

  String? _extractImagePath(String? content) {
    if (content == null || !content.contains('[IMAGE:')) return null;
    
    final start = content.indexOf('[IMAGE:') + 7;
    final end = content.indexOf(']', start);
    return content.substring(start, end);
  }

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
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  final FocusNode _textFieldFocusNode = FocusNode();

  // Function to handle saving the note
  Future<void> _saveNote() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save notes')),
      );
      if (!mounted) return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note title cannot be empty')),
      );
      if (!mounted) return;
    }

    if (widget.isNewNote) {
      await provider.addNote(Note(
        userId: userId!,
        title: _titleController.text.trim(),
        content: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        folder: widget.folder,
        imageUrl: widget.imageUrl,
        imageLocalPath: widget.imageLocalPath,
      ));
    } else {
      await provider.updateNote(
        Note(
          id: widget.noteId,
          userId: userId!,
          title: _titleController.text.trim(),
          content: _descriptionController.text.trim(),
          createdAt: widget.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          folder: widget.folder,
          imageUrl: widget.imageUrl,
          imageLocalPath: widget.imageLocalPath,
        ),
      );
    }

    // Return true to indicate success
    navigator.pop(true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save note: ${e.toString()}')),
    );
  }
}

  Future<void> _deleteNote() async {
    if (!widget.isNewNote && widget.noteId != null) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        await Provider.of<NotesProvider>(context, listen: false)
            .deleteNote(widget.noteId!, FirebaseAuth.instance.currentUser!.uid);
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      // Get current cursor position
      final cursorPos = _descriptionController.selection.base.offset;
      final text = _descriptionController.text;
      
      // Insert image marker at cursor position
      final newText = text.substring(0, cursorPos) + 
          '\n[IMAGE:${pickedFile.path}]\n' + 
          text.substring(cursorPos);
      
      _descriptionController.text = newText;
      // Move cursor after the inserted image
      _descriptionController.selection = TextSelection.collapsed(
        offset: cursorPos + '\n[IMAGE:${pickedFile.path}]\n'.length,
      );
    }
  }
  
  Widget _buildImagePreview(String imagePath) {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[200],
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteContent(String content) {
  final parts = content.split(RegExp(r'(\[IMAGE:[^\]]+\])'));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: parts.map((part) {
      if (part.startsWith('[IMAGE:')) {
        final path = part.substring(7, part.length - 1);
        return _buildImagePreview(path);
      }
      return Text(part);
    }).toList(),
  );
}

  @override
  Widget build(BuildContext context) {
  final imagePath = _extractImagePath(_descriptionController.text);
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
        title: Text( // Static "Create Note" as per the new image
          widget.isNewNote ? 'Create Note' : 'Edit Note',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false, // Align title to the left as per image
        actions: [
          if (!widget.isNewNote)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteNote,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'save':
                  _saveNote();
                  break;
                case 'export':
                  _exportNote();
                  break;
                case 'share':
                  _shareNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Text('Save'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export as PDF'),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Share'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  Container(
                    color: Colors.yellow.shade200,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'TITLE',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Description Field
                  TextField(
                    controller: _descriptionController,
                    enableInteractiveSelection: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Description "I like turtles"',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (text) {
                      // Track cursor position
                      _cursorPosition = _descriptionController.selection.base.offset;
                    },
                  ),
                  // Display any images in the note
                  if (imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _buildLocalImagePreview(imagePath),
                    ),

                  // Display network image if URL exists
                  if (widget.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _buildNetworkImagePreview(widget.imageUrl!),
                    ),
                ],
              ),
            ),
          ),
          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Add Photo Button
                _buildIconButton(
                  icon: Icons.add_photo_alternate,
                  label: 'ADD PHOTO',
                  onPressed: _addPhoto,
                ),
                _buildIconButton(
                  icon: Icons.keyboard_voice,
                  label: 'VOICE INPUT',
                  onPressed: () {
                    // Just focuses the text field to show keyboard microphone
                    FocusScope.of(context).requestFocus(_textFieldFocusNode);
                    // For iOS, you might want to show a hint
                    if (Theme.of(context).platform == TargetPlatform.iOS) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tap the microphone on your keyboard'))
                      );
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveNote,
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.save, color: Colors.black),
      ),
    );
  }

  Widget _buildLocalImagePreview(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      ),
    );
  }

  Widget _buildNetworkImagePreview(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: 200,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.yellow : Colors.black,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: isActive ? Colors.yellow : Colors.black, size: 30),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.yellow : Colors.black,
        )),
      ],
    );
  }

  Future<void> _exportNote() async {
  try {
    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    // Create PDF document
    final pdf = pw.Document();

    // Add a page to the PDF (with corrected page format)
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _titleController.text,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  _descriptionController.text,
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save and share the PDF
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Note_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export failed: ${e.toString()}')),
    );
    debugPrint('PDF export error: $e');
  }
}

  Future<void> _shareNote() async {
    try {
      // Prepare content for sharing
      final content = '''
  ${_titleController.text}

  ${_descriptionController.text.replaceAll('[IMAGE:', '\n[Image Attachment]\n')}
  ''';

      // Share text + image if available
      final files = <XFile>[];
      if (widget.imageUrl != null) {
        if (widget.imageUrl!.startsWith('http')) {
          final response = await get(Uri.parse(widget.imageUrl!));
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/shared_image.jpg');
          await file.writeAsBytes(response.bodyBytes);
          files.add(XFile(file.path));
        } else {
          files.add(XFile(widget.imageUrl!));
        }
      }

      // Execute share
      await Share.shareXFiles(
        files,
        text: content,
        subject: 'Shared Note: ${_titleController.text}',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sharing failed: ${e.toString()}')),
        );
      }
    }
  }
}

