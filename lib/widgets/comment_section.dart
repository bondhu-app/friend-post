import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class CommentSection extends StatefulWidget {
  const CommentSection({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  State<CommentSection> createState() =>
      _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController =
      TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>
      get _comments => _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments');

  Future<void> _sendComment() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final text = _commentController.text.trim();

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
      final postReference = _firestore
          .collection('posts')
          .doc(widget.postId);

      final postSnapshot =
          await postReference.get();

      if (!postSnapshot.exists) {
        _showMessage('Post not found.');
        return;
      }

      final postData =
          postSnapshot.data() ?? <String, dynamic>{};

      final postOwnerId =
          (postData['uid'] ??
                  postData['userId'] ??
                  postData['ownerId'] ??
                  '')
              .toString();

      final userName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Friend';

      final commentReference =
          _comments.doc();

      final commentData = <String, dynamic>{
        'commentId': commentReference.id,
        'postId': widget.postId,
        'userId': user.uid,
        'uid': user.uid,
        'userName': userName,
        'userPhotoUrl': '',
        'photoUrl': '',
        'text': text,
        'content': text,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      final currentCommentCount =
          _toInt(postData['commentCount']);

      final batch =
          _firestore.batch();

      batch.set(
        commentReference,
        commentData,
      );

      batch.update(
        postReference,
        {
          'commentCount':
              currentCommentCount + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _commentController.clear();

      // ----------------------------------------------------------
      // COMMENT NOTIFICATION
      // ----------------------------------------------------------
      // নিজের পোস্টে নিজে কমেন্ট করলে notification যাবে না।
      if (postOwnerId.isNotEmpty &&
          postOwnerId != user.uid) {
        try {
          await NotificationService.instance
              .notifyComment(
            receiverId: postOwnerId,
            senderId: user.uid,
            senderName: userName,
            commentText: text,
          );
        } catch (e) {
          // Notification ব্যর্থ হলেও comment সফল থাকবে।
          debugPrint(
            'Comment notification error: $e',
          );
        }
      }

      if (!mounted) {
        return;
      }

      _showMessage('Comment added.');
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not add your comment.',
      );
    } catch (e) {
      debugPrint(
        'Add comment error: $e',
      );

      _showMessage(
        'Could not add your comment. Please try again.',
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
    String commentId,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final commentReference =
          _comments.doc(commentId);

      final commentSnapshot =
          await commentReference.get();

      if (!commentSnapshot.exists) {
        return;
      }

      final commentData =
          commentSnapshot.data() ??
              <String, dynamic>{};

      final commentUserId =
          (commentData['userId'] ??
                  commentData['uid'] ??
                  '')
              .toString();

      if (commentUserId != user.uid) {
        _showMessage(
          'You can only delete your own comment.',
        );
        return;
      }

      final postReference = _firestore
          .collection('posts')
          .doc(widget.postId);

      final postSnapshot =
          await postReference.get();

      final postData =
          postSnapshot.data() ??
              <String, dynamic>{};

      final currentCommentCount =
          _toInt(
        postData['commentCount'],
      );

      final batch =
          _firestore.batch();

      batch.delete(
        commentReference,
      );

      if (postSnapshot.exists) {
        batch.update(
          postReference,
          {
            'commentCount':
                currentCommentCount > 0
                    ? currentCommentCount - 1
                    : 0,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      _showMessage('Comment deleted.');
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not delete the comment.',
      );
    } catch (e) {
      debugPrint(
        'Delete comment error: $e',
      );

      _showMessage(
        'Could not delete the comment.',
      );
    }
  }

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

  Widget _buildAvatar(
    String photoUrl,
  ) {
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
        size: 22,
      ),
    );
  }

  Widget _buildComment(
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data =
        document.data() ??
            <String, dynamic>{};

    final currentUser =
        _auth.currentUser;

    final userId =
        (data['userId'] ??
                data['uid'] ??
                '')
            .toString();

    final userName =
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
                data['content'] ??
                '')
            .toString();

    final createdAt =
        data['createdAt'];

    final canDelete =
        currentUser != null &&
            currentUser.uid == userId;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildAvatar(photoUrl),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.all(12),
              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      if (canDelete)
                        PopupMenuButton<String>(
                          padding:
                              EdgeInsets.zero,
                          iconSize: 20,
                          onSelected:
                              (value) {
                            if (value ==
                                'delete') {
                              _deleteComment(
                                document.id,
                              );
                            }
                          },
                          itemBuilder:
                              (context) {
                            return const [
                              PopupMenuItem<
                                  String>(
                                value:
                                    'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons
                                          .delete_outline,
                                      size: 20,
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
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    _formatDate(
                      createdAt,
                    ),
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream: _comments
              .orderBy(
                'createdAt',
                descending: true,
              )
              .snapshots(),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.hasError) {
              debugPrint(
                'Comments stream error: '
                '${snapshot.error}',
              );

              return const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Text(
                  'Could not load comments.',
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 20,
                ),
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
                  ),
                ),
              );
            }

            return Column(
              children: comments
                  .map(
                    _buildComment,
                  )
                  .toList(),
            );
          },
        ),

        const SizedBox(
          height: 8,
        ),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller:
                    _commentController,
                minLines: 1,
                maxLines: 4,
                textInputAction:
                    TextInputAction.newline,
                enabled: !_isSending,
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

            const SizedBox(
              width: 8,
            ),

            SizedBox(
              height: 52,
              width: 52,
              child: IconButton(
                onPressed: _isSending
                    ? null
                    : _sendComment,
                style:
                    IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context)
                          .colorScheme
                          .primary,
                  foregroundColor:
                      Theme.of(context)
                          .colorScheme
                          .onPrimary,
                ),
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
                        Icons.send_rounded,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
