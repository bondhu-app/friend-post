import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FriendPostApp());
}

class FriendPostApp extends StatelessWidget {
  const FriendPostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friend Post',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const FriendPostHomePage(),
    );
  }
}

class FriendPostHomePage extends StatelessWidget {
  const FriendPostHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friend Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 90,
              ),
              const SizedBox(height: 24),
              const Text(
                'Friend Post',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'বন্ধুদের সাথে যুক্ত থাকুন, পোস্ট ও ছবি শেয়ার করুন, '
                'লাইক, কমেন্ট এবং আরও অনেক কিছু করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Friend Post সফলভাবে চালু হয়েছে।',
                      ),
                    ),
                  );
                },
                child: const Text('শুরু করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
