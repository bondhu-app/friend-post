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

  String _userName = 'Friend';
  String _userPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      if (!mounted) return;

      setState(() {
        _userName = (data?['name'] ??
                user.displayName ??
                'Friend')
            .toString();

        _userPhotoUrl =
            (data?['photoUrl'] ?? '')
                .toString();
      });
    } catch (e) {
      debugPrint(
        'Load user data error: $e',
      );

      if (!mounted) return;

      setState(() {
        _userName =
            user.displayName ?? 'Friend';

        _userPhotoUrl =
            user.photoURL ?? '';
      });
    }
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    final text =
        _textController.text.trim();

    if (text.isEmpty) {
      _showMessage(
        'Please write something first.',
      );
      return;
    }

    if (_isPosting) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isPosting = true;
    });

    try {
      final postReference =
          _firestore
              .collection('posts')
              .doc();

      await postReference.set({
        'postId':
            postReference.id,

        'uid':
            user.uid,

        'userId':
            user.uid,

        'userName':
            _userName,

        'name':
            _userName,

        'photoUrl':
            _userPhotoUrl,

        'text':
            text,

        'content':
            text,

        'imageUrl':
            '',

        'likeCount':
            0,

        'likes':
            0,

        'commentCount':
            0,

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
          'Post count update error: $e',
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      _showMessage(
        e.message ??
            'Could not create post.',
      );
    } catch (e) {
      debugPrint(
        'Create post error: $e',
      );

      _showMessage(
        'Could not create post. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_userPhotoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage:
            NetworkImage(_userPhotoUrl),
      );
    }

    return const CircleAvatar(
      radius: 25,
      child: Icon(
        Icons.person,
        size: 28,
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
              right: 10,
            ),
            child: FilledButton(
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
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Text(
                      _userName,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              TextField(
                controller:
                    _textController,
                autofocus: true,
                minLines: 7,
                maxLines: 15,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                decoration:
                    const InputDecoration(
                  hintText:
                      'What\'s on your mind?',
                  border:
                      InputBorder.none,
                ),
                style:
                    const TextStyle(
                  fontSize: 20,
                  height: 1.45,
                ),
              ),

              const Divider(
                height: 30,
              ),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const Icon(
                        Icons
                            .photo_outlined,
                      ),
                      title: const Text(
                        'Photo / Video',
                      ),
                      subtitle:
                          const Text(
                        'Photo upload will be added next.',
                      ),
                      onTap: () {
                        _showMessage(
                          'Photo upload will be added next.',
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading:
                          const Icon(
                        Icons
                            .emoji_emotions_outlined,
                      ),
                      title: const Text(
                        'Feeling / Activity',
                      ),
                      onTap: () {
                        _showMessage(
                          'Feeling feature will be added next.',
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                    ),
                    ListTile(
                      leading:
                          const Icon(
                        Icons
                            .location_on_outlined,
                      ),
                      title: const Text(
                        'Check in',
                      ),
                      onTap: () {
                        _showMessage(
                          'Check-in feature will be added next.',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isPosting
                          ? null
                          : _createPost,
                  icon: const Icon(
                    Icons.send_rounded,
                  ),
                  label: _isPosting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Publish Post',
                          style:
                              TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
