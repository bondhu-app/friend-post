import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'friends_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  int _currentIndex = 0;

  bool _isLoading = true;

  String _userName = 'Friend';
  String _userPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (!mounted) return;

      setState(() {
        _userName =
            (data?['name'] ??
                    user.displayName ??
                    'Friend')
                .toString();

        _userPhotoUrl =
            (data?['photoUrl'] ?? '').toString();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Load user data error: $e',
      );

      if (!mounted) return;

      setState(() {
        _userName =
            user.displayName ?? 'Friend';

        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
          ),
        ),
      );
    }
  }

  Widget _avatar({
    double radius = 24,
  }) {
    if (_userPhotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage:
            NetworkImage(_userPhotoUrl),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: Icon(
        Icons.person,
        size: radius,
      ),
    );
  }

  Future<void> _openFriends() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const FriendsScreen(),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const ProfileScreen(),
      ),
    );

    if (!mounted) return;

    await _loadUserData();
  }

  Widget _homePage() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _avatar(radius: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notifications coming soon.',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s on your mind?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _avatar(radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger
                                    .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Create post coming soon.',
                                ),
                              ),
                            );
                          },
                          child: const Align(
                            alignment:
                                Alignment
                                    .centerLeft,
                            child: Text(
                              'Write something...',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child:
                            TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger
                                    .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Photo post coming soon.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.photo_outlined,
                          ),
                          label:
                              const Text(
                            'Photo',
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger
                                    .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Feeling feature coming soon.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons
                                .emoji_emotions_outlined,
                          ),
                          label:
                              const Text(
                            'Feeling',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Posts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openFriends,
                icon: const Icon(
                  Icons.people_outline,
                ),
                label:
                    const Text('Friends'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: _firestore
                .collection('posts')
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .limit(20)
                .snapshots(),
            builder:
                (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .article_outlined,
                          size: 48,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No posts available yet.',
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(30),
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              }

              final posts =
                  snapshot.data?.docs ?? [];

              if (posts.isEmpty) {
                return const Card(
                  child: Padding(
                    padding:
                        EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .dynamic_feed_outlined,
                          size: 50,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No posts yet.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Be the first person to create a post.',
                          textAlign:
                              TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: posts
                    .map(
                      _postCard,
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _postCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        post,
  ) {
    final data = post.data();

    final name =
        (data['userName'] ??
                data['name'] ??
                'Friend')
            .toString();

    final text =
        (data['text'] ??
                data['content'] ??
                '')
            .toString();

    final imageUrl =
        (data['imageUrl'] ?? '')
            .toString();

    final photoUrl =
        (data['photoUrl'] ?? '')
            .toString();

    final likes =
        data['likeCount'] ??
            data['likes'] ??
            0;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (photoUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 22,
                    backgroundImage:
                        NetworkImage(
                      photoUrl,
                    ),
                  )
                else
                  const CircleAvatar(
                    radius: 22,
                    child: Icon(
                      Icons.person,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
                  Icons.more_horiz,
                ),
              ],
            ),

            if (text.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                text,
                style:
                    const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],

            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                child: Image.network(
                  imageUrl,
                  width:
                      double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: Icon(
                          Icons
                              .broken_image_outlined,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  '$likes likes',
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons
                        .favorite_border,
                  ),
                  label:
                      const Text('Like'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    Icons
                        .comment_outlined,
                  ),
                  label:
                      const Text('Comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsPage() {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 26,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons
                      .notifications_outlined,
                ),
                title: const Text(
                  'Notifications',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                ),
                title: const Text(
                  'Privacy',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons
                      .security_outlined,
                ),
                title: const Text(
                  'Security',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                ),
                title: const Text(
                  'About Friend Post',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName:
                        'Friend Post',
                    applicationVersion:
                        '1.0.0',
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                ),
                title:
                    const Text('Logout'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _currentPage() {
    switch (_currentIndex) {
      case 0:
        return _homePage();

      case 1:
        return const FriendsScreen();

      case 2:
        return ProfileScreen(
          key: const ValueKey(
            'profile-screen',
          ),
        );

      case 3:
        return _settingsPage();

      default:
        return _homePage();
    }
  }

  String _title() {
    switch (_currentIndex) {
      case 0:
        return 'Friend Post';
      case 1:
        return 'Friends';
      case 2:
        return 'My Profile';
      case 3:
        return 'Settings';
      default:
        return 'Friend Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(),
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: _loadUserData,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
        ],
      ),

      body: _currentPage(),

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _currentIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
                Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline,
            ),
            selectedIcon:
                Icon(Icons.people),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon:
                Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
            ),
            selectedIcon:
                Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),

      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger
                            .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Create post coming soon.',
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.add,
                  ),
                )
              : null,
    );
  }
}
