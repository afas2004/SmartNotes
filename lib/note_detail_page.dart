import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartnotes/models/note.dart';
import 'package:smartnotes/providers/notes_provider.dart';
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
  final FocusNode _textFieldFocusNode = FocusNode();

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

  List<String> _extractImagePaths(String? content) {
    if (content == null) return [];
    final regex = RegExp(r'\[IMAGE:([^\]]+)\]');
    return regex.allMatches(content).map((match) => match.group(1)!).toList();
  }

  Future<void> _saveNote() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to save notes')),
        );
        return;
      }

      final provider = Provider.of<NotesProvider>(context, listen: false);
      final navigator = Navigator.of(context);

      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note title cannot be empty')),
        );
        return;
      }

      final note = Note(
        id: widget.noteId,
        userId: userId,
        title: _titleController.text.trim(),
        content: _descriptionController.text.trim(),
        createdAt: widget.isNewNote ? DateTime.now() : widget.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        folder: widget.folder,
        imageUrl: widget.imageUrl,
        imageLocalPath: widget.imageLocalPath,
      );

      if (widget.isNewNote) {
        await provider.addNote(note);
      } else {
        await provider.updateNote(note);
      }

      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: ${e.toString()}')),
        );
      }
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

      if (shouldDelete == true && mounted) {
        await Provider.of<NotesProvider>(context, listen: false)
            .deleteNote(widget.noteId!, FirebaseAuth.instance.currentUser!.uid);
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null && mounted) {
      final cursorPos = _descriptionController.selection.base.offset.clamp(
        0, 
        _descriptionController.text.length
      );
      
      final newText = _descriptionController.text.substring(0, cursorPos) + 
          '\n[IMAGE:${pickedFile.path}]\n' + 
          _descriptionController.text.substring(cursorPos);
      
      setState(() {
        _descriptionController.text = newText;
        _descriptionController.selection = TextSelection.collapsed(
          offset: cursorPos + '\n[IMAGE:${pickedFile.path}]\n'.length,
        );
      });
    }
  }

  Widget _buildImagePreview(String imagePath) {
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 400,
      ),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain, // Changed from BoxFit.cover to BoxFit.contain
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: Icon(Icons.broken_image, 
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    ),
  );
}

  Future<void> _exportNote() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final pdf = pw.Document();
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

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Note_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareNote() async {
    try {
      final content = '''
${_titleController.text}

${_descriptionController.text.replaceAll('[IMAGE:', '\n[Image Attachment]\n')}
''';

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

  @override
  Widget build(BuildContext context) {
    final imagePaths = _extractImagePaths(_descriptionController.text);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isNewNote ? 'Create Note' : 'Edit Note',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!widget.isNewNote)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteNote,
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
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
                  Container(
                    color: colorScheme.primaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'TITLE',
                        hintStyle: TextStyle(color: colorScheme.onPrimaryContainer.withOpacity(0.6)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    focusNode: _textFieldFocusNode,
                    enableInteractiveSelection: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Description "I like turtles"',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                    onChanged: (text) => setState(() {}),
                    // This will hide the image tags in the text field
                    buildCounter: (context, 
                        {required currentLength, required isFocused, maxLength}) {
                      final displayText = _descriptionController.text
                        .replaceAll(RegExp(r'\[IMAGE:[^\]]+\]'), '');
                      return Text(
                        '${displayText.length} characters',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                  ...imagePaths.map((path) => _buildImagePreview(path)).toList(),
                  if (widget.imageUrl != null)
                    _buildNetworkImagePreview(widget.imageUrl!),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconButton(
                  icon: Icons.add_photo_alternate,
                  label: 'ADD PHOTO',
                  onPressed: _addPhoto,
                  color: colorScheme.primaryContainer, // Use theme color
                ),
                _buildIconButton(
                  icon: Icons.keyboard_voice,
                  label: 'VOICE INPUT',
                  onPressed: () {
                    FocusScope.of(context).requestFocus(_textFieldFocusNode);
                    if (Theme.of(context).platform == TargetPlatform.iOS) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tap the microphone on your keyboard'))
                      );
                    }
                  },
                  color: colorScheme.primaryContainer, // Use theme color
                ),
                _buildIconButton(
                  icon: Icons.save,
                  label: 'SAVE',
                  onPressed: _saveNote,
                  color: Theme.of(context).colorScheme.primary, // Use theme color
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImagePreview(String imageUrl) {
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 400,
      ),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain, // Changed from BoxFit.cover to BoxFit.contain
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: Icon(Icons.broken_image, 
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed, required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: theme.colorScheme.onSurface, size: 30),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}