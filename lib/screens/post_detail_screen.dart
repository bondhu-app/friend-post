import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/comment_section.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isLiking = false;
  bool _isDeleting = false;

  DocumentReference<Map<String, dynamic>>
      get _postReference {
    return _firestore
        .collection('posts')
        .doc(widget.postId);
  }

  Future<void> _toggleLike(
    Map<String, dynamic> postData,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    if (_isLiking) {
      return;
    }

    setState(() {
      _isLiking = true;
    });

    try {
      final likeReference =
          _postReference
              .collection('likes')
              .doc(user.uid);

      final likeDocument =
          await likeReference.get();

      final postDocument =
          await _postReference.get();

      if (!postDocument.exists) {
        _showMessage(
          'This post no longer exists.',
        );
        return;
      }

      final data =
          postDocument.data() ?? {};

      final currentLikes = _toInt(
        data['likeCount'] ??
            data['likes'],
      );

      if (likeDocument.exists) {
        await likeReference.delete();

        await _postReference.update({
          'likeCount':
              currentLikes > 0
                  ? currentLikes - 1
                  : 0,
          'likes':
              currentLikes > 0
                  ? currentLikes - 1
                  : 0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        await likeReference.set({
          'uid': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        await _postReference.update({
          'likeCount':
              currentLikes + 1,
          'likes':
              currentLikes + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not update like.',
      );
    } catch (e) {
      debugPrint(
        'Like error: $e',
      );

      _showMessage(
        'Could not update like.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  Future<void> _deletePost(
    Map<String, dynamic> postData,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final postUserId =
        (postData['uid'] ??
                postData['userId'] ??
                '')
            .toString();

    if (postUserId != user.uid) {
      _showMessage(
        'You can only delete your own post.',
      );
      return;
    }

    if (_isDeleting) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post',
          ),
          content: const Text(
            'Are you sure you want to delete this post?',
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

    setState(() {
      _isDeleting = true;
    });

    try {
      final comments =
          await _postReference
              .collection('comments')
              .get();

      for (final comment
          in comments.docs) {
        await comment.reference.delete();
      }

      final likes =
          await _postReference
              .collection('likes')
              .get();

      for (final like
          in likes.docs) {
        await like.reference.delete();
      }

      await _postReference.delete();

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'postCount':
              FieldValue.increment(-1),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint(
          'Post count update error: $e',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not delete post.',
      );
    } catch (e) {
      debugPrint(
        'Delete post error: $e',
      );

      _showMessage(
        'Could not delete post.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
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

  String _formatDate(
    dynamic value,
  ) {
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

  Widget _avatar(
    String photoUrl,
  ) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage:
            NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 24,
      child: Icon(
        Icons.person,
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream:
            _postReference.snapshots(),
        builder:
            (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(24),
                child: Text(
                  'Could not load this post.',
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

          final document =
              snapshot.data;

          if (document == null ||
              !document.exists) {
            return const Center(
              child: Text(
                'This post has been deleted.',
              ),
            );
          }

          final postData =
              document.data() ?? {};

          final user =
              _auth.currentUser;

          final postUserId =
              (postData['uid'] ??
                      postData['userId'] ??
                      '')
                  .toString();

          final isOwner =
              user != null &&
                  postUserId ==
                      user.uid;

          final name =
              (postData['userName'] ??
                      postData['name'] ??
                      'Friend')
                  .toString();

          final text =
              (postData['text'] ??
                      postData['content'] ??
                      '')
                  .toString();

          final photoUrl =
              (postData['photoUrl'] ??
                      '')
                  .toString();

          final imageUrl =
              (postData['imageUrl'] ??
                      '')
                  .toString();

          final likes =
              _toInt(
            postData['likeCount'] ??
                postData['likes'],
          );

          final comments =
              _toInt(
            postData['commentCount'],
          );

          final createdAt =
              postData['createdAt'];

          return Column(
            children: [
              Expanded(
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          _avatar(
                            photoUrl,
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  name,
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  _formatDate(
                                    createdAt,
                                  ),
                                  style:
                                      const TextStyle(
                                    fontSize:
                                        13,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOwner)
                            PopupMenuButton<
                                String>(
                              onSelected:
                                  (value) {
                                if (value ==
                                    'delete') {
                                  _deletePost(
                                    postData,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) {
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
                                              10,
                                        ),
                                        Text(
                                          'Delete Post',
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
                        height: 20,
                      ),

                      if (text.isNotEmpty)
                        Text(
                          text,
                          style:
                              const TextStyle(
                            fontSize: 18,
                            height: 1.45,
                          ),
                        ),

                      if (imageUrl
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 18,
                        ),
                        ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                          child:
                              Image.network(
                            imageUrl,
                            width:
                                double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const SizedBox(
                                height: 200,
                                child:
                                    Center(
                                  child: Icon(
                                    Icons
                                        .broken_image_outlined,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 18,
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            '$likes likes',
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          const Icon(
                            Icons
                                .comment_outlined,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            '$comments comments',
                          ),
                        ],
                      ),

                      const Divider(
                        height: 30,
                      ),

                      StreamBuilder<
                          DocumentSnapshot<
                              Map<String,
                                  dynamic>>>(
                        stream: user == null
                            ? null
                            : _postReference
                                .collection(
                                  'likes',
                                )
                                .doc(
                                  user.uid,
                                )
                                .snapshots(),
                        builder:
                            (
                          context,
                          likeSnapshot,
                        ) {
                          final liked =
                              likeSnapshot
                                  .data
                                  ?.exists ??
                                  false;

                          return SizedBox(
                            width:
                                double.infinity,
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  _isLiking
                                      ? null
                                      : () {
                                          _toggleLike(
                                            postData,
                                          );
                                        },
                              icon: Icon(
                                liked
                                    ? Icons
                                        .favorite
                                    : Icons
                                        .favorite_border,
                              ),
                              label: Text(
                                liked
                                    ? 'Liked'
                                    : 'Like',
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      CommentSection(
                        postId:
                            widget.postId,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
