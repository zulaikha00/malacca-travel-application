import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_dashboard.dart';

class AdminEditProfile extends StatefulWidget {
  final String adminId; // Document ID in 'admins' collection

  const AdminEditProfile({super.key, required this.adminId});

  @override
  State<AdminEditProfile> createState() => _AdminEditProfileState();
}

class _AdminEditProfileState extends State<AdminEditProfile> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;

  String? _imageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _roleController = TextEditingController();
    _loadAdminData(); // Load data on startup
  }

  /// 🔁 Load admin data from Firestore
  Future<void> _loadAdminData() async {
    final doc = await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).get();
    final data = doc.data();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _roleController.text = data['role'] ?? '';
      _imageUrl = data['photo'];
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// 📤 Pick and upload photo to Firebase Storage
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final Uint8List bytes = await image.readAsBytes();
    final ref = FirebaseStorage.instance
        .ref()
        .child('admin_photos/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putData(bytes);
    final url = await ref.getDownloadURL();

    setState(() {
      _imageUrl = url;
    });
  }

  /// 💾 Save profile updates to Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).update({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _roleController.text.trim(),
      'photo': _imageUrl ?? '',
    });

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  /// ✨ UI
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final fillColor = isDark ? Colors.grey[850] : Colors.grey.shade100;
    final inputBorderColor = isDark ? Colors.grey[700]! : Colors.grey;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Admin Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                ),
              );
            },
          ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Ensures back arrow is white
      ),
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🖼️ Profile Image + Edit
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageUrl != null
                          ? NetworkImage(_imageUrl!)
                          : const AssetImage('assets/placeholder.jpg') as ImageProvider,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ✍️ Name
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                icon: Icons.person,
                fillColor: fillColor!,
                borderColor: inputBorderColor,
                textColor: textColor,
              ),

              const SizedBox(height: 16),

              // 📧 Email (readonly)
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                readOnly: true,
                fillColor: fillColor,
                borderColor: inputBorderColor,
                textColor: textColor,
              ),

              const SizedBox(height: 16),

              // 🛡️ Role (Editable only for non-Super Admin)
              _buildRoleField(
                controller: _roleController,
                fillColor: fillColor,
                borderColor: inputBorderColor,
                textColor: textColor,
              ),




              const SizedBox(height: 24), // Add some spacing before the button
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF29469E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// 🔧 Reusable styled text field for light/dark mode
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: (value) => value == null || value.trim().isEmpty ? 'Required field' : null,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: textColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: const Color(0xFF29469E), width: 2),
        ),
      ),
    );
  }

  /// 🛡️ Custom Role field - readonly for Super Admin, dropdown for others
  Widget _buildRoleField({
    required TextEditingController controller,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final bool isSuperAdmin = controller.text.trim() == 'Super Admin';

    if (isSuperAdmin) {
      return _buildTextField(
        controller: controller,
        label: 'Role',
        icon: Icons.badge,
        fillColor: fillColor,
        borderColor: borderColor,
        textColor: textColor,
        readOnly: true,
      );
    } else {
      return DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        items: const [
          DropdownMenuItem(value: 'Admin', child: Text('Admin')),
          DropdownMenuItem(value: 'Super Admin', child: Text('Super Admin')),
        ],
        onChanged: (value) {
          controller.text = value!;
        },
        icon: const Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          labelText: 'Role',
          prefixIcon: Icon(Icons.badge, color: textColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF29469E), width: 2),
          ),
          labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
        ),
        dropdownColor: fillColor,
        style: TextStyle(color: textColor),
      );
    }
  }
}

