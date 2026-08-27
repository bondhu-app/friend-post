import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // বর্তমানে লগইন করা ইউজার
  User? get currentUser => _auth.currentUser;

  // Authentication state পরিবর্তন হলে Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // নতুন অ্যাকাউন্ট তৈরি
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ইমেইল ও পাসওয়ার্ড দিয়ে লগইন
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // লগআউট
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // পাসওয়ার্ড রিসেট
  Future<void> resetPassword({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }

  // Forgot Password Screen-এর জন্য একই Password Reset Method
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }
}
