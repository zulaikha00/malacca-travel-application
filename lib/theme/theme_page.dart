import 'package:flutter/material.dart';
import 'package:fyp25/theme/theme.dart';
import 'package:provider/provider.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Theme Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                ),
              );
            },
          ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1),
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white), //  Makes back icon white too
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDarkMode
                  ? const Color(0xFF64B5F6)
                  : const Color.fromRGBO(41, 70, 158, 1.0),
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            trailing: Switch.adaptive(
              value: isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: const Color(0xFF64B5F6), // Sky blue
            ),
          ),
        ),
      ),
    );
  }
}
