import 'dart:io';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp25/page/recommendation_service.dart';

class RecommendationAccuracyTester {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RecommendationService _recommender = RecommendationService();

  // Main function to evaluate recommendation accuracy
  Future<void> runAccuracyTestForCurrentUser({int k = 5}) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user is currently logged in.');
      return;
    }

    final uid = user.uid;

    // Fetch user's liked places from Firestore
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      print('❌ User document not found.');
      return;
    }

    final likedPlaces = List<String>.from(userDoc.data()?['liked'] ?? []);
    if (likedPlaces.isEmpty) {
      print('⚠️ User has not liked any places.');
      return;
    }

    // Get top-K recommendations
    final recommended = await _recommender.getRecommendedMelakaPlaces(uid);
    final topK = recommended.take(k).toList();
    if (topK.isEmpty) {
      print('⚠️ No recommendations available.');
      return;
    }

    // Prepare Excel workbook
    final excel = Excel.createExcel();
    final sheet = excel['AccuracyReport'];

    // Headers for main evaluation
    sheet.appendRow([
      'User ID',
      'Hits',
      'Precision',
      'Recall',
      'F1 Score',
      'liked',
      'preference',
      'liked+preference',
      'general'
    ]);

    int hits = 0;

    // Track reasons
    Map<String, int> reasonCount = {
      'liked': 0,
      'preference': 0,
      'liked+preference': 0,
      'general': 0,
    };
    Map<String, int> reasonTypeHits = {
      'liked': 0,
      'preference': 0,
      'liked+preference': 0,
      'general': 0,
    };
    Map<String, int> reasonTypeTotal = {
      'liked': 0,
      'preference': 0,
      'liked+preference': 0,
      'general': 0,
    };

    // For tag-level analysis
    Map<String, int> tagTotal = {};
    Map<String, int> tagHits = {};

    // Evaluate top-k recommendations
    for (var place in topK) {
      final placeId = place['placeId'];
      final reasonType = place['reasonType'] ?? 'general';
      final tags = List<String>.from(place['tags_suggested_by_ml'] ?? []);

      // Count reason type totals
      reasonTypeTotal[reasonType] = (reasonTypeTotal[reasonType] ?? 0) + 1;
      reasonCount[reasonType] = (reasonCount[reasonType] ?? 0) + 1;

      // Count tag total occurrences
      for (var tag in tags) {
        tagTotal[tag] = (tagTotal[tag] ?? 0) + 1;
      }

      // If it's a hit (user liked it)
      if (likedPlaces.contains(placeId)) {
        hits++;
        reasonTypeHits[reasonType] = (reasonTypeHits[reasonType] ?? 0) + 1;

        // Count tag hits
        for (var tag in tags) {
          tagHits[tag] = (tagHits[tag] ?? 0) + 1;
        }
      }
    }

    // Calculate precision, recall, F1
    double precision = hits / k;
    double recall = hits / likedPlaces.length;
    double f1 = (precision + recall) > 0 ? 2 * (precision * recall) / (precision + recall) : 0;

    // Append main accuracy results
    sheet.appendRow([
      uid,
      hits,
      '=B2/${k}', // Excel formula for precision = hits / k
      '=B2/${likedPlaces.length}', // Excel formula for recall = hits / liked.length
      '=IF((C2+D2)=0, 0, 2*C2*D2/(C2+D2))', // Excel formula for F1
      reasonCount['liked'],
      reasonCount['preference'],
      reasonCount['liked+preference'],
      reasonCount['general'],
    ]);

    // Add reason type breakdown
    sheet.appendRow([]);
    sheet.appendRow(['ReasonType', 'Hits', 'Total', 'Precision (%)']);
    for (var type in reasonTypeHits.keys) {
      final hit = reasonTypeHits[type]!;
      final total = reasonTypeTotal[type]!;
      final reasonPrecision = total > 0 ? (hit / total * 100).toStringAsFixed(2) : 'N/A';
      sheet.appendRow([type, hit, total, reasonPrecision]);
    }

    // Add second sheet for tag-level evaluation
    final tagSheet = excel['TagAnalysis'];
    tagSheet.appendRow(['Tag', 'Hits', 'Total', 'Precision (%)']);
    for (var tag in tagTotal.keys) {
      final hit = tagHits[tag] ?? 0;
      final total = tagTotal[tag]!;
      final tagPrecision = total > 0 ? (hit / total * 100).toStringAsFixed(2) : '0.00';
      tagSheet.appendRow([tag, hit, total, tagPrecision]);
    }

    // Save Excel file
    final filename = 'AccuracyReport_${uid}_Top$k.xlsx';
    await _saveToDownloadsDirectly(excel, filename);
  }

  // Save file to Downloads
  Future<void> _saveToDownloadsDirectly(Excel excel, String fileName) async {
    try {
      final file = File('/storage/emulated/0/Download/$fileName');
      await file.writeAsBytes(excel.encode()!);
      print('✅ Excel report saved to Downloads: ${file.path}');
    } catch (e) {
      print('❌ Failed to save Excel file: $e');
    }
  }
}
