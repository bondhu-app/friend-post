import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _isAdmin = false;

  int _usersCount = 0;
  int _postsCount = 0;
  int _commentsCount = 0;
  int _withdrawCount = 0;

  double _adminBalance = 0;
  double _totalEarned = 0;
  double _totalPaidToUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }

      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      final userData = userDoc.data() ?? {};

      final isAdminValue =
          userData['isAdmin'] == true || userData['admin'] == true;

      if (!isAdminValue) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _loading = false;
        });
        return;
      }

      _isAdmin = true;

      await Future.wait([
        _loadUsersCount(),
        _loadPostsCount(),
        _loadCommentsCount(),
        _loadWithdrawCount(),
        _loadAdminWallet(),
      ]);
    } catch (e) {
      if (mounted) {
        _showMessage('Dashboard লোড করতে সমস্যা হয়েছে');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadUsersCount() async {
    try {
      final snapshot = await _firestore.collection('users').count().get();

      _usersCount = snapshot.count ?? 0;
    } catch (_) {
      try {
        final snapshot = await _firestore.collection('users').get();
        _usersCount = snapshot.docs.length;
      } catch (_) {
        _usersCount = 0;
      }
    }
  }

  Future<void> _loadPostsCount() async {
    try {
      final snapshot = await _firestore.collection('posts').count().get();

      _postsCount = snapshot.count ?? 0;
    } catch (_) {
      try {
        final snapshot = await _firestore.collection('posts').get();
        _postsCount = snapshot.docs.length;
      } catch (_) {
        _postsCount = 0;
      }
    }
  }

  Future<void> _loadCommentsCount() async {
    try {
      int total = 0;

      final postsSnapshot = await _firestore.collection('posts').get();

      for (final post in postsSnapshot.docs) {
        try {
          final comments = await _firestore
              .collection('posts')
              .doc(post.id)
              .collection('comments')
              .count()
              .get();

          total += comments.count ?? 0;
        } catch (_) {}
      }

      _commentsCount = total;
    } catch (_) {
      _commentsCount = 0;
    }
  }

  Future<void> _loadWithdrawCount() async {
    try {
      final snapshot =
          await _firestore.collection('withdraw_requests').count().get();

      _withdrawCount = snapshot.count ?? 0;
    } catch (_) {
      try {
        final snapshot =
            await _firestore.collection('withdraw_requests').get();

        _withdrawCount = snapshot.docs.length;
      } catch (_) {
        _withdrawCount = 0;
      }
    }
  }

  Future<void> _loadAdminWallet() async {
    try {
      final walletDoc =
          await _firestore.collection('earnings').doc('owner_wallet').get();

      if (!walletDoc.exists) {
        return;
      }

      final data = walletDoc.data() ?? {};

      _adminBalance = _toDouble(data['balance']);
      _totalEarned = _toDouble(data['totalEarned']);
      _totalPaidToUsers = _toDouble(data['totalPaidToUsers']);
    } catch (_) {
      try {
        final walletDoc =
            await _firestore.collection('admin').doc('owner_wallet').get();

        if (!walletDoc.exists) {
          return;
        }

        final data = walletDoc.data() ?? {};

        _adminBalance = _toDouble(data['balance']);
        _totalEarned = _toDouble(data['totalEarned']);
        _totalPaidToUsers = _toDouble(data['totalPaidToUsers']);
      } catch (_) {}
    }
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

  String _money(double value) {
    return '৳${value.toStringAsFixed(2)}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openWithdrawRequests() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _WithdrawRequestsScreen(),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _openUsers() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _AdminUsersScreen(),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _openPosts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _AdminPostsScreen(),
      ),
    );

    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'আপনার Admin Access নেই',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Firebase Firestore-এর users collection-এ '
                  'আপনার document-এর isAdmin অথবা admin field true হতে হবে।',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildStatisticsGrid(),
            const SizedBox(height: 20),
            _buildRevenueCard(),
            const SizedBox(height: 20),
            _buildManagementSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final email = _auth.currentUser?.email ?? 'Admin';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: const Icon(
                Icons.admin_panel_settings,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Admin',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _statCard(
          title: 'Users',
          value: '$_usersCount',
          icon: Icons.people,
        ),
        _statCard(
          title: 'Posts',
          value: '$_postsCount',
          icon: Icons.article,
        ),
        _statCard(
          title: 'Comments',
          value: '$_commentsCount',
          icon: Icons.comment,
        ),
        _statCard(
          title: 'Withdraw',
          value: '$_withdrawCount',
          icon: Icons.payments,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet),
                SizedBox(width: 10),
                Text(
                  'Admin Revenue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _revenueRow(
              'Admin Balance',
              _money(_adminBalance),
            ),
            const Divider(),
            _revenueRow(
              'Total Earned',
              _money(_totalEarned),
            ),
            const Divider(),
            _revenueRow(
              'Paid to Users',
              _money(_totalPaidToUsers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _revenueRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _managementTile(
          icon: Icons.people,
          title: 'Manage Users',
          subtitle: 'Users দেখা এবং Admin status পরিচালনা',
          onTap: _openUsers,
        ),
        _managementTile(
          icon: Icons.article,
          title: 'Manage Posts',
          subtitle: 'Posts দেখা এবং প্রয়োজন হলে delete করা',
          onTap: _openPosts,
        ),
        _managementTile(
          icon: Icons.account_balance_wallet,
          title: 'Admin Wallet',
          subtitle: 'Admin balance এবং revenue',
          onTap: () {
            _showWalletDialog();
          },
        ),
        _managementTile(
          icon: Icons.payments,
          title: 'Withdraw Requests',
          subtitle: 'User withdrawal requests পরিচালনা',
          onTap: _openWithdrawRequests,
        ),
      ],
    );
  }

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showWalletDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogMoneyRow(
                'Balance',
                _money(_adminBalance),
              ),
              const SizedBox(height: 12),
              _dialogMoneyRow(
                'Total Earned',
                _money(_totalEarned),
              ),
              const SizedBox(height: 12),
              _dialogMoneyRow(
                'Paid to Users',
                _money(_totalPaidToUsers),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বন্ধ করুন'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogMoneyRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              USERS SCREEN                                  */
/* -------------------------------------------------------------------------- */

class _AdminUsersScreen extends StatelessWidget {
  const _AdminUsersScreen();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Users লোড করা যায়নি'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('কোনো user পাওয়া যায়নি'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name =
                  (data['name'] ?? data['displayName'] ?? 'Unknown User')
                      .toString();

              final email = (data['email'] ?? '').toString();

              final isAdmin =
                  data['isAdmin'] == true || data['admin'] == true;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    ),
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    email.isEmpty ? doc.id : email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isAdmin
                      ? const Chip(
                          label: Text('ADMIN'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              POSTS SCREEN                                  */
/* -------------------------------------------------------------------------- */

class _AdminPostsScreen extends StatelessWidget {
  const _AdminPostsScreen();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deletePost(
    BuildContext context,
    String postId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Post Delete'),
          content: const Text(
            'আপনি কি এই post-টি delete করতে চান?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('না'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestore.collection('posts').doc(postId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post delete হয়েছে'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post delete করা যায়নি'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Posts'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('posts')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Posts লোড করতে সমস্যা হয়েছে।\n'
                'createdAt index/order field না থাকলে এখানে error হতে পারে।',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('কোনো post পাওয়া যায়নি'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final text = (data['text'] ??
                      data['content'] ??
                      data['caption'] ??
                      '')
                  .toString();

              final userName =
                  (data['userName'] ?? data['name'] ?? 'User').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.article),
                  ),
                  title: Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    text.isEmpty ? 'No text' : text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _deletePost(
                        context,
                        doc.id,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         WITHDRAW REQUEST SCREEN                            */
/* -------------------------------------------------------------------------- */

class _WithdrawRequestsScreen extends StatelessWidget {
  const _WithdrawRequestsScreen();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _money(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else if (value is String) {
      amount = double.tryParse(value) ?? 0;
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  Future<void> _updateRequest(
    BuildContext context,
    String requestId,
    String status,
  ) async {
    try {
      await _firestore
          .collection('withdraw_requests')
          .doc(requestId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Withdraw approved'
                  : 'Withdraw rejected',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request update করা যায়নি'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Requests'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('withdraw_requests')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Withdraw requests লোড করতে সমস্যা হয়েছে।',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('কোনো withdraw request নেই'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final userName =
                  (data['userName'] ?? data['name'] ?? 'User').toString();

              final userId = (data['userId'] ?? '').toString();

              final amount = data['amount'];

              final method =
                  (data['method'] ?? data['paymentMethod'] ?? 'Unknown')
                      .toString();

              final status =
                  (data['status'] ?? 'pending').toString().toLowerCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userId.isNotEmpty)
                                  Text(
                                    userId,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _money(amount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Payment: $method'),
                      const SizedBox(height: 6),
                      Text('Status: $status'),
                      const SizedBox(height: 12),
                      if (status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _updateRequest(
                                    context,
                                    doc.id,
                                    'rejected',
                                  );
                                },
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  _updateRequest(
                                    context,
                                    doc.id,
                                    'approved',
                                  );
                                },
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
