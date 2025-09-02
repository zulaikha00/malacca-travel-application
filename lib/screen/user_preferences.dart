import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/bottom_nav_bar.dart';
import '../widgets/custom_scaffold.dart';

class UserPreferencePage extends StatefulWidget {
  final String userId;

  const UserPreferencePage({Key? key, required this.userId}) : super(key: key);

  @override
  _UserPreferencePageState createState() => _UserPreferencePageState();
}

class _UserPreferencePageState extends State<UserPreferencePage> {
  // 🌐 List of available preferences
  final List<String> preferences = [
    'tourist_attraction',
    'museum',
    'art_gallery',
    'park',
    'zoo',
    'restaurant',
    'cafe',
    'shopping_mall',
    'beach',
    'campground',
    'mosque',
    'lodging',
  ];

  List<String> selectedPreferences = [];

  void togglePreference(String pref) {
    setState(() {
      if (selectedPreferences.contains(pref)) {
        selectedPreferences.remove(pref);
      } else {
        selectedPreferences.add(pref);
      }
    });
  }

  Future<void> savePreferences() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'preferences': selectedPreferences,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavigationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      showBackArrow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🧢 Page Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
            child: Center(
              child: Text(
                'Choose your interests',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),

          ),

          // 📦 Preferences Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 3,
                children: preferences.map((pref) {
                  final isSelected = selectedPreferences.contains(pref);

                  return GestureDetector(
                    onTap: () => togglePreference(pref),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromRGBO(41, 70, 158, 1.0)
                            : (isDark ? Colors.grey[800] : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color.fromRGBO(41, 70, 158, 1.0)
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                        boxShadow: [
                          if (!isDark && !isSelected)
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pref.replaceAll('_', ' ').toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 🚀 Next Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: selectedPreferences.isEmpty
                ? const SizedBox.shrink()
                : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: savePreferences,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16),
                    ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
