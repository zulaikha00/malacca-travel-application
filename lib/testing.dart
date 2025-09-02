import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class RecommendationEvaluator {
  /// 🔢 Evaluate precision, recall, and F1 score
  Map<String, double> evaluateRecommendationTags({
    required List<Map<String, dynamic>> recommendedPlaces,
    required Set<String> likedTags,
  }) {
    double totalPrecision = 0;
    double totalRecall = 0;
    int evaluated = 0;

    for (var place in recommendedPlaces) {
      final tags = List<String>.from(place['tags_suggested_by_ml'] ?? []);
      if (tags.isEmpty) continue;

      final matched = tags.where((tag) => likedTags.contains(tag)).toList();
      double precision = matched.length / tags.length;
      double recall = likedTags.isEmpty ? 0.0 : matched.length / likedTags.length;

      totalPrecision += precision;
      totalRecall += recall;
      evaluated++;
    }

    if (evaluated == 0) return {
      'precision': 0,
      'recall': 0,
      'f1': 0,
    };

    double avgPrecision = totalPrecision / evaluated;
    double avgRecall = totalRecall / evaluated;
    double f1 = (avgPrecision + avgRecall) == 0
        ? 0
        : 2 * (avgPrecision * avgRecall) / (avgPrecision + avgRecall);

    return {
      'precision': avgPrecision,
      'recall': avgRecall,
      'f1': f1,
    };
  }

  /// 📄 Generate Excel file showing place-by-place evaluation
  Future<void> generateEvaluationExcel({
    required String uid,
    required List<Map<String, dynamic>> recommendedPlaces,
    required Set<String> likedTags,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Evaluation'];

    // Header
    sheet.appendRow([
      'Place Name',
      'Tags',
      'Matched Tags',
      'Precision',
      'Recall',
      'F1 Score (Per Place)'
    ]);

    double totalPrecision = 0;
    double totalRecall = 0;
    int count = 0;

    for (var place in recommendedPlaces) {
      final placeName = place['name'] ?? 'Unnamed';
      final tags = List<String>.from(place['tags_suggested_by_ml'] ?? []);
      if (tags.isEmpty) continue;

      final matched = tags.where((tag) => likedTags.contains(tag)).toList();
      double precision = matched.length / tags.length;
      double recall = likedTags.isEmpty ? 0.0 : matched.length / likedTags.length;
      double f1 = (precision + recall) == 0
          ? 0
          : 2 * (precision * recall) / (precision + recall);

      sheet.appendRow([
        placeName,
        tags.join(', '),
        matched.join(', '),
        precision.toStringAsFixed(2),
        recall.toStringAsFixed(2),
        f1.toStringAsFixed(2),
      ]);

      totalPrecision += precision;
      totalRecall += recall;
      count++;
    }

    // Summary row
    double avgPrecision = totalPrecision / count;
    double avgRecall = totalRecall / count;
    double f1Score = (avgPrecision + avgRecall) == 0
        ? 0
        : 2 * (avgPrecision * avgRecall) / (avgPrecision + avgRecall);

    sheet.appendRow([]);
    sheet.appendRow(['Average', '', '', avgPrecision, avgRecall, f1Score]);

    // Save file to documents folder
    // ✅ Save to Downloads
    final fileName = 'recommendation_evaluation_$uid.xlsx';
    final filePath = '/storage/emulated/0/Download/$fileName';

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes, flush: true);
      print("✅ Excel saved to: $filePath");
    }
  }
}