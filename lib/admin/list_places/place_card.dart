import 'package:flutter/material.dart';

class PlaceCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isSelected;

  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?> onCheckboxChanged;

  final bool isPhone; // ✅ Add this

  const PlaceCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onCheckboxChanged,
    required this.isPhone, // ✅ Add this
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        color: isSelected ? Colors.grey[300] : null, // 🔘 Highlight if selected
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: onCheckboxChanged,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),

              // 🖼️ Image preview
              // 🖼️ Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  width: 100,
                  height: 70,
                  fit: BoxFit.cover,
                )
                    : Container(
                        width: 100,
                        height: 70,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),

              const SizedBox(width: 12),

              // 📛 Place name
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isPhone ? 14 : 16, // 👈 Adjust font size

                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
