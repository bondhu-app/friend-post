import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // USER NOTIFICATIONS COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _userNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  // ============================================================
  // CREATE NOTIFICATION
  // ============================================================

  Future<void> createNotification({
    required String receiverId,
    required String title,
    required String message,
    String type = 'general',
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? postId,
  }) async {
    if (receiverId.trim().isEmpty) {
      return;
    }

    final uid = _auth.currentUser?.uid;

    // নিজের কাজের জন্য নিজেকে notification দেওয়া হবে না।
    if (uid != null && uid == receiverId) {
      return;
    }

    final data = <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
      'read': false,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (senderId != null &&
        senderId.trim().isNotEmpty) {
      data['senderId'] = senderId.trim();
    }

    if (senderName != null &&
        senderName.trim().isNotEmpty) {
      data['senderName'] = senderName.trim();
    }

    if (senderPhotoUrl != null &&
        senderPhotoUrl.trim().isNotEmpty) {
      data['senderPhotoUrl'] =
          senderPhotoUrl.trim();
    }

    if (postId != null &&
        postId.trim().isNotEmpty) {
      data['postId'] = postId.trim();
    }

    await _userNotifications(receiverId).add(data);
  }

  // ============================================================
  // LIKE NOTIFICATION
  // ============================================================

  Future<void> likeNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    String senderPhotoUrl = '',
  }) async {
    await createNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
      type: 'like',
      title: 'Post Like',
      message:
          '$senderName আপনার পোস্টে Like দিয়েছে।',
    );
  }

  // ============================================================
  // OLD / COMPATIBLE LIKE METHOD
  // ============================================================
  //
  // like_service.dart বর্তমানে এই method ব্যবহার করছে।
  // তাই এটি রাখা হয়েছে।
  //

  Future<void> notifyLike({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    String senderPhotoUrl = '',
  }) async {
    await likeNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
    );
  }

  // ============================================================
  // COMMENT NOTIFICATION
  // ============================================================

  Future<void> commentNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    required String commentText,
    String senderPhotoUrl = '',
  }) async {
    String message =
        '$senderName আপনার পোস্টে Comment করেছে।';

    final text = commentText.trim();

    if (text.isNotEmpty) {
      final shortText = text.length > 80
          ? '${text.substring(0, 80)}...'
          : text;

      message = '$senderName: $shortText';
    }

    await createNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
      type: 'comment',
      title: 'New Comment',
      message: message,
    );
  }

  // ============================================================
  // OLD / COMPATIBLE COMMENT METHOD
  // ============================================================
  //
  // comment_section.dart বর্তমানে এই method ব্যবহার করছে।
  // তাই এটি রাখা হয়েছে।
  //

  Future<void> notifyComment({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    required String commentText,
    String senderPhotoUrl = '',
  }) async {
    await commentNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
      commentText: commentText,
    );
  }

  // ============================================================
  // FRIEND REQUEST
  // ============================================================

  Future<void> friendRequestNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    String senderPhotoUrl = '',
  }) async {
    await createNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: 'friend_request',
      title: 'Friend Request',
      message:
          '$senderName আপনাকে Friend Request পাঠিয়েছে।',
    );
  }

  // ============================================================
  // FRIEND ACCEPTED
  // ============================================================

  Future<void> friendAcceptedNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    String senderPhotoUrl = '',
  }) async {
    await createNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: 'friend_accepted',
      title: 'Friend Request Accepted',
      message:
          '$senderName আপনার Friend Request গ্রহণ করেছে।',
    );
  }

  // ============================================================
  // SHARE NOTIFICATION
  // ============================================================

  Future<void> shareNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String postId,
    String senderPhotoUrl = '',
  }) async {
    await createNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      postId: postId,
      type: 'share',
      title: 'Post Shared',
      message:
          '$senderName আপনার পোস্ট Share করেছে।',
    );
  }

  // ============================================================
  // MESSAGE NOTIFICATION
  // ============================================================

  Future<void> messageNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    String senderPhotoUrl = '',
  }) async {
    await createNotification(
      receiverId: receiverId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: 'message',
      title: 'New Message',
      message:
          '$senderName আপনাকে একটি Message পাঠিয়েছে।',
    );
  }

  // ============================================================
  // GENERAL NOTIFICATION
  // ============================================================

  Future<void> generalNotification({
    required String receiverId,
    required String title,
    required String message,
    String type = 'general',
  }) async {
    await createNotification(
      receiverId: receiverId,
      title: title,
      message: message,
      type: type,
    );
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> markAsRead({
    required String notificationId,
  }) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return;
    }

    await _userNotifications(uid)
        .doc(notificationId)
        .update({
      'read': true,
      'isRead': true,
    });
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return;
    }

    final snapshot =
        await _userNotifications(uid)
            .where(
              'read',
              isEqualTo: false,
            )
            .limit(500)
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final notification
        in snapshot.docs) {
      batch.update(
        notification.reference,
        {
          'read': true,
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  // ============================================================
  // DELETE ONE NOTIFICATION
  // ============================================================

  Future<void> deleteNotification({
    required String notificationId,
  }) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return;
    }

    await _userNotifications(uid)
        .doc(notificationId)
        .delete();
  }

  // ============================================================
  // DELETE ALL NOTIFICATIONS
  // ============================================================

  Future<void> deleteAllNotifications() async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return;
    }

    final snapshot =
        await _userNotifications(uid)
            .limit(500)
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final notification
        in snapshot.docs) {
      batch.delete(
        notification.reference,
      );
    }

    await batch.commit();
  }

  // ============================================================
  // NOTIFICATIONS STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      notificationsStream() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Stream.empty();
    }

    return _userNotifications(uid)
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .snapshots();
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  Stream<int> unreadCountStream() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return Stream<int>.value(0);
    }

    return _userNotifications(uid)
        .where(
          'read',
          isEqualTo: false,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.length,
        );
  }
}
