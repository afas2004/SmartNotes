import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:smartnotes/providers/theme_provider.dart';
import 'package:smartnotes/screens/login_page.dart';

class SettingsPage extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final tilePadding = const EdgeInsets.symmetric(horizontal: 12.0);
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 📌 Account Info Section
          Text('Account', style: sectionTitleStyle),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user?.displayName ?? 'No display name'),
            subtitle: Text(user?.email ?? 'No email'),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: tilePadding,
          ),

          const SizedBox(height: 24),

          // 🎨 Appearance Section
          Text('Appearance', style: sectionTitleStyle),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            secondary: const Icon(Icons.dark_mode),
          ),

          const SizedBox(height: 24),

          // ☁️ Monetization & Premium
          Text('Premium & Features', style: sectionTitleStyle),
          ListTile(
            leading: const Icon(Icons.upgrade),
            title: const Text('Upgrade to Premium'),
            subtitle: const Text('Unlock cloud sync, multi-device access'),
            onTap: () {
              // Navigate to premium upgrade screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Custom Themes'),
            subtitle: const Text('Personalize app colors and styles'),
            onTap: () {
              // Theme customization
            },
          ),

          const SizedBox(height: 24),

          // 🔐 Security & Notifications
          Text('App Preferences', style: sectionTitleStyle),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Enable app-lock for secure access'),
            onTap: () {
              // Navigate to biometric settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Sync & Backup'),
            subtitle: const Text('Manage cloud sync settings'),
            onTap: () {
              // Sync settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Preferences'),
            subtitle: const Text('Set reminders and task nudges'),
            onTap: () {
              // Notification settings
            },
          ),

          const SizedBox(height: 32),

          // 🚪 Logout (Always visible)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}