import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  DataService._();

  static final DataService instance = DataService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }
    return user.uid;
  }

  // ============================================================
  // USERS
  // ============================================================

  Future<void> createOrUpdateUserProfile({
    String? name,
    String? photoUrl,
    String? email,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);

    final data = <String, dynamic>{
      'uid': user.uid,
      'email': email ?? user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null && name.trim().isNotEmpty) {
      data['name'] = name.trim();
    }

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      data['photoUrl'] = photoUrl.trim();
    }

    await userRef.set(
      data,
      SetOptions(merge: true),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String userId,
  ) async {
    return _firestore
        .collection('users')
        .doc(userId)
        .get();
  }

  // ============================================================
  // POSTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createPost({
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('লগইন করা নেই।');
    }

    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      throw Exception('পোস্টের লেখা খালি রাখা যাবে না।');
    }

    String userName = 'Friend';
    String userPhotoUrl = '';

    try {
      final profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (profile.exists) {
        final data = profile.data();

        if (data != null) {
          final name = data['name'];

          if (name is String && name.trim().isNotEmpty) {
            userName = name.trim();
          }

          final photo = data['photoUrl'];

          if (photo is String && photo.trim().isNotEmpty) {
            userPhotoUrl = photo.trim();
          }
        }
      }
    } catch (_) {
      // Profile না পাওয়া গেলেও পোস্ট তৈরি হবে।
    }

    final postRef = await _firestore.collection('posts').add({
      'userId': user.uid,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': trimmedText,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'commentCount': 0,
      'shareCount': 0,
    });

    return postRef.id;
  }

  Future<void> deletePost(String postId) async {
    final uid = currentUserId;

    final postRef = _firestore
        .collection('posts')
        .doc(postId);

    final post = await postRef.get();

    if (!post.exists) {
      return;
    }

    final data = post.data();

    if (data == null || data['userId'] != uid) {
      throw Exception('শুধু নিজের পোস্ট মুছে ফেলা যাবে।');
    }

    await postRef.delete();
  }

  // ============================================================
  // LIKE
  // ============================================================

  Stream<bool> likeStatusStream(String postId) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream<bool>.value(false);
    }

    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> likePost(String postId) async {
    final uid = currentUserId;

    final postRef = _firestore
        .collection('posts')
        .doc(postId);

    final likeRef = postRef
        .collection('likes')
        .doc(uid);

    final likeSnapshot = await likeRef.get();

    if (likeSnapshot.exists) {
      await likeRef.delete();

      await postRef.update({
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await likeRef.set({
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await postRef.update({
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(
    String postId,
  ) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('লগইন করা নেই।');
    }

    final trimmedText = text.trim();

    if (trimmedText.isEmpty) {
      return;
    }

    String userName = 'Friend';
    String userPhotoUrl = '';

    try {
      final profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (profile.exists) {
        final data = profile.data();

        if (data != null) {
          final name = data['name'];

          if (name is String && name.trim().isNotEmpty) {
            userName = name.trim();
          }

          final photo = data['photoUrl'];

          if (photo is String && photo.trim().isNotEmpty) {
            userPhotoUrl = photo.trim();
          }
        }
      }
    } catch (_) {}

    final postRef = _firestore
        .collection('posts')
        .doc(postId);

    await postRef
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': trimmedText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await postRef.update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final uid = currentUserId;

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    final comment = await commentRef.get();

    if (!comment.exists) {
      return;
    }

    final data = comment.data();

    if (data == null || data['userId'] != uid) {
      throw Exception('শুধু নিজের কমেন্ট মুছতে পারবেন।');
    }

    await commentRef.delete();

    await _firestore
        .collection('posts')
        .doc(postId)
        .update({
      'commentCount': FieldValue.increment(-1),
    });
  }

  // ============================================================
  // SHARE
  // ============================================================

  Stream<bool> shareStatusStream(String postId) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream<bool>.value(false);
    }

    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('shares')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<void> sharePost(String postId) async {
    final uid = currentUserId;

    final postRef = _firestore
        .collection('posts')
        .doc(postId);

    final shareRef = postRef
        .collection('shares')
        .doc(uid);

    final shareSnapshot = await shareRef.get();

    // একই user একই post একাধিকবার share করলে
    // share count বারবার বাড়বে না।
    if (shareSnapshot.exists) {
      return;
    }

    await shareRef.set({
      'userId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await postRef.update({
      'shareCount': FieldValue.increment(1),
    });
  }

  // ============================================================
  // COUNTS
  // ============================================================

  Stream<int> likeCountStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      final count = data['likeCount'];

      if (count is int) {
        return count;
      }

      if (count is num) {
        return count.toInt();
      }

      return 0;
    });
  }

  Stream<int> commentCountStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      final count = data['commentCount'];

      if (count is int) {
        return count;
      }

      if (count is num) {
        return count.toInt();
      }

      return 0;
    });
  }

  Stream<int> shareCountStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (data == null) {
        return 0;
      }

      final count = data['shareCount'];

      if (count is int) {
        return count;
      }

      if (count is num) {
        return count.toInt();
      }

      return 0;
    });
  }
}
