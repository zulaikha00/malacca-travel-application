import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_card.dart'; // 👈 Custom widget for displaying a place card

/// 📋 A vertically scrollable list of place cards
/// Each item supports tap, long press, and checkbox selection
class ListPlaceCardList extends StatelessWidget {
  final List<DocumentSnapshot> places; // 🔹 List of places to display
  final Set<String> selectedIds; // 🔹 Stores currently selected place IDs
  final void Function(String docId) onToggleSelection; // 🔁 Toggle selected/unselected
  final void Function(BuildContext, DocumentSnapshot) onTapPlace; // 🔍 Open detail view

  const ListPlaceCardList({
    super.key,
    required this.places,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onTapPlace,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final doc = places[index];
        final docId = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final imageUrl = (data['photos'] is List && data['photos'].isNotEmpty)
            ? data['photos'][0]
            : '';

        final isSelected = selectedIds.contains(docId);

        return PlaceCard(
          name: name,
          imageUrl: imageUrl,
          isSelected: isSelected,
          isPhone: isPhone, // ✅ Pass this here
          onTap: () {
            if (selectedIds.isNotEmpty) {
              onToggleSelection(docId);
            } else {
              onTapPlace(context, doc);
            }
          },
          onLongPress: () => onToggleSelection(docId),
          onCheckboxChanged: (_) => onToggleSelection(docId),
        );
      },
    );
  }

}
