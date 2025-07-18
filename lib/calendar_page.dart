import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting

// Ensure these imports match your project structure
import 'package:smartnotes/notebook_page.dart';
import 'package:smartnotes/providers/theme_provider.dart';
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
     _showAddTaskDialog(context);
    _loadTasksForSelectedDay(); // Reload tasks after dialog closes
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
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
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDarkMode ? Colors.grey[200]! : Colors.black),
          onPressed: _goToPreviousMonth,
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(_focusedDay),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: isDarkMode ? Colors.grey[200]! : Colors.black),
            onPressed: _goToNextMonth,
          ),
          IconButton(
            icon: Icon(Icons.settings, color: isDarkMode ? Colors.grey[200]! : Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, '/settings'); // If you have a settings route
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
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Table(
                        border: TableBorder.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.black,
                          width: 1.0,
                        ),
                        children: [
                          TableRow(
                            children: [
                              _DayOfWeekHeader('Sun', isDarkMode: isDarkMode),
                              _DayOfWeekHeader('Mon', isDarkMode: isDarkMode),
                              _DayOfWeekHeader('Tue', isDarkMode: isDarkMode),
                              _DayOfWeekHeader('Wed', isDarkMode: isDarkMode),
                              _DayOfWeekHeader('Thu', isDarkMode: isDarkMode),
                              _DayOfWeekHeader('Fri', isDarkMode: isDarkMode),
                              _DayOfWeekHeader('Sat', isDarkMode: isDarkMode),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Calendar Grid
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Table(
                        border: TableBorder.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.black,
                          width: 1.0,
                        ),
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
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? isDarkMode ? Colors.yellow.shade900 : Colors.yellow.shade200
                                        : (isToday 
                                            ? (isDarkMode ? Colors.blue[900]! : Colors.blue.shade100)
                                            : (isDarkMode ? Colors.grey[900]! : Colors.white)),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.grey[700]! : Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    day != null && isCurrentMonthDay ? day.toString() : '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrentMonthDay 
                                          ? (isDarkMode ? Colors.white : Colors.black)
                                          : (isDarkMode ? Colors.grey[500]! : Colors.grey),
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
    );
  }

  Widget _buildTaskItem(Task task) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
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
                border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.black, width: 1.0),
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
            icon: Icon(Icons.edit, color: isDarkMode ? Colors.grey[200]! : Colors.black, size: 20),
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
                  'Due: ${DateFormat.yMd().format(dueDate ?? DateTime.now())}',
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
  final bool isDarkMode;
  
  const _DayOfWeekHeader(this.text, {required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
