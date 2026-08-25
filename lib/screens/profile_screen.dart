import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.userId,
  });

  final String? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isAdmin = false;

  String _name = 'Friend';
  String _email = '';
  String _photoUrl = '';
  String _bio = '';
  String _location = '';
  String _phone = '';
  String _website = '';

  int _postCount = 0;
  int _friendCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String get _profileUserId {
    return widget.userId ?? _auth.currentUser?.uid ?? '';
  }

  Future<void> _loadProfile() async {
    final uid = _profileUserId;

    if (uid.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final user = _auth.currentUser;

      final profileSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!profileSnapshot.exists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final data = profileSnapshot.data() ?? {};

      final adminValue = data['isAdmin'];

      final bool adminStatus =
          adminValue == true ||
          adminValue.toString().toLowerCase() == 'true';

      final String loadedName =
          (data['name'] ??
                  data['userName'] ??
                  data['displayName'] ??
                  user?.displayName ??
                  'Friend')
              .toString()
              .trim();

      final String loadedEmail =
          (data['email'] ??
                  user?.email ??
                  '')
              .toString()
              .trim();

      final String loadedPhoto =
          (data['photoUrl'] ??
                  data['userPhotoUrl'] ??
                  data['profileImage'] ??
                  user?.photoURL ??
                  '')
              .toString()
              .trim();

      final String loadedBio =
          (data['bio'] ?? '')
              .toString()
              .trim();

      final String loadedLocation =
          (data['location'] ?? '')
              .toString()
              .trim();

      final String loadedPhone =
          (data['phone'] ?? '')
              .toString()
              .trim();

      final String loadedWebsite =
          (data['website'] ?? '')
              .toString()
              .trim();

      int loadedPosts = 0;

      try {
        final postsSnapshot = await _firestore
            .collection('posts')
            .where(
              'userId',
              isEqualTo: uid,
            )
            .get();

        loadedPosts = postsSnapshot.docs.length;
      } catch (_) {
        try {
          final postsSnapshot = await _firestore
              .collection('posts')
              .where(
                'uid',
                isEqualTo: uid,
              )
              .get();

          loadedPosts = postsSnapshot.docs.length;
        } catch (_) {
          loadedPosts = 0;
        }
      }

      int loadedFriends = 0;

      final friendCountValue =
          data['friendCount'];

      if (friendCountValue is num) {
        loadedFriends =
            friendCountValue.toInt();
      } else {
        loadedFriends =
            int.tryParse(
                  friendCountValue
                          ?.toString() ??
                      '',
                ) ??
                0;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isAdmin = adminStatus;
        _name = loadedName.isEmpty
            ? 'Friend'
            : loadedName;
        _email = loadedEmail;
        _photoUrl = loadedPhoto;
        _bio = loadedBio;
        _location = loadedLocation;
        _phone = loadedPhone;
        _website = loadedWebsite;
        _postCount = loadedPosts;
        _friendCount = loadedFriends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Could not load profile.',
      );
    }
  }

  Future<void> _openAdminDashboard() async {
    if (!_isAdmin) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AdminDashboardScreen(),
      ),
    );
  }

  Future<void> _editProfile() async {
    _showMessage(
      'Profile editing is available from the Edit Profile option.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 58,
        backgroundImage: NetworkImage(
          _photoUrl,
        ),
      );
    }

    return const CircleAvatar(
      radius: 58,
      child: Icon(
        Icons.person,
        size: 58,
      ),
    );
  }

  Widget _buildStat(
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildAdminCard() {
    if (!_isAdmin) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(
        top: 14,
        bottom: 12,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          16,
        ),
        onTap: _openAdminDashboard,
        child: Padding(
          padding: const EdgeInsets.all(
            18,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 30,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Manage Friend Post',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
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
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(
            16,
          ),
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  20,
                ),
                child: Column(
                  children: [
                    _buildAvatar(),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      _name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (_email.isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        _email,
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ],
                    if (_isAdmin) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        _buildStat(
                          _postCount.toString(),
                          'Posts',
                        ),
                        _buildStat(
                          _friendCount.toString(),
                          'Friends',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(
                  Icons.edit,
                ),
                label: const Text(
                  'Edit Profile',
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                ),
              ),
            ),

            _buildAdminCard(),

            const SizedBox(
              height: 8,
            ),

            _buildInfoCard(
              Icons.info_outline,
              'Bio',
              _bio,
            ),

            _buildInfoCard(
              Icons.location_on_outlined,
              'Location',
              _location,
            ),

            _buildInfoCard(
              Icons.phone_outlined,
              'Phone',
              _phone,
            ),

            _buildInfoCard(
              Icons.language,
              'Website',
              _website,
            ),

            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(
                  Icons.article_outlined,
                ),
                title: const Text(
                  'My Posts',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$_postCount posts',
                ),
              ),
            ),

            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(
                  Icons.people_outline,
                ),
                title: const Text(
                  'Friends',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$_friendCount friends',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
