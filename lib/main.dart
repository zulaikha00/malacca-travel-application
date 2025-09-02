import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fyp25/screen/user_preferences.dart';
import 'package:fyp25/theme/theme.dart';
import 'package:provider/provider.dart'; // 👈 Import provider
import 'package:fyp25/screen/welcome_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔐 Stripe publishable key (Test mode)
  Stripe.publishableKey = '';

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyMelaka',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode, // 🔁 Apply dynamic theme
      home: const WelcomeScreen(),
      //home: const UserPreferencePage(userId: '',),
      //home: TicketPage(),
    );
  }
}
