import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.userId,
  });

  final String? userId;

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  String _name = 'Friend';
  String _email = '';
  String _photoUrl = '';
  String _bio = '';

  int _postCount = 0;
  int _friendCount = 0;

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  String get _profileUserId {
    final suppliedId =
        widget.userId?.trim() ?? '';

    if (suppliedId.isNotEmpty) {
      return suppliedId;
    }

    return _auth.currentUser?.uid ?? '';
  }

  bool get _isOwnProfile {
    final currentUid =
        _auth.currentUser?.uid;

    return currentUid != null &&
        currentUid == _profileUserId;
  }

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController();

    _bioController =
        TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = _profileUserId;

    if (uid.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profileFuture = _firestore
          .collection('users')
          .doc(uid)
          .get();

      final postsFuture = _firestore
          .collection('posts')
          .where(
            'userId',
            isEqualTo: uid,
          )
          .get();

      final friendsFuture = _firestore
          .collection('users')
          .doc(uid)
          .collection('friends')
          .get();

      final results = await Future.wait([
        profileFuture,
        postsFuture,
        friendsFuture,
      ]);

      final profile =
          results[0]
              as DocumentSnapshot<
                  Map<String, dynamic>>;

      final posts =
          results[1]
              as QuerySnapshot<
                  Map<String, dynamic>>;

      final friends =
          results[2]
              as QuerySnapshot<
                  Map<String, dynamic>>;

      final data =
          profile.data() ?? {};

      final name =
          (data['name'] ??
                  data['displayName'] ??
                  _auth.currentUser
                      ?.displayName ??
                  'Friend')
              .toString()
              .trim();

      final email =
          (data['email'] ??
                  _auth.currentUser?.email ??
                  '')
              .toString()
              .trim();

      final photoUrl =
          (data['photoUrl'] ??
                  data['userPhotoUrl'] ??
                  _auth.currentUser?.photoURL ??
                  '')
              .toString()
              .trim();

      final bio =
          (data['bio'] ?? '')
              .toString()
              .trim();

      if (!mounted) {
        return;
      }

      setState(() {
        _name =
            name.isEmpty ? 'Friend' : name;

        _email = email;
        _photoUrl = photoUrl;
        _bio = bio;

        _postCount = posts.docs.length;
        _friendCount = friends.docs.length;

        _nameController.text = _name;
        _bioController.text = _bio;

        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'Profile loading error: ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        e.message ??
            'Could not load profile.',
      );
    } catch (e) {
      debugPrint(
        'Profile loading error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading =
