import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarningsService {
  EarningsService._();

  static final EarningsService instance = EarningsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _usersCollection = 'users';
  static const String _earningsCollection = 'earnings';
  static const String _transactionsCollection = 'transactions';
  static const String _withdrawCollection = 'withdraw_requests';

  static const String _ownerWalletDocument = 'owner_wallet';

  /// User-এর বর্তমান wallet balance
  Future<double> getUserBalance(String userId) async {
    try {
      final doc = await _firestore
          .collection(_earningsCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return 0;
      }

      final data = doc.data() ?? {};

      return _toDouble(data['balance']);
    } catch (_) {
      return 0;
    }
  }

  /// বর্তমান logged-in user-এর wallet balance
  Future<double> getMyBalance() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 0;
    }

    return getUserBalance(user.uid);
  }

  /// User wallet document তৈরি/নিশ্চিত করা
  Future<void> ensureUserWallet(String userId) async {
    final walletRef =
        _firestore.collection(_earningsCollection).doc(userId);

    final snapshot = await walletRef.get();

    if (snapshot.exists) {
      return;
    }

    await walletRef.set({
      'userId': userId,
      'balance': 0.0,
      'totalEarned': 0.0,
      'totalWithdrawn': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// User-এর wallet-এ earning যোগ করা
  ///
  /// উদাহরণ:
  /// addUserEarning(
  ///   userId: 'USER_ID',
  ///   amount: 10,
  ///   source: 'ad_reward',
  /// );
  Future<void> addUserEarning({
    required String userId,
    required double amount,
    String source = 'earning',
    String? description,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Amount অবশ্যই 0-এর বেশি হতে হবে।');
    }

    final userWalletRef =
        _firestore.collection(_earningsCollection).doc(userId);

    final ownerWalletRef =
        _firestore.collection(_earningsCollection).doc(_ownerWalletDocument);

    final transactionRef =
        _firestore.collection(_transactionsCollection).doc();

    await _firestore.runTransaction((transaction) async {
      final userWalletSnapshot =
          await transaction.get(userWalletRef);

      final ownerWalletSnapshot =
          await transaction.get(ownerWalletRef);

      final userWalletData =
          userWalletSnapshot.data() ?? <String, dynamic>{};

      final ownerWalletData =
          ownerWalletSnapshot.data() ?? <String, dynamic>{};

      final oldUserBalance =
          _toDouble(userWalletData['balance']);

      final oldUserTotalEarned =
          _toDouble(userWalletData['totalEarned']);

      final oldOwnerBalance =
          _toDouble(ownerWalletData['balance']);

      final oldOwnerTotalEarned =
          _toDouble(ownerWalletData['totalEarned']);

      final newUserBalance =
          oldUserBalance + amount;

      final newUserTotalEarned =
          oldUserTotalEarned + amount;

      final newOwnerBalance =
          oldOwnerBalance + amount;

      final newOwnerTotalEarned =
          oldOwnerTotalEarned + amount;

      transaction.set(
        userWalletRef,
        {
          'userId': userId,
          'balance': newUserBalance,
          'totalEarned': newUserTotalEarned,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        ownerWalletRef,
        {
          'balance': newOwnerBalance,
          'totalEarned': newOwnerTotalEarned,
          'totalPaidToUsers':
              _toDouble(ownerWalletData['totalPaidToUsers']),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        transactionRef,
        {
          'userId': userId,
          'type': 'earning',
          'source': source,
          'amount': amount,
          'description': description ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  /// User wallet থেকে টাকা withdraw request তৈরি করা
  Future<String> createWithdrawRequest({
    required double amount,
    required String method,
    required String accountNumber,
    String? accountName,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User লগইন করা নেই।');
    }

    if (amount <= 0) {
      throw Exception('Withdraw amount অবশ্যই 0-এর বেশি হতে হবে।');
    }

    if (method.trim().isEmpty) {
      throw Exception('Payment method দিন।');
    }

    if (accountNumber.trim().isEmpty) {
      throw Exception('Payment account দিন।');
    }

    final userWalletRef =
        _firestore.collection(_earningsCollection).doc(user.uid);

    final requestRef =
        _firestore.collection(_withdrawCollection).doc();

    await _firestore.runTransaction((transaction) async {
      final walletSnapshot =
          await transaction.get(userWalletRef);

      if (!walletSnapshot.exists) {
        throw Exception('Wallet পাওয়া যায়নি।');
      }

      final walletData =
          walletSnapshot.data() ?? <String, dynamic>{};

      final currentBalance =
          _toDouble(walletData['balance']);

      if (currentBalance < amount) {
        throw Exception(
          'আপনার wallet balance যথেষ্ট নয়। বর্তমান balance: ৳${currentBalance.toStringAsFixed(2)}',
        );
      }

      final newBalance =
          currentBalance - amount;

      transaction.update(
        userWalletRef,
        {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      transaction.set(
        requestRef,
        {
          'userId': user.uid,
          'userName': user.displayName ?? '',
          'email': user.email ?? '',
          'amount': amount,
          'method': method.trim(),
          'paymentMethod': method.trim(),
          'accountNumber': accountNumber.trim(),
          'accountName': accountName?.trim() ?? '',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });

    return requestRef.id;
  }

  /// Owner/Admin wallet-এর তথ্য
  Future<Map<String, dynamic>> getOwnerWallet() async {
    try {
      final doc = await _firestore
          .collection(_earningsCollection)
          .doc(_ownerWalletDocument)
          .get();

      if (!doc.exists) {
        return {
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalPaidToUsers': 0.0,
        };
      }

      final data = doc.data() ?? {};

      return {
        'balance': _toDouble(data['balance']),
        'totalEarned': _toDouble(data['totalEarned']),
        'totalPaidToUsers':
            _toDouble(data['totalPaidToUsers']),
      };
    } catch (_) {
      return {
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalPaidToUsers': 0.0,
      };
    }
  }

  /// Admin wallet document তৈরি করা
  Future<void> ensureOwnerWallet() async {
    final walletRef =
        _firestore.collection(_earningsCollection).doc(_ownerWalletDocument);

    final snapshot = await walletRef.get();

    if (snapshot.exists) {
      return;
    }

    await walletRef.set({
      'balance': 0.0,
      'totalEarned': 0.0,
      'totalPaidToUsers': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// User-এর earning history
  Stream<QuerySnapshot<Map<String, dynamic>>> userTransactionsStream(
    String userId,
  ) {
    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// বর্তমান user-এর earning history
  Stream<QuerySnapshot<Map<String, dynamic>>> myTransactionsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return userTransactionsStream(user.uid);
  }

  /// বর্তমান user-এর withdraw history
  Stream<QuerySnapshot<Map<String, dynamic>>> myWithdrawRequestsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection(_withdrawCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Admin withdraw request approve করবে
  ///
  /// Approve করলে:
  /// 1. request status approved হবে
  /// 2. owner wallet থেকে amount কমবে
  /// 3. totalPaidToUsers বাড়বে
  Future<void> approveWithdrawRequest(
    String requestId,
  ) async {
    final requestRef =
        _firestore.collection(_withdrawCollection).doc(requestId);

    final ownerWalletRef =
        _firestore.collection(_earningsCollection).doc(_ownerWalletDocument);

    final transactionRef =
        _firestore.collection(_transactionsCollection).doc();

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot =
          await transaction.get(requestRef);

      final ownerSnapshot =
          await transaction.get(ownerWalletRef);

      if (!requestSnapshot.exists) {
        throw Exception('Withdraw request পাওয়া যায়নি।');
      }

      final requestData =
          requestSnapshot.data() ?? <String, dynamic>{};

      final currentStatus =
          (requestData['status'] ?? 'pending').toString().toLowerCase();

      if (currentStatus != 'pending') {
        throw Exception('এই request ইতিমধ্যে process করা হয়েছে।');
      }

      final amount =
          _toDouble(requestData['amount']);

      if (amount <= 0) {
        throw Exception('Invalid withdraw amount।');
      }

      final ownerData =
          ownerSnapshot.data() ?? <String, dynamic>{};

      final ownerBalance =
          _toDouble(ownerData['balance']);

      final totalPaid =
          _toDouble(ownerData['totalPaidToUsers']);

      if (ownerBalance < amount) {
        throw Exception(
          'Admin wallet-এ পর্যাপ্ত balance নেই।',
        );
      }

      transaction.update(
        requestRef,
        {
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
        },
      );

      transaction.set(
        ownerWalletRef,
        {
          'balance': ownerBalance - amount,
          'totalEarned':
              _toDouble(ownerData['totalEarned']),
          'totalPaidToUsers': totalPaid + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        transactionRef,
        {
          'userId': requestData['userId'] ?? '',
          'type': 'withdraw',
          'source': 'withdraw_approved',
          'amount': amount,
          'requestId': requestId,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  /// Admin withdraw request reject করবে।
  ///
  /// Reject হলে user-এর টাকা আবার wallet-এ ফেরত যাবে।
  Future<void> rejectWithdrawRequest(
    String requestId,
  ) async {
    final requestRef =
        _firestore.collection(_withdrawCollection).doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot =
          await transaction.get(requestRef);

      if (!requestSnapshot.exists) {
        throw Exception('Withdraw request পাওয়া যায়নি।');
      }

      final requestData =
          requestSnapshot.data() ?? <String, dynamic>{};

      final currentStatus =
          (requestData['status'] ?? 'pending').toString().toLowerCase();

      if (currentStatus != 'pending') {
        throw Exception('এই request ইতিমধ্যে process করা হয়েছে।');
      }

      final userId =
          (requestData['userId'] ?? '').toString();

      final amount =
          _toDouble(requestData['amount']);

      if (userId.isEmpty) {
        throw Exception('User ID পাওয়া যায়নি।');
      }

      if (amount <= 0) {
        throw Exception('Invalid withdraw amount।');
      }

      final userWalletRef =
          _firestore.collection(_earningsCollection).doc(userId);

      final walletSnapshot =
          await transaction.get(userWalletRef);

      final walletData =
          walletSnapshot.data() ?? <String, dynamic>{};

      final currentBalance =
          _toDouble(walletData['balance']);

      transaction.set(
        userWalletRef,
        {
          'userId': userId,
          'balance': currentBalance + amount,
          'totalEarned':
              _toDouble(walletData['totalEarned']),
          'totalWithdrawn':
              _toDouble(walletData['totalWithdrawn']),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.update(
        requestRef,
        {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
          'rejectedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  /// Admin status check
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data() ?? {};

      return data['isAdmin'] == true ||
          data['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  /// User-এর wallet-এর সম্পূর্ণ data
  Future<Map<String, dynamic>> getUserWallet(
    String userId,
  ) async {
    try {
      final doc =
          await _firestore.collection(_earningsCollection).doc(userId).get();

      if (!doc.exists) {
        return {
          'userId': userId,
          'balance': 0.0,
          'totalEarned': 0.0,
          'totalWithdrawn': 0.0,
        };
      }

      final data = doc.data() ?? {};

      return {
        'userId': userId,
        'balance': _toDouble(data['balance']),
        'totalEarned': _toDouble(data['totalEarned']),
        'totalWithdrawn':
            _toDouble(data['totalWithdrawn']),
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
      };
    } catch (_) {
      return {
        'userId': userId,
        'balance': 0.0,
        'totalEarned': 0.0,
        'totalWithdrawn': 0.0,
      };
    }
  }

  /// টাকা format করার helper
  String formatMoney(dynamic value) {
    final amount = _toDouble(value);

    return '৳${amount.toStringAsFixed(2)}';
  }

  double _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}
