import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'create_post_screen.dart';
import 'friends_screen.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
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
        _userName = (data?['name'] ??
                user.displayName ??
                'Friend')
            .toString();

        _userPhotoUrl =
            (data?['photoUrl'] ?? user.photoURL ?? '')
                .toString();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load user data error: $e');

      if (!mounted) return;

      setState(() {
        _userName = user.displayName ?? 'Friend';
        _userPhotoUrl = user.photoURL ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreatePost() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreatePostScreen(),
        ),
      );

      if (mounted) {
        await _loadUserData();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Open create post error: $e');

      if (!mounted) return;

      _showMessage('Create Post screen খুলতে সমস্যা হয়েছে');
    }
  }

  Future<void> _openPost(String postId) async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            postId: postId,
          ),
        ),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Open post error: $e');

      if (!mounted) return;

      _showMessage('Post খুলতে সমস্যা হয়েছে');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
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
    } catch (e) {
      debugPrint('Logout error: $e');

      if (!mounted) return;

      _showMessage('Logout failed');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _avatar({
    double radius = 24,
  }) {
    if (_userPhotoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(
          _userPhotoUrl,
        ),
        onBackgroundImageError: (_, __) {},
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

  Widget _homePage() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _showMessage(
                    'Notifications coming soon.',
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s on your mind?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _avatar(radius: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _openCreatePost,
                          child: const Align(
                            alignment: Alignment.centerLeft,
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
                        child: TextButton.icon(
                          onPressed: _openCreatePost,
                          icon: const Icon(
                            Icons.photo_outlined,
                          ),
                          label: const Text('Photo'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _openCreatePost,
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                          ),
                          label: const Text('Feeling'),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  try {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            const FriendsScreen(),
                      ),
                    );
                  } catch (e) {
                    debugPrint(
                      'Open friends error: $e',
                    );
                  }
                },
                icon: const Icon(
                  Icons.people_outline,
                ),
                label: const Text('Friends'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPosts(),
        ],
      ),
    );
  }

  Widget _buildPosts() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('posts')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Posts stream error: ${snapshot.error}',
          );

          return _postsErrorCard();
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  Icon(
                    Icons.dynamic_feed_outlined,
                    size: 50,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No posts yet.',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Be the first person to create a post.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sortedPosts = List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>.from(posts);

        sortedPosts.sort((a, b) {
          final aDate = a.data()['createdAt'];
          final bDate = b.data()['createdAt'];

          if (aDate is Timestamp &&
              bDate is Timestamp) {
            return bDate.compareTo(aDate);
          }

          if (aDate is Timestamp) {
            return -1;
          }

          if (bDate is Timestamp) {
            return 1;
          }

          return 0;
        });

        return Column(
          children: sortedPosts
              .map(_postCard)
              .toList(),
        );
      },
    );
  }

  Widget _postsErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.article_outlined,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              'Could not load posts.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your Firebase configuration and Firestore rules.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _postCard(
    QueryDocumentSnapshot<Map<String, dynamic>> post,
  ) {
    final data = post.data();

    final name = (
      data['userName'] ??
      data['name'] ??
      'Friend'
    ).toString();

    final text = (
      data['text'] ??
      data['content'] ??
      ''
    ).toString();

    final imageUrl =
        (data['imageUrl'] ?? '').toString();

    final photoUrl =
        (data['photoUrl'] ?? '').toString();

    final likes = _toInt(
      data['likeCount'] ?? data['likes'],
    );

    final comments = _toInt(
      data['commentCount'],
    );

    final createdAt = data['createdAt'];

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _openPost(post.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _postAvatar(
                    photoUrl,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz,
                  ),
                ],
              ),
              if (text.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
              if (imageUrl.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) {
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
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$comments comments',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _openPost(post.id);
                      },
                      icon: const Icon(
                        Icons.favorite_border,
                      ),
                      label: const Text('Like'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _openPost(post.id);
                      },
                      icon: const Icon(
                        Icons.comment_outlined,
                      ),
                      label: const Text('Comment'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _openPost(post.id);
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                      ),
                      label: const Text('Open'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postAvatar(String photoUrl) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(
          photoUrl,
        ),
        onBackgroundImageError: (_, __) {},
      );
    }

    return const CircleAvatar(
      radius: 22,
      child: Icon(Icons.person),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Just now';
    }

    final date = value.toDate();
    final now = DateTime.now();

    if (date.isAfter(now)) {
      return 'Just now';
    }

    final difference =
        now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                ),
                title:
                    const Text('Notifications'),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showMessage(
                    'Notifications coming soon.',
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                ),
                title: const Text('Privacy'),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showMessage(
                    'Privacy settings coming soon.',
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.security_outlined,
                ),
                title: const Text('Security'),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () {
                  _showMessage(
                    'Security settings coming soon.',
                  );
                },
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
                title: const Text('Logout'),
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
        return const ProfileScreen();
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (!mounted) return;

          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
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
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: _openCreatePost,
                  tooltip: 'Create Post',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
