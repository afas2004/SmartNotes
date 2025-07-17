import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final user = FirebaseAuth.instance.currentUser;

    final logoutButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.displayName ?? 'No display name'),
              subtitle: Text(user?.email ?? 'No email'),
              tileColor: Theme.of(context).colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 24),

            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: onThemeChanged,
              secondary: const Icon(Icons.dark_mode),
            ),
            const Spacer(),

            // 🔴 Logout Button (Highly Visible)
            ElevatedButton.icon(
              style: logoutButtonStyle,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}