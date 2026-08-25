import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get _currentUser => _auth.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _notificationsStream() {
    final user = _currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(100)
        .snapshots();
  }

  Future<void> _markAsRead(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    try {
      if (notification.data()?['read'] == true) {
        return;
      }

      await notification.reference.update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        'Mark notification as read error: $e',
      );
    }
  }

  Future<void> _markAllAsRead(
    List<DocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    if (notifications.isEmpty) {
      return;
    }

    try {
      final batch = _firestore.batch();

      for (final notification in notifications) {
        final data = notification.data();

        if (data['read'] != true) {
          batch.update(
            notification.reference,
            {
              'read': true,
              'readAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage(
        'সব Notification পড়া হয়েছে।',
      );
    } catch (e) {
      debugPrint(
        'Mark all notifications error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Notification update করা যায়নি।',
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

      if (!mounted) return;

      _showMessage(
        'Notification মুছে ফেলা যায়নি।',
      );
    }
  }

  Future<void> _clearAllNotifications(
    List<DocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    if (notifications.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'সব Notification মুছে ফেলবেন?',
          ),
          content: const Text(
            'এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('মুছে ফেলুন'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final batch = _firestore.batch();

      for (final notification in notifications) {
        batch.delete(notification.reference);
      }

      await batch.commit();

      if (!mounted) return;

      _showMessage(
        'সব Notification মুছে ফেলা হয়েছে।',
      );
    } catch (e) {
      debugPrint(
        'Clear notifications error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'সব Notification মুছে ফেলা যায়নি।',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _notificationTitle(
    Map<String, dynamic> data,
  ) {
    final title = data['title'];

    if (title is String &&
        title.trim().isNotEmpty) {
      return title.trim();
    }

    final type = data['type']?.toString();

    switch (type) {
      case 'like':
        return 'নতুন Like';
      case 'comment':
        return 'নতুন Comment';
      case 'friend_request':
        return 'Friend Request';
      case 'friend_accepted':
        return 'Friend Request Accepted';
      case 'share':
        return 'Post Share হয়েছে';
      default:
        return 'Notification';
    }
  }

  String _notificationBody(
    Map<String, dynamic> data,
  ) {
    final body = data['body'];

    if (body is String &&
        body.trim().isNotEmpty) {
      return body.trim();
    }

    final message = data['message'];

    if (message is String &&
        message.trim().isNotEmpty) {
      return message.trim();
    }

    final senderName = data['senderName'];

    final name =
        senderName is String &&
                senderName.trim().isNotEmpty
            ? senderName.trim()
            : 'কেউ একজন';

    final type = data['type']?.toString();

    switch (type) {
      case 'like':
        return '$name আপনার পোস্টে Like দিয়েছে।';

      case 'comment':
        return '$name আপনার পোস্টে Comment করেছে।';

      case 'friend_request':
        return '$name আপনাকে Friend Request পাঠিয়েছে।';

      case 'friend_accepted':
        return '$name আপনার Friend Request গ্রহণ করেছে।';

      case 'share':
        return '$name আপনার পোস্ট Share করেছে।';

      default:
        return 'আপনার জন্য একটি নতুন Notification আছে।';
    }
  }

  IconData _notificationIcon(
    Map<String, dynamic> data,
  ) {
    final type = data['type']?.toString();

    switch (type) {
      case 'like':
        return Icons.favorite;

      case 'comment':
        return Icons.mode_comment;

      case 'friend_request':
        return Icons.person_add;

      case 'friend_accepted':
        return Icons.people;

      case 'share':
        return Icons.share;

      default:
        return Icons.notifications;
    }
  }

  Color _notificationIconColor(
    Map<String, dynamic> data,
  ) {
    final type = data['type']?.toString();

    switch (type) {
      case 'like':
        return Colors.red;

      case 'comment':
        return Colors.blue;

      case 'friend_request':
        return Colors.orange;

      case 'friend_accepted':
        return Colors.green;

      case 'share':
        return Colors.purple;

      default:
        return Colors.indigo;
    }
  }

  String _timeText(
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    if (timestamp is! Timestamp) {
      return 'এইমাত্র';
    }

    final date = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.isNegative) {
      return 'এইমাত্র';
    }

    if (difference.inMinutes < 1) {
      return 'এইমাত্র';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} মিনিট আগে';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} ঘণ্টা আগে';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} দিন আগে';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _notificationAvatar(
    Map<String, dynamic> data,
  ) {
    final photoUrl =
        data['senderPhotoUrl']?.toString() ??
            data['userPhotoUrl']?.toString() ??
            '';

    if (photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 27,
        backgroundImage: NetworkImage(
          photoUrl.trim(),
        ),
      );
    }

    final color =
        _notificationIconColor(data);

    return CircleAvatar(
      radius: 27,
      backgroundColor:
          color.withValues(alpha: 0.12),
      child: Icon(
        _notificationIcon(data),
        color: color,
      ),
    );
  }

  Widget _buildNotificationItem(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) {
    final data = notification.data();

    if (data == null) {
      return const SizedBox();
    }

    final isRead = data['read'] == true;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(
          bottom: 8,
        ),
        padding: const EdgeInsets.only(
          right: 24,
        ),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        try {
          await _deleteNotification(
            notification,
          );
          return true;
        } catch (_) {
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(
          bottom: 8,
        ),
        elevation: isRead ? 0 : 1,
        color: isRead
            ? null
            : Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () {
            _markAsRead(notification);
          },
          child: Padding(
            padding:
                const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _notificationAvatar(data),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _notificationTitle(
                                data,
                              ),
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 9,
                              height: 9,
                              margin:
                                  const EdgeInsets
                                      .only(
                                top: 5,
                                left: 8,
                              ),
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .primary,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _notificationBody(data),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        _timeText(data),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'read') {
                      _markAsRead(
                        notification,
                      );
                    }

                    if (value == 'delete') {
                      _deleteNotification(
                        notification,
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      if (!isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .mark_email_read_outlined,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'পড়া হয়েছে',
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

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
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: _notificationsStream(),
            builder: (context, snapshot) {
              final notifications =
                  snapshot.data?.docs ?? [];

              final unreadCount =
                  notifications.where(
                (notification) {
                  return notification
                          .data()['read'] !=
                      true;
                },
              ).length;

              if (unreadCount == 0) {
                return const SizedBox();
              }

              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'read') {
                    _markAllAsRead(
                      notifications,
                    );
                  }

                  if (value == 'clear') {
                    _clearAllNotifications(
                      notifications,
                    );
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .mark_email_read_outlined,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'সব পড়া হয়েছে',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'সব মুছে ফেলুন',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
              'Notifications error: ${snapshot.error}',
            );

            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons
                          .notifications_off_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Notification লোড করা যায়নি।',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'আবার চেষ্টা করুন',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final notifications =
              snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 130),
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'এখনও কোনো Notification নেই।',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 300),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationItem(
                  notifications[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
