import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _notifications =>
          _firestore.collection('notifications');

  String? get currentUserId =>
      _auth.currentUser?.uid;

  Future<void> createNotification({
    required String receiverId,
    required String type,
    String? message,
    String? senderName,
    String? senderPhotoUrl,
    String? postId,
    String? commentId,
  }) async {
    final sender = _auth.currentUser;

    if (sender == null) {
      return;
    }

    if (receiverId.isEmpty) {
      return;
    }

    if (receiverId == sender.uid) {
      return;
    }

    try {
      final notification =
          _notifications.doc();

      await notification.set({
        'notificationId': notification.id,
        'receiverId': receiverId,
        'senderId': sender.uid,
        'senderName':
            senderName ??
                sender.displayName ??
                'Someone',
        'senderPhotoUrl':
            senderPhotoUrl ?? '',
        'type': type,
        'message': message ?? '',
        'postId': postId ?? '',
        'commentId': commentId ?? '',
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Create notification error: $e',
      );
    }
  }

  Future<void> notifyLike({
    required String postOwnerId,
    required String postId,
  }) async {
    final sender = _auth.currentUser;

    if (sender == null ||
        postOwnerId.isEmpty ||
        postOwnerId == sender.uid) {
      return;
    }

    await createNotification(
      receiverId: postOwnerId,
      type: 'like',
      senderName:
          sender.displayName ?? 'Someone',
      postId: postId,
      message:
          '${sender.displayName ?? 'Someone'} liked your post.',
    );
  }

  Future<void> notifyComment({
    required String postOwnerId,
    required String postId,
    String? commentId,
  }) async {
    final sender = _auth.currentUser;

    if (sender == null ||
        postOwnerId.isEmpty ||
        postOwnerId == sender.uid) {
      return;
    }

    await createNotification(
      receiverId: postOwnerId,
      type: 'comment',
      senderName:
          sender.displayName ?? 'Someone',
      postId: postId,
      commentId: commentId,
      message:
          '${sender.displayName ?? 'Someone'} commented on your post.',
    );
  }

  Future<void> notifyFriendRequest({
    required String receiverId,
  }) async {
    final sender = _auth.currentUser;

    if (sender == null ||
        receiverId.isEmpty ||
        receiverId == sender.uid) {
      return;
    }

    await createNotification(
      receiverId: receiverId,
      type: 'friend_request',
      senderName:
          sender.displayName ?? 'Someone',
      message:
          '${sender.displayName ?? 'Someone'} sent you a friend request.',
    );
  }

  Future<void> notifyFriendAccepted({
    required String receiverId,
  }) async {
    final sender = _auth.currentUser;

    if (sender == null ||
        receiverId.isEmpty ||
        receiverId == sender.uid) {
      return;
    }

    await createNotification(
      receiverId: receiverId,
      type: 'friend_accepted',
      senderName:
          sender.displayName ?? 'Someone',
      message:
          '${sender.displayName ?? 'Someone'} accepted your friend request.',
    );
  }

  Future<void> markAsRead(
    String notificationId,
  ) async {
    if (notificationId.isEmpty) {
      return;
    }

    try {
      await _notifications
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Mark notification read error: $e',
      );
    }
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final result = await _notifications
          .where(
            'receiverId',
            isEqualTo: user.uid,
          )
          .where(
            'isRead',
            isEqualTo: false,
          )
          .get();

      if (result.docs.isEmpty) {
        return;
      }

      final batch =
          _firestore.batch();

      for (final notification
          in result.docs) {
        batch.update(
          notification.reference,
          {
            'isRead': true,
            'readAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        'Mark all notifications read error: $e',
      );
    }
  }

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    if (notificationId.isEmpty) {
      return;
    }

    try {
      await _notifications
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint(
        'Delete notification error: $e',
      );
    }
  }
}
