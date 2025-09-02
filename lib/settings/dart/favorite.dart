import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritePlacesPage extends StatefulWidget {
  final String uid;

  const FavoritePlacesPage({super.key, required this.uid});

  @override
  State<FavoritePlacesPage> createState() => _FavoritePlacesPageState();
}

class _FavoritePlacesPageState extends State<FavoritePlacesPage> {
  List<Map<String, dynamic>> likedPlaces = [];
  bool isLoading = true;

  // 🔁 Fetch liked places from Firestore
  Future<void> fetchLikedPlaces() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    final likedPlaceIds = List<String>.from(userDoc['liked'] ?? []);

    if (likedPlaceIds.isEmpty) {
      setState(() {
        likedPlaces = [];
        isLoading = false;
      });
      return;
    }

    final placesSnap = await FirebaseFirestore.instance
        .collection('melaka_places')
        .where(FieldPath.documentId, whereIn: likedPlaceIds)
        .get();

    setState(() {
      likedPlaces = placesSnap.docs.map((doc) {
        final data = doc.data();
        data['placeId'] = doc.id;
        return data;
      }).toList();
      isLoading = false;
    });
  }

  // ❌ Remove place from user's liked list
  Future<void> unlikePlace(String placeId) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
      'liked': FieldValue.arrayRemove([placeId]),
    });

    // 🧹 Remove from local list to update UI
    setState(() {
      likedPlaces.removeWhere((place) => place['placeId'] == placeId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites')),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchLikedPlaces();
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
              'Favorite',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
              ),
            );
          },
        ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : likedPlaces.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
            itemCount: likedPlaces.length,
            itemBuilder: (context, index) {
              final place = likedPlaces[index];
              final name = place['name'] ?? 'Unnamed';
              final placeId = place['placeId'];
              final imageUrl = (place['photos'] is List && (place['photos'] as List).isNotEmpty)
                  ? (place['photos'] as List).first
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null
                        ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    tooltip: 'Remove from favorites',
                    onPressed: () => unlikePlace(placeId),
                  ),
                ),
              );
        },
      ),
    );
  }
}
