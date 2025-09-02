import 'package:flutter/material.dart';
import 'package:fyp25/screen/welcome_screen.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.showBackArrow = true, // Add a flag to show or hide the back arrow
  });

  final Widget? child;
  final PreferredSizeWidget? appBar;
  final bool showBackArrow; // Flag to control the back arrow visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ??
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0, // Remove the app bar shadow
            automaticallyImplyLeading: false, // Remove the default back arrow
            leading: showBackArrow
                ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              },
            )
                : null, // If showBackArrow is false, don't show the back arrow
          ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Image.asset(
            'assets/background/photo.png',
            fit: BoxFit.cover, // Cover the full screen
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(child: child!),
        ],
      ),
    );
  }
}
