import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _userReference(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid);
  }

  Future<void> _saveProfile(
    String uid,
    Map<String, dynamic> currentData,
  ) async {
    if (_isSaving) {
      return;
    }

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      _showMessage('Name cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _userReference(uid).set(
        {
          'uid': uid,
          'name': name,
          'bio': bio,
          'email': _auth.currentUser?.email ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
      });

      _showMessage('Profile updated successfully.');
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not update profile.',
      );
    } catch (e) {
      debugPrint('Profile update error: $e');
      _showMessage('Could not update profile.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true) {
      return;
    }

    try {
      await _auth.signOut();
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not logout.',
      );
    } catch (e) {
      debugPrint('Logout error: $e');
      _showMessage('Could not logout.');
    }
  }

  void _startEditing(
    Map<String, dynamic> data,
    User user,
  ) {
    final name = (data['name'] ?? '').toString();
    final bio = (data['bio'] ?? '').toString();

    _nameController.text =
        name.isNotEmpty ? name : (user.displayName ?? 'Friend');

    _bioController.text = bio;

    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isEditing = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAvatar(
    String photoUrl,
    String name,
  ) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    final firstLetter = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'F';

    return CircleAvatar(
      radius: 55,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 8,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    String uid,
    User user,
    Map<String, dynamic> data,
  ) {
    final name =
        (data['name'] ?? user.displayName ?? 'Friend')
            .toString();

    final email =
        (data['email'] ?? user.email ?? '')
            .toString();

    final bio =
        (data['bio'] ?? '')
            .toString();

    final photoUrl =
        (data['photoUrl'] ?? user.photoURL ?? '')
            .toString();

    final postCount =
        _toInt(data['postCount']);

    final friendCount =
        _toInt(data['friendCount']);

    final followerCount =
        _toInt(data['followerCount']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),

        Center(
          child: _buildAvatar(
            photoUrl,
            name,
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              email,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],

        if (bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        Row(
          children: [
            _buildStatCard(
              'Posts',
              postCount.toString(),
              Icons.article_outlined,
            ),
            _buildStatCard(
              'Friends',
              friendCount.toString(),
              Icons.people_outline,
            ),
            _buildStatCard(
              'Followers',
              followerCount.toString(),
              Icons.person_add_alt_1_outlined,
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (_isEditing)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameController,
                    textCapitalization:
                        TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText:
                          'Tell something about yourself...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(
                          bottom: 65,
                        ),
                        child: Icon(
                          Icons.info_outline,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : _cancelEditing,
                          child:
                              const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _saveProfile(
                                    uid,
                                    data,
                                  );
                                },
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.edit_outlined,
              ),
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'Update your name and bio',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                _startEditing(
                  data,
                  user,
                );
              },
            ),
          ),

        const SizedBox(height: 10),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.email_outlined,
            ),
            title: const Text('Email'),
            subtitle: Text(
              email.isEmpty
                  ? 'No email'
                  : email,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.verified_user_outlined,
            ),
            title: const Text(
              'Account',
            ),
            subtitle: const Text(
              'Your Friend Post account',
            ),
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _logout,
          ),
        ),

        const SizedBox(height: 30),
      ],
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userReference(user.uid).snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load profile.',
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data =
              snapshot.data?.data() ??
                  <String, dynamic>{};

          return _buildProfileContent(
            user.uid,
            user,
            data,
          );
        },
      ),
    );
  }
}
