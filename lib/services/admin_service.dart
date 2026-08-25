import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  AdminService._();

  static final AdminService instance = AdminService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final tokenResult =
          await user.getIdTokenResult(true);

      final claims = tokenResult.claims;

      return claims != null &&
          claims['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> requireAdmin() async {
    final admin = await isAdmin();

    if (!admin) {
      throw Exception(
        'আপনার Admin access নেই।',
      );
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    await requireAdmin();

    final usersSnapshot =
        await _firestore
            .collection('users')
            .get();

    final postsSnapshot =
        await _firestore
            .collection('posts')
            .get();

    final withdrawSnapshot =
        await _firestore
            .collection('withdraw_requests')
            .where(
              'status',
              isEqualTo: 'pending',
            )
            .get();

    final walletSnapshot =
        await _firestore
            .collection('settings')
            .doc('owner_wallet')
            .get();

    final walletData =
        walletSnapshot.data() ?? {};

    return {
      'users': usersSnapshot.size,
      'posts': postsSnapshot.size,
      'pendingWithdraws':
          withdrawSnapshot.size,
      'ownerBalance':
          _toDouble(walletData['balance']),
      'totalEarned':
          _toDouble(walletData['totalEarned']),
      'totalPaidToUsers':
          _toDouble(
        walletData['totalPaidToUsers'],
      ),
    };
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      ownerWalletStream() {
    return _firestore
        .collection('settings')
        .doc('owner_wallet')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      revenueSettingsStream() {
    return _firestore
        .collection('settings')
        .doc('revenue')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      usersStream() {
    return _firestore
        .collection('users')
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      postsStream() {
    return _firestore
        .collection('posts')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      pendingWithdrawalsStream() {
    return _firestore
        .collection('withdraw_requests')
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Future<void> initializeAdminData() async {
    await requireAdmin();

    final batch =
        _firestore.batch();

    final walletRef = _firestore
        .collection('settings')
        .doc('owner_wallet');

    final revenueRef = _firestore
        .collection('settings')
        .doc('revenue');

    batch.set(
      walletRef,
      {
        'balance': 0,
        'totalEarned': 0,
        'totalPaidToUsers': 0,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      revenueRef,
      {
        'userPercent': 80,
        'adminPercent': 20,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> updateRevenueSplit({
    required double userPercent,
    required double adminPercent,
  }) async {
    await requireAdmin();

    if (userPercent < 0 ||
        adminPercent < 0) {
      throw Exception(
        'Revenue percentage cannot be negative.',
      );
    }

    final total =
        userPercent + adminPercent;

    if (total != 100) {
      throw Exception(
        'User এবং Admin percentage মিলিয়ে 100% হতে হবে।',
      );
    }

    await _firestore
        .collection('settings')
        .doc('revenue')
        .set(
      {
        'userPercent': userPercent,
        'adminPercent': adminPercent,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateOwnerWallet({
    required double balance,
    required double totalEarned,
    required double totalPaidToUsers,
  }) async {
    await requireAdmin();

    await _firestore
        .collection('settings')
        .doc('owner_wallet')
        .set(
      {
        'balance': balance,
        'totalEarned': totalEarned,
        'totalPaidToUsers':
            totalPaidToUsers,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> signOutAdmin() async {
    await _auth.signOut();
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
