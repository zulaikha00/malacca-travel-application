import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp25/screen/register.dart';
import 'package:fyp25/screen/user_preferences.dart';
import 'package:icons_plus/icons_plus.dart';

import '../admin/admin_profile/admin_dashboard.dart';
import '../navigation/bottom_nav_bar.dart';
import '../service/auth_service.dart';
import '../widgets/custom_scaffold.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formLoginKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberPassword = false;
  bool _obscurePassword = true;

  //texfield decoration
  InputDecoration _buildInputDecoration(
      String label,
      String hint,
      IconData icon, {
        Widget? suffixIcon,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[700]), // always same
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[100], // always same background
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black45),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      showBackArrow: true,
      child: Column(
        children: [
          const Expanded(flex: 1, child: SizedBox(height: 10)),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formLoginKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 30.0,
                            fontWeight: FontWeight.w900,
                            color: Color.fromRGBO(41, 70, 158, 1.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      TextFormField(
                        controller: emailController,
                        style: TextStyle(color: Colors.black87),
                        // only value adapts
                        decoration: _buildInputDecoration(
                          'Email',
                          'Enter Email',
                          Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 20),


                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        obscuringCharacter: '*',
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter Password' : null,

                        // ✅ This controls the typed value color (dark/light mode)
                        style: TextStyle(color: Colors.black87),


                        // ✅ Decoration with dark mode only affecting suffixIcon
                        decoration: _buildInputDecoration(
                          'Password',
                          'Enter Password',
                          Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[300]  // Lighter for dark background
                                  : Colors.grey[700], // Darker for light background
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),

                        ),
                      ),



                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberPassword,
                                onChanged: (value) {
                                  setState(() => rememberPassword = value ?? false);
                                },
                                activeColor: Colors.blueAccent,
                              ),
                              const Text('Remember me', style: TextStyle(color: Colors.black45)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            if (_formLoginKey.currentState!.validate()) {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();
                              final AuthService _authService = AuthService();
                              User? user = await _authService.loginWithEmail(email, password);

                              if (user != null) {
                                final adminDoc = await FirebaseFirestore.instance
                                    .collection('admins')
                                    .doc(user.uid)
                                    .get();

                                if (adminDoc.exists) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => AdminDashboard()),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Welcome Admin'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                  return;
                                }

                                final userDoc = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .get();

                                final userData = userDoc.data();

                                if (mounted) {
                                  if (userData != null && userData['preferences'] != null) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const BottomNavigationPage()),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => UserPreferencePage(userId: user.uid)),
                                    );
                                  }
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Login Successful'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid Email or Password'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all fields'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          child: const Text('Login', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          const Expanded(child: Divider(thickness: 0.8)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Sign up with',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          const Expanded(child: Divider(thickness: 0.8)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final AuthService _authService = AuthService();
                            User? user = await _authService.signInWithGoogle();

                            if (user != null) {
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .get();

                              final userData = userDoc.data();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Login with Google successful')),
                              );

                              if (mounted) {
                                if (userData != null && userData['preferences'] != null) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const BottomNavigationPage()),
                                  );
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => UserPreferencePage(userId: user.uid)),
                                  );
                                }
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Google sign-in failed')),
                              );
                            }
                          },
                          child: Logo(Logos.google),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account?',
                            style: TextStyle(color: Colors.black45),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (e) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              ' Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
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