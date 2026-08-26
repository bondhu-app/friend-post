lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration for Friend Post.
///
/// This file is intentionally kept self-contained so the app can initialize
/// Firebase without depending on generated files during the GitHub Actions
/// build.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return android;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        return android;

      case TargetPlatform.macOS:
        return android;

      case TargetPlatform.windows:
        return android;

      case TargetPlatform.linux:
        return android;

      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
  );
}
