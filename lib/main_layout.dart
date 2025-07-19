import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/homepage.dart';
import 'package:smartnotes/calendar_page.dart';
import 'package:smartnotes/notebook_page.dart';
import 'package:smartnotes/providers/theme_provider.dart';
import 'package:smartnotes/screens/login_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  User? _user;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Store the subscription so we can cancel it later
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _authSubscription?.cancel();
    super.dispose();
  }

  List<Widget> get _pages {
    return [
      const HomePage(),
      const CalendarTaskListPage(),
      const NotesPage(),
    ];
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const LoginPage();
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

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

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: isDarkMode ? Colors.white70 : Colors.black,
        onTap: _onItemTapped,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}