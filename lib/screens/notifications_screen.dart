import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  FirebaseFirestore get _firestore =>
      FirebaseFirestore.instance;

  FirebaseAuth get _auth =>
      FirebaseAuth.instance;

  String _notificationText(
    Map<String, dynamic> data,
  ) {
    final type =
        (data['type'] ?? 'general').toString();

    final senderName =
        (data['senderName'] ?? 'Someone').toString();

    switch (type) {
      case 'friend_request':
        return '$senderName sent you a friend request.';

      case 'friend_accepted':
        return '$senderName accepted your friend request.';

      case 'like':
        return '$senderName liked your post.';

      case 'comment':
        return '$senderName commented on your post.';

      case 'general':
      default:
        return (data['message'] ??
                'You have a new notification.')
            .toString();
    }
  }

  IconData _notificationIcon(
    Map<String, dynamic> data,
  ) {
    final type =
        (data['type'] ?? 'general').toString();

    switch (type) {
      case 'friend_request':
        return Icons.person_add_alt_1;

      case 'friend_accepted':
        return Icons.people_alt_outlined;

      case 'like':
        return Icons.favorite;

      case 'comment':
        return Icons.comment_outlined;

      case 'general':
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _markAsRead(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    try {
      await notification.reference.update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Mark notification as read error: $e',
      );
    }
  }

  Future<void> _markAllAsRead(
    String uid,
  ) async {
    try {
      final result = await _firestore
          .collection('notifications')
          .where(
            'receiverId',
            isEqualTo: uid,
          )
          .where(
            'isRead',
            isEqualTo: false,
          )
          .get();

      if (result.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();

      for (final notification in result.docs) {
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
        'Mark all notifications as read error: $e',
      );
    }
  }

  Future<void> _deleteNotification(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    try {
      await notification.reference.delete();
    } catch (e) {
      debugPrint(
        'Delete notification error: $e',
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('notifications')
                .where(
                  'receiverId',
                  isEqualTo: user.uid,
                )
                .where(
                  'isRead',
                  isEqualTo: false,
                )
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data?.docs.length ?? 0;

              if (unreadCount == 0) {
                return const SizedBox();
              }

              return TextButton(
                onPressed: () {
                  _markAllAsRead(user.uid);
                },
                child: const Text(
                  'Read all',
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('notifications')
            .where(
              'receiverId',
              isEqualTo: user.uid,
            )
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load notifications.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications =
              snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Icon(
                      Icons.notifications_none,
                      size: 64,
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.separated(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 8,
              ),
              itemCount:
                  notifications.length,
              separatorBuilder:
                  (context, index) {
                return const Divider(
                  height: 1,
                );
              },
              itemBuilder:
                  (context, index) {
                final notification =
                    notifications[index];

                final data =
                    notification.data();

                final isRead =
                    data['isRead'] == true;

                final senderPhoto =
                    (data['senderPhotoUrl'] ??
                            '')
                        .toString();

                final text =
                    _notificationText(data);

                final date =
                    _formatDate(
                  data['createdAt'],
                );

                return Dismissible(
                  key: ValueKey(
                    notification.id,
                  ),
                  direction:
                      DismissDirection.endToStart,
                  background: Container(
                    alignment:
                        Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(
                      right: 20,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
                  onDismissed: (_) {
                    _deleteNotification(
                      notification,
                    );
                  },
                  child: ListTile(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(
                          notification,
                        );
                      }
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      clipBehavior:
                          Clip.none,
                      children: [
                        if (senderPhoto
                            .trim()
                            .isNotEmpty)
                          CircleAvatar(
                            radius: 26,
                            backgroundImage:
                                NetworkImage(
                              senderPhoto,
                            ),
                          )
                        else
                          const CircleAvatar(
                            radius: 26,
                            child: Icon(
                              Icons.person,
                            ),
                          ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color:
                                  Theme.of(
                                context,
                              ).colorScheme.primary,
                              border:
                                  Border.all(
                                color:
                                    Theme.of(
                                  context,
                                )
                                    .scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _notificationIcon(
                                data,
                              ),
                              size: 12,
                              color:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      text,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 4,
                      ),
                      child: Text(
                        date,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    trailing: isRead
                        ? null
                        : Container(
                            width: 9,
                            height: 9,
                            decoration:
                                const BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
