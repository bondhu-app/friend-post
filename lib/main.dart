import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseInitializationResult firebaseResult;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    firebaseResult = const FirebaseInitializationResult.success();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');

    firebaseResult = FirebaseInitializationResult.failure(
      e.toString(),
    );
  }

  runApp(
    FriendPostApp(
      firebaseResult: firebaseResult,
    ),
  );
}

class FirebaseInitializationResult {
  final bool success;
  final String? error;

  const FirebaseInitializationResult.success()
      : success = true,
        error = null;

  const FirebaseInitializationResult.failure(this.error)
      : success = false;
}

class FriendPostApp extends StatelessWidget {
  final FirebaseInitializationResult firebaseResult;

  const FriendPostApp({
    super.key,
    required this.firebaseResult,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friend Post',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      home: firebaseResult.success
          ? const AuthGate()
          : FirebaseErrorScreen(
              error: firebaseResult.error,
            ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const FirebaseErrorScreen(
            error: 'Firebase Authentication চালু করা যায়নি।',
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final String? error;

  const FirebaseErrorScreen({
    super.key,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Friend Post চালু করা যাচ্ছে না',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Firebase configuration-এ সমস্যা হয়েছে। '
                  'অ্যাপ crash না করে এখানে সমস্যাটি দেখানো হবে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                if (error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                    ),
                    child: SelectableText(
                      error!,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
