import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim();
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friend Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await _logout(context);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await Future<void>.delayed(
            const Duration(milliseconds: 500),
          );
        },

        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),

            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Welcome${displayName != null && displayName.isNotEmpty ? ', $displayName' : ''}!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 35),

            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(
                    alpha: 0.12,
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Home',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Your Friend Post home feed',
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(
                    alpha: 0.12,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'My Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'View and manage your profile',
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Profile section will be added next.',
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(
                    alpha: 0.12,
                  ),
                  child: const Icon(
                    Icons.post_add_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Create Post',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Share something with your friends',
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Post creation will be added next.',
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            OutlinedButton.icon(
              onPressed: () async {
                await _logout(context);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
