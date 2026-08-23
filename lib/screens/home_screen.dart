herimport 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get _currentUser => _auth.currentUser;

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    try {
      final document =
          await _firestore.collection('users').doc(user.uid).get();

      if (document.exists) {
        return document.data();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }

    return null;
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
        ),
      );
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is coming soon.'),
      ),
    );
  }

  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _getUserData(),
            builder: (context, snapshot) {
              final userData = snapshot.data;

              final name =
                  (userData?['name'] as String?)?.trim().isNotEmpty == true
                      ? userData!['name'] as String
                      : (_currentUser?.displayName?.trim().isNotEmpty == true
                          ? _currentUser!.displayName!
                          : 'Friend');

              final photoUrl =
                  (userData?['photoUrl'] as String?)?.trim() ?? '';

              return Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showComingSoon('Create Post');
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'What\'s on your mind?',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.dynamic_feed_outlined,
                    size: 58,
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your Feed',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Posts from your friends will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () {
                      _showComingSoon('Find Friends');
                    },
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Find Friends'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsPage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 70,
          ),
          SizedBox(height: 16),
          Text(
            'Posts',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Posts will appear here.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_alt_outlined,
            size: 70,
          ),
          const SizedBox(height: 16),
          const Text(
            'Friends',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your friends will appear here.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              _showComingSoon('Find Friends');
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Find Friends'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        final userData = snapshot.data;

        final name =
            (userData?['name'] as String?)?.trim().isNotEmpty == true
                ? userData!['name'] as String
                : (_currentUser?.displayName?.trim().isNotEmpty == true
                    ? _currentUser!.displayName!
                    : 'Friend');

        final email =
            (userData?['email'] as String?)?.trim().isNotEmpty == true
                ? userData!['email'] as String
                : (_currentUser?.email ?? '');

        final bio = (userData?['bio'] as String?) ?? '';

        final photoUrl = (userData?['photoUrl'] as String?) ?? '';

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blue,
                backgroundImage: photoUrl.trim().isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.trim().isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 55,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Center(
              child: Text(
                email,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            if (bio.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  bio,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Card(
              elevation: 0,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('My Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showComingSoon('My Profile');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showComingSoon('Settings');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();

      case 1:
        return _buildPostsPage();

      case 2:
        return _buildFriendsPage();

      case 3:
        return _buildProfilePage();

      default:
        return _buildHomePage();
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Friend Post';

      case 1:
        return 'Posts';

      case 2:
        return 'Friends';

      case 3:
        return 'My Profile';

      default:
        return 'Friend Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login again.',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                _showComingSoon('Notifications');
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
              ),
            ),
          if (_currentIndex == 0)
            IconButton(
              tooltip: 'Messages',
              onPressed: () {
                _showComingSoon('Messages');
              },
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
              ),
            ),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (_isValidIndex(index)) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  bool _isValidIndex(int index) {
    return index >= 0 && index <= 3;
  }
}
