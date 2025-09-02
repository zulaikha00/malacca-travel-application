import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 Detect if dark mode is active
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black, // Text color
        ),
        decoration: InputDecoration(
          hintText: 'Search places...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700], // Hint color
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white : Colors.black, // Icon color
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.grey[200], // Background color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // No border line
          ),
        ),
      ),
    );
  }
}
