
import 'dart:math';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp25/page/recommendation_places.dart';

import '../places/place_detail.dart';
import '../places/place_filter.dart';
import '../search/search_places.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final random = Random();

  List<Map<String, dynamic>> rawPlaces = [];
  List<Map<String, dynamic>> allPlaces = [];
  List<Map<String, dynamic>> filteredPlaces = [];
  List<String> preferences = [];
  bool isSearching = false;
  String selectedPreference = 'All';
  String selectedSort = 'None';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
    fetchPlaces();
  }

  /// 🔄 Fetch all places and filter by user preferences
  Future<void> fetchPlaces() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      preferences = List<String>.from(userDoc.data()?['preferences'] ?? []);

      final snapshot = await FirebaseFirestore.instance.collection('melaka_places').get();
      final allFetchedPlaces = snapshot.docs.map((doc) {
        final data = doc.data();
        data['placeId'] = doc.id;

        // 🔽 Handle images (either Base64 or URL)
        if (data['photos'] != null && data['photos'] is List && data['photos'].isNotEmpty) {
          final photos = List<String>.from(data['photos']);
          data['image_urls'] = photos;
          final randomPhoto = photos[random.nextInt(photos.length)];
          if (randomPhoto.startsWith('http')) {
            data['image_url'] = randomPhoto;
            data['image_bytes'] = null;
          } else {
            try {
              data['image_bytes'] = base64Decode(randomPhoto);
              data['image_url'] = null;
            } catch (_) {
              data['image_url'] = null;
              data['image_bytes'] = null;
            }
          }
        } else {
          data['image_url'] = null;
          data['image_urls'] = [];
          data['image_bytes'] = null;
        }

        return data;
      }).toList();

      final matched = preferences.isEmpty
          ? allFetchedPlaces
          : filterPlacesByPreferences(allPlaces: allFetchedPlaces, preferences: preferences);

      matched.shuffle(random);

      setState(() {
        rawPlaces = allFetchedPlaces;
        allPlaces = matched;
        filteredPlaces = matched;
      });

// ✅ Show total count using SnackBar + Terminal Debug
      final totalCount = matched.length;
      print('✅ Total Places Available: $totalCount');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Total Places Available: $totalCount'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e) {
      print('❌ Failed to fetch places: $e');
    }
  }

  /// 🔍 Handle search input
  void updateSearch(String query) {
    setState(() {
      isSearching = query.isNotEmpty;
      filteredPlaces = filterPlacesByName(rawPlaces, query);
    });
  }

  /// 📷 Render image from Base64 or URL
  Widget buildImage(Map<String, dynamic> place) {
    if (place['image_bytes'] != null) {
      return Image.memory(place['image_bytes'], fit: BoxFit.cover);
    } else if (place['image_url'] != null) {
      return Image.network(place['image_url'], fit: BoxFit.cover);
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('No Photo Available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final ratingFive = rawPlaces.where((p) => p['rating'] == 5 || p['rating'] == '5' || p['rating'] == 5.0).toList()
      ..shuffle(random);
    final popular = ratingFive.take(10).toList();
    final display = isSearching ? filteredPlaces : allPlaces;


    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedChipColor = const Color(0xFF29469E); // Dark blue

    final unselectedChipColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final selectedTextColor = Colors.white;
    final unselectedTextColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
            title: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isPhone = screenWidth < 600;

                return Text(
                  'Discover Places',
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
      ),

      /// 🔘 Floating Smart Recommendation Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecommendationPage(userId: user.uid),
              ),
            );
          }
        },
        icon: const Icon(Icons.lightbulb),
        label: const Text("Smart Recommendation"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 6,
      ),

      /// 🔄 Main Body
      body: Column(
        children: [
          /// 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: updateSearch,
              decoration: InputDecoration(
                hintText: 'Search places...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[700],
                ),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).iconTheme.color),
                      onPressed: () {
                        searchController.clear();
                        updateSearch('');
                      },
                )
                    : null,
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.grey[100],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                ),
              ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),

          /// 🧭 Refreshable content area
          Expanded(
            child: allPlaces.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchPlaces, // 🧽 Pull-to-refresh logic
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(), // Ensure pull works even with small content
                      padding: const EdgeInsets.all(16),
                      children: [

                        /// ⭐ Popular Row + Filter Dropdown
                        if (popular.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Popular', style: Theme.of(context).textTheme.titleMedium),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Refresh',
                                    onPressed: () async {
                                      setState(() {
                                        isSearching = false;
                                        searchController.clear();
                                      });
                                      await fetchPlaces();
                                    },
                                  ),
                                  DropdownButton<String>(
                                    value: selectedSort == 'None' ? null : selectedSort,
                                    hint: Text(
                                      "Sort",
                                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                    icon: Icon(Icons.filter_list, color: Theme.of(context).iconTheme.color),
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'None', child: Text("None")),
                                      DropdownMenuItem(value: 'A-Z', child: Text("A-Z")),
                                      DropdownMenuItem(value: 'Rating', child: Text("Rating")),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedSort = value;
                                          if (value == 'A-Z') {
                                            allPlaces.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
                                          } else if (value == 'Rating') {
                                            allPlaces.sort((b, a) => (a['rating'] ?? 0).compareTo(b['rating'] ?? 0));
                                          } else if (value == 'None') {
                                            allPlaces = List<Map<String, dynamic>>.from(rawPlaces);
                                          }
                                          filteredPlaces = allPlaces;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 12),

                          /// 🖼️ Popular Cards
                          SizedBox(
                            height: 180,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: popular.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final p = popular[i];
                                return SizedBox(
                                  width: 250,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlaceDetailPage(place: p, placeId: p['placeId']),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          buildImage(p),
                                          Container(
                                            alignment: Alignment.bottomCenter,
                                            padding: const EdgeInsets.all(8),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Colors.transparent, Colors.black45],
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p['name'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star, color: Colors.orange, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      ((p['rating'] ?? 0).toDouble()).toStringAsFixed(1),
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        /// 🎯 Preference Filter Chips
                        if (preferences.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text("All"),
                                backgroundColor:
                                selectedPreference == 'All' ? selectedChipColor : unselectedChipColor,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: selectedPreference == 'All'
                                      ? selectedTextColor
                                      : unselectedTextColor,
                                ),
                                elevation: selectedPreference == 'All' ? 2 : 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedPreference = 'All';
                                    allPlaces = filterPlacesByPreferences(
                                      allPlaces: rawPlaces,
                                      preferences: preferences,
                                    );
                                    filteredPlaces = allPlaces;
                                    isSearching = false;
                                  });
                                },
                              ),
                              ...preferences.map(
                                    (pref) => ActionChip(
                                  label: Text(pref),
                                  backgroundColor:
                                  selectedPreference == pref ? selectedChipColor : unselectedChipColor,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: selectedPreference == pref
                                        ? selectedTextColor
                                        : unselectedTextColor,
                                  ),
                                  elevation: selectedPreference == pref ? 2 : 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedPreference = pref;
                                      final matched = rawPlaces.where((p) {
                                        final types = List<String>.from(p['types'] ?? []);
                                        return types.contains(pref);
                                      }).toList();
                                      allPlaces = matched;
                                      filteredPlaces = matched;
                                      isSearching = false;
                                    });
                                  },
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        /// 📌 Recommended Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recommended', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 12),

                        /// 📦 Grid of Places
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: display.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 3 / 4,
                          ),
                          itemBuilder: (_, idx) {
                            final p = display[idx];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlaceDetailPage(place: p, placeId: p['placeId']),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    buildImage(p),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.transparent, Colors.black54],
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
                                          children: [
                                            Text(
                                              p['name'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center, // ⬅️ Center the text inside the widget
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min, // ⬅️ Shrink row to content width
                                              children: [
                                                const Icon(Icons.star, color: Colors.orange, size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  ((p['rating'] ?? 0).toDouble()).toStringAsFixed(1),
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),


                            );
                          },
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
