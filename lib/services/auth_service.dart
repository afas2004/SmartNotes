import 'package:smartnotes/db_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartnotes/notes_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // expose the auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // sign up
  Future<UserCredential> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // sign in
  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }
  User? get currentUser {
    return _auth.currentUser;
  }


  Future<void> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        message: 'Sign in aborted by user',
        code: 'ERROR_ABORTED_BY_USER',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (e) {
    rethrow;
  }
}

  // sign out
  Future<void> signOut() async {
  await _auth.signOut();
  await GoogleSignIn().signOut();
}

  // delete user
  Future<void> deleteUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    } else {
      throw FirebaseAuthException(message: 'No user signed in', code: 'ERROR_NO_USER');
    }
  }



}