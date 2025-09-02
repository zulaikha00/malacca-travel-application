import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageGallerySlider extends StatelessWidget {
  final List<dynamic> imageUrls; // can be String or Uint8List

  const ImageGallerySlider({
    Key? key,
    required this.imageUrls,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: PageView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            var imageUrl = imageUrls[index];

            if (imageUrl is String && imageUrl.isNotEmpty) {
              return Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorImage();
                },
              );
            } else if (imageUrl is Uint8List) {
              return Image.memory(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorImage();
                },
              );
            } else {
              return _buildErrorImage();
            }
          },
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
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
