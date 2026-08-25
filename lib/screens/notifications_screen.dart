import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notificationsCollection(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  String _textFromData(Map<String, dynamic> data) {
    final value = data['message'] ??
        data['text'] ??
        data['title'] ??
        'নতুন Notification';

    return value.toString();
  }

  String _titleFromData(Map<String, dynamic> data) {
    final value = data['title'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return 'Notification';
  }

  String _timeText(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final difference = DateTime.now().difference(date);

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

    return '';
  }

  Future<void> _markAsRead(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    try {
      await notification.reference.update({
        'read': true,
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Mark notification read error: $e');
    }
  }

  Future<void> _deleteNotification(
    DocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    try {
      await notification.reference.delete();
    } catch (e) {
      debugPrint('Delete notification error: $e');
    }
  }

  Future<void> _markAllAsRead(
    String uid,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    if (notifications.isEmpty) {
      return;
    }

    try {
      final batch = _firestore.batch();

      for (final notification in notifications) {
        final data = notification.data();

        final read = data['read'];
        final isRead = data['isRead'];

        final alreadyRead =
            read == true || isRead == true;

        if (!alreadyRead) {
          batch.update(notification.reference, {
            'read': true,
            'isRead': true,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Mark all notifications read error: $e');
    }
  }

  Widget _notificationIcon(
    Map<String, dynamic> data,
  ) {
    final type = (data['type'] ?? '').toString();

    IconData icon;

    switch (type) {
      case 'like':
        icon = Icons.favorite;
        break;

      case 'comment':
        icon = Icons.comment;
        break;

      case 'friend_request':
        icon = Icons.person_add;
        break;

      case 'friend_accepted':
        icon = Icons.people;
        break;

      case 'message':
        icon = Icons.message;
        break;

      default:
        icon = Icons.notifications;
    }

    return CircleAvatar(
      radius: 24,
      child: Icon(icon),
    );
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

    final uid = user.uid;

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
            stream: _notificationsCollection(uid)
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              final notifications =
                  snapshot.data?.docs ??
                      <QueryDocumentSnapshot<
                          Map<String, dynamic>>>[];

              final unread = notifications.where((doc) {
                final data = doc.data();

                return data['read'] != true &&
                    data['isRead'] != true;
              }).toList();

              if (unread.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'Mark all as read',
                onPressed: () {
                  _markAllAsRead(
                    uid,
                    notifications,
                  );
                },
                icon: const Icon(
                  Icons.done_all,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationsCollection(uid)
            .orderBy(
              'createdAt',
              descending: true,
            )
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
              'Notifications error: ${snapshot.error}',
            );

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Notifications load করা যায়নি।',
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
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<
                      Map<String, dynamic>>>[];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 70,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'এখনও কোনো Notification নেই।',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification =
                    notifications[index];

                // গুরুত্বপূর্ণ:
                // data() nullable হতে পারে।
                // তাই সরাসরি data['x'] ব্যবহার করা যাবে না।
                // এখানে null হলে empty map নেওয়া হয়েছে।
                final data =
                    notification.data();

                final title =
                    _titleFromData(data);

                final message =
                    _textFromData(data);

                final createdAt =
                    data['createdAt'];

                final time =
                    _timeText(createdAt);

                final isRead =
                    data['read'] == true ||
                        data['isRead'] == true;

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: Dismissible(
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
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteNotification(
                        notification,
                      );

                      return true;
                    },
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading:
                          _notificationIcon(data),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding:
                            const EdgeInsets.only(
                          top: 5,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              maxLines: 3,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                            if (time.isNotEmpty) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: isRead
                          ? null
                          : const Icon(
                              Icons.circle,
                              size: 10,
                            ),
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(
                            notification,
                          );
                        }
                      },
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
