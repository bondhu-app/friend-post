import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  String get _userId => _auth.currentUser!.uid;

  String get _userName {
    final user = _auth.currentUser;

    if (user?.displayName != null &&
        user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    return user?.email ?? 'Friend Post User';
  }

  // ==============================
  // CREATE POST
  // ==============================

  Future<void> createPost({
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw Exception('পোস্ট খালি হতে পারবে না।');
    }

    await _posts.add({
      'userId': _userId,
      'userName': _userName,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': <String>[],
      'likeCount': 0,
      'commentCount': 0,
    });
  }

  // ==============================
  // GET POSTS
  // ==============================

  Stream<QuerySnapshot<Map<String, dynamic>>> getPosts() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==============================
  // LIKE / UNLIKE
  // ==============================

  Future<void> toggleLike({
    required String postId,
    required List<String> currentLikes,
  }) async {
    final postRef = _posts.doc(postId);

    if (currentLikes.contains(_userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([_userId]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([_userId]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // ==============================
  // ADD COMMENT
  // ==============================

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final postRef = _posts.doc(postId);

    await postRef.collection('comments').add({
      'userId': _userId,
      'userName': _userName,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await postRef.update({
      'commentCount': FieldValue.increment(1),
    });
  }

  // ==============================
  // GET COMMENTS
  // ==============================

  Stream<QuerySnapshot<Map<String, dynamic>>> getComments(
    String postId,
  ) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // ==============================
  // DELETE POST
  // ==============================

  Future<void> deletePost(String postId) async {
    final postRef = _posts.doc(postId);

    final comments = await postRef.collection('comments').get();

    final batch = _firestore.batch();

    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }

    batch.delete(postRef);

    await batch.commit();
  }
}
