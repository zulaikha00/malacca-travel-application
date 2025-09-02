import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:reorderables/reorderables.dart';

class EditPlacePage extends StatefulWidget {
  final String docId;

  const EditPlacePage({super.key, required this.docId});

  @override
  State<EditPlacePage> createState() => _EditPlacePageState();
}

class _EditPlacePageState extends State<EditPlacePage> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _ratingController;
  final TextEditingController _newTypeController = TextEditingController();
  final TextEditingController _newTagController = TextEditingController();

  // Firebase-loaded fields
  List<String> _photos = [];
  List<String> _types = [];
  List<String> _tagsML = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _ratingController = TextEditingController();
    _loadPlaceData(); // Load place data from Firestore
  }

  // 🔄 Load place details from Firestore
  Future<void> _loadPlaceData() async {
    final doc = await FirebaseFirestore.instance
        .collection('melaka_places')
        .doc(widget.docId)
        .get();
    final data = doc.data()!;

    _nameController.text = data['name'] ?? '';
    _addressController.text = data['address'] ?? '';
    _ratingController.text = (data['rating'] ?? '').toString();
    _photos = List<String>.from(data['photos'] ?? []);
    _types = List<String>.from(data['types'] ?? []);
    _tagsML = List<String>.from(data['tags_suggested_by_ml'] ?? []);

    setState(() {});
  }

  // 📸 Pick images from gallery and upload to Firebase Storage
  Future<void> _pickAndUploadImages() async {
    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage();
    if (pickedImages == null || pickedImages.isEmpty) return;

    for (final image in pickedImages) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('place_photos/${DateTime.now().millisecondsSinceEpoch}.jpg');

      Uint8List bytes = await image.readAsBytes();
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      _photos.add(url);
    }

    setState(() {});
  }

  // 🔁 Remove or add types and tags
  void _removeType(int index) => setState(() => _types.removeAt(index));
  void _removeTag(int index) => setState(() => _tagsML.removeAt(index));

  void _addType() {
    final newType = _newTypeController.text.trim();
    if (newType.isNotEmpty && !_types.contains(newType)) {
      setState(() {
        _types.add(newType);
        _newTypeController.clear();
      });
    }
  }

  void _addTag() {
    final newTag = _newTagController.text.trim();
    if (newTag.isNotEmpty && !_tagsML.contains(newTag)) {
      setState(() {
        _tagsML.add(newTag);
        _newTagController.clear();
      });
    }
  }

  // ✅ Save updated data to Firestore
  Future<void> _updatePlace() async {
    await FirebaseFirestore.instance.collection('melaka_places').doc(widget.docId).update({
      'name': _nameController.text,
      'address': _addressController.text,
      'rating': double.tryParse(_ratingController.text) ?? 0.0,
      'photos': _photos,
      'types': _types,
      'tags_suggested_by_ml': _tagsML,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Place updated')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _ratingController.dispose();
    _newTypeController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  // 🔤 Text field widget with dark/light theme styling
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isNumber = false,
        required bool isDark,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🎨 Custom button color depending on theme mode
    final buttonColor = isDark
        ? Colors.lightBlueAccent // Sky blue in dark mode
        : const Color.fromRGBO(41, 70, 158, 1.0); // Dark blue in light mode

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Edit Place',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                ),
              );
            },
          ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updatePlace,
            tooltip: 'Save Changes',
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("🖼️ Photos", style: _sectionHeaderStyle(isDark)),
                      const SizedBox(height: 10),

                      // 📷 Display uploaded photos
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _photos.map((url) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _photos.remove(url)),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black45,
                                    child: Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // 📤 Add photo button with dynamic color
                      OutlinedButton.icon(
                        onPressed: _pickAndUploadImages,
                        icon: Icon(Icons.add_photo_alternate, color: buttonColor),
                        label: Text('Add More Photos', style: TextStyle(color: buttonColor)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: buttonColor,
                          side: BorderSide(color: buttonColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const Divider(height: 20),
                      Text("📍 Place Details", style: _sectionHeaderStyle(isDark)),
                      const SizedBox(height: 10),
                      _buildTextField(_nameController, 'Place Name', Icons.place, isDark: isDark),
                      const SizedBox(height: 12),
                      _buildTextField(_addressController, 'Address', Icons.location_on, isDark: isDark),
                      const SizedBox(height: 12),
                      _buildTextField(_ratingController, 'Rating', Icons.star, isNumber: true, isDark: isDark),
                      const Divider(height: 32),

                      // 🏷️ Categories
                      Text("🏷️ Categories", style: _sectionHeaderStyle(isDark)),
                      const SizedBox(height: 8),
                      ReorderableWrap(
                        spacing: 8,
                        runSpacing: 8,
                        needsLongPressDraggable: true,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            final item = _types.removeAt(oldIndex);
                            _types.insert(newIndex, item);
                          });
                        },
                        children: _types.asMap().entries.map((entry) {
                          int index = entry.key;
                          String type = entry.value;
                          return Chip(
                            key: ValueKey(type),
                            label: Text(type, style: const TextStyle(color: Colors.black)),
                            backgroundColor: Colors.orange.shade100,
                            deleteIcon: const Icon(Icons.cancel),
                            onDeleted: () => _removeType(index),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      _buildInputWithAddButton(
                        controller: _newTypeController,
                        hint: 'Add new category',
                        isDark: isDark,
                        onPressed: _addType,
                        iconColor: Colors.orange,
                      ),

                      const Divider(height: 20),
                      Text("🏷️ Tags (ML Suggested)", style: _sectionHeaderStyle(isDark)),
                      const SizedBox(height: 8),
                      ReorderableWrap(
                        spacing: 8,
                        runSpacing: 8,
                        needsLongPressDraggable: true,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            final tag = _tagsML.removeAt(oldIndex);
                            _tagsML.insert(newIndex, tag);
                          });
                        },
                        children: _tagsML.asMap().entries.map((entry) {
                          int index = entry.key;
                          String tag = entry.value;
                          return Chip(
                            key: ValueKey(tag),
                            avatar: Icon(Icons.tag, size: 16, color: isDark ? Colors.white : Colors.black54),
                            label: Text(tag, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            backgroundColor: isDark ? Colors.green.shade900 : Colors.green.shade100,
                            deleteIcon: const Icon(Icons.cancel),
                            onDeleted: () => _removeTag(index),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      _buildInputWithAddButton(
                        controller: _newTagController,
                        hint: 'Add new tag',
                        isDark: isDark,
                        onPressed: _addTag,
                        iconColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Section title style
  TextStyle _sectionHeaderStyle(bool isDark) => TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: isDark ? Colors.white : Colors.black,
  );

  // 🆕 Add input field with confirm button
  Widget _buildInputWithAddButton({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: hint,
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              prefixIcon: Icon(Icons.add, color: isDark ? Colors.white70 : Colors.black54),
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Icon(Icons.check),
        ),
      ],
    );
  }
}
