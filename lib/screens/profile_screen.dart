import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _name = 'Friend';
  String _email = '';
  String _photoUrl = '';
  String _bio = '';

  int _postCount = 0;
  int _friendCount = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  String get _profileUserId {
    final requestedId = widget.userId?.trim();

    if (requestedId != null && requestedId.isNotEmpty) {
      return requestedId;
    }

    return _auth.currentUser?.uid ?? '';
  }

  bool get _isOwnProfile {
    final currentUid = _auth.currentUser?.uid;

    return currentUid != null &&
        currentUid == _profileUserId;
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _bioController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
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
      final results = await Future.wait([
        _firestore.collection('users').doc(uid).get(),
        _firestore
            .collection('posts')
            .where('userId', isEqualTo: uid)
            .get(),
        _firestore
            .collection('users')
            .doc(uid)
            .collection('friends')
            .get(),
      ]);

      final userSnapshot =
          results[0] as DocumentSnapshot<Map<String, dynamic>>;

      final postsSnapshot =
          results[1] as QuerySnapshot<Map<String, dynamic>>;

      final friendsSnapshot =
          results[2] as QuerySnapshot<Map<String, dynamic>>;

      final data = userSnapshot.data();

      if (data != null) {
        final name = (data['name'] ?? '').toString().trim();
        final email =
            (data['email'] ?? '').toString().trim();
        final photoUrl =
            (data['photoUrl'] ?? '').toString().trim();
        final bio = (data['bio'] ?? '').toString().trim();

        _name = name.isEmpty ? 'Friend' : name;
        _email = email;
        _photoUrl = photoUrl;
        _bio = bio;
      } else {
        final user = _auth.currentUser;

        if (user != null && user.uid == uid) {
          _name = user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Friend';

          _email = user.email ?? '';
          _photoUrl = user.photoURL ?? '';
        }
      }

      _postCount = postsSnapshot.docs.length;
      _friendCount = friendsSnapshot.docs.length;

      _nameController.text = _name;
      _bioController.text = _bio;
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not load profile.',
      );
    } catch (_) {
      _showMessage(
        'Could not load profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    if (!_isOwnProfile) {
      return;
    }

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
      await _firestore.collection('users').doc(user.uid).set(
        {
          'uid': user.uid,
          'name': name,
          'email': user.email ?? _email,
          'photoUrl': _photoUrl,
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      try {
        await user.updateDisplayName(name);
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        _name = name;
        _bio = bio;
        _isEditing = false;
      });

      _showMessage('Profile updated successfully.');
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not update profile.',
      );
    } catch (_) {
      _showMessage(
        'Could not update profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _loadProfile();
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

  Widget _buildAvatar() {
    if (_photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: NetworkImage(_photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 52,
      child: Icon(
        Icons.person,
        size: 52,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 14),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_email.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                _email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
            if (_bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    value: _postCount.toString(),
                    label: 'Posts',
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    value: _friendCount.toString(),
                    label: 'Friends',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEditSection() {
    if (!_isOwnProfile || !_isEditing) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(
                  Icons.person_outline,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bioController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Bio',
                prefixIcon: const Icon(
                  Icons.info_outline,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
                        : () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text = _name;
                              _bioController.text = _bio;
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (!_isOwnProfile) {
      return const SizedBox.shrink();
    }

    if (_isEditing) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _isEditing = true;
            _nameController.text = _name;
            _bioController.text = _bio;
          });
        },
        icon: const Icon(
          Icons.edit_outlined,
        ),
        label: const Text('Edit Profile'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('Please login first.'),
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
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _refreshProfile,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 14),
                  _buildActionButton(),
                  _buildEditSection(),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.post_add_outlined,
                      ),
                      title: const Text(
                        'My Posts',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '$_postCount posts',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.people_outline,
                      ),
                      title: const Text(
                        'Friends',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '$_friendCount friends',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
