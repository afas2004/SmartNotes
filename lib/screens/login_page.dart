import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartnotes/services/auth_service.dart';
import 'register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({Key? key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _authService.signIn(
        email: _emailCtrl.text,
        password: _pwdCtrl.text,
      );
      // on success, authStateChanges will trigger rebuild to HomePage
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      // on success, authStateChanges will trigger rebuild to HomePage
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center (
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            CircleAvatar(radius: 40, child: Text("Logo")),
              SizedBox(height: 20),
              Text("Welcome to Note&Go", style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pwdCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                      onPressed: () async {
                        await _login();
                        if (FirebaseAuth.instance.currentUser != null && mounted) {
                        Navigator.of(context).pushReplacementNamed('/homepage');
                        }
                      },
                      child: const Text('Sign In'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                      icon: Image.asset(
                        'assets/google_logo.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text('Sign in with Google'),
                      onPressed: () async {
                        await _loginWithGoogle();
                        if (FirebaseAuth.instance.currentUser != null && mounted) {
                        Navigator.of(context).pushReplacementNamed('/homepage');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      ),
                    ],
                  ),
                  
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, RegisterPage.routeName),
              child: const Text('Don’t have an account? Register here'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}