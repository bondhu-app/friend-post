import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter-এর সাধারণ error ধরবে।
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  // Flutter-এর বাইরে আসা async error ধরবে।
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('ASYNC ERROR: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  String? firebaseError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('================================');
    debugPrint('FIREBASE INITIALIZATION SUCCESS');
    debugPrint('================================');
  } catch (e, stack) {
    firebaseError = e.toString();

    debugPrint('================================');
    debugPrint('FIREBASE INITIALIZATION FAILED');
    debugPrint('ERROR: $e');
    debugPrint('================================');

    debugPrintStack(stackTrace: stack);
  }

  runApp(
    FriendPostApp(
      firebaseError: firebaseError,
    ),
  );
}

class FriendPostApp extends StatelessWidget {
  final String? firebaseError;

  const FriendPostApp({
    super.key,
    this.firebaseError,
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

      home: firebaseError != null
          ? FirebaseErrorScreen(
              error: firebaseError!,
            )
          : const AuthGate(),
    );
  }
}

// ============================================================
// FIREBASE ERROR SCREEN
// ============================================================

class FirebaseErrorScreen extends StatelessWidget {
  final String error;

  const FirebaseErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Post'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Firebase চালু হতে সমস্যা হয়েছে',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'অ্যাপ বন্ধ না হয়ে নিচে সমস্যাটি দেখানো হচ্ছে:',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () {
                    runApp(
                      const FriendPostApp(
                        firebaseError: null,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {
        // Firebase Auth চালু হচ্ছে
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Auth error
        if (snapshot.hasError) {
          return AuthErrorScreen(
            error: snapshot.error.toString(),
          );
        }

        final User? user = snapshot.data;

        // Login করা আছে
        if (user != null) {
          return const HomeScreen();
        }

        // Login করা নেই
        return const AuthScreen();
      },
    );
  }
}

// ============================================================
// AUTH ERROR SCREEN
// ============================================================

class AuthErrorScreen extends StatelessWidget {
  final String error;

  const AuthErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Post'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Authentication Error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    error,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: () {
                    runApp(
                      const FriendPostApp(
                        firebaseError: null,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
