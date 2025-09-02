import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fyp25/profile/verify_email.dart';
import 'package:fyp25/profile/profile_menu_item.dart';
import 'package:fyp25/profile/update_profile.dart';
import 'package:fyp25/service/profile_image_service.dart';
import '../service/auth_service.dart';
import '../settings/dart/favorite.dart';
import '../history/history.dart';
import '../settings/dart/settings_page.dart';
import '../theme/theme_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileImageService _profileService = ProfileImageService();
  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  User? _currentUser;
  String _name = '';
  String _email = '';
  bool _isEmailVerified = false;
  bool _showEmailWarning = true;

  List<String> _preferences = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage();
  }

  String _capitalize(String text) {
    return text
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      await _currentUser!.reload();
      _currentUser = FirebaseAuth.instance.currentUser;
      _email = _currentUser!.email ?? '';
      _isEmailVerified = _currentUser!.emailVerified;

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        setState(() {
          _name = data?['name'] ?? '';
          _preferences = (data?['preferences'] != null && data!['preferences'] is List)
              ? List<String>.from(data['preferences'])
              : [];
        });
      }

      setState(() {
        _showEmailWarning = !_isEmailVerified;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    final imageBytes = await _profileService.loadProfileImage();
    if (imageBytes != null) {
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  void _showPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: isDark ? Colors.white : Colors.black),
                title: Text('Gallery', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: isDark ? Colors.white : Colors.black),
                title: Text('Camera', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final pickedImage = await _profileService.pickImage(context, source);
    if (pickedImage != null) {
      setState(() {
        _isLoading = true;
        _imageFile = pickedImage;
      });

      try {
        await _profileService.uploadImage(pickedImage, context);
        await _loadProfileImage();
        await _loadUserData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 👇 Force phone-like behavior regardless of screen width
    final darkBlue = const Color.fromRGBO(41, 70, 158, 1.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBlue,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18, // Fixed font size for both phone/tablet
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
        child: Column(
          children: [
            // 📧 Email Warning
            if (_currentUser != null && !_isEmailVerified && _showEmailWarning)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Your email is not verified.",
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => VerifyEmailPage())),
                      child: const Text("Verify Now", style: TextStyle(color: Colors.red)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _showEmailWarning = false),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // 👤 Profile Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : _imageBytes != null
                      ? MemoryImage(_imageBytes!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: (_imageFile == null && _imageBytes == null)
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: _showPicker,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: darkBlue,
                      child: const Icon(Icons.add_a_photo_outlined,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🧑 Name & 📧 Email
            Text(
              _name.isNotEmpty ? _name : 'No Name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _email.isNotEmpty ? _email : 'No Email',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            // 🏷️ Preferences
            if (_preferences.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Text(
                      'Your Interests',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _preferences.map((tag) {
                        final tagName = _capitalize(tag.replaceAll("_", " "));
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_outlined, size: 18, color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              Text(
                                tagName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // ✏️ Edit Profile
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditProfile())),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: darkBlue,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Edit Profile', style: TextStyle(fontSize: 14)),
            ),

            const SizedBox(height: 20),

            // 📋 Menu Items
            ProfileMenuItem(icon: Icons.settings, title: 'Settings', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
            }),
            ProfileMenuItem(icon: Icons.mark_email_read, title: 'Verify Email', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyEmailPage()));
            }),
            ProfileMenuItem(icon: Icons.favorite, title: 'Favorite', onTap: () {
              if (_currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoritePlacesPage(uid: _currentUser!.uid)),
                );
              }
            }),
            ProfileMenuItem(icon: Icons.history_outlined, title: 'History', onTap: () {
              if (_currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ViewedHistoryPage(uid: _currentUser!.uid)),
                );
              }
            }),
            ProfileMenuItem(icon: Icons.brightness_2_outlined, title: 'Theme', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemePage()));
            }),
            ProfileMenuItem(icon: Icons.logout, title: 'Logout', isLogout: true, onTap: () async {
              await AuthService().signOut(context);
            }),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
