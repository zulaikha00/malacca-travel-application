import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp25/admin/list_places/place_details.dart';
import 'package:fyp25/admin/list_places/add_places.dart';
import '../admin_search/admin_search_bar.dart';
import 'grid_place_card.dart';
import 'list_place_card.dart';

class ViewPlacesPage extends StatefulWidget {
  const ViewPlacesPage({super.key});

  @override
  State<ViewPlacesPage> createState() => _ViewPlacesPageState();
}

class _ViewPlacesPageState extends State<ViewPlacesPage> {
  bool isGrid = true; // 🔄 Toggle between Grid and List view
  Set<String> selectedIds = {}; // ✅ Store selected document IDs (for future actions like edit/delete)
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<DocumentSnapshot> _places = []; // 🗃️ Local list of places
  bool _isLoading = true; // ⏳ Track loading state

  // 🔁 Toggle selection state for a place
  void _toggleSelection(String docId) {
    setState(() {
      if (selectedIds.contains(docId)) {
        selectedIds.remove(docId);
      } else {
        selectedIds.add(docId);
      }
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

  /// 🔄 Fetch places from Firestore manually
  Future<void> _fetchPlaces() async {
    setState(() => _isLoading = true);
    final snapshot = await FirebaseFirestore.instance.collection('melaka_places').get();
    setState(() {
      _places = snapshot.docs;
      _isLoading = false;
    });
  }

  /// 🔍 Filter places based on search query
  List<DocumentSnapshot> _filteredPlaces() {
    return _places.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchPlaces(); // 🔁 Initial data load
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
                'View Places',
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
            icon: Icon(
              isGrid ? Icons.list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPlacePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onChanged: (query) {
              setState(() {
                searchQuery = query.trim().toLowerCase();
              });
            },
          ),
          Expanded(
            // 🔄 Wrap in RefreshIndicator to enable pull-to-refresh
            child: RefreshIndicator(
              onRefresh: _fetchPlaces, // 🧼 Reload Firestore data on pull
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (isGrid
                  ? GridPlaceCardList(
                places: _filteredPlaces(),
                selectedIds: selectedIds,
                onToggleSelection: _toggleSelection,
                onTapPlace: _showPlaceDetails,
              )
                  : ListPlaceCardList(
                places: _filteredPlaces(),
                selectedIds: selectedIds,
                onToggleSelection: _toggleSelection,
                onTapPlace: _showPlaceDetails,
              )),
            ),
          ),
        ],
      ),
    );
  }
}
