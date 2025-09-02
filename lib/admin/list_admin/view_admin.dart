import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'delete_admin.dart'; // 🔁 Your Cloud Function HTTP call
import 'add_admin.dart';   // ➕ Add Admin dialog

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  bool _isSuperAdmin = false;           // ✅ Role check flag
  String? _currentUid;                  // ✅ Track logged-in user's UID
  bool _isSelectionMode = false;        // ✅ Multi-select mode flag
  final Set<String> _selectedUids = {}; // ✅ List of selected UIDs

  @override
  void initState() {
    super.initState();
    checkIfSuperAdmin(); // 🔍 Check role on page load
  }

  /// 🔍 Check if the current user is a Super Admin
  Future<void> checkIfSuperAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _currentUid = user.uid;
    final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();

    if (doc.exists && doc['role'] == 'Super Admin') {
      setState(() {
        _isSuperAdmin = true;
      });
    }
  }

  /// 🔁 Toggle select/unselect a user
  void _toggleSelection(String uid) {
    setState(() {
      if (_selectedUids.contains(uid)) {
        _selectedUids.remove(uid);
      } else {
        _selectedUids.add(uid);
      }
      _isSelectionMode = _selectedUids.isNotEmpty;
    });
  }

  /// 🗑️ Delete all selected admins via Cloud Function
  Future<void> _deleteSelectedAdmins() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final myUid = user?.uid;

    // ❌ Remove self if selected
    _selectedUids.remove(myUid);

    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ You cannot delete your own account.')),
      );
      setState(() {
        _isSelectionMode = false;
      });
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.dialogBackgroundColor,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: colorScheme.secondary, size: 28),
              const SizedBox(width: 10),
              Text(
                'Delete Admins',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the selected admins? This action cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );


    if (confirm != true) return;

    for (final uid in _selectedUids) {
      try {
        await deleteAdminViaHttp(
          context: context,
          adminToDeleteUid: uid,
          idToken: idToken!,
        );
      } catch (e) {
        print('❌ Error deleting admin $uid: $e');
      }
    }

    setState(() {
      _selectedUids.clear();
      _isSelectionMode = false;
    });
  }

  /// 🎨 Badge with color based on role
  Widget buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'Super Admin':
        color = Colors.deepPurple;
        break;
      case 'Admin':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
            title: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isPhone = screenWidth < 600;

                return Text(
                  _isSelectionMode ? '${_selectedUids.length} selected' : 'Admins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPhone ? 16 : 20, // 👈 Adjust font size based on screen
                    //fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

        backgroundColor: Color.fromRGBO(41, 70, 158, 1.0),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedAdmins,
              tooltip: 'Delete selected admins',
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 🔍 Optional: search functionality
            },
          ),
        ],
      ),

      // 📡 Real-time stream of admins from Firestore
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No admins found.'));
          }

          // 🔃 Sort: Super Admins first, then Admins
          final admins = snapshot.data!.docs..sort((a, b) {
            final aRole = a['role'] ?? '';
            final bRole = b['role'] ?? '';

            if (aRole == 'Super Admin' && bRole != 'Super Admin') return -1;
            if (aRole != 'Super Admin' && bRole == 'Super Admin') return 1;
            return 0; // Keep original order otherwise
          });

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final doc = admins[index];
              final data = doc.data() as Map<String, dynamic>;
              final uid = doc.id;
              final name = data['name'] ?? 'Unnamed';
              final email = data['email'] ?? 'No email';
              final role = data['role'] ?? 'No role';
              final photoUrl = data['photo']?.toString() ?? '';

              final isSelected = _selectedUids.contains(uid);
              final isCurrentUser = uid == _currentUid;

              return GestureDetector(
                onLongPress: () {
                  if (!_isSuperAdmin || isCurrentUser) return;
                  _toggleSelection(uid);
                },
                onTap: () {
                  if (_isSelectionMode && !isCurrentUser) {
                    _toggleSelection(uid);
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: isSelected ? Colors.red.shade100 : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email),
                        const SizedBox(height: 4),
                        buildRoleBadge(role), // 🎖️ Show role badge
                      ],
                    ),
                    trailing: _isSelectionMode && isSelected
                        ? const Icon(Icons.check_circle, color: Colors.red)
                        : null,
                  ),
                ),
              );
            },
          );
        },
      ),

      // ➕ FAB only visible to Super Admins & not in selection mode
      floatingActionButton: _isSuperAdmin && !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () {
                showAddAdminDialog(context); // ⬅️ Add Admin dialog
              },
              backgroundColor: Color.fromRGBO(41, 70, 158, 1.0),
             child: const Icon(Icons.person_add, color: Colors.white),

        tooltip: 'Add Admin',
      )
          : null,
    );
  }
}
