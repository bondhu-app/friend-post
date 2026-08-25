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

  bool _processing = false;

  User? get _currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>
      get _notifications {
    final user = _currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  String _notificationText(
    Map<String, dynamic> data,
  ) {
    final message = data['message'];

    if (message is String &&
        message.trim().isNotEmpty) {
      return message.trim();
    }

    final type = data['type']?.toString() ?? '';

    switch (type) {
      case 'friend_request':
        return 'আপনাকে Friend Request পাঠানো হয়েছে।';

      case 'friend_accepted':
        return 'আপনার Friend Request গ্রহণ করা হয়েছে।';

      case 'like':
        return 'আপনার পোস্টে Like দেওয়া হয়েছে।';

      case 'comment':
        return 'আপনার পোস্টে Comment করা হয়েছে।';

      case 'share':
        return 'আপনার পোস্ট Share করা হয়েছে।';

      default:
        return 'আপনার জন্য একটি নতুন Notification আছে।';
    }
  }

  String _senderName(
    Map<String, dynamic> data,
  ) {
    final name = data['senderName'];

    if (name is String &&
        name.trim().isNotEmpty) {
      return name.trim();
    }

    return 'Friend';
  }

  String _timeText(
    Map<String, dynamic> data,
  ) {
    final value = data['createdAt'];

    if (value is! Timestamp) {
      return 'এইমাত্র';
    }

    final date = value.toDate();
    final difference =
        DateTime.now().difference(date);

    if (difference.isNegative) {
      return 'এইমাত্র';
    }

    if (difference.inSeconds < 60) {
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

  IconData _notificationIcon(
    Map<String, dynamic> data,
  ) {
    switch (data['type']?.toString()) {
      case 'friend_request':
        return Icons.person_add_alt_1;

      case 'friend_accepted':
        return Icons.people_alt;

      case 'like':
        return Icons.favorite;

      case 'comment':
        return Icons.comment;

      case 'share':
        return Icons.share;

      default:
        return Icons.notifications;
    }
  }

  Color _notificationColor(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    switch (data['type']?.toString()) {
      case 'friend_request':
        return Colors.blue;

      case 'friend_accepted':
        return Colors.green;

      case 'like':
        return Colors.red;

      case 'comment':
        return Colors.orange;

      case 'share':
        return Colors.purple;

      default:
        return Theme.of(context)
            .colorScheme
            .primary;
    }
  }

  Future<void> _markAsRead(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    final data = notification.data();

    if (data == null) {
      return;
    }

    final isRead = data['isRead'] == true;

    if (isRead) {
      return;
    }

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

  Future<void> _deleteNotification(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    try {
      await notification.reference.delete();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Notification মুছতে সমস্যা হয়েছে।',
      );

      debugPrint(
        'Delete notification error: $e',
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final user = _currentUser;

    if (user == null || _processing) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          _showMessage(
            'সব Notification আগেই পড়া হয়েছে।',
          );
        }
        return;
      }

      final batch = _firestore.batch();

      for (final notification in snapshot.docs) {
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

      if (mounted) {
        _showMessage(
          'সব Notification পড়া হয়েছে।',
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Notification update করা যায়নি।',
        );
      }
    } catch (e) {
      debugPrint(
        'Mark all notifications error: $e',
      );

      if (mounted) {
        _showMessage(
          'Notification update করা যায়নি।',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final user = _currentUser;

    if (user == null || _processing) {
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
            'সব Notification স্থায়ীভাবে মুছে যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
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

    setState(() {
      _processing = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          _showMessage(
            'মুছে ফেলার মতো কোনো Notification নেই।',
          );
        }
        return;
      }

      final batch = _firestore.batch();

      for (final notification in snapshot.docs) {
        batch.delete(notification.reference);
      }

      await batch.commit();

      if (mounted) {
        _showMessage(
          'সব Notification মুছে ফেলা হয়েছে।',
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Notification মুছে ফেলা যায়নি।',
        );
      }
    } catch (e) {
      debugPrint(
        'Clear notifications error: $e',
      );

      if (mounted) {
        _showMessage(
          'Notification মুছে ফেলা যায়নি।',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
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

  Widget _buildNotificationItem(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>>
        notification,
  ) {
    final data = notification.data();

    if (data == null) {
      return const SizedBox();
    }

    final isRead = data['isRead'] == true;

    final icon =
        _notificationIcon(data);

    final iconColor =
        _notificationColor(
      context,
      data,
    );

    final senderName =
        _senderName(data);

    final message =
        _notificationText(data);

    final time =
        _timeText(data);

    final photoUrl =
        data['senderPhotoUrl']?.toString() ??
            '';

    return Dismissible(
      key: ValueKey(notification.id),
      direction:
          DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
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
          bottom: 10,
        ),
        elevation: isRead ? 0 : 2,
        color: isRead
            ? Theme.of(context)
                .colorScheme
                .surface
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
                const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior:
                      Clip.none,
                  children: [
                    if (photoUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            NetworkImage(
                          photoUrl,
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            iconColor.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                        ),
                      ),
                    if (!isRead)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration:
                              BoxDecoration(
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .primary,
                            shape:
                                BoxShape.circle,
                            border:
                                Border.all(
                              color: Theme.of(
                                context,
                              )
                                  .scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              senderName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Icon(
                              Icons.circle,
                              size: 9,
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style:
                            TextStyle(
                          fontSize: 14,
                          color: Colors
                              .grey
                              .shade700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        time,
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  padding:
                      EdgeInsets.zero,
                  onSelected: (value) {
                    if (value ==
                        'read') {
                      _markAsRead(
                        notification,
                      );
                    }

                    if (value ==
                        'delete') {
                      _deleteNotification(
                        notification,
                      );
                    }
                  },
                  itemBuilder:
                      (context) {
                    return [
                      if (!isRead)
                        const PopupMenuItem(
                          value: 'read',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .done,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Mark as read',
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
                              color:
                                  Colors.red,
                            ),
                            SizedBox(
                              width: 8,
                            ),
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

    final notificationStream =
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'read') {
                _markAllAsRead();
              }

              if (value == 'clear') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all),
                      SizedBox(width: 8),
                      Text(
                        'Mark all as read',
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
                        'Clear all',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
              'Notifications error: ${snapshot.error}',
            );

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Notification লোড করা যায়নি।\n'
                  'Firestore index/rules পরীক্ষা করুন।',
                  textAlign: TextAlign.center,
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
                  SizedBox(height: 150),
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'এখনও কোনো Notification নেই।',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
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
              padding:
                  const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder:
                  (context, index) {
                return _buildNotificationItem(
                  context,
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
