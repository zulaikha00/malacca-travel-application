import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../list_places/places_by_types.dart';

class TypesPage extends StatelessWidget {
  const TypesPage({super.key});

  /// 🔍 Get unique first types from Firestore 'types' field
  Future<List<String>> _getUniqueFirstTypes() async {
    final snapshot = await FirebaseFirestore.instance.collection('melaka_places').get();
    final Set<String> uniqueFirstTypes = {};

    for (var doc in snapshot.docs) {
      final List<dynamic>? types = doc['types'];
      if (types != null && types.isNotEmpty && types[0] is String) {
        uniqueFirstTypes.add(types[0]);
      }
    }

    return uniqueFirstTypes.toList()..sort();
  }

  /// 🎨 Generate pastel colors (light mode)
  List<Color> _generatePastelColors(int count) {
    final random = Random();
    return List.generate(count, (_) {
      return Color.fromARGB(
        255,
        200 + random.nextInt(55),
        200 + random.nextInt(55),
        200 + random.nextInt(55),
      );
    });
  }

  /// 🌒 Generate dark card colors (dark mode)
  List<Color> _generateDarkColors(int count) {
    final random = Random();
    return List.generate(count, (_) {
      return Color.fromARGB(
        255,
        30 + random.nextInt(50),
        30 + random.nextInt(50),
        30 + random.nextInt(50),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600; // 📱 Detect if it's a phone

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.white : Colors.black54;
    final Color bgColor = isDark ? Colors.black : Colors.grey[100]!;
    final List<Color> cardColors = isDark ? _generateDarkColors(10) : _generatePastelColors(10);

    // 🎚 Responsive dimensions
    final double titleFontSize = isPhone ? 16 : 20;
    final double cardPaddingV = isPhone ? 10 : 14;
    final double cardPaddingH = isPhone ? 16 : 20;
    final double iconSize = isPhone ? 18 : 22;
    final double cardRadius = isPhone ? 12 : 16;
    final double circleAvatarRadius = isPhone ? 18 : 22;
    final double arrowSize = isPhone ? 14 : 16;
    final double textFontSize = isPhone ? 14 : 16;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Categories',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize, // 📏 Adjusted for screen size
          ),
        ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: bgColor,
      body: FutureBuilder<List<String>>(
        future: _getUniqueFirstTypes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No categories found.',
                style: TextStyle(color: textColor, fontSize: textFontSize),
              ),
            );
          }

          final types = snapshot.data!;

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cardColor = cardColors[index % cardColors.length];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlacesByTypePage(type: types[index]),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(cardRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPaddingH,
                    vertical: cardPaddingV,
                  ),
                  child: Row(
                    children: [
                      // 🧿 Circle icon
                      CircleAvatar(
                        backgroundColor: isDark ? Colors.white24 : Colors.white,
                        radius: circleAvatarRadius,
                        child: Icon(Icons.category, color: iconColor, size: iconSize),
                      ),
                      const SizedBox(width: 16),

                      // 🔤 Category title
                      Expanded(
                        child: Text(
                          types[index],
                          style: TextStyle(
                            fontSize: textFontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),

                      // ➡️ Arrow
                      Icon(Icons.arrow_forward_ios, size: arrowSize, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
