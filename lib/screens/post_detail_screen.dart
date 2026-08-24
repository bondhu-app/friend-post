import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/comment_section.dart';
import '../widgets/like_button.dart';

class PostDetailScreen extends StatelessWidget {
  PostDetailScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _loadPost() {
    return _firestore
        .collection('posts')
        .doc(postId)
        .get();
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

  Widget _buildAvatar(String photoUrl) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        future: _loadPost(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load this post.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final document = snapshot.data;

          if (document == null ||
              !document.exists) {
            return const Center(
              child: Text(
                'Post not found.',
              ),
            );
          }

          final data =
              document.data() ?? {};

          final postIdValue = document.id;

          final userName =
              (data['userName'] ??
                      data['name'] ??
                      'Friend')
                  .toString();

          final userPhotoUrl =
              (data['userPhotoUrl'] ??
                      data['photoUrl'] ??
                      '')
                  .toString();

          final text =
              (data['text'] ??
                      data['content'] ??
                      data['description'] ??
                      '')
                  .toString();

          final imageUrl =
              (data['imageUrl'] ??
                      data['image'] ??
                      '')
                  .toString();

          final createdAt =
              data['createdAt'];

          final commentCount =
              _toInt(
            data['commentCount'],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Card(
                  clipBehavior:
                      Clip.antiAlias,
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
                              userPhotoUrl,
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
                                    userName,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 16,
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
                          ],
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        if (text.isNotEmpty)
                          Text(
                            text,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),

                        if (text.isNotEmpty &&
                            imageUrl.isNotEmpty)
                          const SizedBox(
                            height: 14,
                          ),

                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              12,
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
                                  height: 220,
                                  alignment:
                                      Alignment.center,
                                  child:
                                      const Icon(
                                    Icons
                                        .broken_image_outlined,
                                    size: 50,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress ==
                                    null) {
                                  return child;
                                }

                                return Container(
                                  width:
                                      double.infinity,
                                  height: 220,
                                  alignment:
                                      Alignment.center,
                                  child:
                                      const CircularProgressIndicator(),
                                );
                              },
                            ),
                          ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Divider(),

                        Row(
                          children: [
                            LikeButton(
                              postId:
                                  postIdValue,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              '$commentCount comments',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: CommentSection(
                      postId: postIdValue,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
}
