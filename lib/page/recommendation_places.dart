import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp25/page/recommendation_service.dart' as RecommendationService;
import '../accuracy_test.dart';
import '../places/place_detail.dart';
import '../testing.dart';

class RecommendationPage extends StatefulWidget {
  final String userId;

  const RecommendationPage({super.key, required this.userId});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  List<Map<String, dynamic>> recommendedPlaces = [];
  bool isLoading = true;
  List<String> allTags = [];         // All unique tags collected from results
  List<String> selectedTags = [];    // Tags selected by user
  String selectedFilter = 'None';    // Dropdown filter value

  @override
  void initState() {
    super.initState();
    loadRecommendations(); // Fetch data when screen is loaded
  }

  /// Load recommended places and extract all tags (cleaned and lowercased)
  Future<void> loadRecommendations() async {
    final results = await RecommendationService.RecommendationService()
        .getRecommendedMelakaPlaces(widget.userId);

    final tagsSet = <String>{};

    // ✅ Load all tags from full `melaka_places` collection in Firestore
    final allPlacesSnapshot = await FirebaseFirestore.instance.collection('melaka_places').get();
    for (var doc in allPlacesSnapshot.docs) {
      final tags = List<String>.from(doc['tags_suggested_by_ml'] ?? []); // Use 'types' or your tag field
      tagsSet.addAll(tags.map((t) => t.trim()));
    }

    setState(() {
      recommendedPlaces = results;
      allTags = tagsSet.toList()
        ..sort((a, b) => a.length.compareTo(b.length)); // 🔁 Sort shortest to longest

      isLoading = false;
    });

    // ✅ Show SnackBar with count
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Loaded ${results.length} recommended places"),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  /// Return places based on selected tags and filters
  List<Map<String, dynamic>> get filteredPlaces {
    List<Map<String, dynamic>> places = List.from(recommendedPlaces);

    if (selectedTags.isNotEmpty) {
      places = places.where((place) {
        final rawTags = place['tags_suggested_by_ml'];
        if (rawTags is! List) return false;

        final tags = rawTags.map((t) => t.toString().toLowerCase().trim()).toList();
        return tags.any((tag) => selectedTags
            .map((t) => t.toLowerCase().trim())
            .contains(tag));
      }).toList();
    }

    switch (selectedFilter) {
      case 'A-Z':
        places.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'Rating':
        places.sort((b, a) => (a['rating'] ?? 0).compareTo(b['rating'] ?? 0));
        break;
      case 'Liked':
        places = places.where((p) => p['reasonType'] == 'liked').toList();
        break;
      case 'Preference':
        places = places.where((p) => p['reasonType'] == 'preference').toList();
        break;
      case 'Liked+Preference':
        places = places.where((p) => p['reasonType'] == 'liked+preference').toList();
        break;
    }

    return places;
  }

  /// Filter by tag chips and dropdown
  Widget buildTagFilterChips() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 600; // Phone width check

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // tighter padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Filter by Tags",
            style: TextStyle(
              fontSize: isSmall ? 14 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isSmall ? 6 : 10), // tighter spacing on phone

          // Tag chips
          Wrap(
            spacing: 8,
            runSpacing: isSmall ? 6 : 8, // closer spacing on small screen
            children: allTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(
                  tag,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 13, // smaller text on phone
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.blueGrey, // selected = dark grey
                backgroundColor: Colors.grey[200], // unselected = light grey
                onSelected: (selected) {
                  setState(() {
                    selected ? selectedTags.add(tag) : selectedTags.remove(tag);
                  });
                },
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 8 : 10,
                  vertical: isSmall ? 4 : 6,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? Colors.blueGrey.shade700 : Colors.grey.shade400,
                  ),
                ),
              );
            }).toList(),
          ),

          // Clear button if filters selected
          if (selectedTags.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedTags.clear();
                  });
                },
                child: Text(
                  "Clear All Filters",
                  style: TextStyle(fontSize: isSmall ? 12 : 14),
                ),
              ),
            ),

          SizedBox(height: isSmall ? 8 : 12), // tighter bottom spacing

          // Dropdown filter (sort)
          DropdownButton<String>(
            value: selectedFilter == 'None' ? null : selectedFilter,
            hint: Text(
              "Sort / Filter",
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            icon: Icon(Icons.filter_list, size: isSmall ? 20 : 24),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Theme.of(context).cardColor,
            items: const [
              DropdownMenuItem(value: 'None', child: Text("None")),
              DropdownMenuItem(value: 'A-Z', child: Text("A-Z")),
              DropdownMenuItem(value: 'Rating', child: Text("Rating")),
              DropdownMenuItem(value: 'Liked', child: Text("Liked")),
              DropdownMenuItem(value: 'Preference', child: Text("Preference")),
              DropdownMenuItem(value: 'Liked+Preference', child: Text("Liked + Preference")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedFilter = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }


  /// Card UI for a single recommended place
  Widget buildPlaceCard(Map<String, dynamic> place) {
    final String name = place['name'] ?? 'Unnamed Place';
    final String address = place['address'] ?? 'No address';
    final double rating = (place['rating'] ?? 0).toDouble();
    final List tags = place['tags_suggested_by_ml'] ?? [];
    final List photos = place['photos'] ?? [];
    final String imageUrl = photos.isNotEmpty ? photos[0] : '';
    final String reason = place['reason'] ?? '';
    final String reasonType = place['reasonType'] ?? '';

    Color reasonColor = Colors.grey;
    if (reasonType == 'liked') {
      reasonColor = Colors.green;
    } else if (reasonType == 'preference') {
      reasonColor = Colors.purple;
    } else if (reasonType == 'liked+preference') {
      reasonColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailPage(place: place, placeId: place['placeId']),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (reason.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.recommend, size: 16, color: reasonColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(reason,
                                style: TextStyle(
                                    fontSize: 13, color: reasonColor, fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(address,
                              style: const TextStyle(fontSize: 13, color: Colors.grey))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.star, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1))
                      ]),
                      Flexible(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.take(3).map<Widget>((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.blue.shade50,
                              ),
                              child: Text(tag,
                                  style: const TextStyle(fontSize: 12, color: Colors.blue)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Main build method
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Smart Recommendations',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20,
              ),
            );
          },
        ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),

        /*actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Accuracy Report',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ No user logged in')),
                );
                return;
              }

              final uid = user.uid;

              try {
                final tester =RecommendationReportGenerator();
                await tester.generateScenarioReport(uid);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Excel report downloaded')),
                );
              } catch (e) {
                print("❌ Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Failed to generate report')),
                );
              }
            },
          ),
        ],*/
      ),


      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendedPlaces.isEmpty
          ? const Center(child: Text("No recommendations found."))
          : RefreshIndicator(
              onRefresh: () async {
                await loadRecommendations(); // Refreshes data
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Enables scroll even if content is short
                children: [
                  if (allTags.isNotEmpty) buildTagFilterChips(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable internal scroll
                        itemCount: filteredPlaces.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3 / 3.3,
                        ),
                        itemBuilder: (context, index) {
                          return buildPlaceCard(filteredPlaces[index]);
                        },
                      );
                    },
                  ),

                  //
                ],

              ),
      ),


    );
  }


  /// Placeholder for broken/missing images
  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
