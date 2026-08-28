import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/data_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService();

  final TextEditingController _postController =
      TextEditingController();

  bool _posting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text = _postController.text.trim();

    if (text.isEmpty) {
      _showMessage('পোস্ট লিখুন।');
      return;
    }

    setState(() {
      _posting = true;
    });

    try {
      await _dataService.createPost(
        text: text,
      );

      _postController.clear();

      if (!mounted) return;

      _showMessage('পোস্ট সফলভাবে প্রকাশ হয়েছে।');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'পোস্ট প্রকাশ করা যায়নি। আবার চেষ্টা করুন।',
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friend Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildCreatePostCard(user),
            const SizedBox(height: 12),
            _buildFeed(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostCard(User? user) {
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email ?? 'আপনি';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _postController,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'আপনার মনে কী আছে?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _posting ? null : _createPost,
                icon: _posting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _posting ? 'প্রকাশ হচ্ছে...' : 'পোস্ট করুন',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _dataService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'পোস্ট লোড করা যায়নি।',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 60,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'এখনো কোনো পোস্ট নেই।',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'প্রথম পোস্টটি আপনিই করুন!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                dataService: _dataService,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> post;
  final DataService dataService;

  const PostCard({
    super.key,
    required this.post,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    final data = post.data();

    final String userName =
        data['userName']?.toString() ?? 'Friend Post User';

    final String text =
        data['text']?.toString() ?? '';

    final List<String> likes =
        List<String>.from(data['likes'] ?? []);

    final int likeCount =
        (data['likeCount'] as num?)?.toInt() ?? likes.length;

    final int commentCount =
        (data['commentCount'] as num?)?.toInt() ?? 0;

    final String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    final bool liked = likes.contains(currentUserId);

    final Timestamp? timestamp =
        data['createdAt'] as Timestamp?;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(timestamp),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                if (data['userId'] ==
                    currentUserId)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await dataService.deletePost(
                          post.id,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline),
                            SizedBox(width: 8),
                            Text('পোস্ট মুছুন'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await dataService.toggleLike(
                        postId: post.id,
                        currentLikes: likes,
                      );
                    },
                    icon: Icon(
                      liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: Text(
                      likeCount.toString(),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) {
                          return CommentsSheet(
                            postId: post.id,
                            dataService: dataService,
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.comment_outlined,
                    ),
                    label: Text(
                      commentCount.toString(),
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

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'এইমাত্র';
    }

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
}

class CommentsSheet extends StatefulWidget {
  final String postId;
  final DataService dataService;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.dataService,
  });

  @override
  State<CommentsSheet> createState() =>
      _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController =
      TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await widget.dataService.addComment(
        postId: widget.postId,
        text: text,
      );

      _commentController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কমেন্ট করা যায়নি।'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'কমেন্ট',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.dataService
                    .getComments(widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'কমেন্ট লোড করা যায়নি।',
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final comments =
                      snapshot.data?.docs ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'এখনো কোনো কমেন্ট নেই।',
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data =
                          comments[index].data();

                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          data['userName']?.toString() ??
                              'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['text']?.toString() ?? '',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        textInputAction:
                            TextInputAction.send,
                        onSubmitted: (_) =>
                            _sendComment(),
                        decoration:
                            const InputDecoration(
                          hintText: 'কমেন্ট লিখুন...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed:
                          _sending ? null : _sendComment,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
