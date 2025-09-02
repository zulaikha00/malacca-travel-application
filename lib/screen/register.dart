
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp25/screen/user_preferences.dart';
import 'package:fyp25/service/auth_service.dart';
import 'package:fyp25/widgets/custom_scaffold.dart';
import 'package:fyp25/screen/login.dart';
import 'package:icons_plus/icons_plus.dart';

import '../navigation/bottom_nav_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formRegisterKey = GlobalKey<FormState>();
  bool agreePersonalData = true;

  //firebase
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final auth = AuthService();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.black87), // fixed color
      hintStyle: TextStyle(color: Colors.grey),     // fixed color
      prefixIcon: Icon(icon, color: Colors.grey[600]), // fixed icon color
      filled: true,
      fillColor: Colors.grey[100], // fixed background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color.fromRGBO(41, 70, 158, 1.0), width: 1.5),
      ),
    );
  }



  //validate password
  //condition
  String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Please enter Confirm Password';
    }
    if (value != passwordController.text) {
      return 'Password do not match';
    }
    return null;
  }

  //register method
  void register() async {

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password do not match')));
      return;
    }

    final user = await auth.registerWithEmail(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    //condition
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showBackArrow:true,
      child: Column(
        children: [
          const Expanded(flex: 0, child: SizedBox(height: 10)),
          Expanded(
            //adjust space secara auto
            flex: 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),

                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formRegisterKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(41, 70, 158, 1.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: nameController,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter full name' : null,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _buildInputDecoration('Full Name', 'Enter Full Name', Icons.person),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: emailController,
                          validator: (value) => value == null || value.isEmpty ? 'Please enter Email' : null,
                          style: const TextStyle(color: Colors.black87),
                          decoration: _buildInputDecoration('Email', 'Enter Email', Icons.email),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: passwordController,
                          obscureText: !passwordVisible,
                          style: const TextStyle(color: Colors.black87),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Password';
                            } else if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          decoration: _buildInputDecoration('Password', 'Enter Password', Icons.lock).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                passwordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300] // Brighter for dark background
                                    : Colors.grey[600], // Darker for light background
                              ),
                              onPressed: () {
                                setState(() {
                                  passwordVisible = !passwordVisible;
                                });
                              },
                            ),

                          ),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !confirmPasswordVisible,
                          style: const TextStyle(color: Colors.black87),
                          validator: (value) =>
                          value != passwordController.text ? 'Passwords do not match' : null,
                          decoration:
                          _buildInputDecoration('Confirm Password', 'Re-enter Password', Icons.lock_outline)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[300] // Brighter color for dark theme
                                    : Colors.grey[600], // Default gray for light theme
                              ),
                              onPressed: () {
                                setState(() {
                                  confirmPasswordVisible = !confirmPasswordVisible;
                                });
                              },
                            ),

                          ),
                        ),
                        const SizedBox(height: 25),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: agreePersonalData,
                              onChanged: (value) => setState(() => agreePersonalData = value!),
                              activeColor: Colors.blueAccent,
                            ),
                            const Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I agree to the processing of',
                                  style: TextStyle(color: Colors.black45),
                                  children: [
                                    TextSpan(
                                      text: ' Personal data',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (_formRegisterKey.currentState!.validate() && agreePersonalData) {
                                register();
                              } else if (!agreePersonalData) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please agree to the processing personal data'),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300, thickness: 1),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('Sign up with', style: TextStyle(color: Colors.black45)),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300, thickness: 1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final AuthService _authService = AuthService();
                                User? user = await _authService.signInWithGoogle();

                                if (user != null) {
                                  final userDocRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid);

                                  final userDoc = await userDocRef.get();

                                  // 🔹 If this is the first sign-in, create the document
                                  if (!userDoc.exists) {
                                    await userDocRef.set({
                                      'uid': user.uid,
                                      'name': user.displayName ?? '',
                                      'email': user.email ?? '',
                                      'photoURL': user.photoURL ?? '',
                                      'preferences': null, // Default empty for first-timers
                                    });
                                  }

                                  final updatedUserDoc = await userDocRef.get();
                                  final userData = updatedUserDoc.data();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Google sign-in successful')),
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
                                        MaterialPageRoute(
                                          builder: (_) => UserPreferencePage(userId: user.uid),
                                        ),
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
                          ],
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?', style: TextStyle(color: Colors.black45)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                ' Login',
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
                )

            ),
          ),
        ],
      ),
    );
  }
}
