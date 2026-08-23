import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class CommentSection extends StatefulWidget {
  final String postId;

  const CommentSection({
    super.key,
    required this.postId,
  });

  @override
  State<CommentSection> createState() =>
      _CommentSectionState();
}

class _CommentSectionState
    extends State<CommentSection> {
  final TextEditingController _commentController =
      TextEditingController();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isSending = false;

  CollectionReference<Map<String, dynamic>>
      get _comments {
    return _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments');
  }

  DocumentReference<Map<String, dynamic>>
      get _postReference {
    return _firestore
        .collection('posts')
        .doc(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final text =
        _commentController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final postSnapshot =
          await _postReference.get();

      if (!postSnapshot.exists) {
        _showMessage(
          'This post no longer exists.',
        );
        return;
      }

      final postData =
          postSnapshot.data() ?? {};

      final postOwnerId =
          (postData['uid'] ??
                  postData['userId'] ??
                  '')
              .toString();

      final comment =
          _comments.doc();

      await comment.set({
        'commentId': comment.id,
        'uid': user.uid,
        'userId': user.uid,
        'userName':
            user.displayName ?? 'Friend',
        'userPhotoUrl': '',
        'text': text,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      final currentCount =
          _toInt(
        postData['commentCount'],
      );

      await _postReference.update({
        'commentCount':
            currentCount + 1,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (postOwnerId.isNotEmpty &&
          postOwnerId != user.uid) {
        await NotificationService.instance
            .notifyComment(
          postOwnerId: postOwnerId,
          postId: widget.postId,
          commentId: comment.id,
        );
      }

      _commentController.clear();

      if (!mounted) return;

      FocusScope.of(context).unfocus();
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not send comment.',
      );
    } catch (e) {
      debugPrint(
        'Send comment error: $e',
      );

      _showMessage(
        'Could not send comment.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteComment(
    DocumentSnapshot<Map<String, dynamic>>
        comment,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final data = comment.data();

    if (data == null) {
      return;
    }

    final commentUserId =
        (data['uid'] ??
                data['userId'] ??
                '')
            .toString();

    if (commentUserId != user.uid) {
      _showMessage(
        'You can only delete your own comment.',
      );
      return;
    }

    try {
      await comment.reference.delete();

      final postSnapshot =
          await _postReference.get();

      if (postSnapshot.exists) {
        final postData =
            postSnapshot.data() ?? {};

        final currentCount =
            _toInt(
          postData['commentCount'],
        );

        await _postReference.update({
          'commentCount':
              currentCount > 0
                  ? currentCount - 1
                  : 0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint(
        'Delete comment error: $e',
      );

      _showMessage(
        'Could not delete comment.',
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Just now';
    }

    final date = value.toDate();

    final difference =
        DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _avatar(String photoUrl) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage:
            NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 20,
      child: Icon(
        Icons.person,
        size: 20,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (user != null)
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const CircleAvatar(
                radius: 20,
                child: Icon(
                  Icons.person,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: TextField(
                  controller:
                      _commentController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction:
                      TextInputAction.newline,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Write a comment...',
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              IconButton.filled(
                onPressed:
                    _isSending
                        ? null
                        : _sendComment,
                tooltip: 'Send comment',
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                      ),
              ),
            ],
          ),

        const SizedBox(height: 18),

        StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _comments
              .orderBy(
                'createdAt',
                descending: false,
              )
              .snapshots(),
          builder:
              (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding:
                    EdgeInsets.all(16),
                child: Text(
                  'Could not load comments.',
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

            final comments =
                snapshot.data?.docs ?? [];

            if (comments.isEmpty) {
              return const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Center(
                  child: Text(
                    'No comments yet.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder:
                  (context, index) {
                return const SizedBox(
                  height: 10,
                );
              },
              itemBuilder:
                  (context, index) {
                final comment =
                    comments[index];

                final data =
                    comment.data();

                final name =
                    (data['userName'] ??
                            data['name'] ??
                            'Friend')
                        .toString();

                final photoUrl =
                    (data['userPhotoUrl'] ??
                            data['photoUrl'] ??
                            '')
                        .toString();

                final text =
                    (data['text'] ??
                            data['comment'] ??
                            '')
                        .toString();

                final commentUserId =
                    (data['uid'] ??
                            data['userId'] ??
                            '')
                        .toString();

                final isOwner =
                    user != null &&
                        user.uid ==
                            commentUserId;

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _avatar(photoUrl),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  if (isOwner)
                                    PopupMenuButton<
                                        String>(
                                      padding:
                                          EdgeInsets.zero,
                                      onSelected:
                                          (value) {
                                        if (value ==
                                            'delete') {
                                          _deleteComment(
                                            comment,
                                          );
                                        }
                                      },
                                      itemBuilder:
                                          (
                                        context,
                                      ) {
                                        return const [
                                          PopupMenuItem(
                                            value:
                                                'delete',
                                            child:
                                                Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .delete_outline,
                                                ),
                                                SizedBox(
                                                  width:
                                                      8,
                                                ),
                                                Text(
                                                  'Delete',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ];
                                      },
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                text,
                                style:
                                    const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                _formatDate(
                                  data['createdAt'],
                                ),
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
