import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_profile.dart';

class AdminProfileHeader extends StatefulWidget {
  final Map<String, dynamic> adminData;
  final VoidCallback onPhotoUpdated;

  const AdminProfileHeader({
    super.key,
    required this.adminData,
    required this.onPhotoUpdated,
  });

  @override
  State<AdminProfileHeader> createState() => _AdminProfileHeaderState();
}

class _AdminProfileHeaderState extends State<AdminProfileHeader> {
  bool _isUploading = false;

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              _uploadPhoto(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              _uploadPhoto(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (picked == null) return;

    setState(() => _isUploading = true);
    final uid = widget.adminData['uid'];
    final file = File(picked.path);

    try {
      final ref = FirebaseStorage.instance.ref('admin_photos/$uid.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('admins').doc(uid).update({
        'photo': url,
      });

      widget.onPhotoUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.adminData['photo']?.toString().trim() ?? '';
    final name = widget.adminData['name'] ?? 'No Name';
    final email = widget.adminData['email'] ?? 'No Email';
    final role = widget.adminData['role'] ?? 'No Role';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),

            if (_isUploading)
              const Positioned.fill(
                child: Center(child: CircularProgressIndicator()),
              ),

            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _showPhotoPicker,
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color.fromRGBO(41, 70, 158, 1.0),
                  child: Icon(Icons.add_a_photo, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
        const SizedBox(height: 2),
        Text(
          'Role: $role',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700])

        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminEditProfile(adminId: widget.adminData['uid']),
              ),
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }
}
