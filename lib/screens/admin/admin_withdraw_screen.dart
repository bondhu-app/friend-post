import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWithdrawScreen extends StatefulWidget {
  const AdminWithdrawScreen({super.key});

  @override
  State<AdminWithdrawScreen> createState() =>
      _AdminWithdrawScreenState();
}

class _AdminWithdrawScreenState
    extends State<AdminWithdrawScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isUpdating = false;

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  Future<void> _updateRequest({
    required String requestId,
    required String status,
  }) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _firestore
          .collection('withdraw_requests')
          .doc(requestId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Withdraw approved successfully.'
                  : 'Withdraw rejected successfully.',
            ),
          ),
        );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.message ??
                  'Withdraw request update করা যায়নি।',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Withdraw request update করা যায়নি।',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _confirmAction({
    required String requestId,
    required String status,
  }) async {
    final isApprove = status == 'approved';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isApprove
                ? 'Approve Withdraw'
                : 'Reject Withdraw',
          ),
          content: Text(
            isApprove
                ? 'আপনি কি এই withdrawal request approve করতে চান?'
                : 'আপনি কি এই withdrawal request reject করতে চান?',
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
              child: Text(
                isApprove ? 'Approve' : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _updateRequest(
      requestId: requestId,
      status: status,
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final userName =
        (data['userName'] ??
                data['name'] ??
                data['displayName'] ??
                'User')
            .toString();

    final userId =
        (data['userId'] ??
                data['uid'] ??
                '')
            .toString();

    final amount = data['amount'];

    final method =
        (data['method'] ??
                data['paymentMethod'] ??
                'Unknown')
            .toString();

    final account =
        (data['account'] ??
                data['accountNumber'] ??
                data['number'] ??
                data['phone'] ??
                '')
            .toString();

    final status =
        (data['status'] ??
                'pending')
            .toString()
            .toLowerCase();

    final createdAt =
        data['createdAt'];

    String dateText = 'সময় পাওয়া যায়নি';

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      dateText =
          '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : 'U',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      if (userId.isNotEmpty)
                        Text(
                          userId,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  _money(amount),
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _infoRow(
              'Payment Method',
              method,
            ),

            if (account.isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(
                'Account',
                account,
              ),
            ],

            const SizedBox(height: 8),

            _infoRow(
              'Date',
              dateText,
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                _statusChip(status),
              ],
            ),

            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isUpdating
                              ? null
                              : () {
                                  _confirmAction(
                                    requestId:
                                        document.id,
                                    status:
                                        'rejected',
                                  );
                                },
                      icon: const Icon(
                        Icons.close,
                      ),
                      label: const Text(
                        'Reject',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isUpdating
                              ? null
                              : () {
                                  _confirmAction(
                                    requestId:
                                        document.id,
                                    status:
                                        'approved',
                                  );
                                },
                      icon: const Icon(
                        Icons.check,
                      ),
                      label: const Text(
                        'Approve',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    String label = status;

    if (status == 'pending') {
      label = 'PENDING';
    } else if (status == 'approved') {
      label = 'APPROVED';
    } else if (status == 'rejected') {
      label = 'REJECTED';
    }

    return Chip(
      label: Text(label),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Withdraw Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: _firestore
            .collection(
              'withdraw_requests',
            )
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      'Withdraw requests লোড করা যায়নি।',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      snapshot.error
                              ?.toString() ??
                          '',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                children: const [
                  SizedBox(
                    height: 220,
                  ),
                  Center(
                    child: Text(
                      'কোনো withdrawal request নেই।',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final sortedDocuments =
              [...documents];

          sortedDocuments.sort(
            (a, b) {
              final aData = a.data();
              final bData = b.data();

              final aTime =
                  aData['createdAt'];

              final bTime =
                  bData['createdAt'];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime.compareTo(
                  aTime,
                );
              }

              return 0;
            },
          );

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  sortedDocuments.length,
              itemBuilder: (
                context,
                index,
              ) {
                return _buildRequestCard(
                  context,
                  sortedDocuments[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
