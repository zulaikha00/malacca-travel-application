import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GridPlaceCardList extends StatelessWidget {
  // 🔹 List of place documents from Firestore
  final List<DocumentSnapshot> places;

  // 🔹 Set of selected place document IDs
  final Set<String> selectedIds;

  // 🔹 Callback to toggle selection
  final void Function(String docId) onToggleSelection;

  // 🔹 Callback to open place details
  final void Function(BuildContext, DocumentSnapshot) onTapPlace;

  const GridPlaceCardList({
    super.key,
    required this.places,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onTapPlace,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 📐 Determine layout based on screen width
        final double width = constraints.maxWidth;

        // 📱 If width < 600, assume it's a phone
        final bool isTablet = width >= 600;

        // 🔁 Define grid layout settings based on device size
        final int crossAxisCount = isTablet ? 2 : 2;
        final double aspectRatio = isTablet ? 3 / 2.8 : 3 / 6; //tab:phone

        // 🔄 Wrap with RefreshIndicator for pull-to-refresh
        return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: places.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,       // 🧱 Number of cards per row
              mainAxisSpacing: 12,                  // 🟰 Space between rows
              crossAxisSpacing: 12,                 // 🟰 Space between columns
              childAspectRatio: aspectRatio,        // 🧮 Width:Height ratio of each card
            ),
            itemBuilder: (context, index) {
              final doc = places[index];
              final docId = doc.id;
              final data = doc.data() as Map<String, dynamic>;

              final isSelected = selectedIds.contains(docId);

              // 📷 Get image URL if available
              final imageUrl = (data['photos'] is List && data['photos'].isNotEmpty)
                  ? data['photos'][0]
                  : null;

              return GestureDetector(
                onTap: () {
                  if (selectedIds.isNotEmpty) {
                    onToggleSelection(docId); // ✅ Toggle selection
                  } else {
                    onTapPlace(context, doc); // 🔍 Show place detail
                  }
                },
                onLongPress: () => onToggleSelection(docId), // 🧲 Start selection mode
                child: Card(
                  color: isSelected ? Colors.grey[300] : null, // ✨ Highlight if selected
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 🖼️ Image with fallback and overlay
                      Stack(
                        children: [
                          SizedBox(
                            height: 200, // Fixed height for image
                            width: double.infinity,
                            child: imageUrl != null
                                ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image, size: 60),
                                  ),
                            )
                                : Container(
                                  color: Colors.grey[300],
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image, size: 60, color: Colors.white),
                            ),
                          ),

                          // ✅ Checkmark overlay if selected
                          if (isSelected) ...[
                            Positioned.fill(
                              child: Container(color: Colors.black.withOpacity(0.4)),
                            ),
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle, color: Colors.white, size: 28),
                            ),
                          ],
                        ],
                      ),

                      // 🏷️ Place name and rating
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isPhone = screenWidth < 600; // ✅ true for phones

                            return Column(
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: isPhone ? 12 : 16, // 👈 smaller on phone
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, size: isPhone ? 14 : 16, color: Colors.amber), // 👈 icon also shrinks
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data['rating'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: isPhone ? 12 : 14, // 👈 smaller on phone
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    ],
                  ),
                ),
              );
            },
          );

      },
    );
  }
}
