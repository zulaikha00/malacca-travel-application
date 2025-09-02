
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class PlaceRatingWidget extends StatelessWidget {
  final double initialRating;
  final void Function(double)? onRatingUpdate;
  final bool interactive;

  const PlaceRatingWidget({
    Key? key,
    required this.initialRating,
    this.onRatingUpdate,
    this.interactive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: 24,
      ignoreGestures: !interactive, // Disable if not interactive
      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      itemBuilder: (context, _) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      onRatingUpdate: onRatingUpdate ?? (rating) {},
    );
  }
}
