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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isSaving = false;

  String _name = 'Friend';
  String _email = '';
  String _bio = '';
  String _phone = '';
  String _location = '';
  String _website = '';
  String _photoUrl = '';
  String _coverPhotoUrl = '';

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
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (mounted) {
        setState(() {
          _name =
              (data?['name'] ??
                      user.displayName ??
                      'Friend')
                  .toString();

          _email =
              (data?['email'] ??
                      user.email ??
                      '')
                  .toString();

          _bio =
              (data?['bio'] ?? '').toString();

          _phone =
              (data?['phone'] ?? '').toString();

          _location =
              (data?['location'] ?? '')
                  .toString();

          _website =
              (data?['website'] ?? '')
                  .toString();

          _photoUrl =
              (data?['photoUrl'] ?? '')
                  .toString();

          _coverPhotoUrl =
              (data?['coverPhotoUrl'] ?? '')
                  .toString();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Could not load profile: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final nameController =
        TextEditingController(text: _name);

    final bioController =
        TextEditingController(text: _bio);

    final phoneController =
        TextEditingController(text: _phone);

    final locationController =
        TextEditingController(text: _location);

    final websiteController =
        TextEditingController(text: _website);

    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Profile',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(
                      Icons.edit_note,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration:
                      const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller:
                      locationController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller:
                      websiteController,
                  keyboardType:
                      TextInputType.url,
                  decoration:
                      const InputDecoration(
                    labelText: 'Website',
                    prefixIcon: Icon(
                      Icons.language,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name =
                    nameController.text
                        .trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Name cannot be empty.',
                      ),
                    ),
                  );
                  return;
                }

                final user =
                    _auth.currentUser;

                if (user == null) {
                  return;
                }

                setState(() {
                  _isSaving = true;
                });

                try {
                  await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .set(
                    {
                      'name': name,
                      'email':
                          user.email ?? _email,
                      'bio':
                          bioController.text
                              .trim(),
                      'phone':
                          phoneController.text
                              .trim(),
                      'location':
                          locationController
                              .text
                              .trim(),
                      'website':
                          websiteController
                              .text
                              .trim(),
                      'updatedAt':
                          FieldValue
                              .serverTimestamp(),
                    },
                    SetOptions(
                      merge: true,
                    ),
                  );

                  await user
                      .updateDisplayName(
                    name,
                  );

                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    _name = name;
                    _bio =
                        bioController.text
                            .trim();
                    _phone =
                        phoneController.text
                            .trim();
                    _location =
                        locationController
                            .text
                            .trim();
                    _website =
                        websiteController
                            .text
                            .trim();
                  });

                  Navigator.pop(
                    dialogContext,
                    true,
                  );

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Profile updated successfully.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  setState(() {
                    _isSaving = false;
                  });

                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not update profile: $e',
                      ),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
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
                  : const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    bioController.dispose();
    phoneController.dispose();
    locationController.dispose();
    websiteController.dispose();

    if (result == true && mounted) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
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
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  Widget _buildProfileAvatar() {
    if (_photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage:
            NetworkImage(_photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 55,
      child: Icon(
        Icons.person,
        size: 60,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
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
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon:
                const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            if (_coverPhotoUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                child: Image.network(
                  _coverPhotoUrl,
                  height: 150,
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
                      height: 150,
                    );
                  },
                ),
              ),

            const SizedBox(
              height: 20,
            ),

            Center(
              child:
                  _buildProfileAvatar(),
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              _name,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              _email,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),

            if (_bio.isNotEmpty) ...[
              const SizedBox(
                height: 14,
              ),
              Text(
                _bio,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 15,
                ),
              ),
            ],

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _editProfile,
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Edit Profile',
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Card(
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: _phone,
                  ),
                  _buildInfoTile(
                    icon: Icons
                        .location_on_outlined,
                    title: 'Location',
                    value: _location,
                  ),
                  _buildInfoTile(
                    icon: Icons.language,
                    title: 'Website',
                    value: _website,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                ),
                title:
                    const Text('Logout'),
                onTap: _logout,
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
