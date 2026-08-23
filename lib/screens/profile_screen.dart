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

  bool _isLoading = true;

  String _name = '';
  String _email = '';
  String _bio = '';
  String _location = '';
  String _website = '';
  String _photoUrl = '';

  int _postCount = 0;
  int _friendCount = 0;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      if (data != null) {
        _name = (data['name'] ?? user.displayName ?? '').toString();
        _email = (data['email'] ?? user.email ?? '').toString();
        _bio = (data['bio'] ?? '').toString();
        _location = (data['location'] ?? '').toString();
        _website = (data['website'] ?? '').toString();
        _photoUrl = (data['photoUrl'] ?? '').toString();

        _postCount = _toInt(data['postCount']);
        _friendCount = _toInt(data['friendCount']);
        _followerCount = _toInt(data['followerCount']);
        _followingCount = _toInt(data['followingCount']);
      } else {
        _name = user.displayName ?? '';
        _email = user.email ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _editProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final nameController = TextEditingController(text: _name);
    final bioController = TextEditingController(text: _bio);
    final locationController = TextEditingController(text: _location);
    final websiteController = TextEditingController(text: _website);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                ),
              ],
            ),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      bioController.dispose();
      locationController.dispose();
      websiteController.dispose();
      return;
    }

    final newName = nameController.text.trim();
    final newBio = bioController.text.trim();
    final newLocation = locationController.text.trim();
    final newWebsite = websiteController.text.trim();

    nameController.dispose();
    bioController.dispose();
    locationController.dispose();
    websiteController.dispose();

    if (newName.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty.'),
        ),
      );

      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      await user.updateDisplayName(newName);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': newName,
          'bio': newBio,
          'location': newLocation,
          'website': newWebsite,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _name = newName;
      _bio = newBio;
      _location = newLocation;
      _website = newWebsite;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update profile: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    if (_photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: NetworkImage(_photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 55,
      child: Icon(
        Icons.person_rounded,
        size: 60,
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
  ) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Edit Profile',
            onPressed: _isLoading ? null : _editProfile,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 10),

                  Center(
                    child: _buildAvatar(),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _name.isEmpty ? 'Friend Post User' : _name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          _buildStat(
                            _postCount.toString(),
                            'Posts',
                          ),
                          _buildStat(
                            _friendCount.toString(),
                            'Friends',
                          ),
                          _buildStat(
                            _followerCount.toString(),
                            'Followers',
                          ),
                          _buildStat(
                            _followingCount.toString(),
                            'Following',
                          ),
                        ],
                      ),
                    ),
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
                            'About',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _buildInfoRow(
                            Icons.info_outline,
                            _bio,
                          ),

                          _buildInfoRow(
                            Icons.location_on_outlined,
                            _location,
                          ),

                          _buildInfoRow(
                            Icons.language_outlined,
                            _website,
                          ),

                          if (_bio.isEmpty &&
                              _location.isEmpty &&
                              _website.isEmpty)
                            const Text(
                              'No profile information added yet.',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit Profile'),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
