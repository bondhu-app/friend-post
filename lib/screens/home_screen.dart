import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'friends_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = user?.displayName?.trim();
    final email = user?.email ?? '';

    final welcomeName =
        displayName != null && displayName.isNotEmpty
            ? ', $displayName'
            : '';

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
            icon: const Icon(
              Icons.logout_rounded,
            ),
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
          physics: const AlwaysScrollableScrollPhysics(),
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
              'Welcome$welcomeName!',
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withValues(alpha: 0.12),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withValues(alpha: 0.12),
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
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  _openScreen(
                    context,
                    const ProfileScreen(),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Friends',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Find and connect with friends',
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  _openScreen(
                    context,
                    const FriendsScreen(),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withValues(alpha: 0.12),
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
                trailing: const Icon(
                  Icons.chevron_right_rounded,
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

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blue.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Manage your account settings',
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Settings section will be added next.',
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
              icon: const Icon(
                Icons.logout_rounded,
              ),
              label: const Text(
                'Logout',
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
