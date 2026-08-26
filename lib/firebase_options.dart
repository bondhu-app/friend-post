// File: lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        return ios;

      case TargetPlatform.macOS:
        return macos;

      case TargetPlatform.windows:
        return windows;

      case TargetPlatform.linux:
        return linux;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
    iosBundleId: 'com.friendpost.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTmMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
    iosBundleId: 'com.friendpost.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTmMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAbYCTmMxhCJzft1dgnpHDRkbC4v9RMU4GE',
    appId: '1:1074705827775:android:68710467504787bc3a430a',
    messagingSenderId: '1074705827775',
    projectId: 'friend-post-fbfdd',
    storageBucket: 'friend-post-fbfdd.firebasestorage.app',
  );
}
