import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileImageService {
  final picker = ImagePicker();

  /// Load profile image from Firestore (base64 encoded)
  Future<Uint8List?> loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final base64Image = doc.data()?['profileImage'];
      if (base64Image != null) {
        try {
          return base64Decode(base64Image); // Decode base64 to image bytes
        } catch (_) {
          return null; // If decoding fails
        }
      }
    }
    return null;
  }

  /// Pick image from camera or gallery
  Future<File?> pickImage(BuildContext context, ImageSource source) async {
    try {
      final status = await _requestPermissions(source);

      if (status.isGranted) {
        // Reduce image quality to avoid large base64 size
        final pickedFile = await picker.pickImage(source: source, imageQuality: 60);
        if (pickedFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image selected.')),
          );
          return null;
        }
        return File(pickedFile.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
    return null;
  }

  /// Ask permission for camera or photos
  Future<PermissionStatus> _requestPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      return await Permission.camera.request();
    } else {
      if (Platform.isAndroid) {
        // Try requesting both storage and photos for broader support
        final storageStatus = await Permission.storage.request();
        return storageStatus;
      } else {
        // For iOS, request photos
        return await Permission.photos.request();
      }
    }
  }


  /// Upload image to Firestore as base64 string
  Future<void> uploadImage(File imageFile, BuildContext context) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // ✅ Use .set() with merge:true to avoid Firestore error if document doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImage': base64Image,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    }
  }
}
