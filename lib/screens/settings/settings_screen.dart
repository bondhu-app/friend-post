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
  bool _darkModeEnabled = false;
  bool _privateAccountEnabled = false;

  User? get _currentUser => _auth.currentUser;

  String get _userName {
    final user = _currentUser;
    final name = user?.displayName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Friend';
  }

  String get _userEmail {
    final email = _currentUser?.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'No email available';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final photoUrl = _currentUser?.photoURL?.trim() ?? '';

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundImage: NetworkImage(photoUrl),
      );
    }

    return const CircleAvatar(
      radius: 34,
      child: Icon(
        Icons.person,
        size: 34,
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Friend Post',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.people_alt_rounded,
        size: 42,
      ),
      children: const [
        Text(
          'Friend Post is a social networking application '
          'where you can connect with friends, create posts, '
          'like, comment and share.',
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final user = _currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final email = user.email;

    if (email == null || email.trim().isEmpty) {
      _showMessage('No email address is connected to this account.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );

      _showMessage(
        'Password reset link has been sent to your email.',
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(
        e.message ?? 'Could not send password reset email.',
      );
    } catch (_) {
      _showMessage(
        'Could not send password reset email.',
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Log Out'),
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

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(
        e.message ?? 'Could not log out.',
      );
    } catch (_) {
      _showMessage(
        'Could not log out.',
      );
    }
  }

  void _showPrivacyInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Privacy'),
          content: const Text(
            'Your account information and social activity '
            'are managed through your Friend Post account. '
            'Keep your password private and never share it '
            'with anyone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'If you are having a problem with Friend Post, '
            'please check your internet connection and try '
            'again. You can also contact the app administrator '
            'for further assistance.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        top: 18,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 72,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _buildProfileAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionTitle('General'),

          _buildSettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: _notificationsEnabled
                    ? 'Notifications are enabled'
                    : 'Notifications are disabled',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });

                    _showMessage(
                      value
                          ? 'Notifications enabled.'
                          : 'Notifications disabled.',
                    );
                  },
                ),
                onTap: () {
                  setState(() {
                    _notificationsEnabled =
                        !_notificationsEnabled;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: _darkModeEnabled
                    ? 'Dark mode is enabled'
                    : 'Dark mode is disabled',
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });

                    _showMessage(
                      'Dark mode setting changed.',
                    );
                  },
                ),
                onTap: () {
                  setState(() {
                    _darkModeEnabled =
                        !_darkModeEnabled;
                  });
                },
              ),
            ],
          ),

          _buildSectionTitle('Privacy'),

          _buildSettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.lock_outline,
                title: 'Private Account',
                subtitle: _privateAccountEnabled
                    ? 'Your account is private'
                    : 'Your account is public',
                trailing: Switch(
                  value: _privateAccountEnabled,
                  onChanged: (value) {
                    setState(() {
                      _privateAccountEnabled = value;
                    });

                    _showMessage(
                      value
                          ? 'Private account enabled.'
                          : 'Private account disabled.',
                    );
                  },
                ),
                onTap: () {
                  setState(() {
                    _privateAccountEnabled =
                        !_privateAccountEnabled;
                  });
                },
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Information',
                subtitle: 'Learn about privacy and security',
                onTap: _showPrivacyInfo,
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),

          _buildSectionTitle('Account'),

          _buildSettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.lock_reset_outlined,
                title: 'Change Password',
                subtitle: 'Send a password reset link',
                onTap: _changePassword,
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),

          _buildSectionTitle('Support'),

          _buildSettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help using Friend Post',
                onTap: _showHelpDialog,
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
              _buildDivider(),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About Friend Post',
                subtitle: 'Version 1.0.0',
                onTap: _showAboutDialog,
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),

          _buildSectionTitle('Account Actions'),

          _buildSettingsCard(
            children: [
              _buildSettingTile(
                icon: Icons.logout,
                title: 'Log Out',
                subtitle: 'Sign out of your account',
                onTap: _signOut,
                trailing: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'Friend Post • Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
