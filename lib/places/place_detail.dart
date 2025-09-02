// 🌐 Flutter UI and Firebase dependencies
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp25/places/place_rating_widget.dart';
import 'package:fyp25/places/place_review_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// 🗺️ Navigation & Opening Hours Helpers
import '../maps/direction_maps.dart';
import '../page/recommendation_service.dart';
import '../review/add_review.dart';
import 'opening_hours.dart';

// 📍 Place Detail Page
class PlaceDetailPage extends StatefulWidget {
  final Map<String, dynamic> place;   // 🧭 Place data
  final String placeId;               // 🆔 Place unique ID

  const PlaceDetailPage({super.key, required this.place, required this.placeId});

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  final PageController _pageController = PageController(); // 📸 Image slider controller
  int _currentImageIndex = 0;
  bool _isLiked = false; // ❤️ Track if user liked this place
  bool _isLoadingRecommendations = true; // 🔄 Track loading state for recommendations
  List<Map<String, dynamic>> _recommendedPlaces = []; // 💡 Store recommended places

  final RecommendationService _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    _checkIfLiked();            // 🔍 Determine if place is liked
    _logView();                 // 📊 Track user views
    _fetchRecommendations();    // 🎯 Load similar places
  }

  /// 🔍 Check if the user already liked this place
  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final likedList = List<String>.from(doc.data()?['liked'] ?? []);

    setState(() {
      _isLiked = likedList.contains(widget.placeId);
    });
  }

  /// ❤️ Like / 💔 Unlike a place using array field
  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    if (_isLiked) {
      // 💔 Remove from 'liked' array
      await userDoc.update({
        'liked': FieldValue.arrayRemove([widget.placeId]),
      });
    } else {
      // ❤️ Add to 'liked' array
      await userDoc.update({
        'liked': FieldValue.arrayUnion([widget.placeId]),
      });
    }

    setState(() {
      _isLiked = !_isLiked;
    });
  }

  /// 📊 Track place views for personalization
  Future<void> _logView() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _recommendationService.logPlaceView(user.uid, widget.placeId);
  }

  /// 🎯 Fetch top 3 recommendations excluding current place
  Future<void> _fetchRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recommendations = await _recommendationService.getRecommendedMelakaPlaces(user.uid);
    recommendations.removeWhere((place) => place['placeId'] == widget.placeId);

    setState(() {
      _recommendedPlaces = recommendations.take(3).toList();
      _isLoadingRecommendations = false;
    });
  }



  /// 🧱 UI Build
  @override
  Widget build(BuildContext context) {
    // 🖼️ Prepare imageUrls list based on available data
    List<dynamic> imageUrls = [];

// ✅ Case 1: If 'photos' field exists and is a non-empty List → use it
    if (widget.place.containsKey('photos') &&
        widget.place['photos'] is List &&
        widget.place['photos'].isNotEmpty) {
      imageUrls = widget.place['photos'];
    }

// ✅ Case 2: If a single 'image_url' field exists → wrap it into a list
    else if (widget.place['image_url'] != null) {
      imageUrls = [widget.place['image_url']];
    }

// ❌ Case 3: Fallback → use a placeholder image URL
    else {
      imageUrls = ['https://via.placeholder.com/300'];
    }



    // 🕒 Load opening hours and determine if open now
    final openingHours = widget.place['opening_hours'] ?? {};
    final bool isOpenNow = openingHours['periods'] != null
        ? isOpenNowMYT(openingHours)
        : (openingHours['open_now'] ?? false);

    // 📆 Extract formatted weekday hours
    List<String>? weekdayText = (openingHours['weekday_text'] as List?)?.cast<String>();

// 🛠️ If missing, build manually from 'periods'
    if ((weekdayText == null || weekdayText.isEmpty) && openingHours['periods'] != null) {
      weekdayText = buildWeekdayTextFromPeriods(
        openingHours['periods'],
        openingHours['weekday_text'],
      );
    }


    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image Carousel + Back Button
            Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 400,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: imageUrls.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrls[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: imageUrls.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: Colors.blueAccent,
                        dotColor: Colors.grey.shade400,
                        dotHeight: 8,
                        dotWidth: 8,
                      ),
                    ),
                  ],
                ),

                // 🔙 Back Button
                Positioned(
                  top: 40,
                  left: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🏰 Section: Place Name, Like Button, and View Map
            Row(
              children: [
                // 🏷️ Place name (bold, responsive)
                Expanded(
                  child: Text(
                    widget.place['name'] ?? 'Unknown Place',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ❤️ Like / Unlike button (toggle heart icon)
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),

                // 🗺️ View map button (goes to DirectionPage)
                ElevatedButton.icon(
                  onPressed: () {
                    LatLng destination = LatLng(
                      _toDouble(widget.place['latitude']),
                      _toDouble(widget.place['longitude']),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DirectionPage(
                          destination: destination,
                          destinationName: widget.place['name'] ?? 'Unknown',
                          imageUrl: imageUrls.first,
                          rating: (widget.place['rating'] ?? 0.0).toDouble(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 18, color: Colors.white),
                  label: const Text('View Map', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // 🔹 Extra spacing for visual clarity

// 🔴🟢 Section: Open Status Indicator
            Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  openingHours.isEmpty
                      ? Icons.help_outline
                      : isOpenNow
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: openingHours.isEmpty
                      ? Colors.grey
                      : isOpenNow
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  openingHours.isEmpty
                      ? 'Not available'
                      : isOpenNow
                      ? 'Open Now'
                      : 'Closed Now',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: openingHours.isEmpty
                        ? Colors.grey
                        : isOpenNow
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12), // 🔹 Space before next section

// 📍 Section: Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Address: ',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.place['address'] ?? 'No address available',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

// 📍 Latitude & Longitude rows (custom widgets)
            _buildLocationText('Latitude', widget.place['latitude']),
            _buildLocationText('Longitude', widget.place['longitude']),

// 🏷️ Section: Place Type / Category
            if (widget.place['types'] != null && widget.place['types'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.category, color: Colors.deepOrange, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Category: ',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: widget.place['types'][0],
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 💡 Inline Display of ML-Suggested Tags
            if (widget.place['tags_suggested_by_ml'] != null &&
                widget.place['tags_suggested_by_ml'] is List &&
                widget.place['tags_suggested_by_ml'].isNotEmpty) ...[

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tag, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Suggested Tags: ',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: (widget.place['tags_suggested_by_ml'] as List).join(', '),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],


// ⭐ Section: Rating
            Row(
              children: [
                const Icon(Icons.reviews, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                const Text('Rating: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                PlaceRatingWidget(
                  initialRating: (widget.place['rating'] ?? 0.0).toDouble(),
                  interactive: false,
                ),
              ],
            ),

// ⏰ Section: Opening Hours (if available)
            if (weekdayText != null && weekdayText.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.access_time, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 8),
                      Text('Opening Hours:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...weekdayText.map((dayText) => Padding(
                    padding: const EdgeInsets.only(left: 26.0, top: 4),
                    child: Text(dayText, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  )),
                ],
              ),

            const SizedBox(height: 24), // 🔹 Space before review section

// 💬 Section: Reviews & Add Review Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                // ➕ Add Review Button
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewPage(placeId: widget.placeId),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review, size: 18, color: Colors.white),
                  label: const Text('Add Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),


            const SizedBox(height: 10),
            PlaceReviewsWidget(placeId: widget.placeId, place: widget.place),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 🧭 Location Row Widget (Latitude / Longitude)
  Widget _buildLocationText(String label, dynamic value) {
    IconData? icon;
    if (label.toLowerCase().contains('latitude')) {
      icon = Icons.my_location;
    } else if (label.toLowerCase().contains('longitude')) {
      icon = Icons.explore;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: Colors.teal),
            const SizedBox(width: 8),
          ],
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(
            child: Text(value?.toString() ?? 'Unknown', style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// 🖼️ Fallback for broken images
  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 400,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
    );
  }

  /// 🔁 Helper: convert any type to double
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }
}
