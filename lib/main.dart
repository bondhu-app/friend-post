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

  // ------------------------------------------------------------
  // GLOBAL FLUTTER ERROR HANDLER
  // ------------------------------------------------------------

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);

    debugPrint(
      '================ FLUTTER ERROR ================',
    );
    debugPrint(details.exceptionAsString());
    debugPrintStack(
      stackTrace: details.stack,
    );
    debugPrint(
      '================================================',
    );
  };

  // ------------------------------------------------------------
  // GLOBAL ASYNC ERROR HANDLER
  // ------------------------------------------------------------

  PlatformDispatcher.instance.onError =
      (Object error, StackTrace stack) {
    debugPrint(
      '================ ASYNC ERROR ==================',
    );
    debugPrint(error.toString());
    debugPrintStack(stackTrace: stack);
    debugPrint(
      '================================================',
    );

    // Error handled so Flutter does not terminate the process.
    return true;
  };

  // ------------------------------------------------------------
  // FIREBASE INITIALIZATION
  // ------------------------------------------------------------

  String? firebaseError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'Firebase initialization successful.',
    );
  } catch (error, stack) {
    firebaseError = error.toString();

    debugPrint(
      '================ FIREBASE ERROR ===============',
    );
    debugPrint(error.toString());
    debugPrintStack(stackTrace: stack);
    debugPrint(
      '================================================',
    );
  }

  // ------------------------------------------------------------
  // RUN APPLICATION
  // ------------------------------------------------------------

  runZonedGuarded(
    () {
      runApp(
        FriendPostApp(
          firebaseError: firebaseError,
        ),
      );
    },
    (Object error, StackTrace stack) {
      debugPrint(
        '================ ZONE ERROR ===================',
      );
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stack);
      debugPrint(
        '================================================',
      );
    },
  );
}

// ============================================================
// FRIEND POST APP
// ============================================================

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

      // --------------------------------------------------------
      // GLOBAL ERROR BUILDER
      // --------------------------------------------------------

      builder: (
        BuildContext context,
        Widget? child,
      ) {
        ErrorWidget.builder =
            (FlutterErrorDetails details) {
          return AppErrorScreen(
            error: details.exception.toString(),
          );
        };

        if (child == null) {
          return const AppErrorScreen(
            error: 'Application screen could not be created.',
          );
        }

        return child;
      },

      home: firebaseError != null
          ? FirebaseErrorScreen(
              error: firebaseError!,
            )
          : const AuthGate(),
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
    try {
      return StreamBuilder<User?>(
        stream:
            FirebaseAuth.instance.authStateChanges(),

        builder: (
          BuildContext context,
          AsyncSnapshot<User?> snapshot,
        ) {
          // ----------------------------------------------------
          // WAITING
          // ----------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const StartupLoadingScreen();
          }

          // ----------------------------------------------------
          // AUTH ERROR
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return AuthErrorScreen(
              error: snapshot.error.toString(),
            );
          }

          // ----------------------------------------------------
          // LOGGED IN
          // ----------------------------------------------------

          final User? user = snapshot.data;

          if (user != null) {
            return const SafeHomeScreen();
          }

          // ----------------------------------------------------
          // NOT LOGGED IN
          // ----------------------------------------------------

          return const SafeAuthScreen();
        },
      );
    } catch (error) {
      return AuthErrorScreen(
        error: error.toString(),
      );
    }
  }
}

// ============================================================
// SAFE AUTH SCREEN
// ============================================================

class SafeAuthScreen extends StatelessWidget {
  const SafeAuthScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return const AuthScreen();
    } catch (error) {
      return AppErrorScreen(
        error: error.toString(),
      );
    }
  }
}

// ============================================================
// SAFE HOME SCREEN
// ============================================================

class SafeHomeScreen extends StatelessWidget {
  const SafeHomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return const HomeScreen();
    } catch (error) {
      return AppErrorScreen(
        error: error.toString(),
      );
    }
  }
}

// ============================================================
// STARTUP LOADING SCREEN
// ============================================================

class StartupLoadingScreen extends StatelessWidget {
  const StartupLoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(),
              ),
              SizedBox(height: 24),
              Text(
                'Friend Post',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Starting application...',
              ),
            ],
          ),
        ),
      ),
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
              mainAxisAlignment:
                  MainAxisAlignment.center,
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

                const SizedBox(height: 12),

                const Text(
                  'অ্যাপ বন্ধ না হয়ে সমস্যাটি নিচে দেখানো হচ্ছে।',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                ErrorBox(
                  error: error,
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () {
                    _restartApplication(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'আবার চেষ্টা করুন',
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
              mainAxisAlignment:
                  MainAxisAlignment.center,
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

                const SizedBox(height: 12),

                const Text(
                  'Firebase Authentication চালু করতে সমস্যা হয়েছে।',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                ErrorBox(
                  error: error,
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () {
                    _restartApplication(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'আবার চেষ্টা করুন',
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

// ============================================================
// GENERAL APP ERROR SCREEN
// ============================================================

class AppErrorScreen extends StatelessWidget {
  final String error;

  const AppErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Friend Post',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'অ্যাপ চালু হতে সমস্যা হয়েছে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'অ্যাপটি বন্ধ না হয়ে সমস্যাটি দেখানোর চেষ্টা করছে।',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  ErrorBox(
                    error: error,
                  ),

                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: () {
                      _restartApplication(
                        context,
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'আবার চেষ্টা করুন',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR BOX
// ============================================================

class ErrorBox extends StatelessWidget {
  final String error;

  const ErrorBox({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: SelectableText(
        error,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
        ),
      ),
    );
  }
}

// ============================================================
// RESTART APPLICATION STATE
// ============================================================

void _restartApplication(
  BuildContext context,
) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => const FriendPostApp(),
    ),
    (route) => false,
  );
}
