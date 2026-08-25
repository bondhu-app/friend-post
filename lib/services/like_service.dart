import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class LikeService {
  LikeService._();

  static final LikeService instance = LikeService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  Future<bool> isLiked(String postId) async {
    final user = _auth.currentUser;

    if (user == null || postId.isEmpty) {
      return false;
    }

    final like = await _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .get();

    return like.exists;
  }

  Stream<bool> likedStream(String postId) {
    final user = _auth.currentUser;

    if (user == null || postId.isEmpty) {
      return Stream<bool>.value(false);
    }

    return _posts
        .doc(postId)
        .collection('likes')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<int> likeCountStream(String postId) {
    if (postId.isEmpty) {
      return Stream<int>.value(0);
    }

    return _posts
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      final value = data['likeCount'];

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
    });
  }

  Future<void> toggleLike({
    required String postId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Please login first.',
      );
    }

    if (postId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Invalid post ID.',
      );
    }

    final postReference = _posts.doc(postId);

    final likeReference = postReference
        .collection('likes')
        .doc(user.uid);

    final postSnapshot = await postReference.get();

    if (!postSnapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Post not found.',
      );
    }

    final postData = postSnapshot.data() ?? <String, dynamic>{};

    final ownerId = (
      postData['uid'] ??
      postData['userId'] ??
      postData['ownerId'] ??
      ''
    ).toString();

    final likeSnapshot = await likeReference.get();

    final batch = _firestore.batch();

    final currentLikeCount =
        _toInt(postData['likeCount']);

    if (likeSnapshot.exists) {
      batch.delete(likeReference);

      batch.update(
        postReference,
        {
          'likeCount':
              currentLikeCount > 0
                  ? currentLikeCount - 1
                  : 0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    } else {
      batch.set(
        likeReference,
        {
          'uid': user.uid,
          'userId': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        postReference,
        {
          'likeCount': currentLikeCount + 1,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();

    // নতুন Like হলে পোস্ট মালিককে notification পাঠানো হবে।
    if (!likeSnapshot.exists &&
        ownerId.isNotEmpty &&
        ownerId != user.uid) {
      final senderName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Friend';

      await NotificationService.instance.notifyLike(
        receiverId: ownerId,
        senderId: user.uid,
        senderName: senderName,
        postId: postId,
      );
    }
  }

  Future<void> like({
    required String postId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Please login first.',
      );
    }

    if (postId.isEmpty) {
      return;
    }

    final postReference = _posts.doc(postId);

    final likeReference = postReference
        .collection('likes')
        .doc(user.uid);

    final likeSnapshot = await likeReference.get();

    if (likeSnapshot.exists) {
      return;
    }

    final postSnapshot = await postReference.get();

    if (!postSnapshot.exists) {
      return;
    }

    final postData =
        postSnapshot.data() ?? <String, dynamic>{};

    final ownerId = (
      postData['uid'] ??
      postData['userId'] ??
      postData['ownerId'] ??
      ''
    ).toString();

    final currentLikeCount =
        _toInt(postData['likeCount']);

    final batch = _firestore.batch();

    batch.set(
      likeReference,
      {
        'uid': user.uid,
        'userId': user.uid,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      postReference,
      {
        'likeCount': currentLikeCount + 1,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    if (ownerId.isNotEmpty &&
        ownerId != user.uid) {
      final senderName =
          user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Friend';

      await NotificationService.instance.notifyLike(
        receiverId: ownerId,
        senderId: user.uid,
        senderName: senderName,
        postId: postId,
      );
    }
  }

  Future<void> unlike({
    required String postId,
  }) async {
    final user = _auth.currentUser;

    if (user == null || postId.isEmpty) {
      return;
    }

    final postReference = _posts.doc(postId);

    final likeReference = postReference
        .collection('likes')
        .doc(user.uid);

    final likeSnapshot = await likeReference.get();

    if (!likeSnapshot.exists) {
      return;
    }

    final postSnapshot = await postReference.get();

    if (!postSnapshot.exists) {
      return;
    }

    final postData =
        postSnapshot.data() ?? <String, dynamic>{};

    final currentLikeCount =
        _toInt(postData['likeCount']);

    final batch = _firestore.batch();

    batch.delete(likeReference);

    batch.update(
      postReference,
      {
        'likeCount':
            currentLikeCount > 0
                ? currentLikeCount - 1
                : 0,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
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
