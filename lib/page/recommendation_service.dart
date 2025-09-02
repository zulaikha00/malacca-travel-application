import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧠 Service to handle personalized content-based recommendations
class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔁 Calculates cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// 🧾 Get the display name of the current user from Firestore
  Future<String> getCurrentUserName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('name')) {
      return doc['name'];
    }
    return "User"; // Fallback name
  }

  /// 🎯 Main function to recommend Melaka places based on user preferences & likes
  Future<List<Map<String, dynamic>>> getRecommendedMelakaPlaces(
      String uid, {
        Set<String> tempDisliked = const {},
      }) async {
    /// 🔍 Step 1: Fetch user document
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;
    final userTypes = List<String>.from(userData['preferences'] ?? []);
    final likedPlaceIds = List<String>.from(userData['liked'] ?? []);

    /// ✨ Greet user
    String userName = await getCurrentUserName(uid);
    print("👤 Hello, $userName!");

    /// 🎯 Print preferences
    print("\n🎯 Your Preferences:");
    for (var type in userTypes) {
      print("• $type");
    }

    /// 🔍 Step 1a: Fetch liked places' details
    List<Map<String, dynamic>> likedPlaces = [];

    for (String placeId in likedPlaceIds) {
      try {
        final placeDoc = await _firestore.collection('melaka_places').doc(placeId).get();
        if (placeDoc.exists) {
          final data = placeDoc.data()!;
          likedPlaces.add({
            'name': data['name'],
            'tags': List<String>.from(data['tags_suggested_by_ml'] ?? []),
          });
        } else {
          print("❌ Place ID not found: $placeId");
        }
      } catch (e) {
        print("⚠️ Error for place ID $placeId: $e");
      }
    }



    /// ❤️ Print liked places and their tags
    print("\n❤️ Liked Places & Their Tags:");
    for (var place in likedPlaces) {
      final name = place['name'];
      final tags = (place['tags'] as List<String>).join(', ');
      print("• $name");
      print("  Tags: $tags");
    }


    // 📥 Step 2: Load all places
    final snapshot = await _firestore.collection('melaka_places').get();

    List<Map<String, dynamic>> allPlaces = [];
    Set<String> allTagsSet = {};
    Map<String, double> userTagFreq = {};
    Set<String> likedTags = {};
    Set<String> likedPlaceTypes = {};

    bool hasLiked = likedPlaceIds.isNotEmpty;
    bool hasPrefs = userTypes.isNotEmpty;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['placeId'] = doc.id;

      if (tempDisliked.contains(doc.id)) continue;

      final types = List<String>.from(data['types'] ?? []);
      final tags = List<String>.from(data['tags_suggested_by_ml'] ?? []);
      if (tags.isEmpty) continue;

      // Collect type preferences from liked places
      if (hasLiked && likedPlaceIds.contains(doc.id)) {
        likedPlaceTypes.addAll(types);
      }

      // Weight tags from matching preference types
      if (hasPrefs && types.any((type) => userTypes.contains(type))) {
        for (var tag in tags) {
          userTagFreq[tag] = (userTagFreq[tag] ?? 0) + 1.5;
        }
        allTagsSet.addAll(tags);
      }

      // Weight tags from liked places
      if (hasLiked && likedPlaceIds.contains(doc.id)) {
        for (var tag in tags) {
          userTagFreq[tag] = (userTagFreq[tag] ?? 0) + 1.3;
        }
        likedTags.addAll(tags);
        allTagsSet.addAll(tags);
      }

      allPlaces.add(data);
    }

    // ⚠️ Step 3: Fallback if no user vector (no tags matched)
    if (userTagFreq.isEmpty) {
      print("⚠️ No user vector available. Fallback to rating 5 only.");
      final rating5Places = allPlaces.where((p) => (p['rating'] ?? 0) == 5).toList();
      for (var place in rating5Places) {
        place['reason'] = 'Recommended by rating (5 stars)';
        place['reasonType'] = 'rating';
        place['similarity'] = 0.0;
      }
      return rating5Places;
    }

    print("📊 User TF tag weights: $userTagFreq");
    print("🏷️ Tags count: ${allTagsSet.length}");

    // 🧠 Step 4: Compute IDF for all tags
    final allTags = allTagsSet.toList();
    int totalPlaces = allPlaces.length;
    Map<String, double> idf = {};
    for (String tag in allTags) {
      int count = allPlaces.where((p) =>
          List<String>.from(p['tags_suggested_by_ml'] ?? []).contains(tag)
      ).length;
      idf[tag] = log(totalPlaces / (1 + count));
    }

    // 🔬 Step 5: Compute user TF-IDF vector
    List<double> userVector = allTags.map((tag) {
      double tf = userTagFreq[tag] ?? 0.0;
      return tf * (idf[tag] ?? 0.0);
    }).toList();

    // 📌 Step 6: Score each place based on cosine similarity
    List<Map<String, dynamic>> scoredPlaces = [];
    Set<String> acceptedTypes = {...userTypes, ...likedPlaceTypes};

    for (var place in allPlaces) {
      final tags = List<String>.from(place['tags_suggested_by_ml'] ?? []);
      Map<String, int> placeTF = {};
      for (var tag in tags) {
        placeTF[tag] = (placeTF[tag] ?? 0) + 1;
      }

      List<double> placeVector = allTags.map((tag) {
        int tf = placeTF[tag] ?? 0;
        return tf * (idf[tag] ?? 0.0);
      }).toList();

      double similarity = _cosineSimilarity(userVector, placeVector);
      double rating = (place['rating'] ?? 0.0).toDouble();
      final placeTypes = List<String>.from(place['types'] ?? []);

      bool matchedPref = placeTypes.any((type) => userTypes.contains(type));
      bool matchedLikedType = placeTypes.any((type) => likedPlaceTypes.contains(type));

      // Apply threshold and match tags/types
      if (similarity >= 0.5 && placeTypes.any((type) => acceptedTypes.contains(type))) {
        String reason;
        String reasonType;
        int priority;

        if (matchedPref) {
          reason = "Recommended based on your preferences";
          reasonType = "preference";
          priority = 2;
        } else if (matchedLikedType) {
          reason = "Recommended based on your likes";
          reasonType = "liked";
          priority = 1;
        } else {
          reason = "Recommended";
          reasonType = "general";
          priority = 0;
        }

        scoredPlaces.add({
          'data': place,
          'similarity': similarity,
          'rating': rating,
          'reason': reason,
          'reasonType': reasonType,
          'priority': priority,
        });
      }
    }

    // 📊 Step 7: Sort by similarity and then rating
    scoredPlaces.sort((a, b) {
      int simCompare = b['similarity'].compareTo(a['similarity']);
      return simCompare != 0 ? simCompare : b['rating'].compareTo(a['rating']);
    });

    // 📤 Step 8: Final output formatting
    final result = scoredPlaces.map((entry) {
      Map<String, dynamic> placeData = Map<String, dynamic>.from(entry['data']);
      placeData['reason'] = entry['reason'];
      placeData['reasonType'] = entry['reasonType'];
      placeData['similarity'] = entry['similarity'];
      return placeData;
    }).toList();

    // 📌 Print final results
    print("📍 Final Recommended Places:");
    for (var place in result) {
      print("🔸 ${place['name']} - Similarity: ${place['similarity'].toStringAsFixed(2)} | Reason: ${place['reason']}");
    }
    print("✅ Total Recommended Places: ${result.length}");

    // 📈 Optional: accuracy calculation
    int matchedCount = 0;
    for (var entry in scoredPlaces) {
      final tags = List<String>.from(entry['data']['tags_suggested_by_ml'] ?? []);
      final types = List<String>.from(entry['data']['types'] ?? []);
      if (tags.any((tag) => likedTags.contains(tag)) ||
          types.any((t) => userTypes.contains(t))) {
        matchedCount++;
      }
    }
    double accuracy = scoredPlaces.isEmpty ? 0 : (matchedCount / scoredPlaces.length) * 100;
    print("📈 Accuracy: ${accuracy.toStringAsFixed(2)}%");

    return result;
  }

  /// ❤️ Add a place to user's liked list
  Future<void> saveLikedPlace(String uid, Map<String, dynamic> place) async {
    final placeId = place['placeId'];
    await _firestore.collection('users').doc(uid).update({
      'liked': FieldValue.arrayUnion([placeId]),
    });
  }

  /// 💔 Remove a place from liked list
  Future<void> removeLikedPlace(String uid, String placeId) async {
    await _firestore.collection('users').doc(uid).update({
      'liked': FieldValue.arrayRemove([placeId]),
    });
  }

  /// 👁️ Log place view to track user engagement
  Future<void> logPlaceView(String uid, String placeId) async {
    await _firestore.collection('users').doc(uid).update({
      'viewed': FieldValue.arrayUnion([placeId]),
    });
  }
}
