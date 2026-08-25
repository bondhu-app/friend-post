import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/data_service.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final DataService _dataService = DataService.instance;

  final TextEditingController _commentController =
      TextEditingController();

  bool _showComments = false;
  bool _working = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _data {
    return widget.post.data() ?? <String, dynamic>{};
  }

  String get _postId => widget.post.id;

  String get _userName {
    final value = _data['userName'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return 'Friend';
  }

  String get _text {
    final value = _data['text'];

    if (value is String) {
      return value;
    }

    return '';
  }

  String get _photoUrl {
    final value = _data['userPhotoUrl'];

    if (value is String) {
      return value;
    }

    return '';
  }

  String _timeText() {
    final timestamp = _data['createdAt'];

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'এইমাত্র';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} মিনিট আগে';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours} ঘণ্টা আগে';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays} দিন আগে';
      }

      return '${date.day}/${date.month}/${date.year}';
    }

    return 'এইমাত্র';
  }

  Future<void> _toggleLike() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await _dataService.likePost(_postId);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Like করা যায়নি: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _sharePost() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    try {
      await _dataService.sharePost(_postId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post শেয়ার করা হয়েছে।'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share করা যায়নি: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) {
      return;
    }

    try {
      await _dataService.addComment(
        postId: _postId,
        text: text,
      );

      _commentController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment করা যায়নি: $e'),
        ),
      );
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Post মুছে ফেলবেন?'),
          content: const Text(
            'এই পোস্টটি স্থায়ীভাবে মুছে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _dataService.deletePost(_postId);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post মুছে ফেলা যায়নি: $e'),
        ),
      );
    }
  }

  Widget _avatar() {
    if (_photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 23,
        backgroundImage: NetworkImage(_photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 23,
      child: Icon(Icons.person),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _dataService.currentUser?.uid;
    final postOwnerUid = _data['userId']?.toString();

    return Card(
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // POST HEADER
            // ======================================================

            Row(
              children: [
                _avatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _timeText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentUid != null &&
                    currentUid == postOwnerUid)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost();
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text('Delete Post'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ======================================================
            // POST TEXT
            // ======================================================

            if (_text.isNotEmpty)
              Text(
                _text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

            const SizedBox(height: 14),

            // ======================================================
            // COUNTS
            // ======================================================

            StreamBuilder<int>(
              stream: _dataService.likeCountStream(_postId),
              builder: (context, likeSnapshot) {
                final likeCount = likeSnapshot.data ?? 0;

                return StreamBuilder<int>(
                  stream: _dataService.commentCountStream(_postId),
                  builder: (context, commentSnapshot) {
                    final commentCount =
                        commentSnapshot.data ?? 0;

                    return StreamBuilder<int>(
                      stream: _dataService.shareCountStream(_postId),
                      builder: (context, shareSnapshot) {
                        final shareCount =
                            shareSnapshot.data ?? 0;

                        if (likeCount == 0 &&
                            commentCount == 0 &&
                            shareCount == 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              if (likeCount > 0) ...[
                                const Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 5),
                                Text('$likeCount'),
                              ],

                              const Spacer(),

                              if (commentCount > 0)
                                Text(
                                  '$commentCount comments',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                              if (commentCount > 0 &&
                                  shareCount > 0)
                                const SizedBox(width: 12),

                              if (shareCount > 0)
                                Text(
                                  '$shareCount shares',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const Divider(),

            // ======================================================
            // LIKE / COMMENT / SHARE
            // ======================================================

            Row(
              children: [
                // LIKE
                Expanded(
                  child: StreamBuilder<bool>(
                    stream: _dataService.likeStatusStream(_postId),
                    builder: (context, snapshot) {
                      final liked = snapshot.data ?? false;

                      return TextButton.icon(
                        onPressed:
                            _working ? null : _toggleLike,
                        icon: Icon(
                          liked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: liked
                              ? Colors.red
                              : Colors.grey.shade700,
                        ),
                        label: Text(
                          'Like',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: liked
                                ? Colors.red
                                : Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // COMMENT
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                    ),
                    label: const Text(
                      'Comment',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // SHARE
                Expanded(
                  child: StreamBuilder<bool>(
                    stream: _dataService.shareStatusStream(_postId),
                    builder: (context, snapshot) {
                      final shared = snapshot.data ?? false;

                      return TextButton.icon(
                        onPressed:
                            _working ? null : _sharePost,
                        icon: Icon(
                          Icons.share_outlined,
                          color: shared
                              ? Colors.green
                              : Colors.grey.shade700,
                        ),
                        label: Text(
                          'Share',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: shared
                                ? Colors.green
                                : Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ======================================================
            // COMMENTS
            // ======================================================

            if (_showComments) ...[
              const Divider(),

              StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _dataService.commentsStream(_postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final comments =
                      snapshot.data?.docs ?? [];

                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'এখনও কোনো Comment নেই।',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: comments.map((comment) {
                      final data = comment.data();

                      final name =
                          data['userName']?.toString() ??
                              'Friend';

                      final text =
                          data['text']?.toString() ?? '';

                      final userId =
                          data['userId']?.toString() ?? '';

                      final photo =
                          data['userPhotoUrl']?.toString() ??
                              '';

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (photo.isNotEmpty)
                              CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                    NetworkImage(photo),
                              )
                            else
                              const CircleAvatar(
                                radius: 18,
                                child: Icon(
                                  Icons.person,
                                  size: 20,
                                ),
                              ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Container(
                                padding:
                                    const EdgeInsets.all(10),
                                decoration: BoxDecoration(
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
                                            name,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        if (userId ==
                                            currentUid)
                                          InkWell(
                                            onTap: () async {
                                              try {
                                                await _dataService
                                                    .deleteComment(
                                                  postId: _postId,
                                                  commentId:
                                                      comment.id,
                                                );
                                              } catch (e) {
                                                if (!mounted) {
                                                  return;
                                                }

                                                ScaffoldMessenger
                                                    .of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Comment মুছতে সমস্যা: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Icon(
                                              Icons
                                                  .delete_outline,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      text,
                                      style:
                                          const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 8),

              // ====================================================
              // COMMENT INPUT
              // ====================================================

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Comment লিখুন...',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(22),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filled(
                    onPressed: _addComment,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
