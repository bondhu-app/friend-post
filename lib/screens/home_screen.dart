import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<void> _logout() async {
    await _auth.signOut();
  }

  Future<void> _openCreatePost() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildPostCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final authorName =
        (data['authorName'] ??
                data['name'] ??
                'Friend Post User')
            .toString();

    final text =
        (data['text'] ??
                data['content'] ??
                '')
            .toString();

    final likeCount =
        (data['likeCount'] ?? 0) as num;

    final commentCount =
        (data['commentCount'] ?? 0) as num;

    final timestamp = data['createdAt'];

    String dateText = '';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      dateText =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.person_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (dateText.isNotEmpty)
                        Text(
                          dateText,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  likeCount.toString(),
                ),
                const SizedBox(width: 22),
                const Icon(
                  Icons.comment_outlined,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  commentCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('posts')
          .where(
            'isDeleted',
            isEqualTo: false,
          )
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load posts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final documents =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

        if (documents.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 60,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
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

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            100,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return _buildPostCard(
              context,
              documents[index],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    final displayName =
        user?.displayName?.trim();

    final name =
        displayName != null &&
                displayName.isNotEmpty
            ? displayName
            : 'Friend Post User';

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
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              10,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  child: Icon(
                    Icons.person_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Welcome, $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildFeed(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Create Post',
        ),
      ),
    );
  }
}
