import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/data_service.dart';
import '../../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService.instance;

  final TextEditingController _postController =
      TextEditingController();

  bool _posting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  String get _userName {
    final user = _dataService.currentUser;

    if (user == null) {
      return 'Friend';
    }

    final displayName = user.displayName;

    if (displayName != null &&
        displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    return 'Friend';
  }

  Future<void> _createPost() async {
    final text = _postController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আগে কিছু লিখুন।'),
        ),
      );
      return;
    }

    if (_posting) {
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

      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post সফলভাবে প্রকাশ হয়েছে।'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post করা যায়নি: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  void _openPostComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom +
                20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Post',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _postController,
                autofocus: true,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'What’s on your mind?',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _posting
                      ? null
                      : () async {
                          await _createPost();

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  icon: _posting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _posting
                        ? 'Publishing...'
                        : 'Publish Post',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _createPostBox() {
    return Card(
      margin: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        18,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'What’s on your mind?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  child: Icon(Icons.person),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: InkWell(
                    onTap: _openPostComposer,
                    borderRadius:
                        BorderRadius.circular(30),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade500,
                        ),
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Write something...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _openPostComposer,
                    icon: const Icon(
                      Icons.photo_outlined,
                    ),
                    label: const Text('Photo'),
                  ),
                ),

                Expanded(
                  child: TextButton.icon(
                    onPressed: _openPostComposer,
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                    ),
                    label: const Text('Feeling'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 38,
            child: Icon(
              Icons.person,
              size: 38,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content:
                      Text('Notifications শীঘ্রই আসছে।'),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _postsSection() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _dataService.postsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Post লোড করতে সমস্যা হয়েছে.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Card(
            margin: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              20,
            ),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 55,
                horizontal: 25,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.layers_clear_outlined,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No posts yet.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first person to create a post.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                12,
              ),
              child: Row(
                children: [
                  Text(
                    'Recent Posts',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.people_outline),
                  SizedBox(width: 6),
                  Text(
                    'Friends',
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),

            ...posts.map(
              (post) => PostCard(
                post: post,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(
              Icons.refresh,
              size: 30,
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future<void>.delayed(
            const Duration(milliseconds: 500),
          );
        },
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            _welcomeHeader(),
            _createPostBox(),
            _postsSection(),

            const SizedBox(height: 90),
          ],
        ),
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: _openPostComposer,
        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),
    );
  }
}
