import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _controller =
      TextEditingController();

  bool _isSending = false;

  CollectionReference<Map<String, dynamic>>
      get _commentsReference {
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final text =
        _controller.text.trim();

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
      String userName =
          user.displayName ?? 'Friend';

      String photoUrl =
          user.photoURL ?? '';

      try {
        final userDocument =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

        final userData =
            userDocument.data();

        if (userData != null) {
          final name =
              userData['name'];

          final savedPhoto =
              userData['photoUrl'];

          if (name != null &&
              name
                  .toString()
                  .trim()
                  .isNotEmpty) {
            userName =
                name.toString();
          }

          if (savedPhoto != null &&
              savedPhoto
                  .toString()
                  .trim()
                  .isNotEmpty) {
            photoUrl =
                savedPhoto.toString();
          }
        }
      } catch (e) {
        debugPrint(
          'User data error: $e',
        );
      }

      final comment =
          _commentsReference.doc();

      await comment.set({
        'commentId':
            comment.id,
        'postId':
            widget.postId,
        'uid':
            user.uid,
        'userId':
            user.uid,
        'userName':
            userName,
        'name':
            userName,
        'photoUrl':
            photoUrl,
        'text':
            text,
        'content':
            text,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      await _postReference.update({
        'commentCount':
            FieldValue.increment(1),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      _controller.clear();
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not add comment.',
      );
    } catch (e) {
      debugPrint(
        'Send comment error: $e',
      );

      _showMessage(
        'Could not add comment.',
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
    DocumentSnapshot<
            Map<String, dynamic>>
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

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Delete Comment'),
          content: const Text(
            'Are you sure you want to delete this comment?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await comment.reference.delete();

      try {
        await _postReference.update({
          'commentCount':
              FieldValue.increment(-1),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint(
          'Comment count update error: $e',
        );
      }
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not delete comment.',
      );
    } catch (e) {
      debugPrint(
        'Delete comment error: $e',
      );

      _showMessage(
        'Could not delete comment.',
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Just now';
    }

    final date =
        value.toDate();

    final difference =
        DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
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
        size: 21,
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
  Widget build(
    BuildContext context,
  ) {
    final user =
        _auth.currentUser;

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

        StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: _commentsReference
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
              return const Padding(
                padding:
                    EdgeInsets.all(16),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              );
            }

            final comments =
                snapshot.data?.docs ?? [];

            if (comments.isEmpty) {
              return const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 18,
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

            return Column(
              children: comments
                  .map(
                    (comment) {
                  final data =
                      comment.data();

                  final name =
                      (data['userName'] ??
                              data['name'] ??
                              'Friend')
                          .toString();

                  final text =
                      (data['text'] ??
                              data['content'] ??
                              '')
                          .toString();

                  final photoUrl =
                      (data['photoUrl'] ??
                              '')
                          .toString();

                  final uid =
                      (data['uid'] ??
                              data['userId'] ??
                              '')
                          .toString();

                  final createdAt =
                      data['createdAt'];

                  final isOwner =
                      user != null &&
                          uid == user.uid;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        _avatar(
                          photoUrl,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Container(
                            padding:
                                const EdgeInsets
                                    .all(
                              12,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          Text(
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
                                        icon:
                                            const Icon(
                                          Icons
                                              .more_horiz,
                                          size: 20,
                                        ),
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
                                                    Icons.delete_outline,
                                                  ),
                                                  SizedBox(
                                                    width: 8,
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
                                    fontSize:
                                        15,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  _formatDate(
                                    createdAt,
                                  ),
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        11,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            if (user != null)
              const CircleAvatar(
                radius: 20,
                child: Icon(
                  Icons.person,
                  size: 21,
                ),
              ),

            if (user != null)
              const SizedBox(
                width: 8,
              ),

            Expanded(
              child: TextField(
                controller:
                    _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    InputDecoration(
                  hintText:
                      'Write a comment...',
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) {
                  if (!_isSending) {
                    _sendComment();
                  }
                },
              ),
            ),

            const SizedBox(width: 5),

            IconButton(
              onPressed:
                  _isSending
                      ? null
                      : _sendComment,
              tooltip:
                  'Send comment',
              icon: _isSending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons
                          .send_rounded,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
