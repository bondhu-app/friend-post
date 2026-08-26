import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
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
    apiKey: 'AIzaSyAbYCTmMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
  );
}
