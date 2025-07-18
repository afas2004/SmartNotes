import 'package:flutter/material.dart';
import 'db_helper.dart';

class NewNotePage extends StatefulWidget {
  const NewNotePage({super.key});

  @override
  State<NewNotePage> createState() => _NewNotePageState();
}

class _NewNotePageState extends State<NewNotePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Senarai pilihan folder
  final List<String> _folderOptions = ['Umum', 'Peribadi', 'Kerja', 'Universiti'];
  String? _selectedFolder;

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final folder = _selectedFolder ?? 'Umum'; // default jika tiada dipilih

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila isi nota dahulu')),
      );
      return;
    }

    final now = DateTime.now().toIso8601String();

    await DBHelper().insertNote({
      'title': title.isEmpty ? 'Tiada Tajuk' : title,
      'content': content,
      'folder': folder,
      'created_at': now,
      'updated_at': now,
    });

    Navigator.pop(context); // kembali ke halaman NotesPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown folder
            DropdownButtonFormField<String>(
              value: _selectedFolder,
              decoration: const InputDecoration(
                labelText: 'Folder',
                border: OutlineInputBorder(),
              ),
              items: _folderOptions.map((folder) {
                return DropdownMenuItem(
                  value: folder,
                  child: Text(folder),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFolder = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Input tajuk
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tajuk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Input kandungan nota
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Kandungan Nota',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Butang simpan
            ElevatedButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
