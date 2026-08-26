import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'নাম বা Email দিয়ে খুঁজুন',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('users')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _buildError();
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();

                  final name = (data['name'] ??
                          data['displayName'] ??
                          '')
                      .toString()
                      .toLowerCase();

                  final email =
                      (data['email'] ?? '').toString().toLowerCase();

                  final uid = doc.id.toLowerCase();

                  if (_searchQuery.isEmpty) {
                    return true;
                  }

                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      uid.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'কোনো user পাওয়া যায়নি'
                              : 'কোনো user পাওয়া যায়নি',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      20,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return _buildUserCard(
                        context,
                        doc,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final name = (data['name'] ??
            data['displayName'] ??
            'Unknown User')
        .toString();

    final email = (data['email'] ?? '').toString();

    final phone = (data['phone'] ?? '').toString();

    final isAdmin =
        data['isAdmin'] == true || data['admin'] == true;

    final photoUrl =
        (data['photoUrl'] ?? data['photoURL'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(
                  name: name,
                  photoUrl: photoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? 'Unknown User' : name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAdmin)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Chip(
                                label: Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                visualDensity:
                                    VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showUserDetails(
                        context,
                        doc,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _showAdminDialog(
                        context,
                        doc,
                        isAdmin,
                      );
                    },
                    icon: Icon(
                      isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.admin_panel_settings_outlined,
                    ),
                    label: Text(
                      isAdmin ? 'Admin' : 'Make Admin',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String name,
    required String photoUrl,
  }) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
      );
    }

    final firstLetter =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return CircleAvatar(
      radius: 28,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 70,
            ),
            const SizedBox(height: 16),
            const Text(
              'Users লোড করা যায়নি',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Firestore-এর users collection অথবা '
              'security rules পরীক্ষা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdminDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool currentlyAdmin,
  ) async {
    final userName = (doc.data()['name'] ??
            doc.data()['displayName'] ??
            'এই user')
        .toString();

    final newAdminStatus = !currentlyAdmin;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            newAdminStatus
                ? 'Admin বানাবেন?'
                : 'Admin Access সরাবেন?',
          ),
          content: Text(
            newAdminStatus
                ? '$userName-কে Admin করা হবে। আপনি কি নিশ্চিত?'
                : '$userName-এর Admin Access সরানো হবে। আপনি কি নিশ্চিত?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('হ্যাঁ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _setAdminStatus(
      context,
      doc.id,
      newAdminStatus,
    );
  }

  Future<void> _setAdminStatus(
    BuildContext context,
    String userId,
    bool isAdmin,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        {
          'isAdmin': isAdmin,
          'admin': isAdmin,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isAdmin
                  ? 'User-কে Admin করা হয়েছে'
                  : 'Admin Access সরানো হয়েছে',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Admin status পরিবর্তন করা যায়নি। '
              'Firestore Rules পরীক্ষা করুন।',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _showUserDetails(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final name = (data['name'] ??
            data['displayName'] ??
            'Unknown User')
        .toString();

    final email = (data['email'] ?? '').toString();

    final phone = (data['phone'] ?? '').toString();

    final location = (data['location'] ?? '').toString();

    final bio = (data['bio'] ?? '').toString();

    final website = (data['website'] ?? '').toString();

    final isAdmin =
        data['isAdmin'] == true || data['admin'] == true;

    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  'Name',
                  name,
                ),
                _detailRow(
                  'Email',
                  email.isEmpty ? '—' : email,
                ),
                _detailRow(
                  'Phone',
                  phone.isEmpty ? '—' : phone,
                ),
                _detailRow(
                  'Location',
                  location.isEmpty ? '—' : location,
                ),
               
