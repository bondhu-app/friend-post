import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/like_service.dart';
import '../widgets/comment_section.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isSharing = false;
  bool _isDeleting = false;

  DocumentReference<Map<String, dynamic>>
      get _postReference => _firestore
          .collection('posts')
          .doc(widget.postId);

  String _getString(
    Map<String, dynamic> data,
    List<String> keys, {
    String defaultValue = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value is String &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return defaultValue;
  }

  int _getInt(dynamic value) {
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

  Widget _buildAvatar({
    required String name,
    required String photoUrl,
  }) {
    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage:
            NetworkImage(photoUrl),
      );
    }

    final firstLetter =
        name.trim().isNotEmpty
            ? name.trim()[0].toUpperCase()
            : 'F';

    return CircleAvatar(
      radius: 24,
      child: Text(
        firstLetter,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    try {
      await LikeService.instance.toggleLike(
        postId: widget.postId,
      );
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not update like.',
      );
    } catch (e) {
      debugPrint(
        'Toggle like error: $e',
      );

      _showMessage(
        'Could not update like.',
      );
    }
  }

  Future<void> _sharePost() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    if (_isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      await DataService.instance.sharePost(
        widget.postId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Post shared successfully.',
      );
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not share post.',
      );
    } catch (e) {
      debugPrint(
        'Share post error: $e',
      );

      _showMessage(
        'Could not share post.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _deletePost() async {
    final user = _auth.currentUser;

    if (user == null) {
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
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Delete',
              ),
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
      final postSnapshot =
          await _postReference.get();

      if (!postSnapshot.exists) {
        _showMessage(
          'Post not found.',
        );
        return;
      }

      final data =
          postSnapshot.data() ??
              <String, dynamic>{};

      final ownerId = _getString(
        data,
        [
          'userId',
          'uid',
          'ownerId',
        ],
      );

      if (ownerId != user.uid) {
        _showMessage(
          'You can only delete your own post.',
        );
        return;
      }

      await DataService.instance.deletePost(
        widget.postId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Post deleted.',
      );

      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ?? 'Could not delete post.',
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

  Widget _buildPostContent(
    Map<String, dynamic> data,
  ) {
    final user =
        _auth.currentUser;

    final ownerId = _getString(
      data,
      [
        'userId',
        'uid',
        'ownerId',
      ],
    );

    final userName = _getString(
      data,
      [
        'userName',
        'name',
        'authorName',
      ],
      defaultValue: 'Friend',
    );

    final photoUrl = _getString(
      data,
      [
        'userPhotoUrl',
        'photoUrl',
        'authorPhotoUrl',
      ],
    );

    final text = _getString(
      data,
      [
        'text',
        'content',
        'description',
      ],
    );

    final imageUrl = _getString(
      data,
      [
        'imageUrl',
        'mediaUrl',
      ],
    );

    final createdAt =
        data['createdAt'];

    final likeCount = _getInt(
      data['likeCount'],
    );

    final commentCount = _getInt(
      data['commentCount'],
    );

    final shareCount = _getInt(
      data['shareCount'],
    );

    final isOwner =
        user != null &&
            user.uid == ownerId;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(
                      name: userName,
                      photoUrl: photoUrl,
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
                            userName,
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
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
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      PopupMenuButton<String>(
                        onSelected:
                            (value) {
                          if (value ==
                              'delete') {
                            _deletePost();
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
                                  ),
                                  SizedBox(
                                    width: 8,
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
                  height: 18,
                ),

                if (text.isNotEmpty)
                  Text(
                    text,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      height: 1.5,
                    ),
                  ),

                if (imageUrl.isNotEmpty)
                  const SizedBox(
                    height: 14,
                  ),

                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    child: Image.network(
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
                        return Container(
                          width:
                              double.infinity,
                          height: 200,
                          alignment:
                              Alignment.center,
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
                          child:
                              const Text(
                            'Image unavailable',
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(
                  height: 16,
                ),

                Row(
                  children: [
                    Text(
                      '$likeCount likes',
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      '$commentCount comments',
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      '$shareCount shares',
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                const Divider(
                  height: 1,
                ),

                const SizedBox(
                  height: 6,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          StreamBuilder<bool>(
                        stream:
                            LikeService
                                .instance
                                .likedStream(
                          widget.postId,
                        ),
                        builder:
                            (
                          context,
                          snapshot,
                        ) {
                          final isLiked =
                              snapshot.data ??
                                  false;

                          return TextButton.icon(
                            onPressed:
                                user == null
                                    ? null
                                    : _toggleLike,
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons
                                      .favorite_border,
                              color: isLiked
                                  ? Colors.red
                                  : null,
                            ),
                            label: Text(
                              isLiked
                                  ? 'Liked'
                                  : 'Like',
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child:
                          TextButton.icon(
                        onPressed: () {},
                        icon:
                            const Icon(
                          Icons
                              .comment_outlined,
                        ),
                        label:
                            const Text(
                          'Comment',
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          TextButton.icon(
                        onPressed:
                            _isSharing
                                ? null
                                : _sharePost,
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .share_outlined,
                              ),
                        label:
                            const Text(
                          'Share',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        CommentSection(
          postId: widget.postId,
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (widget.postId.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Post',
          ),
        ),
        body: const Center(
          child: Text(
            'Invalid post.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<
              Map<String, dynamic>>>(
        stream: _postReference.snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not load post.',
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
                'Post not found.',
              ),
            );
          }

          final data =
              document.data();

          if (data == null) {
            return const Center(
              child: Text(
                'Post data unavailable.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _postReference.get();
            },
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(16),
              children: [
                _buildPostContent(
                  data,
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
