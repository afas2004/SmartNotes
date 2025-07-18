import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smartnotes/firebase_options.dart';
import 'package:smartnotes/homepage.dart';
import 'package:smartnotes/services/auth_service.dart';
import 'package:smartnotes/screens/login_page.dart';
import 'package:smartnotes/screens/register_page.dart';
import 'package:smartnotes/settings_page.dart';
import 'package:smartnotes/profile_page.dart';
import 'package:smartnotes/calendar_page.dart';
import 'package:smartnotes/new_note_page.dart';
import 'package:smartnotes/note_detail_page.dart';
import 'package:smartnotes/notebook_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authService = AuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartNotesApp());
}

class SmartNotesApp extends StatefulWidget {
  const SmartNotesApp({super.key});

  @override
  State<SmartNotesApp> createState() => _SmartNotesAppState();
}

class _SmartNotesAppState extends State<SmartNotesApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartNotes',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Named navigation routes
      routes: {
        LoginPage.routeName: (_) => const LoginPage(),
        RegisterPage.routeName: (_) => const RegisterPage(),
        '/new_note': (_) => const NewNotePage(),
        '/calendar': (_) => CalendarTaskListPage(),
        '/profile': (_) => const ProfilePage(),
        '/homepage': (_) => HomePage(),
        '/notebook': (_) => NotesPage(),
        '/note_detail': (_) => NoteDetailPage(
          title: '',
          description: '',
          isNewNote: true,
        ),
        '/settings': (_) => SettingsPage(
          isDarkMode: _isDarkMode,
          onThemeChanged: _toggleTheme,
        ),
      },

      // Auth stream decides initial screen
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData) {
            return const LoginPage();
          }

          return HomePage();
        },
      ),
    );
  }
}