import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _postController =
      TextEditingController();

  bool _isPosting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final text = _postController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please write something before posting.',
          ),
        ),
      );
      return;
    }

    if (text.length > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post is too long. Maximum 5000 characters.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final userDocument = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData =
          userDocument.data() ?? <String, dynamic>{};

      final name =
          (userData['name'] ??
                  user.displayName ??
                  'Friend Post User')
              .toString();

      final email =
          (userData['email'] ??
                  user.email ??
                  '')
              .toString();

      final photoUrl =
          (userData['photoUrl'] ?? '').toString();

      final postReference =
          _firestore.collection('posts').doc();

      final batch = _firestore.batch();

      batch.set(
        postReference,
        {
          'postId': postReference.id,
          'userId': user.uid,
          'authorId': user.uid,
          'authorName': name,
          'authorEmail': email,
          'authorPhotoUrl': photoUrl,
          'text': text,
          'content': text,
          'imageUrl': '',
          'likeCount': 0,
          'commentCount': 0,
          'shareCount': 0,
          'isDeleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      final userReference = _firestore
          .collection('users')
          .doc(user.uid);

      batch.set(
        userReference,
        {
          'postCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _postController.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post published successfully!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Could not publish the post.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
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
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    final displayName =
        user?.displayName?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          child: Icon(
                            Icons.person_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayName?.isNotEmpty == true
                                ? displayName!
                                : 'Friend Post User',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    TextField(
                      controller: _postController,
                      enabled: !_isPosting,
                      minLines: 7,
                      maxLines: 12,
                      maxLength: 5000,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'What are you thinking?',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.blue.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            color: Colors.blue,
                          ),
                        ),
                        title: const Text(
                          'Public post',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Your post can be viewed by other users.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _isPosting ? null : _createPost,
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
