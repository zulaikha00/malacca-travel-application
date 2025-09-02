import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailPage extends StatefulWidget {
  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  User? user;
  bool isEmailVerified = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser(); // Load current user info on init
  }

  // Load current user and check email verification status
  Future<void> _loadUser() async {
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user!.reload(); // Refresh user info
      user = FirebaseAuth.instance.currentUser;
      setState(() {
        isEmailVerified = user!.emailVerified;
        isLoading = false;
      });
    }
  }

  // Send verification email
  Future<void> _sendVerificationEmail() async {
    try {
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;

    // ✅ Always use this dark blue for buttons regardless of theme
    const Color primaryColor = Color(0xFF29469E);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Verify Email',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: primaryColor, // ✅ Always dark blue
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Email Info
              Text(
                'Email: ${user?.email ?? "No user"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Verification Status Icon
              Icon(
                isEmailVerified ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isEmailVerified ? Colors.green : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 12),

              Text(
                isEmailVerified
                    ? 'Your email is verified!'
                    : 'Your email is not verified.',
                style: TextStyle(
                  fontSize: 16,
                  color: isEmailVerified ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Send Verification Email Button
              if (!isEmailVerified)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendVerificationEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // ✅ Always dark blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text(
                      'Send Verification Email',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // ✅ Refresh Button (outlined)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadUser,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white70 : Color(0xFF29469E), // ✅ Light border in dark mode
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? Colors.white : Color(0xFF29469E), // ✅ Icon matches theme
                  ),
                  label: Text(
                    'Refresh Status',
                    style: TextStyle(
                      color: isDark ? Colors.white : Color(0xFF29469E), // ✅ Text matches theme
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
