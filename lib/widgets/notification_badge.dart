import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return IconButton(
        onPressed: onTap,
        tooltip: 'Notifications',
        icon: const Icon(
          Icons.notifications_outlined,
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
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
        final count =
            snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onTap,
              tooltip: 'Notifications',
              icon: const Icon(
                Icons.notifications_outlined,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 5,
                top: 5,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: Theme.of(context)
                            .scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      count > 99
                          ? '99+'
                          : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
