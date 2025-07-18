import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting

// Ensure these imports match your project structure
import 'package:smartnotes/notebook_page.dart';
import 'homepage.dart';
import 'package:smartnotes/models/task.dart';
import 'package:smartnotes/providers/notes_provider.dart';
// import 'package:smartnotes/services/auth_service.dart'; // AuthService is not directly used here for task logic

class CalendarTaskListPage extends StatefulWidget {
  const CalendarTaskListPage({super.key});

  @override
  State<CalendarTaskListPage> createState() => _CalendarTaskListPageState();
}

class _CalendarTaskListPageState extends State<CalendarTaskListPage> {
  int _selectedIndex = 1; // Calendar is selected by default
  List<Task> _tasksForSelectedDay = [];

  late DateTime _focusedDay;
  DateTime? _selectedDay; // Nullable for no day selected initially

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now(); // Initialize with the current month
    _selectedDay = _focusedDay; // Select the current day by default

    // Load tasks for the initially selected day after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasksForSelectedDay();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      Provider.of<NotesProvider>(context, listen: true).loadTasks(userId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTasksForSelectedDay();
      });
    }
  }

  void _loadTasksForSelectedDay() {
    if (!mounted || _selectedDay == null) return;

    final provider = Provider.of<NotesProvider>(context, listen: false);
    final List<Task> tasks = provider.getTasksForDate(_selectedDay!);

    setState(() {
      _tasksForSelectedDay = tasks;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!mounted) return;
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadTasksForSelectedDay(); // Reload tasks for the newly selected day

    // Show the add task dialog immediately after selecting a day
    await _showAddTaskDialog(context);
    _loadTasksForSelectedDay(); // Reload tasks after dialog closes
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
    }
  }

  void _goToPreviousMonth() {
    if (!mounted) return;
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      _selectedDay = null; // Clear selected day when changing month
    });
  }

  void _goToNextMonth() {
    if (!mounted) return;
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
      _selectedDay = null; // Clear selected day when changing month
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final DateTime lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final int daysInMonth = lastDayOfMonth.day;

    final int firstWeekday = firstDayOfMonth.weekday % 7; // Sunday=0, Monday=1, ..., Saturday=6

    List<int?> daysGrid = [];
    for (int i = 0; i < firstWeekday; i++) {
      daysGrid.add(null);
    }
    for (int i = 1; i <= daysInMonth; i++) {
      daysGrid.add(i);
    }
    while (daysGrid.length < 42) {
      daysGrid.add(null);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: _goToPreviousMonth,
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(_focusedDay),
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
            onPressed: _goToNextMonth,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // Navigator.pushNamed(context, '/settings'); // If you have a settings route
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
                                    ? () => _onDaySelected(currentCellDate, _focusedDay) // Now triggers dialog
                                    : null,
                                child: Container(
                                  height: 50,
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
                    if (_tasksForSelectedDay.isEmpty)
                      const Text('No tasks for this day.')
                    else
                      ..._tasksForSelectedDay
                          .map((task) => _buildTaskItem(task))
                          .toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // FloatingActionButton and floatingActionButtonLocation are removed
      bottomNavigationBar: BottomNavigationBar(
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

  Widget _buildTaskItem(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (bool? newValue) async {
              final provider = Provider.of<NotesProvider>(context, listen: false);
              await provider.updateTask(
                task.copyWith(isCompleted: newValue ?? false),
              );
              _loadTasksForSelectedDay();
            },
            activeColor: Colors.pink,
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
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black, size: 20),
            onPressed: () {
              // TODO: Implement task editing dialog/page
              print('Edit task: ${task.title}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.pink, size: 20),
            onPressed: () async {
              final provider = Provider.of<NotesProvider>(context, listen: false);
              await provider.deleteTask(task.id!, task.userId);
              _loadTasksForSelectedDay();
            },
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final textController = TextEditingController();
    DateTime initialDueDate = _selectedDay ?? DateTime.now();
    DateTime? dueDate = initialDueDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Task Title'),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                return TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setStateDialog(() {
                        dueDate = date;
                      });
                    }
                  },
                  child: Text(
                    'Due: ${DateFormat.yMd().format(dueDate)}',
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  final provider = Provider.of<NotesProvider>(context, listen: false);
                  await provider.addTask(Task(
                    userId: userId,
                    title: textController.text,
                    createdAt: DateTime.now(),
                    dueDate: dueDate,
                    isCompleted: false,
                  ));
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _DayOfWeekHeader extends StatelessWidget {
  final String text;
  const _DayOfWeekHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
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
