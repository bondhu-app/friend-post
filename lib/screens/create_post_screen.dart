import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({
    super.key,
  });

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState
    extends State<CreatePostScreen> {
  final TextEditingController _postController =
      TextEditingController();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isPosting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text =
        _postController.text.trim();

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

    if (_isPosting) {
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

    final messenger =
        ScaffoldMessenger.of(context);

    setState(() {
      _isPosting = true;
    });

    try {
      final userReference = _firestore
          .collection('users')
          .doc(user.uid);

      final userSnapshot =
          await userReference.get();

      final userData =
          userSnapshot.data() ?? {};

      final userName =
          (userData['name'] ??
                  userData['userName'] ??
                  user.displayName ??
                  'Friend')
              .toString()
              .trim();

      final photoUrl =
          (userData['photoUrl'] ??
                  userData['profileImage'] ??
                  '')
              .toString()
              .trim();

      final postReference =
          _firestore.collection('posts').doc();

      await postReference.set({
        'postId': postReference.id,
        'uid': user.uid,
        'userId': user.uid,
        'ownerId': user.uid,
        'userName': userName.isEmpty
            ? 'Friend'
            : userName,
        'name': userName.isEmpty
            ? 'Friend'
            : userName,
        'userPhotoUrl': photoUrl,
        'photoUrl': photoUrl,
        'text': text,
        'content': text,
        'imageUrl': '',
        'image': '',
        'likeCount': 0,
        'commentCount': 0,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      _postController.clear();

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Post published successfully!',
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Could not publish the post.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not publish the post. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),
            child: FilledButton(
              onPressed: _isPosting
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
                      'Post',
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color: theme
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          theme
                              .colorScheme
                              .primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: theme
                            .colorScheme
                            .onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'Create a new post',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              TextField(
                controller:
                    _postController,
                minLines: 8,
                maxLines: 15,
                maxLength: 5000,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration:
                    InputDecoration(
                  hintText:
                      "What's on your mind?",
                  alignLabelWithHint:
                      true,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide(
                      color: theme
                          .colorScheme
                          .outline,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    borderSide:
                        BorderSide(
                      color: theme
                          .colorScheme
                          .primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      theme
                          .colorScheme
                          .surface,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: theme
                        .colorScheme
                        .outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.public,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Public post',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            'Anyone can see this post.',
                            style:
                                TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons
                          .check_circle,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isPosting
                      ? null
                      : _createPost,
                  icon: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                        ),
                  label: Text(
                    _isPosting
                        ? 'Publishing...'
                        : 'Publish Post',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Center(
                child: Text(
                  'Be respectful and kind to other users.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign:
                      TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
