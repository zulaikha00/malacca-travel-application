import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class PlaceReviewsWidget extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> place;

  const PlaceReviewsWidget({
    Key? key,
    required this.placeId,
    required this.place,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> combinedReviews = [];

        // ✅ Embedded reviews from Google Places API
        List<dynamic> embedded = place['reviews'] ?? [];
        for (var r in embedded) {
          final unixTime = r['time']; // Usually in seconds
          final reviewTime = unixTime != null
              ? DateTime.fromMillisecondsSinceEpoch(unixTime * 1000)
              : DateTime.now(); // fallback

          combinedReviews.add({
            'name': r['author_name'] ?? 'Anonymous',
            'rating': (r['rating'] ?? 0).toDouble(),
            'timestamp': reviewTime,
            'comment': r['text'] ?? '',
          });
        }

        // ✅ Firestore reviews from user submission
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final firestoreReviews = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now();

            return {
              'name': data['name'] ?? 'Anonymous',
              'rating': (data['rating'] ?? 0).toDouble(),
              'timestamp': timestamp,
              'comment': data['comment'] ?? '',
            };
          }).toList();

          combinedReviews.addAll(firestoreReviews);
        }

        // ❌ No reviews found
        if (combinedReviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'No reviews available.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          );
        }

        // 🔃 Sort by most recent
        combinedReviews.sort((a, b) =>
            (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: combinedReviews.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final review = combinedReviews[index];
            final timestamp = review['timestamp'] as DateTime;
            final formattedDate =
                '${timestamp.day}/${timestamp.month}/${timestamp.year}';

            return ListTile(
              title: Text(
                review['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: review['rating'],
                        itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                        itemSize: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(review['comment']),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
