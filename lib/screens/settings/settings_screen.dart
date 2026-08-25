import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _privateAccountEnabled = false;

  User? get _currentUser => _auth.currentUser;

  String get _userName {
    final user = _currentUser;

    if (user == null) {
      return 'Friend';
    }

    final name =
        user.displayName?.trim() ?? '';

    if (name.isNotEmpty) {
      return name;
    }

    return 'Friend';
  }

  String get _userEmail {
    return _currentUser?.email ?? '';
  }

  String get _photoUrl {
    return _currentUser?.photoURL ?? '';
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
    if (_photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(
          _photoUrl,
        ),
      );
    }

    return const CircleAvatar(
      radius: 32,
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
      applicationLegalese:
          '© Friend Post',
      children: const [
        SizedBox(
          height: 16,
        ),
        Text(
          'Friend Post is a social networking application where users can connect with friends, create posts, like, comment and share.',
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    final email = user.email;

    if (email == null ||
        email.trim().isEmpty) {
      _showMessage(
        'No email address is available for this account.',
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );

      _showMessage(
        'Password reset email sent.',
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(
        e.message ??
            'Could not send password reset email.',
      );
    } catch (e) {
      debugPrint(
        'Password reset error: $e',
      );

      _showMessage(
        'Could not send password reset email.',
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Log Out',
          ),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Log Out',
              ),
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
        e.message ??
            'Could not log out.',
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );

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
          title: const Text(
            'Privacy',
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Your account information is stored securely using Firebase services. '
              'Your profile and posts are controlled by the privacy settings available in Friend Post.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Close',
              ),
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
          title: const Text(
            'Help & Support',
          ),
          content: const SingleChildScrollView(
            child: Text(
              'If you are having a problem with Friend Post, '
              'please check your internet connection and make sure you are logged in. '
              'You can also restart the application and try again.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        top: 20,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context)
              .colorScheme
              .primary,
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
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: CircleAvatar(
        radius: 21,
        child: Icon(
          icon,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(
          top: 3,
        ),
        child: Text(
          subtitle,
        ),
      ),
      trailing: trailing ??
          const Icon(trailing
