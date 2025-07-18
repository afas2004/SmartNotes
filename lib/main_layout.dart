import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/homepage.dart';
import 'package:smartnotes/calendar_page.dart';
import 'package:smartnotes/notebook_page.dart';
import 'package:smartnotes/providers/theme_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
  // Ensure we always have at least 2 pages
  final List<Widget> _pages = [
    const HomePage(),
    const CalendarTaskListPage(),
    const NotesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Always ensure we have at least 2 navigation items
    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedIndex == 0 
                ? (isDarkMode ? Colors.grey[800] : Colors.grey.shade300)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home, size: 30),
              Text('Home', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: _selectedIndex == 1 
                ? (isDarkMode ? Colors.grey[800] : Colors.grey.shade300)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, size: 30),
              Text('Calendar', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        label: '',
      ),
      if (_pages.length > 2) // Only add third item if we have more than 2 pages
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedIndex == 2 
                  ? (isDarkMode ? Colors.grey[800] : Colors.grey.shade300)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notes, size: 30),
                Text('Notes', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          label: '',
        ),
    ];

    // Ensure we have at least 2 navigation items
    assert(navItems.length >= 2, 'BottomNavigationBar must have at least 2 items');

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: navItems.length >= 2 
          ? BottomNavigationBar(
              items: navItems,
              currentIndex: _selectedIndex.clamp(0, navItems.length - 1),
              selectedItemColor: isDarkMode ? Colors.white : Colors.black,
              unselectedItemColor: isDarkMode ? Colors.white70 : Colors.black,
              onTap: _onItemTapped,
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 10,
            )
          : null, // Hide navigation if less than 2 items
    );
  }
}