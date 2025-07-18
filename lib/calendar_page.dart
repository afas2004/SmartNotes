import 'package:flutter/material.dart';
import 'notebook_page.dart'; // Import NotesPage
import '/homePage.dart'; // Import HomePage
import 'package:intl/intl.dart'; // For date formatting

class CalendarTaskListPage extends StatefulWidget {
  const CalendarTaskListPage({super.key});

  @override
  State<CalendarTaskListPage> createState() => _CalendarTaskListPageState();
}

class _CalendarTaskListPageState extends State<CalendarTaskListPage> {
  // The selected index for this page's BottomNavigationBar
  // Calendar is at index 1, so it's selected when this page is active.
  int _selectedIndex = 1;

  // Calendar specific state
  late DateTime _focusedDay;
  DateTime? _selectedDay; // Nullable for no day selected initially

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now(); // Initialize with the current month
    _selectedDay = _focusedDay; // Select the current day by default
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page
    if (index == 0) {
      // Home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 2) {
      // Notes page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
    }
    // If index is 1 (Calendar), stay on this page
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay; // Update focused day if needed
    });
    // You can add logic here to load tasks for the selected day
    print('Selected day: ${DateFormat('yyyy-MM-dd').format(selectedDay)}');
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      // Optionally, clear selected day or re-select if it falls in the new month
      _selectedDay = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      // Optionally, clear selected day or re-select if it falls in the new month
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the first day of the month
    final DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    // Get the number of days in the current month
    final DateTime lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final int daysInMonth = lastDayOfMonth.day;

    // Calculate the weekday of the first day (Monday=1, Sunday=7)
    // Adjust to make Sunday the first day (Sunday=0, Monday=1, ..., Saturday=6)
    final int firstWeekday = firstDayOfMonth.weekday % 7;

    // Create a list of all days to display in the grid (including leading/trailing empty cells)
    List<int?> daysGrid = [];

    // Add leading empty cells (for days before the 1st of the month)
    for (int i = 0; i < firstWeekday; i++) {
      daysGrid.add(null);
    }

    // Add actual days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      daysGrid.add(i);
    }

    // Pad with trailing empty cells to make it a full 6x7 grid if needed
    while (daysGrid.length < 42) { // 6 rows * 7 columns
      daysGrid.add(null);
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: _goToPreviousMonth, // Call function to go to previous month
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(_focusedDay), // Display current month and year
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: _goToNextMonth, // Call function to go to next month
          ),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day of the week headers
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.0),
                      ),
                      child: Table(
                        border: TableBorder.all(color: Colors.black, width: 1.0),
                        children: const [
                          TableRow(
                            children: [
                              _DayOfWeekHeader('Sun'),
                              _DayOfWeekHeader('Mon'),
                              _DayOfWeekHeader('Tue'),
                              _DayOfWeekHeader('Wed'),
                              _DayOfWeekHeader('Thu'),
                              _DayOfWeekHeader('Fri'),
                              _DayOfWeekHeader('Sat'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Calendar Grid
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.0),
                      ),
                      child: Table(
                        border: TableBorder.all(color: Colors.black, width: 1.0),
                        children: List.generate(6, (rowIndex) {
                          return TableRow(
                            children: List.generate(7, (colIndex) {
                              final int dayIndex = rowIndex * 7 + colIndex;
                              final int? day = daysGrid[dayIndex];

                              final bool isCurrentMonthDay = day != null && day <= daysInMonth;
                              final DateTime currentCellDate = DateTime(_focusedDay.year, _focusedDay.month, day ?? 1);
                              final bool isSelected = _selectedDay != null &&
                                  _selectedDay!.year == currentCellDate.year &&
                                  _selectedDay!.month == currentCellDate.month &&
                                  _selectedDay!.day == currentCellDate.day &&
                                  isCurrentMonthDay;

                              final bool isToday = currentCellDate.year == DateTime.now().year &&
                                  currentCellDate.month == DateTime.now().month &&
                                  currentCellDate.day == DateTime.now().day &&
                                  isCurrentMonthDay;

                              return GestureDetector(
                                onTap: day != null && isCurrentMonthDay
                                    ? () => _onDaySelected(currentCellDate, _focusedDay)
                                    : null,
                                child: Container(
                                  height: 50, // Adjust cell height as needed
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.yellow.shade200 : (isToday ? Colors.blue.shade100 : Colors.white),
                                    border: Border.all(color: Colors.black, width: 1.0),
                                  ),
                                  child: Text(
                                    day != null && isCurrentMonthDay ? day.toString() : '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrentMonthDay ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Tasks Section
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Task List Items
                    _buildTaskItem('Task 1'),
                    _buildTaskItem('Task 2'),
                    _buildTaskItem('Task 3'),
                    _buildTaskItem('Task 4'),
                    // Add more task items as needed
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle add new task
        },
        backgroundColor: Colors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0), // Rounded corners
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 35),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar( // Bottom nav bar for Calendar page
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
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedIndex == 1 ? Colors.grey.shade300 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month, size: 30),
                  const Text('Calendar', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              children: [
                const Icon(Icons.notes, size: 30),
                const Text('Notes', style: TextStyle(fontSize: 12)),
              ],
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

  Widget _buildTaskItem(String taskName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: false, // Placeholder for task completion
            onChanged: (bool? newValue) {
              // Handle checkbox state change
            },
            activeColor: Colors.pink, // Checkbox color as per image
            checkColor: Colors.white,
          ),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    taskName,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black, size: 20),
            onPressed: () {
              // Handle edit task
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.pink, size: 20),
            onPressed: () {
              // Handle delete task
            },
          ),
        ],
      ),
    );
  }
}

// Helper widget for day of the week headers
class _DayOfWeekHeader extends StatelessWidget {
  final String text;
  const _DayOfWeekHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30, // Adjust height as needed
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}
