import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _textController =
      TextEditingController();

  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text =
        _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please write something first.',
          ),
        ),
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please login first.',
          ),
        ),
      );
      return;
    }

    if (_isPosting) {
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      String userName =
          user.displayName ?? 'Friend';

      String photoUrl = '';

      try {
        final userDoc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

        final userData =
            userDoc.data();

        if (userData != null) {
          final savedName =
              userData['name'];

          final savedPhoto =
              userData['photoUrl'];

          if (savedName != null &&
              savedName
                  .toString()
                  .trim()
                  .isNotEmpty) {
            userName =
                savedName.toString();
          }

          if (savedPhoto != null) {
            photoUrl =
                savedPhoto.toString();
          }
        }
      } catch (e) {
        debugPrint(
          'Could not load user data: $e',
        );
      }

      final postRef =
          _firestore
              .collection('posts')
              .doc();

      await postRef.set({
        'postId': postRef.id,
        'uid': user.uid,
        'userId': user.uid,
        'userName': userName,
        'name': userName,
        'photoUrl': photoUrl,
        'text': text,
        'content': text,
        'imageUrl': '',
        'likeCount': 0,
        'commentCount': 0,
        'likes': 0,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'postCount':
              FieldValue.increment(1),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint(
          'Could not update post count: $e',
        );
      }

      if (!mounted) return;

      _textController.clear();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Post published successfully!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Could not publish the post.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not publish the post. Please try again.',
          ),
        ),
      );

      debugPrint(
        'Create post error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _showPostOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_outlined,
                ),
                title: const Text(
                  'Add photo',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Photo upload will be added next.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.emoji_emotions_outlined,
                ),
                title: const Text(
                  'Add feeling',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Feeling feature will be added next.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                ),
                title: const Text(
                  'Add location',
                ),
                onTap: () {
                  Navigator.of(
                    sheetContext,
                  ).pop();

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Location feature will be added next.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 8,
            ),
            child: TextButton(
              onPressed:
                  _isPosting
                      ? null
                      : _createPost,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'POST',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              user?.photoURL !=
                                      null
                                  ? NetworkImage(
                                      user!.photoURL!,
                                    )
                                  : null,
                          child:
                              user?.photoURL ==
                                      null
                                  ? const Icon(
                                      Icons.person,
                                    )
                                  : null,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            user?.displayName
                                    ?.trim()
                                    .isNotEmpty ==
                                true
                                ? user!
                                    .displayName!
                                : 'Friend',
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextField(
                      controller:
                          _textController,
                      autofocus: true,
                      maxLines: null,
                      minLines: 8,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'What\'s on your mind?',
                        border:
                            InputBorder.none,
                        hintStyle:
                            TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      style:
                          const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration:
                  BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    )
                        .dividerColor,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            TextButton.icon(
                          onPressed:
                              _isPosting
                                  ? null
                                  : _showPostOptions,
                          icon: const Icon(
                            Icons
                                .add_circle_outline,
                          ),
                          label: const Text(
                            'Add to post',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _isPosting
                                ? null
                                : _createPost,
                        tooltip:
                            'Publish post',
                        icon: const Icon(
                          Icons.send_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
