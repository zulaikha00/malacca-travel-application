// ✅ AddPlacePage with Tag Input for ML & User Tags + Dark Mode Adaptation

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AddPlacePage extends StatefulWidget {
  const AddPlacePage({super.key});

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final typeController = TextEditingController();
  final ratingController = TextEditingController();
  final mlTagController = TextEditingController();

  List<String> mlTags = [];

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool number = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
        prefixIcon: Icon(icon, color: isDark ? Colors.white : Colors.black),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTagField({required String label, required TextEditingController controller, required Function(String) onAdd}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
              fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final tag = controller.text.trim();
            if (tag.isNotEmpty) {
              onAdd(tag);
              controller.clear();
            }
          },
          child: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay? time, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      flex: 2,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[700] : Colors.grey.shade200,
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
        child: Text(time == null ? label : time.format(context)),
      ),
    );
  }

  LatLng? selectedLatLng;
  GoogleMapController? _mapController;
  final LatLng melakaSW = const LatLng(2.1000, 102.2000);
  final LatLng melakaNE = const LatLng(2.4000, 102.4000);
  final LatLng melakaCenter = const LatLng(2.2008, 102.2469);

  List<File> selectedImages = [];
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> downloadUrls = [];
    for (var img in images) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('place_images/$fileName.jpg');
      await ref.putFile(img);
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<void> _getUserLocation() async {
    final position = await Geolocator.getCurrentPosition();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15),
    );
  }

  List<Map<String, dynamic>> openingHours = [];
  String? selectedDay;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && selectedLatLng != null) {
      final imageUrls = await _uploadImages(selectedImages);
      await FirebaseFirestore.instance.collection('melaka_places').add({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'types': [typeController.text.trim()],
        'rating': double.tryParse(ratingController.text) ?? 0.0,
        'latitude': selectedLatLng!.latitude,
        'longitude': selectedLatLng!.longitude,
        'photos': imageUrls,
        'opening_hours': openingHours,
        'tags_suggested_by_ml': mlTags,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place added')));
      Navigator.pop(context);
    }
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
                'Add New Place',
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
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📷 Upload Images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text('Select Images'),
                style: ElevatedButton.styleFrom(backgroundColor: Color.fromRGBO(41, 70, 158, 1.0), foregroundColor: Colors.white),
              ),
              const SizedBox(height: 10),
              if (selectedImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(selectedImages[index], width: 120, height: 120, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => setState(() => selectedImages.removeAt(index)),
                            child: const CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 12,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text("📄 Place Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(nameController, 'Place Name', Icons.place),
                    const SizedBox(height: 10),
                    _buildTextField(addressController, 'Address', Icons.location_on),
                    const SizedBox(height: 10),
                    _buildTextField(typeController, 'Type (e.g. Park, Museum)', Icons.category),
                    const SizedBox(height: 10),
                    _buildTextField(ratingController, 'Rating (0.0 - 5.0)', Icons.star, number: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("🏷️ Tags Suggested by ML"),
              _buildTagField(label: 'Enter ML tag', controller: mlTagController, onAdd: (tag) => setState(() => mlTags.add(tag))),
              Wrap(
                children: mlTags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => mlTags.remove(tag)),
                )).toList(),
              ),
              const SizedBox(height: 10),
              const Text("⏰ Opening Hours"),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedDay,
                      hint: const Text("Day"),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                      onChanged: (val) => setState(() => selectedDay = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildTimeButton("Open", openTime, () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) setState(() => openTime = time);
                  }),
                  const SizedBox(width: 8),
                  _buildTimeButton("Close", closeTime, () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null) setState(() => closeTime = time);
                  }),
                  IconButton(
                    onPressed: (selectedDay != null && openTime != null && closeTime != null)
                        ? () {
                      setState(() {
                        openingHours.add({
                          'day': selectedDay!,
                          'open': openTime!.format(context),
                          'close': closeTime!.format(context),
                        });
                        selectedDay = null;
                        openTime = null;
                        closeTime = null;
                      });
                    }
                        : null,
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...openingHours.map((entry) => ListTile(
                title: Text("${entry['day']}: ${entry['open']} - ${entry['close']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => openingHours.remove(entry)),
                ),
              )),
              const Divider(height: 20),
              const Text("🗺️ Location"),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(border: Border.all(color: Colors.orange)),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: melakaCenter, zoom: 12),
                    onMapCreated: (controller) => _mapController = controller,
                    minMaxZoomPreference: const MinMaxZoomPreference(10, 16),
                    cameraTargetBounds: CameraTargetBounds(LatLngBounds(southwest: melakaSW, northeast: melakaNE)),
                    onTap: (position) {
                      if (position.latitude >= melakaSW.latitude &&
                          position.latitude <= melakaNE.latitude &&
                          position.longitude >= melakaSW.longitude &&
                          position.longitude <= melakaNE.longitude) {
                        setState(() => selectedLatLng = position);
                      }
                    },
                    markers: selectedLatLng != null
                        ? {
                      Marker(markerId: const MarkerId('selected'), position: selectedLatLng!),
                    }
                        : {},
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Add Place'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:  Color.fromRGBO(41, 70, 158, 1.0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}