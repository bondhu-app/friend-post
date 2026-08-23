import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest(
    String targetUserId,
    String targetName,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    if (currentUser.uid == targetUserId) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserDocument = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentUserData =
          currentUserDocument.data() ?? <String, dynamic>{};

      final requestId =
          '${currentUser.uid}_$targetUserId';

      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .set({
        'requestId': requestId,
        'senderId': currentUser.uid,
        'senderName':
            currentUserData['name'] ??
                currentUser.displayName ??
                '',
        'senderEmail':
            currentUserData['email'] ??
                currentUser.email ??
                '',
        'receiverId': targetUserId,
        'receiverName': targetName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request sent to $targetName.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Could not send friend request.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not send friend request.',
          ),
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

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _usersStream() {
    return _firestore
        .collection('users')
        .orderBy('name')
        .limit(50)
        .snapshots();
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final name =
        (data['name'] ?? '').toString().toLowerCase();

    final email =
        (data['email'] ?? '').toString().toLowerCase();

    return name.contains(_searchText) ||
        email.contains(_searchText);
  }

  Widget _buildUserAvatar(
    Map<String, dynamic> data,
  ) {
    final photoUrl =
        (data['photoUrl'] ?? '').toString();

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 27,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 27,
      child: Icon(
        Icons.person_rounded,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(
                          Icons.clear_rounded,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 50,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Could not load users.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                final users = documents.where((document) {
                  final data = document.data();

                  if (currentUser != null &&
                      document.id == currentUser.uid) {
                    return false;
                  }

                  final isBlocked =
                      data['isBlocked'] == true;

                  if (isBlocked) {
                    return false;
                  }

                  return _matchesSearch(data);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 60,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _searchText.isEmpty
                                ? 'No other users found.'
                                : 'No users found for "$_searchText".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                      const Duration(
                        milliseconds: 500,
                      ),
                    );
                  },
                  child: ListView.separated(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24,
                    ),
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final document = users[index];
                      final data = document.data();

                      final userId = document.id;

                      final name =
                          (data['name'] ?? 'Friend Post User')
                              .toString();

                      final email =
                          (data['email'] ?? '')
                              .toString();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              _buildUserAvatar(data),

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
                                      style:
                                          const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    if (email.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              FilledButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        _sendFriendRequest(
                                          userId,
                                          name,
                                        );
                                      },
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 18,
                                ),
                                label:
                                    const Text('Add'),
                              ),
                            ],
                          ),
                        ),
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
}
