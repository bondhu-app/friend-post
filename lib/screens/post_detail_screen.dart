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

  bool _isDeleting = false;
  bool _isSharing = false;

  DocumentReference<Map<String, dynamic>>
      get _postReference => _firestore
          .collection('posts')
          .doc(widget.postId);

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _postStream => _postReference.snapshots();

  String _stringValue(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value is String &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  int _intValue(dynamic value) {
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

  Widget _buildAvatar(
    String name,
    String photoUrl,
  ) {
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
      backgroundColor:
          Theme.of(context)
              .colorScheme
              .primaryContainer,
      child: Text(
        firstLetter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer,
          fontSize: 20,
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
     
