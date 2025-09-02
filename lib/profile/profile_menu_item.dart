import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;
  final Widget? trailing;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing = const SizedBox.shrink(),
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,

        // Leading icon with fixed dark blue background
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color.fromRGBO(41, 70, 158, 1.0), // ✅ moved here directly
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),

        // Title
        title: Text(
          title,
          style: TextStyle(
            color: isLogout
                ? Colors.red
                : (isDarkMode ? Colors.white : Colors.black),
            fontWeight: FontWeight.w500,
          ),
        ),

        // Trailing arrow
        trailing: trailing ??
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDarkMode ? Colors.white : Colors.grey.shade600,
              ),
            ),

        onTap: onTap,
      ),
    );
  }
}
