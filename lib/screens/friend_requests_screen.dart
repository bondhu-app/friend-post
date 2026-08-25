import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({
    super.key,
  });

  @override
  State<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState
    extends State<FriendRequestsScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isProcessing(String requestId) {
    return _processingRequests.contains(requestId);
  }

  final Set<String> _processingRequests = {};

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

  Future<void> _acceptRequest(
    DocumentSnapshot<Map<String, dynamic>> request,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final requestId = request.id;

    if (_isProcessing(requestId)) {
      return;
    }

    final data = request.data();

    if (data == null) {
      _showMessage('Invalid friend request.');
      return;
    }

    final senderId =
        (data['senderId'] ?? '').toString();

    final receiverId =
        (data['receiverId'] ?? '').toString();

    if (senderId.isEmpty ||
        receiverId.isEmpty) {
      _showMessage('Invalid friend request.');
      return;
    }

    if (receiverId != user.uid) {
      _showMessage(
        'You cannot accept this request.',
      );
      return;
    }

    setState(() {
      _processingRequests.add(requestId);
    });

    try {
      final batch = _firestore.batch();

      final myFriendReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('friends')
          .doc(senderId);

      final senderFriendReference = _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(user.uid);

      batch.set(
        myFriendReference,
        {
          'uid': senderId,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        senderFriendReference,
        {
          'uid': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        request.reference,
        {
          'status': 'accepted',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _showMessage(
        'Friend request accepted.',
      );
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not accept friend request.',
      );
    } catch (e) {
      debugPrint(
        'Accept friend request error: $e',
      );

      _showMessage(
        'Could not accept friend request.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequests.remove(
            requestId,
          );
        });
      }
    }
  }

  Future<void> _declineRequest(
    DocumentSnapshot<Map<String, dynamic>> request,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final requestId = request.id;

    if (_isProcessing(requestId)) {
      return;
    }

    final data = request.data();

    if (data == null) {
      _showMessage('Invalid friend request.');
      return;
    }

    final receiverId =
        (data['receiverId'] ?? '').toString();

    if (receiverId != user.uid) {
      _showMessage(
        'You cannot decline this request.',
      );
      return;
    }

    setState(() {
      _processingRequests.add(requestId);
    });

    try {
      await request.reference.update({
        'status': 'declined',
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      _showMessage(
        'Friend request declined.',
      );
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not decline friend request.',
      );
    } catch (e) {
      debugPrint(
        'Decline friend request error: $e',
      );

      _showMessage(
        'Could not decline friend request.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequests.remove(
            requestId,
          );
        });
      }
    }
  }

  Widget _buildAvatar(
    String photoUrl,
    String name,
  ) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 27,
        backgroundImage:
            NetworkImage(photoUrl),
      );
    }

    final firstLetter =
        name.trim().isNotEmpty
            ? name.trim()[0].toUpperCase()
            : 'F';

    return CircleAvatar(
      radius: 27,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    DocumentSnapshot<Map<String, dynamic>> request,
  ) {
    final data = request.data() ?? {};

    final senderName =
        (data['senderName'] ?? 'Friend')
            .toString();

    final senderPhotoUrl =
        (data['senderPhotoUrl'] ??
                data['photoUrl'] ??
                '')
            .toString();

    final senderEmail =
        (data['senderEmail'] ?? '')
            .toString();

    final processing =
        _isProcessing(request.id);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatar(
                  senderPhotoUrl,
                  senderName,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        senderEmail.isEmpty
                            ? 'Wants to be your friend'
                            : senderEmail,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: processing
                        ? null
                        : () {
                            _declineRequest(
                              request,
                            );
                          },
                    child: const Text(
                      'Decline',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: processing
                        ? null
                        : () {
                            _acceptRequest(
                              request,
                            );
                          },
                    child: processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Accept',
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

  Stream<
      QuerySnapshot<Map<String, dynamic>>>
  _requestsStream(String uid) {
    return _firestore
        .collection('friendRequests')
        .where(
          'receiverId',
          isEqualTo: uid,
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Friend Requests',
          ),
        ),
        body: const Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friend Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: _requestsStream(
          user.uid,
        ),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            debugPrint(
              'Friend requests error: '
              '${snapshot.error}',
            );

            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Text(
                  'Could not load friend requests.',
                  textAlign:
                      TextAlign.center,
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

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await _firestore
                    .collection(
                      'friendRequests',
                    )
                    .where(
                      'receiverId',
                      isEqualTo: user.uid,
                    )
                    .where(
                      'status',
                      isEqualTo: 'pending',
                    )
                    .get();
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 180,
                  ),
                  Icon(
                    Icons
                        .people_outline,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Center(
                    child: Text(
                      'No friend requests.',
                      style:
                          TextStyle(
                        fontSize: 17,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _firestore
                  .collection(
                    'friendRequests',
                  )
                  .where(
                    'receiverId',
                    isEqualTo: user.uid,
                  )
                  .where(
                    'status',
                    isEqualTo: 'pending',
                  )
                  .get();
            },
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              children: [
                Text(
                  '${requests.length} Friend '
                  '${requests.length == 1 ? 'Request' : 'Requests'}',
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                ...requests.map(
                  _buildRequestCard,
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
