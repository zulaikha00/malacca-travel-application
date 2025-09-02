import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Import FirebaseAuth
import 'package:fyp25/admin/admin_settings/setting_admin.dart';

import '../../settings/dart/settings_page.dart';
import '../booking/booking_list.dart';
import '../list_places/view_places.dart';
import 'admin_profile_header.dart';
import 'widget_dashboard.dart';

import '../list_admin/view_admin.dart';
import '../list_categories/view_categories.dart';
import '../list_users/view_user.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _adminData;
  bool _isLoading = true;

  /// Load dashboard data and admin profile for current logged-in user
  Future<List<QuerySnapshot>> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No user logged in, return empty results or handle accordingly
      setState(() {
        _adminData = null;
        _isLoading = false;
      });
      return Future.error('User not logged in');
    }

    // Query the admin document for the current user UID
    final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();

    if (!adminDoc.exists) {
      setState(() {
        _adminData = null;
        _isLoading = false;
      });
      return Future.error('Admin document not found');
    }

    // Set _adminData to current admin's document data + uid
    _adminData = adminDoc.data()!..['uid'] = adminDoc.id;

    // Also load other dashboard collections in parallel
    final snapshots = await Future.wait([
      FirebaseFirestore.instance.collection('users').get(),
      FirebaseFirestore.instance.collection('admins').get(),
      FirebaseFirestore.instance.collection('melaka_places').get(),
      FirebaseFirestore.instance.collection('booking').get(),
    ]);

    setState(() {
      _isLoading = false;
    });

    return snapshots;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                ),
              );
            },
          ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(41, 70, 158, 1.0),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white, // 🎨 Set icon color to white
            ),

            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsAdminPage()),
              );
            },
          ),
        ],

        // ✅ Add IconButton for generating accuracy report
        /*actions: [
          IconButton(
            tooltip: 'Run Accuracy Test',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final tester = RecommendationAccuracyTester();
              await tester.runAccuracyTest(k: 5);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Accuracy test completed')),
              );
            },
          ),
        ],*/
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.length < 4) {
            return const Center(child: Text('Failed to load data.'));
          }

          final userCount = snapshot.data![0].docs.length;
          final adminCount = snapshot.data![1].docs.length;
          final placesSnapshot = snapshot.data![2];
          final bookingCount = snapshot.data![3].docs.length;

          // Calculate unique first category types
          final Set<String> uniqueFirstTypes = {};
          for (var doc in placesSnapshot.docs) {
            final List<dynamic>? types = doc['types'];
            if (types != null && types.isNotEmpty && types[0] is String) {
              uniqueFirstTypes.add(types[0]);
            }
          }
          final categoryCount = uniqueFirstTypes.length;

          final dashboardStats = [
            {
              'title': 'Registered Users',
              'value': userCount.toString(),
              'icon': Icons.person,
              'iconColor': Colors.white,
              'iconBg': Colors.deepPurple,
              'cardColor': isDark ? Colors.deepPurple.shade700 : Colors.deepPurple.shade50,
              'onTap': () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const UserListPage())),
            },
            {
              'title': 'Categories',
              'value': categoryCount.toString(),
              'icon': Icons.category,
              'iconColor': Colors.white,
              'iconBg': Colors.teal,
              'cardColor': isDark ? Colors.teal.shade700 : Colors.teal.shade50,
              'onTap': () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const TypesPage())),
            },
            {
              'title': 'Places',
              'value': placesSnapshot.docs.length.toString(),
              'icon': Icons.place,
              'iconColor': Colors.white,
              'iconBg': Colors.orange,
              'cardColor': isDark ? Colors.orange.shade700 : Colors.orange.shade50,
              'onTap': () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ViewPlacesPage())),
            },
            {
              'title': 'Total Booking',
              'value': bookingCount.toString(),
              'icon': Icons.event_note,
              'iconColor': Colors.white,
              'iconBg': Colors.indigo,
              'cardColor': isDark ? Colors.indigo.shade700 : Colors.indigo.shade100,
              'onTap': () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AdminBookingListPage())),
            },
            {
              'title': 'Admins',
              'value': adminCount.toString(),
              'icon': Icons.admin_panel_settings,
              'iconColor': Colors.white,
              'iconBg': Colors.redAccent,
              'cardColor': isDark ? Colors.redAccent.shade700 : Colors.redAccent.shade100,
              'onTap': () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AdminListPage())),
            },
          ];

          // If adminData still null, show error
          if (_adminData == null) {
            return const Center(child: Text('Admin profile not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pass current logged-in admin data to AdminProfileHeader
                AdminProfileHeader(
                  adminData: _adminData!,
                  onPhotoUpdated: () {
                    setState(() {
                      // Reload to refresh profile photo or info
                      _loadData();
                    });
                  },
                ),

                const SizedBox(height: 24),

                ListView.builder(
                  itemCount: dashboardStats.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = dashboardStats[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DashboardStatCard(
                        title: item['title'] as String,
                        value: item['value'] as String,
                        icon: item['icon'] as IconData,
                        iconColor: item['iconColor'] as Color,
                        iconBg: item['iconBg'] as Color,
                        cardColor: item['cardColor'] as Color,
                        onTap: item['onTap'] as VoidCallback?,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
