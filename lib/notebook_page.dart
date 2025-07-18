import 'package:flutter/material.dart';
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
              // Handle settings icon
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Row 1 of notes
                  Row(
                    children: [
                      Expanded(child: _buildNoteCard(
                        context,
                        'Saya belajar abc...',
                        'ABCDEFGHIJKLMNNOPQRSTUV WXYZ',
                        'https://placehold.co/150x100/FFD700/000000?text=ABC',
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNoteCard(
                        context,
                        'Saya belajar 123...',
                        '12345678910',
                        'https://placehold.co/150x100/FFD700/000000?text=123',
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Row 2 of notes
                  Row(
                    children: [
                      Expanded(child: _buildNoteCard(
                        context,
                        'Saya belajar abc...',
                        'ABCDEFGHIJKLMNNOPQRSTUV WXYZ',
                        'https://placehold.co/150x100/FFD700/000000?text=ABC',
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNoteCard(
                        context,
                        'Saya belajar abc...',
                        'ABCDEFGHIJKLMNNOPQRSTUV WXYZ',
                        'https://placehold.co/150x100/FFD700/000000?text=ABC',
                      )),
                    ],
                  ),
                  // Add more rows as needed
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteDetailPage(
              title: '',
              description: '',
              isNewNote: true,
            )),
          );
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

  Widget _buildNoteCard(BuildContext context, String title, String description, String imageUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteDetailPage(
              title: title,
              description: description,
              isNewNote: false,
            )),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
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
