import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  final String placeId;

  const ReviewPage({Key? key, required this.placeId}) : super(key: key);

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _commentController = TextEditingController();
  double _rating = 0;

  // Submit review to Firestore
  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (comment.isNotEmpty && _rating > 0 && user != null) {
      String name = 'Anonymous';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['name'] != null) {
          name = userDoc.data()!['name'];
        }
      } catch (e) {
        print('❌ Failed to get user name: $e');
      }

      await FirebaseFirestore.instance.collection('reviews').add({
        'placeId': widget.placeId,
        'name': name,
        'userId': user.uid,
        'comment': comment,
        'rating': _rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _commentController.clear();
        _rating = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Review submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all fields.")),
      );
    }
  }

  // Custom Star Rating Widget
  Widget _buildStarRating(double rating, {Function(double)? onRatingChanged}) {
    return Row(
      children: List.generate(5, (index) {
        final isFilled = index < rating;
        return IconButton(
          icon: Icon(
            isFilled ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: onRatingChanged != null
              ? () => onRatingChanged(index + 1.0)
              : null,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color.fromRGBO(41, 70, 158, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Add Your Review',
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Comment",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Comment box
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: "Write your experience or feedback here...",
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Your Rating",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Star rating
            _buildStarRating(_rating, onRatingChanged: (newRating) {
              setState(() {
                _rating = newRating;
              });
            }),

            const SizedBox(height: 30),

            // Submit button
            Center(
              child: ElevatedButton.icon(
                onPressed: _submitReview,
                icon: const Icon(Icons.send, size: 20),
                label: const Text(
                  "Submit Review",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
