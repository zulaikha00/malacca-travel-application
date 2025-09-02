import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:fyp25/admin/list_places/place_details.dart'; // 🧩 Bottom sheet for viewing place details
import '../admin_search/admin_search_bar.dart';
import 'edit_places.dart'; // ✏️ For editing a place
import 'grid_place_card.dart'; // 🗃️ Grid view custom widget
import 'list_place_card.dart'; // 📋 List view custom widget

class PlacesByTypePage extends StatefulWidget {
  final String type;

  const PlacesByTypePage({super.key, required this.type});

  @override
  State<PlacesByTypePage> createState() => _PlacesByTypePageState();
}

class _PlacesByTypePageState extends State<PlacesByTypePage> {
  List<DocumentSnapshot> places = []; // 📦 All places of the given type
  Set<String> selectedIds = {}; // ✅ Selected place IDs for edit/delete
  bool _showGridView = true; // 🔄 Toggle between grid/list view
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // 🔍 Check if in selection mode
  bool get selectionMode => selectedIds.isNotEmpty;

  // 🔁 Fetch places from Firestore filtered by type
  Future<void> _fetchPlaces() async {
    final snapshot = await FirebaseFirestore.instance.collection('melaka_places').get();

    final filtered = snapshot.docs.where((doc) {
      final types = doc['types'];
      return types != null && types.isNotEmpty && types[0] == widget.type;
    }).toList();

    setState(() {
      places = filtered;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  // 🔄 Toggle selection on long press or checkbox
  void _toggleSelection(String docId) {
    setState(() {
      if (selectedIds.contains(docId)) {
        selectedIds.remove(docId);
      } else {
        selectedIds.add(docId);
      }
    });
  }

  // 🗑️ Delete selected places
  Future<void> _deleteSelectedPlaces() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete the selected place(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in selectedIds) {
        await FirebaseFirestore.instance.collection('melaka_places').doc(id).delete();
      }

      setState(() {
        selectedIds.clear();
      });

      await _fetchPlaces();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected places deleted')),
      );
    }
  }

  // ✏️ Edit selected place (only if exactly one selected)
  void _editSelectedPlace() {
    final docId = selectedIds.first;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPlacePage(docId: docId)),
    ).then((_) {
      _fetchPlaces();
      setState(() {
        selectedIds.clear();
      });
    });
  }

  // 👁️ Show bottom sheet with place details
  void _showPlaceDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unnamed';
    final photos = (data['photos'] is List) ? List<String>.from(data['photos']) : <String>[];
    final address = data['address'] ?? 'No address';
    final rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
    final types = List<String>.from(data['types'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaceDetailBottomSheet(
        name: name,
        photos: photos,
        address: address,
        rating: rating,
        docId: doc.id,
        types: types,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔎 Filter results based on search
    final filteredPlaces = places.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toLowerCase() ?? '';
      return name.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              widget.type,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
              ),
            );
          },
        ),

        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: selectedIds.length == 1 ? _editSelectedPlace : null,
            child: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: selectedIds.length == 1
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          ),
          TextButton(
            onPressed: selectionMode ? _deleteSelectedPlaces : null,
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: selectionMode
                  ? Colors.white
                  : Colors.white.withOpacity(0.4),
            ),
          ),
          IconButton(
            icon: Icon(
              _showGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            tooltip: _showGridView ? 'Switch to List View' : 'Switch to Grid View',
            onPressed: () {
              setState(() {
                _showGridView = !_showGridView;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              onChanged: (query) {
                setState(() {
                  searchQuery = query.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),
            // ✅ Add RefreshIndicator around the scrollable list/grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPlaces, // 🧼 Reload Firestore data
                child: _showGridView
                    ? GridPlaceCardList(
                  places: filteredPlaces,
                  selectedIds: selectedIds,
                  onToggleSelection: _toggleSelection,
                  onTapPlace: _showPlaceDetails,
                )
                    : ListPlaceCardList(
                  places: filteredPlaces,
                  selectedIds: selectedIds,
                  onToggleSelection: _toggleSelection,
                  onTapPlace: _showPlaceDetails,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
