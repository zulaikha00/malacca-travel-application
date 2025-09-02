import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fyp25/profile/custom_text_field.dart';
import 'package:fyp25/service/profile_image_service.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final nameController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  String? _profileImageUrl;
  bool _isLoading = true;
  final profileImageService = ProfileImageService();

  // 🔹 List of all possible interests
  final List<String> allInterests = [
    'tourist_attraction',
    'museum',
    'art_gallery',
    'park',
    'zoo',
    'restaurant',
    'cafe',
    'shopping_mall',
    'beach',
    'campground',
    'mosque',
    'lodging',
  ];

  // 🔹 List of currently selected interests
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProfileData();
  }

  // 🔄 Load user name and preferences from Firestore
  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      nameController.text = data?['name'] ?? '';
      _selectedInterests = List<String>.from(data?['preferences'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  // 🔄 Load profile image from local storage
  Future<void> _loadProfileData() async {
    final profileImage = await profileImageService.loadProfileImage();
    setState(() {
      _profileImageUrl = profileImage != null ? base64Encode(profileImage) : null;
    });
  }

  // 📸 Pick and upload new profile image
  Future<void> _pickNewProfileImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final newImage = await profileImageService.pickImage(context, source);
      if (newImage != null) {
        await profileImageService.uploadImage(newImage, context);
        setState(() => _profileImageUrl = base64Encode(newImage.readAsBytesSync()));
      }
    }
  }

  // ✅ Update profile (name + interests + password if needed)
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();

    try {
      // 🔐 Re-authenticate if changing password
      if (currentPassword.isNotEmpty && newPassword.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }

      // 📝 Update name and interests
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': nameController.text,
        'preferences': _selectedInterests,
      }, SetOptions(merge: true));

      await user.reload();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _capitalize(String input) {
    return input.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '').join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    const Color iconBgColor = Color.fromRGBO(41, 70, 158, 1.0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: iconBgColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _updateProfile,
            tooltip: 'Save',
          ),
        ],
      ),

      backgroundColor: bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
            children: [
              // 👤 Profile Picture
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      backgroundImage: _profileImageUrl != null
                          ? MemoryImage(base64Decode(_profileImageUrl!))
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                          : null,
                    ),
                    GestureDetector(
                      onTap: _pickNewProfileImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: iconBgColor,
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 👤 Name Input
                CustomTextField(
                  icon: Icons.person,
                  hint: 'Full Name',
                  controller: nameController,
                  isDarkMode: isDarkMode,
                ),

                const SizedBox(height: 12),

                // 🔐 Current Password
                CustomTextField(
                  icon: Icons.lock,
                  hint: 'Current Password',
                  controller: currentPasswordController,
                  isPassword: true,
                  isDarkMode: isDarkMode,
                ),

                const SizedBox(height: 12),

                // 🔐 New Password
                CustomTextField(
                  icon: Icons.lock_outline,
                  hint: 'New Password',
                  controller: newPasswordController,
                  isPassword: true,
                  isDarkMode: isDarkMode,
                ),

                const SizedBox(height: 25),

                // 💬 Interests (ChoiceChips)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Interests:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: allInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return ChoiceChip(
                      label: Text(
                        _capitalize(interest.replaceAll('_', ' ')),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: iconBgColor,
                      backgroundColor: Colors.grey[200],
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),

            const SizedBox(height: 25),

                // 💾 Save Button
                 /*SizedBox(
                  width: double.infinity,
                  height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: iconBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                ),*/
           ],
        ),
      ),
    );
  }
}