import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp25/screen/login.dart';

class ChangeEmailPage extends StatefulWidget {
  @override
  _ChangeEmailPageState createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final currentPasswordController = TextEditingController();
  final newEmailController = TextEditingController();
  bool _isSaving = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔐 Main function to handle secure email change
  Future<void> _changeEmail() async {
    final user = _auth.currentUser!;
    final currentPassword = currentPasswordController.text.trim();
    final newEmail = newEmailController.text.trim();

    // 🧪 Debug: Print current & new email
    print('Current email: ${user.email}');
    print('New email: $newEmail');

    // 🔍 Validation
    if (currentPassword.isEmpty || newEmail.isEmpty) {
      _showAlertDialog('Please fill in all fields');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
      _showAlertDialog('Enter a valid email address');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 🔑 Re-authenticate the user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      print('✅ Re-authentication successful');

      // 📩 Send verification link to new email
      await user.verifyBeforeUpdateEmail(newEmail);
      print('✅ Verification email sent to new email: $newEmail');

      // 📝 Optional: Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'email': newEmail,
      });

      // ✅ Notify user
      _showAlertDialogAndLogout('Verification email sent to $newEmail. Please check your inbox.');
      print('👋 Signing out to complete process...');

      // 🔐 Sign out for security
      //await _auth.signOut();

      // 🔁 Redirect to login screen
     /* Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );*/

    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String msg = switch (e.code) {
        'wrong-password' => 'Incorrect current password',
        'email-already-in-use' => 'Email is already in use by another account',
        'requires-recent-login' => 'Please re-login and try again',
        'invalid-email' => 'Invalid email format',
        'operation-not-allowed' => 'Email/password sign-in is disabled in Firebase',
        _ => 'Error: ${e.message}',
      };
      _showAlertDialog(msg);
    } catch (e) {
      print('❌ General Exception: $e');
      _showAlertDialog('Something went wrong: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// 🧼 Dispose controllers
  @override
  void dispose() {
    currentPasswordController.dispose();
    newEmailController.dispose();
    super.dispose();
  }

  /// 🔔 Basic alert dialog for errors (no auto logout)
  Future<void> _showAlertDialog(String message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: isDark ? Colors.orange[300] : Colors.red),
            const SizedBox(width: 10),
            Text(
              'Alert',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  /// ✅ Alert with logout action (force confirmation before signout)
  Future<void> _showAlertDialogAndLogout(String message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Color(0xFFE3F2FD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: isDark ? Colors.lightBlue[200] : Color(0xFF1976D2)),
            const SizedBox(width: 10),
            Text(
              'Notice',
              style: TextStyle(
                color: isDark ? Colors.white : Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _auth.signOut(); // Sign out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: isDark ? Colors.lightBlue[200] : Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Input styling
  InputDecoration _adaptiveInputDecoration(String label, bool isDark, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: isDark ? Colors.white54 : Colors.grey[700]) : null,
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? Color(0xFF64B5F6) : Color(0xFF29469E),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// 🖼️ UI layout
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const mainColor = Color(0xFF29469E);

    return Scaffold(
      appBar: AppBar(
            title: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isPhone = screenWidth < 600;

                return Text(
                  'Change Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
                  ),
                );
              },
            ),
        backgroundColor: mainColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _changeEmail,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _adaptiveInputDecoration('Current Password', isDark, icon: Icons.lock_outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newEmailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _adaptiveInputDecoration('New Email Address', isDark, icon: Icons.email_outlined),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _changeEmail,
                icon: const Icon(Icons.email_outlined),
                label: _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                    : const Text('Update Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
