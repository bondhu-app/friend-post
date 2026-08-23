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

  try {
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
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon:
                        Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon:
                        Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType:
                      TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon:
                        Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  keyboardType:
                      TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    prefixIcon:
                        Icon(Icons.language),
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
              onPressed: () async {
                final name =
                    nameController.text.trim();

                if (name.isEmpty) {
                  return;
                }

                final user = _auth.currentUser;

                if (user == null) {
                  return;
                }

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
                          bioController.text.trim(),
                      'phone':
                          phoneController.text.trim(),
                      'location':
                          locationController.text
                              .trim(),
                      'website':
                          websiteController.text
                              .trim(),
                      'updatedAt':
                          FieldValue.serverTimestamp(),
                    },
                    SetOptions(merge: true),
                  );

                  await user.updateDisplayName(name);

                  if (!mounted) return;

                  setState(() {
                    _name = name;
                    _bio =
                        bioController.text.trim();
                    _phone =
                        phoneController.text.trim();
                    _location =
                        locationController.text
                            .trim();
                    _website =
                        websiteController.text
                            .trim();
                  });

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext)
                        .pop(true);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not update profile: $e',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      await _loadProfile();
    }
  } finally {
    nameController.dispose();
    bioController.dispose();
    phoneController.dispose();
    locationController.dispose();
    websiteController.dispose();
  }
}
