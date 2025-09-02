// Sectioned report with Section A (Functional Accuracy) and Section B (Metrics)

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:fyp25/page/recommendation_service.dart';
import 'package:path/path.dart' as p;

class RecommendationReportGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RecommendationService _recommendationService = RecommendationService();

  Future<File> _getUniqueFilePath(String basePath, String fileName) async {
    String dir = basePath;
    String base = p.basenameWithoutExtension(fileName);
    String ext = p.extension(fileName);
    String fullPath = p.join(dir, "$base$ext");

    int counter = 1;
    while (await File(fullPath).exists()) {
      fullPath = p.join(dir, "$base ($counter)$ext");
      counter++;
    }

    return File(fullPath);
  }

  Future<void> generateScenarioReport(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      print("❌ User not found");
      return;
    }

    final userData = userDoc.data()!;
    final userName = userData['name'] ?? userData['fullName'] ?? uid;
    final preferences = List<String>.from(userData['preferences'] ?? []);
    final likedPlaceIds = List<String>.from(userData['liked'] ?? []);

    final snapshot = await _firestore.collection('melaka_places').get();
    final allPlaces = snapshot.docs.map((doc) {
      final data = doc.data();
      data['placeId'] = doc.id;
      return data;
    }).toList();

    final recommended = await _recommendationService.getRecommendedMelakaPlaces(uid);
    final Set<String> prefTypes = preferences.toSet();

    final likedPlaces = allPlaces.where((p) => likedPlaceIds.contains(p['placeId'])).toList();
    final likedTags = likedPlaces.expand((p) => List<String>.from(p['tags_suggested_by_ml'] ?? [])).toSet();

    final prefTagSources = allPlaces.where(
            (p) => List<String>.from(p['types'] ?? []).any((type) => prefTypes.contains(type))
    ).toList();
    final preferenceTags = prefTagSources.expand(
            (p) => List<String>.from(p['tags_suggested_by_ml'] ?? [])
    ).toSet();

    String scenario = '';
    String expectedOutcome = '';
    String reason = '';

    final hasNoPreferences = preferences.isEmpty;
    final hasNoLikes = likedPlaceIds.isEmpty;

    if (hasNoPreferences && hasNoLikes) {
      scenario = 'User selects no preferences or likes';
      expectedOutcome = 'All places should be shown';
      reason = 'No filter → All shown as expected';
    } else if (!hasNoPreferences && hasNoLikes) {
      scenario = 'User selects preference: ${preferences.join(", ")}';
      expectedOutcome = 'Recommend only places with type matching preferences';
      reason = 'Using preference only. Tags: ${preferenceTags.take(5).join(", ")}';
    } else if (hasNoPreferences && !hasNoLikes) {
      scenario = 'User likes places with tags: ${likedTags.take(5).join(", ")}';
      expectedOutcome = 'Recommend places with similar tags';
      reason = 'Using liked tag profile only';
    } else {
      scenario = 'User likes tags: ${likedTags.take(3).join(", ")} and preferences: ${preferences.join(", ")}';
      expectedOutcome = 'Recommend places with those tags or types';
      reason = 'Using liked tags + type preferences';
    }

    int matchCount = 0;
    for (var place in recommended) {
      final tags = List<String>.from(place['tags_suggested_by_ml'] ?? []);
      final types = List<String>.from(place['types'] ?? []);
      final hasTag = tags.any((t) => likedTags.contains(t));
      final hasType = types.any((t) => prefTypes.contains(t));

      if (hasNoPreferences && hasNoLikes ||
          (!hasNoLikes && !hasNoPreferences && (hasTag || hasType)) ||
          (!hasNoPreferences && hasNoLikes && hasType) ||
          (!hasNoLikes && hasNoPreferences && hasTag)) {
        matchCount++;
      }
    }

    // TP, FP, FN, TN Calculation
    int TP = 0, FP = 0, FN = 0, TN = 0;
    final recommendedIds = recommended.map((p) => p['placeId']).toSet();
    final allMatchedPlaces = allPlaces.where((place) {
      final tags = List<String>.from(place['tags_suggested_by_ml'] ?? []);
      final types = List<String>.from(place['types'] ?? []);
      return tags.any((tag) => likedTags.contains(tag)) ||
          types.any((type) => prefTypes.contains(type));
    }).toList();
    final matchedIds = allMatchedPlaces.map((p) => p['placeId']).toSet();

    for (var place in recommended) {
      if (matchedIds.contains(place['placeId'])) TP++; else FP++;
    }
    // 🔍 Recalculate TF-IDF vector untuk user
    Set<String> allTagSet = allPlaces.expand((p) => List<String>.from(p['tags_suggested_by_ml'] ?? [])).toSet();
    final allTags = allTagSet.toList();
    int totalPlaces = allPlaces.length;

// IDF
    Map<String, double> idf = {};
    for (String tag in allTags) {
      int count = allPlaces.where((p) => List<String>.from(p['tags_suggested_by_ml'] ?? []).contains(tag)).length;
      idf[tag] = log(totalPlaces / (1 + count));
    }

// Build user vector
    Map<String, double> userTagFreq = {};
    for (var place in likedPlaces) {
      for (var tag in List<String>.from(place['tags_suggested_by_ml'] ?? [])) {
        userTagFreq[tag] = (userTagFreq[tag] ?? 0) + 1.3;
      }
    }
    for (var place in prefTagSources) {
      for (var tag in List<String>.from(place['tags_suggested_by_ml'] ?? [])) {
        userTagFreq[tag] = (userTagFreq[tag] ?? 0) + 1.5;
      }
    }
    List<double> userVector = allTags.map((tag) {
      double tf = userTagFreq[tag] ?? 0.0;
      return tf * (idf[tag] ?? 0.0);
    }).toList();

    /// ✅ Now check only FN if similarity ≥ 0.5
    for (var place in allMatchedPlaces) {
      if (!recommendedIds.contains(place['placeId'])) {
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
        if (similarity >= 0.5) {
          FN++;
        }
      }
    }

    for (var place in allPlaces) {
      final id = place['placeId'];
      if (!recommendedIds.contains(id) && !matchedIds.contains(id)) TN++;
    }

    double precision = (TP + FP) == 0 ? 0 : TP / (TP + FP);
    double recall = (TP + FN) == 0 ? 0 : TP / (TP + FN);
    double f1 = (precision + recall) == 0 ? 0 : 2 * (precision * recall) / (precision + recall);
    double fullAccuracy = (TP + TN + FP + FN) == 0 ? 0 : (TP + TN) / (TP + TN + FP + FN);

    int total = recommended.length;
    double accuracy = total == 0 ? 0 : (matchCount / total) * 100;
    String status = accuracy >= 70 ? "✅ Pass" : "❌ Fail";

// 🔍 DEBUG OUTPUT KE TERMINAL
    print("🔎 Evaluation Metrics for UID: $uid");
    print("• Total Recommended: $total");
    print("• Match Count: $matchCount");
    print("• Accuracy: ${accuracy.toStringAsFixed(2)}%");
    print("• Status: $status");
    print("• TP: $TP | FP: $FP | FN: $FN | TN: $TN");
    print("• Precision: ${precision.toStringAsFixed(2)}");
    print("• Recall: ${recall.toStringAsFixed(2)}");
    print("• F1 Score: ${f1.toStringAsFixed(2)}");
    print("• Full Accuracy: ${fullAccuracy.toStringAsFixed(2)}");


    // Excel Report
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    // Section A: Functional Matching Accuracy
    sheet.appendRow(["SECTION A: FUNCTIONAL ACCURACY"]);
    sheet.appendRow([
      "Test No", "User", "Scenario", "Expected Outcome", "Actual Outcome",
      "Matching Places", "Accuracy (%)", "Pass/Fail", "Reason"
    ]);
    sheet.appendRow([
      "1", userName, scenario, expectedOutcome, "$total places shown",
      "$matchCount/$total match", accuracy.toStringAsFixed(2), status, reason
    ]);

    sheet.appendRow([""]); // Spacer row

    // Section B: Metric-based Evaluation
    sheet.appendRow(["SECTION B: EVALUATION METRICS"]);
    sheet.appendRow([
      "Precision", "Recall", "F1 Score", "TP", "FP", "FN", "TN", "Full Accuracy"
    ]);
    sheet.appendRow([
      precision.toStringAsFixed(2), recall.toStringAsFixed(2), f1.toStringAsFixed(2),
      TP, FP, FN, TN, fullAccuracy.toStringAsFixed(2)
    ]);

    final directory = '/storage/emulated/0/Download';
    final filename = 'reco_scenario_$uid.xlsx';
    final file = await _getUniqueFilePath(directory, filename);
    await file.writeAsBytes(excel.encode()!);
    print("✅ Scenario report saved at \${file.path}");
  }
}

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
