import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'delete_places.dart';
import 'edit_places.dart';

class PlaceDetailBottomSheet extends StatefulWidget {
  final String name;
  final List<String> photos; // ✅ Image URLs
  final String address;
  final double rating;
  final String docId;
  final List<String> types; // ✅ Types like 'museum', 'restaurant'

  const PlaceDetailBottomSheet({
    super.key,
    required this.name,
    required this.photos,
    required this.address,
    required this.rating,
    required this.docId,
    required this.types,
  });

  @override
  State<PlaceDetailBottomSheet> createState() => _PlaceDetailBottomSheetState();
}

class _PlaceDetailBottomSheetState extends State<PlaceDetailBottomSheet> {
  final PageController _pageController = PageController();

  // 🧠 List to store ML-suggested tags from Firestore
  List<String> _mlTags = [];

  @override
  void initState() {
    super.initState();
    _fetchMLTags(); // ⬅️ Fetch ML tags on widget load
  }

  // 🔁 Fetch tags_suggested_by_ml from Firestore document
  Future<void> _fetchMLTags() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('melaka_places')
        .doc(widget.docId)
        .get();

    if (snapshot.exists && snapshot.data()!.containsKey('tags_suggested_by_ml')) {
      final tags = snapshot['tags_suggested_by_ml'];
      if (tags is List) {
        setState(() {
          _mlTags = tags.cast<String>();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔶 Drag handle
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // 🔶 Place Name with Edit & Delete buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷️ Place Name
                Expanded(
                  child: Text(
                    widget.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // ✏️ Edit Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPlacePage(docId: widget.docId),
                      ),
                    );
                  },
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

                // ❌ Delete Button with confirmation dialog
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: const Text('Are you sure you want to delete this place?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await DeletePlacesService().deletePlace(widget.docId);
                        if (context.mounted) Navigator.pop(context); // Close sheet
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete the place')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 📸 Image Carousel
            if (widget.photos.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    itemBuilder: (context, index) {
                      final url = widget.photos[index];
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 🔵 Page indicator
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: widget.photos.length,
                  effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: Colors.orange,
                    dotColor: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 📍 Address display
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(widget.address, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ⭐ Rating display
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${widget.rating.toStringAsFixed(1)} / 5.0', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),

            // 🏷️ Category Chips
            if (widget.types.isNotEmpty) ...[
              const Text(
                'Categories:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.types.map((type) {
                  return Chip(
                    label: Text(
                      type.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                    backgroundColor: Colors.blue.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // 🧠 ML Suggested Tags as Chips with Tag Icons
            if (_mlTags.isNotEmpty) ...[
              const Text(
                'Tags (ML Suggested):',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _mlTags.map((tag) {
                  return Chip(
                    avatar: const Icon(Icons.tag, size: 16, color: Colors.black54),
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12,color: Colors.black),
                    ),
                    backgroundColor: Colors.green.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
