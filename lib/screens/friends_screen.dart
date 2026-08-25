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

  String _searchText = '';

  Future<void> _sendFriendRequest(
    String targetUid,
    String targetName,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    if (user.uid == targetUid) {
      _showMessage('You cannot add yourself.');
      return;
    }

    try {
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: user.uid)
          .where('receiverId', isEqualTo: targetUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        _showMessage('Friend request already sent.');
        return;
      }

      final request =
          _firestore.collection('friendRequests').doc();

      await request.set({
        'requestId': request.id,
        'senderId': user.uid,
        'receiverId': targetUid,
        'senderName': user.displayName ?? 'Friend',
        'receiverName': targetName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Friend request sent.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Could not send friend request.',
      );
    } catch (e) {
      debugPrint('Friend request error: $e');

      if (!mounted) return;

      _showMessage('Could not send friend request.');
    }
  }

  Future<void> _acceptRequest(
    DocumentSnapshot<Map<String, dynamic>> request,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final data = request.data();

    if (data == null) {
      return;
    }

    final senderId = (data['senderId'] ?? '').toString();

    if (senderId.isEmpty) {
      _showMessage('Invalid friend request.');
      return;
    }

    try {
      final batch = _firestore.batch();

      final currentUserFriend = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .doc(senderId);

      final senderFriend = _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(user.uid);

      batch.set(currentUserFriend, {
        'uid': senderId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(senderFriend, {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(request.reference, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      _showMessage('Friend request accepted.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Could not accept request.',
      );
    } catch (e) {
      debugPrint('Accept request error: $e');

      if (!mounted) return;

      _showMessage('Could not accept request.');
    }
  }

  Future<void> _declineRequest(
    DocumentSnapshot<Map<String, dynamic>> request,
  ) async {
    try {
      await request.reference.update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage('Friend request declined.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Could not decline request.',
      );
    } catch (e) {
      debugPrint('Decline request error: $e');

      if (!mounted) return;

      _showMessage('Could not decline request.');
    }
  }

  Future<void> _removeFriend(String friendUid) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: const Text(
            'Are you sure you want to remove this friend?',
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final batch = _firestore.batch();

      final myFriend = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .doc(friendUid);

      final friendOfMine = _firestore
          .collection('users')
          .doc(friendUid)
          .collection('friends')
          .doc(user.uid);

      batch.delete(myFriend);
      batch.delete(friendOfMine);

      await batch.commit();

      if (!mounted) return;

      _showMessage('Friend removed.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.message ?? 'Could not remove friend.',
      );
    } catch (e) {
      debugPrint('Remove friend error: $e');

      if (!mounted) return;

      _showMessage('Could not remove friend.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _avatar(String photoUrl) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 25,
      child: Icon(Icons.person),
    );
  }

  Widget _buildFriendRequests(String uid) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Friend requests error: ${snapshot.error}',
          );

          return const SizedBox();
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return const SizedBox();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Friend Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...requests.map((request) {
                  final data = request.data();

                  final name =
                      (data['senderName'] ?? 'Friend')
                          .toString();

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(name),
                    subtitle: const Text(
                      'Wants to be your friend',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Accept',
                          onPressed: () {
                            _acceptRequest(request);
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Decline',
                          onPressed: () {
                            _declineRequest(request);
                          },
                          icon: const Icon(
                            Icons.cancel_outlined,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(String uid) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Friends list error: ${snapshot.error}',
          );

          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Could not load friends.'),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final friends = snapshot.data?.docs ?? [];

        if (friends.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'You have no friends yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'My Friends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...friends.map((friend) {
              final friendUid = friend.id;

              return FutureBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                future: _firestore
                    .collection('users')
                    .doc(friendUid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text('Loading...'),
                      ),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return const SizedBox();
                  }

                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final data =
                      userSnapshot.data!.data();

                  if (data == null) {
                    return const SizedBox();
                  }

                  final name =
                      (data['name'] ?? 'Friend')
                          .toString();

                  final photoUrl =
                      (data['photoUrl'] ?? '')
                          .toString();

                  final email =
                      (data['email'] ?? '')
                          .toString();

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      leading: _avatar(photoUrl),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        email.isEmpty
                            ? 'Friend'
                            : email,
                      ),
                      trailing:
                          PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') {
                            _removeFriend(friendUid);
                          }
                        },
                        itemBuilder: (context) {
                          return const [
                            PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .person_remove_outlined,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Remove Friend'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSearchUsers(String uid) {
    if (_searchText.trim().isEmpty) {
      return const SizedBox();
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Search users error: ${snapshot.error}',
          );

          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Could not search users.'),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final search =
            _searchText.trim().toLowerCase();

        final users = snapshot.data!.docs.where((doc) {
          if (doc.id == uid) {
            return false;
          }

          final data = doc.data();

          final name =
              (data['name'] ?? '')
                  .toString()
                  .toLowerCase();

          final email =
              (data['email'] ?? '')
                  .toString()
                  .toLowerCase();

          return name.contains(search) ||
              email.contains(search);
        }).toList();

        if (users.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No users found.'),
            ),
          );
        }

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12,
              ),
              child: Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...users.map((doc) {
              final data = doc.data();

              final name =
                  (data['name'] ?? 'Friend')
                      .toString();

              final email =
                  (data['email'] ?? '')
                      .toString();

              final photoUrl =
                  (data['photoUrl'] ?? '')
                      .toString();

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: _avatar(photoUrl),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    email.isEmpty
                        ? 'Friend'
                        : email,
                  ),
                  trailing: FilledButton(
                    onPressed: () {
                      _sendFriendRequest(
                        doc.id,
                        name,
                      );
                    },
                    child: const Text(
                      'Add Friend',
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!mounted) return;

          setState(() {});
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                    _searchText.isNotEmpty
                        ? IconButton(
                            onPressed: () {
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

            const SizedBox(height: 16),

            _buildSearchUsers(user.uid),

            _buildFriendRequests(user.uid),

            _buildFriendsList(user.uid),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
