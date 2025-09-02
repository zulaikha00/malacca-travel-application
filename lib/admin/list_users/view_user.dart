import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'delete_user.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  // 🌈 Cache to keep consistent color per preference
  static final Map<String, Color> _preferenceColorMap = {};
  static final Random _random = Random();

  // 🌈 Generate consistent random color for each preference
  Color getColorForPreference(String pref) {
    if (_preferenceColorMap.containsKey(pref)) {
      return _preferenceColorMap[pref]!;
    } else {
      final color = Color.fromARGB(
        255,
        _random.nextInt(156) + 100,
        _random.nextInt(156) + 100,
        _random.nextInt(156) + 100,
      );
      _preferenceColorMap[pref] = color;
      return color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final avatarBgFallback = isDark ? Colors.blueGrey[300] : Colors.blueGrey;
    final deleteIconColor = isDark ? Colors.red[300] : Colors.redAccent;

    final double avatarRadius = isPhone ? 24 : 30;
    final double nameFontSize = isPhone ? 15 : 17;
    final double emailFontSize = isPhone ? 12 : 14;
    final double chipFontSize = isPhone ? 10 : 12;
    final double cardPadding = isPhone ? 10 : 12;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Users',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isPhone ? 16 : 20,
          ),
        ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No users found.', style: TextStyle(color: textColor)),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'No name';
              final email = data['email'] ?? 'No email';
              final preferences = (data.containsKey('preferences') && data['preferences'] is List)
                  ? List<String>.from(data['preferences'])
                  : <String>[];
              final profileImageBase64 = data['profileImage'] ?? '';

              Image? profileImage;
              try {
                final decodedBytes = base64Decode(profileImageBase64);
                profileImage = Image.memory(decodedBytes, fit: BoxFit.cover);
              } catch (_) {
                profileImage = null;
              }

              return Card(
                color: cardColor,
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: avatarRadius - 3,
                          backgroundImage: profileImage != null
                              ? MemoryImage(base64Decode(profileImageBase64))
                              : null,
                          backgroundColor: profileImage == null
                              ? avatarBgFallback
                              : Colors.transparent,
                          child: profileImage == null
                              ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: avatarRadius - 5, color: Colors.white),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: nameFontSize,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: emailFontSize,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (preferences.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                runSpacing: -4,
                                children: preferences.map((pref) {
                                  final chipColor = getColorForPreference(pref);
                                  return Chip(
                                    label: Text(
                                      pref,
                                      style: TextStyle(
                                        fontSize: chipFontSize,
                                        color: Colors.black45,
                                      ),
                                    ),
                                    backgroundColor: chipColor,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),

                      // Delete button
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: deleteIconColor),
                        tooltip: "Delete User",
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: isDark ? Colors.grey[900] : null,
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure you want to delete this user?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context, true),
                                  icon: const Icon(Icons.delete_forever, size: 16),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            final uidToDelete = user.id;

                            try {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              final idToken = await currentUser?.getIdToken(true);
                              if (idToken == null) throw Exception("Unable to retrieve ID token");

                              await deleteUserViaHttp(
                                userToDeleteUid: uidToDelete,
                                idToken: idToken,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ User deleted successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Error deleting user: $e')),
                              );
                            }
                          }
                        },
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
