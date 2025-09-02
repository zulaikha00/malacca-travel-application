import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screen/login.dart';
import '../../theme/theme.dart';
import 'admin_change_password.dart';

class SettingsAdminPage extends StatefulWidget {
  const SettingsAdminPage({Key? key}) : super(key: key);

  @override
  State<SettingsAdminPage> createState() => _SettingsAdminPageState();
}

class _SettingsAdminPageState extends State<SettingsAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isPhone = screenWidth < 600;

              return Text(
                'Admin Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                ),
              );
            },
          ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0), // 🔵 Dark blue background
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // 👈 This makes the back arrow white
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🌙 Theme Toggle
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle between light and dark theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? '🌑 Dark mode enabled' : '☀️ Light mode enabled'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  secondary: const Icon(Icons.brightness_6),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔐 Change Password
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.blue),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account credentials'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => showChangePasswordDialog(context),
              ),
            ),

            const SizedBox(height: 20),

            /// 🚪 Logout
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                subtitle: const Text('Exit your admin session'),
                trailing: const Icon(Icons.exit_to_app),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout Confirmation'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                            );
                            Future.delayed(const Duration(milliseconds: 300), () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Logout successful'),
                                  backgroundColor: Color(0xFF87CEEB),
                                ),
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white, // 👈 This makes icon and text white
                          ),
                        ),

                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
