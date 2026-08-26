import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
const AdminUsersScreen({super.key});

@override
State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;

bool _loading = true;
bool _isAdmin = false;

@override
void initState() {
super.initState();
_checkAdmin();
}

Future<void> _checkAdmin() async {
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

  final doc = await _firestore.collection('users').doc(user.uid).get();

  final data = doc.data() ?? {};

  final admin = data['isAdmin'] == true || data['admin'] == true;

  if (!mounted) return;

  setState(() {
    _isAdmin = admin;
    _loading = false;
  });
} catch (_) {
  if (!mounted) return;

  setState(() {
    _isAdmin = false;
    _loading = false;
  });
}

}

String _stringValue(dynamic value) {
if (value == null) {
return '';
}

return value.toString();

}

bool _boolValue(dynamic value) {
return value == true;
}

String _userName(Map<String, dynamic> data) {
final name = _stringValue(
data['name'] ??
data['displayName'] ??
data['username'] ??
data['userName'],
);

return name.isEmpty ? 'Unknown User' : name;

}

String _userEmail(
Map<String, dynamic> data,
String documentId,
) {
final email = _stringValue(data['email']);

return email.isEmpty ? documentId : email;

}

String _photoUrl(Map<String, dynamic> data) {
return _stringValue(
data['photoUrl'] ??
data['photoURL'] ??
data['profileImage'] ??
data['imageUrl'],
);
}

String _bio(Map<String, dynamic> data) {
return _stringValue(data['bio']);
}

String _website(Map<String, dynamic> data) {
return _stringValue(data['website']);
}

String _phone(Map<String, dynamic> data) {
return _stringValue(
data['phone'] ?? data['phoneNumber'],
);
}

String _location(Map<String, dynamic> data) {
return _stringValue(
data['location'] ?? data['address'],
);
}

String _createdDate(Map<String, dynamic> data) {
final value = data['createdAt'];

if (value is Timestamp) {
  final date = value.toDate();

  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

return '';

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

Future<void> _toggleAdmin(
String userId,
bool currentValue,
) async {
final currentUser = _auth.currentUser;

if (currentUser == null) {
  _showMessage('Admin login পাওয়া যায়নি');
  return;
}

if (currentUser.uid == userId) {
  _showMessage('নিজের Admin status পরিবর্তন করা যাবে না');
  return;
}

try {
  await _firestore.collection('users').doc(userId).update({
    'isAdmin': !currentValue,
    'admin': !currentValue,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  _showMessage(
    !currentValue
        ? 'User-কে Admin করা হয়েছে'
        : 'Admin status সরানো হয়েছে',
  );
} catch (e) {
  _showMessage('Admin status পরিবর্তন করা যায়নি');
}

}

Future<void> _deleteUser(
String userId,
String name,
) async {
final currentUser = _auth.currentUser;

if (currentUser == null) {
  _showMessage('Admin login পাওয়া যায়নি');
  return;
}

if (currentUser.uid == userId) {
  _showMessage('নিজের account delete করা যাবে না');
  return;
}

final confirmed = await showDialog<bool>(
  context: context,
  builder: (dialogContext) {
    return AlertDialog(
      title: const Text('User Delete'),
      content: Text(
        'আপনি কি "$name" user-এর Firestore profile delete করতে চান?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false);
          },
          child: const Text('না'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(true);
          },
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
  await _firestore.collection('users').doc(userId).delete();

  _showMessage('User profile delete হয়েছে');
} catch (_) {
  _showMessage('User profile delete করা যায়নি');
}

}

void _showUserDetails(
String userId,
Map<String, dynamic> data,
) {
final name = _userName(data);
final email = _userEmail(data, userId);
final phone = _phone(data);
final location = _location(data);
final bio = _bio(data);
final website = _website(data);
final isAdmin =
_boolValue(data['isAdmin']) || _boolValue(data['admin']);
final photoUrl = _photoUrl(data);
final createdDate = _createdDate(data);

showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheetContext) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photoUrl.isNotEmpty)
                CircleAvatar(
                  radius: 42,
                  backgroundImage: NetworkImage(photoUrl),
                )
              else
                CircleAvatar(
                  radius: 42,
                  child: Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (isAdmin)
                const Chip(
                  avatar: Icon(
                    Icons.admin_panel_settings,
                    size: 18,
                  ),
                  label: Text('ADMIN'),
                ),
              const SizedBox(height: 16),
              _detailRow(
                Icons.email_outlined,
                'Email',
                email,
              ),
              _detailRow(
                Icons.phone_outlined,
                'Phone',
                phone.isEmpty ? 'Not set' : phone,
              ),
              _detailRow(
                Icons.location_on_outlined,
                'Location',
                location.isEmpty ? 'Not set' : location,
              ),
              _detailRow(
                Icons.link,
                'Website',
                website.isEmpty ? 'Not set' : website,
              ),
              _detailRow(
                Icons.info_outline,
                'Bio',
                bio.isEmpty ? 'Not set' : bio,
              ),
              _detailRow(
                Icons.calendar_today_outlined,
                'Joined',
                createdDate.isEmpty ? 'Unknown' : createdDate,
              ),
              _detailRow(
                Icons.fingerprint,
                'User ID',
                userId,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('বন্ধ করুন'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);

}

Widget _detailRow(
IconData icon,
String title,
String value,
) {
return Container(
width: double.infinity,
margin: const EdgeInsets.only(bottom: 10),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Theme.of(context)
.colorScheme
.surfaceContainerHighest
.withValues(alpha: 0.45),
borderRadius: BorderRadius.circular(12),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
icon,
size: 22,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade700,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 2),
SelectableText(
value,
style: const TextStyle(
fontSize: 15,
),
),
],
),
),
],
),
);
}

Widget _buildUserAvatar(
Map<String, dynamic> data,
String name,
) {
final photoUrl = _photoUrl(data);

if (photoUrl.isNotEmpty) {
  return CircleAvatar(
    radius: 25,
    backgroundImage: NetworkImage(photoUrl),
  );
}

return CircleAvatar(
  radius: 25,
  child: Text(
    name.isNotEmpty ? name[0].toUpperCase() : 'U',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
);

}

Widget _buildUserCard(
BuildContext context,
QueryDocumentSnapshot<Map<String, dynamic>> document,
) {
final data = document.data();
final userId = document.id;

final name = _userName(data);
final email = _userEmail(data, userId);

final isAdmin =
    _boolValue(data['isAdmin']) || _boolValue(data['admin']);

return Card(
  margin: const EdgeInsets.only(bottom: 10),
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      _showUserDetails(
        userId,
        data,
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildUserAvatar(
            data,
            name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: $userId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'details') {
                _showUserDetails(
                  userId,
                  data,
                );
              } else if (value == 'admin') {
                _toggleAdmin(
                  userId,
                  isAdmin,
                );
              } else if (value == 'delete') {
                _deleteUser(
                  userId,
                  name,
                );
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'details',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.person_outline,
                    ),
                    title: Text('Details'),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'admin',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.admin_panel_settings,
                    ),
                    title: Text(
                      isAdmin
                          ? 'Remove Admin'
                          : 'Make Admin',
                    ),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_outline,
                    ),
                    title: Text('Delete Profile'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    ),
  ),
);

}

@override
Widget build(BuildContext context) {
if (_loading) {
return Scaffold(
appBar: AppBar(
title: const Text('Manage Users'),
),
body: const Center(
child: CircularProgressIndicator(),
),
);
}

if (!_isAdmin) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manage Users'),
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
            const SizedBox(height: 12),
            const Text(
              'Admin Dashboard ব্যবহার করার জন্য '
              'আপনার users document-এ isAdmin অথবা admin '
              'true থাকতে হবে।',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                });

                _checkAdmin();
              },
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
      'Manage Users',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    actions: [
      IconButton(
        tooltip: 'Refresh',
        onPressed: () {
          setState(() {
            _loading = true;
          });

          _checkAdmin();
        },
        icon: const Icon(Icons.refresh),
      ),
    ],
  ),
  body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _firestore
        .collection('users')
        .orderBy(
          'name',
          descending: false,
        )
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Users লোড করতে সমস্যা হয়েছে',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          ),
        );
      }

      final documents = snapshot.data?.docs ?? [];

      if (documents.isEmpty) {
        return RefreshIndicator(
          onRefresh: _checkAdmin,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 220),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 70,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'কোনো user পাওয়া যায়নি',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
        onRefresh: _checkAdmin,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return _buildUserCard(
              context,
              documents[index],
            );
          },
        ),
      );
    },
  ),
);

}
}
