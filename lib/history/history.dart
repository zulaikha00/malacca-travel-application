import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'delete_history.dart';

class ViewedHistoryPage extends StatefulWidget {
  final String uid;

  const ViewedHistoryPage({super.key, required this.uid});

  @override
  State<ViewedHistoryPage> createState() => _ViewedHistoryPageState();
}

class _ViewedHistoryPageState extends State<ViewedHistoryPage> {
  List<Map<String, dynamic>> viewedPlaces = [];
  bool isLoading = true;

  /// 🔄 Load viewed places from Firestore
  Future<void> fetchViewedPlaces() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    final viewedPlaceIds = List<String>.from(userDoc['viewed'] ?? []);

    if (viewedPlaceIds.isEmpty) {
      setState(() {
        viewedPlaces = [];
        isLoading = false;
      });
      return;
    }

    final placesSnap = await FirebaseFirestore.instance
        .collection('melaka_places')
        .where(FieldPath.documentId, whereIn: viewedPlaceIds)
        .get();

    setState(() {
      viewedPlaces = placesSnap.docs.map((doc) {
        final data = doc.data();
        data['placeId'] = doc.id;
        return data;
      }).toList();
      isLoading = false;
    });
  }

  /// 🗑️ Show confirm dialog and delete all viewed history
  Future<void> confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),

          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Clear History',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),

          content: const Text(
            'Are you sure you want to delete all viewed history? This action cannot be undone.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),

    );

    if (confirm == true) {
      await clearViewedHistory(widget.uid); // Call function from other file
      await fetchViewedPlaces(); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viewed history deleted')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchViewedPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Viewed History',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear History',
            onPressed: confirmDelete,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewedPlaces.isEmpty
          ? const Center(child: Text('No viewed places yet.'))
          : ListView.builder(
            itemCount: viewedPlaces.length,
            itemBuilder: (context, index) {
              final place = viewedPlaces[index];
              final name = place['name'] ?? 'Unnamed';
              final photos = place['photos'];
              final imageUrl = (photos is List && photos.isNotEmpty) ? photos.first : null;


              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null && imageUrl.toString().isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Container(
                            width: 60,
                            height: 60,
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: const Icon(Icons.image_not_supported,
                                size: 28, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
        },
      ),
    );
  }
}
