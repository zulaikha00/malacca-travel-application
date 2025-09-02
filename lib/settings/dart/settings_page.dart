import 'package:flutter/material.dart';
import 'package:fyp25/settings/dart/setting_menu_item.dart';
import '../../screen/login.dart';
import '../../service/auth_service.dart';
import 'change_email.dart';
import 'change_name.dart';
import 'change_password.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0), // Always dark blue
        iconTheme: const IconThemeData(color: Colors.white), // Back icon white
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
         /* SettingMenuItem(
            icon: Icons.edit,
            title: 'Change Name',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeName()),
              );
            },
          ),*/
          SettingMenuItem(
            icon: Icons.email,
            title: 'Change Email',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeEmailPage()),
              );
            },
          ),
          /*SettingMenuItem(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePassword()),
              );
            },
          ),*/
          SettingMenuItem(
            icon: Icons.delete,
            title: 'Delete Account',
            isDestructive: true,
            onTap: () async {
              // 🔔 Ask for confirmation to delete account
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Confirm Deletion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Are you sure you want to delete your account?\nThis action cannot be undone.',
                    style: TextStyle(fontSize: 16),
                  ),
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.delete_forever, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // 🔐 Delete Firestore + Auth account (with re-auth)
                await AuthService.deleteAccount(context);

                // 🔄 After deletion, navigate to LoginScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              }
            },
          ),

        ],
      ),
    );
  }
}
