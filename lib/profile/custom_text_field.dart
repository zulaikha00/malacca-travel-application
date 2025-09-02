import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final bool isDarkMode;

  const CustomTextField({
    super.key,
    required this.icon,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      obscuringCharacter: '*',
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
        labelText: hint,
        labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white54 : Color(0xFF29469E),
          ),
        ),
      ),
    );
  }
}
