import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  final List<String> tasks = [
    'Meeting with Sarah',
    'Call Haziq',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Calendar")),
      drawer: Drawer(), // Optional for menu icon
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("16 March 2021", style: TextStyle(fontSize: 20)),
          ),
          // Calendar mock-up (just for UI)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Calendar Widget Placeholder"),
          ),
          Divider(),
          Text("TODAY LIST", style: TextStyle(fontWeight: FontWeight.bold)),
          ...tasks.map((task) => ListTile(
                leading: Icon(Icons.radio_button_unchecked),
                title: Text(task),
              )),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notebook');
            },
            child: Text("Go to Notebook"),
          ),
        ],
      ),
    );
  }
}
