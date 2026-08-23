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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendFriendRequest(
    String userId,
    String name,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    if (currentUser.uid == userId) {
      return;
    }

    try {
      final requestId =
          '${currentUser.uid}_$userId';

      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .set({
        'senderId': currentUser.uid,
        'receiverId': userId,
        'senderName':
            currentUser.displayName ?? 'Friend',
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Friend request sent to $name',
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
    if (_searchText.trim().isEmpty) {
      return true;
    }

    final search =
        _searchText.trim().toLowerCase();

    final name =
        (data['name'] ?? '').toString().toLowerCase();

    final email =
        (data['email'] ?? '').toString().toLowerCase();

    return name.contains(search) ||
        email.contains(search);
  }

  Widget _buildUserAvatar(
    Map<String, dynamic> data,
  ) {
    final photoUrl =
        (data['photoUrl'] ?? '').toString();

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage:
            NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 28,
      child: Icon(
        Icons.person,
        size: 30,
      ),
    );
  }

  Widget _buildUserCard(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data = document.data();

    final userId = document.id;

    final name =
        (data['name'] ?? 'Friend').toString();

    final email =
        (data['email'] ?? '').toString();

    final currentUser =
        _auth.currentUser;

    if (currentUser != null &&
        currentUser.uid == userId) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        leading: _buildUserAvatar(data),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: email.isEmpty
            ? const Text('Friend Post user')
            : Text(email),
        trailing: FilledButton.icon(
          onPressed: () {
            _sendFriendRequest(
              userId,
              name,
            );
          },
          icon: const Icon(
            Icons.person_add_alt_1,
            size: 18,
          ),
          label: const Text('Add'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText:
                    'Search friends...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController
                                  .clear();

                              setState(() {
                                _searchText = '';
                              });
                            },
                            icon: const Icon(
                              Icons.clear,
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

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _usersStream(),
              builder:
                  (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 55,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          const Text(
                            'Could not load users.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            '${snapshot.error}',
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                final filtered =
                    documents.where((doc) {
                  return _matchesSearch(
                    doc.data(),
                  );
                }).toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView(
                      children: const [
                        SizedBox(
                          height: 180,
                        ),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 70,
                              ),
                              SizedBox(
                                height: 14,
                              ),
                              Text(
                                'No friends found.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 6,
                              ),
                              Text(
                                'Try another search.',
                                style:
                                    TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
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
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      20,
                    ),
                    itemCount:
                        filtered.length,
                    itemBuilder:
                        (context, index) {
                      return _buildUserCard(
                        filtered[index],
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
