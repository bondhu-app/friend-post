import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState
    extends State<FriendRequestsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final Set<String> _processingRequests = <String>{};

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _requestsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('friendRequests')
        .where(
          'receiverId',
          isEqualTo: user.uid,
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }

  Future<void> _acceptRequest(
    String requestId,
    Map<String, dynamic> request,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    final senderId =
        (request['senderId'] ?? '').toString();

    if (senderId.isEmpty ||
        senderId == currentUser.uid) {
      return;
    }

    setState(() {
      _processingRequests.add(requestId);
    });

    try {
      final senderDocument = await _firestore
          .collection('users')
          .doc(senderId)
          .get();

      final receiverDocument = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final senderData =
          senderDocument.data() ??
              <String, dynamic>{};

      final receiverData =
          receiverDocument.data() ??
              <String, dynamic>{};

      final senderName =
          (senderData['name'] ??
                  request['senderName'] ??
                  '')
              .toString();

      final receiverName =
          (receiverData['name'] ??
                  currentUser.displayName ??
                  '')
              .toString();

      final batch = _firestore.batch();

      final friendshipId = senderId.compareTo(
                currentUser.uid,
              ) <
              0
          ? '${senderId}_${currentUser.uid}'
          : '${currentUser.uid}_$senderId';

      final friendshipReference = _firestore
          .collection('friendships')
          .doc(friendshipId);

      batch.set(
        friendshipReference,
        {
          'friendshipId': friendshipId,
          'userIds': [
            senderId,
            currentUser.uid,
          ],
          'userId1': senderId,
          'userId2': currentUser.uid,
          'user1Name': senderName,
          'user2Name': receiverName,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      final senderReference = _firestore
          .collection('users')
          .doc(senderId);

      final receiverReference = _firestore
          .collection('users')
          .doc(currentUser.uid);

      batch.set(
        senderReference,
        {
          'friendCount':
              FieldValue.increment(1),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        receiverReference,
        {
          'friendCount':
              FieldValue.increment(1),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final requestReference = _firestore
          .collection('friendRequests')
          .doc(requestId);

      batch.update(
        requestReference,
        {
          'status': 'accepted',
          'acceptedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            senderName.isEmpty
                ? 'Friend request accepted.'
                : '$senderName is now your friend.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Could not accept friend request.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not accept friend request.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequests.remove(requestId);
        });
      }
    }
  }

  Future<void> _rejectRequest(
    String requestId,
  ) async {
    setState(() {
      _processingRequests.add(requestId);
    });

    try {
      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'rejectedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Friend request rejected.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Could not reject friend request.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not reject friend request.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRequests.remove(requestId);
        });
      }
    }
  }

  Widget _buildAvatar(
    Map<String, dynamic> request,
  ) {
    final photoUrl =
        (request['senderPhotoUrl'] ?? '')
            .toString();

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
        Icons.person_rounded,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _requestsStream(),
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
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 55,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load friend requests.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future<void>.delayed(
                  const Duration(
                    milliseconds: 500,
                  ),
                );
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(
                    Icons.person_add_disabled_rounded,
                    size: 65,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No pending friend requests.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document =
                  requests[index];

              final requestId =
                  document.id;

              final request =
                  document.data();

              final senderName =
                  (request['senderName'] ??
                          'Friend Post User')
                      .toString();

              final senderEmail =
                  (request['senderEmail'] ??
                          '')
                      .toString();

              final isProcessing =
                  _processingRequests
                      .contains(requestId);

              return Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildAvatar(request),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  senderName,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                if (senderEmail
                                    .isNotEmpty) ...[
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    senderEmail,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        const TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child:
                                OutlinedButton(
                              onPressed:
                                  isProcessing
                                      ? null
                                      : () {
                                          _rejectRequest(
                                            requestId,
                                          );
                                        },
                              child:
                                  const Text(
                                'Reject',
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child:
                                FilledButton(
                              onPressed:
                                  isProcessing
                                      ? null
                                      : () {
                                          _acceptRequest(
                                            requestId,
                                            request,
                                          );
                                        },
                              child:
                                  isProcessing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
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
            },
          );
        },
      ),
    );
  }
}
