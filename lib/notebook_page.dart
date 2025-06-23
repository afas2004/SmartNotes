import 'package:flutter/material.dart';

class NotebookPage extends StatelessWidget {
  final List<String> notebooks = ['CSC510', 'Work', 'ICT450'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Notebook")),
      drawer: Drawer(), // Optional for menu icon
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: notebooks.map((title) {
                return Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.folder),
                    ),
                    Text(title)
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Divider(),
            Text("RECENT NOTES", style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              leading: Icon(Icons.note),
              title: Text("Project ICT551"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 10),
                  Icon(Icons.delete),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
