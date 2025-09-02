import 'package:cloud_firestore/cloud_firestore.dart';
import '../page/recommendation_service.dart';
import 'accuracy_result_exporter.dart';

class CBFAccuracyTester {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RecommendationService _service = RecommendationService();
  final AccuracyExporter _exporter = AccuracyExporter();

  Future<void> testAndExport(List<String> userIds, {int k = 5}) async {
    List<Map<String, dynamic>> results = [];

    for (String uid in userIds) {
      print("\n🧪 Testing user: $uid");
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) continue;

      final userData = userDoc.data()!;
      final liked = List<String>.from(userData['liked'] ?? []);
      final preferences = List<String>.from(userData['preferences'] ?? []);

      final recommended = await _service.getRecommendedMelakaPlaces(uid);
      final topK = recommended.take(k).toList();
      final topKIds = topK.map((e) => e['placeId'] as String).toList();

      int hits = 0;
      double score = 0.0;
      String method = '';
      List<String> matchedNames = [];

      if (liked.isNotEmpty) {
        // ✅ Precision@K
        for (var place in topK) {
          final placeId = place['placeId'];
          if (liked.contains(placeId)) {
            hits++;
            matchedNames.add(place['name'] ?? placeId);
          }
        }
        score = hits / topK.length; // Elakkan bahagian kosong
            ;
        method = 'Precision@$k';
      } else if (preferences.isNotEmpty) {
        // ✅ Preference Match Rate
        for (var place in topK) {
          final types = List<String>.from(place['types'] ?? []);
          if (types.any((t) => preferences.contains(t))) {
            hits++;
            matchedNames.add(place['name'] ?? place['placeId']);
          }
        }
        score = hits / k;
        method = 'Preference Match Rate@$k';
      } else {
        method = 'No Data';
      }

      results.add({
        'User ID': uid,
        'Method': method,
        'Total Matched': hits,
        'Score': score.toStringAsFixed(2),
        'Matched Place Names': matchedNames.join(', '),
        'Recommended Place IDs': topKIds.join(', '),
      });
    }

    await _exporter.exportToExcel(results, filename: 'cbf_accuracy_results.xlsx');
  }

}
