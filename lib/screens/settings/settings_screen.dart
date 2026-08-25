import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _notificationsEnabled = true;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'আপনি কি Friend Post থেকে Logout করতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _auth.signOut();

      if (!mounted) {
        return;
      }

      // Auth state listener থাকলে অ্যাপ নিজে থেকেই Login screen-এ যাবে।
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout সফল হয়েছে।'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout করা যায়নি: $e'),
        ),
      );
    }
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Push Notifications',
                      ),
                      subtitle: const Text(
                        'নতুন Like, Comment ও Friend activity-এর notification',
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setSheetState(() {
                          _notificationsEnabled = value;
                        });

                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      secondary: const Icon(
                        Icons.notifications_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy'),
          content: const Text(
            'আপনার Profile ও Post-এর privacy settings এখানে '
            'পরবর্তীতে আরও বিস্তারিতভাবে নিয়ন্ত্রণ করা যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  void _showSecurity() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Security'),
          content: const Text(
            'আপনার Account Firebase Authentication দ্বারা '
            'সুরক্ষিত। Password পরিবর্তন ও অন্যান্য security '
            'options এখানে পরবর্তীতে যোগ করা যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Friend Post',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Friend Post',
      children: const [
        SizedBox(height: 16),
        Text(
          'Friend Post একটি সামাজিক যোগাযোগের অ্যাপ। '
          'এখানে আপনি Post, Like, Comment, Share এবং '
          'Friends-এর সঙ্গে যোগাযোগ করতে পারবেন।',
        ),
      ],
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: iconColor ??
                  Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 30,
              color: Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================================
      // SINGLE SETTINGS TITLE
      // ============================================================

      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),

      // ============================================================
      // SETTINGS CONTENT
      // ============================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),
          child: Column(
            children: [
              // ====================================================
              // SETTINGS CARD
              // ====================================================

              Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _settingTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: _notificationsEnabled
                          ? 'Notifications চালু আছে'
                          : 'Notifications বন্ধ আছে',
                      onTap: _showNotifications,
                    ),

                    _divider(),

                    _settingTile(
                      icon: Icons.lock_outline,
                      title: 'Privacy',
                      onTap: _showPrivacy,
                    ),

                    _divider(),

                    _settingTile(
                      icon: Icons.security_outlined,
                      title: 'Security',
                      onTap: _showSecurity,
                    ),

                    _divider(),

                    _settingTile(
                      icon: Icons.info_outline,
                      title: 'About Friend Post',
                      onTap: _showAbout,
                    ),

                    _divider(),

                    _settingTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: _logout,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ====================================================
              // VERSION
              // ====================================================

              Text(
                'Friend Post • Version 1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
