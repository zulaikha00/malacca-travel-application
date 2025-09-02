import 'package:flutter/material.dart';
import 'package:fyp25/page/homepage.dart';       // ✅ Home Page
import '../page/booking.dart';                  // ✅ Booking Page
import '../profile/profile.dart';               // ✅ Profile Page
import '../page/ticket.dart';                   // ✅ Ticket Page

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key});

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  int myCurrentIndex = 0; // 🔢 Track current selected tab index

  // 🔁 List of pages that correspond to each navigation tab
  final List<Widget> pages = [
    const HomePage(),       // Index 0
    TicketPage(),           // Index 1
    BookingPage(),          // Index 2
    ProfilePage(),          // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // 👇 Bottom Navigation Bar section
        bottomNavigationBar: Container(
          height: 70, // ⬆️ Adjust height of bottom bar
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 30,
                offset: Offset(0, 20), // Drop shadow below bar
              ),
            ],
          ),
          child: ClipRRect(
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed, // Prevents shifting animation
              currentIndex: myCurrentIndex,
              //backgroundColor: Colors.white,
              // 🎯 Dynamic color handling
              selectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.lightBlueAccent // 🌙 Dark mode selected
                  : const Color.fromRGBO(41, 70, 158, 1.0), // 🌞 Light mode selected

              unselectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white // 🌙 Dark mode unselected
                  : Colors.black45, // 🌞 Light mode unselected

              selectedFontSize: 12,
              unselectedFontSize: 12, // ✅ Keeps text size consistent
              showSelectedLabels: true,
              showUnselectedLabels: true, // ✅ Show all labels
              selectedIconTheme: IconThemeData(size: 24), // ✅ Prevent icon "up" effect
              unselectedIconTheme: IconThemeData(size: 24), // ✅ Same size to avoid shift
              onTap: (index) {
                setState(() {
                  myCurrentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_sharp),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.confirmation_number_sharp),
                  label: 'Ticket',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_available_sharp),
                  label: 'Booking',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle_sharp),
                  label: 'Account',
                ),
              ],
            )

          ),
        ),

        // 📄 Show selected page based on index
        body: pages[myCurrentIndex],
      ),
    );
  }
}
