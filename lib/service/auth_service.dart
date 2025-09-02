import'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screen/login.dart';


class AuthService{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  //register dgn email dan password
  Future<User?> registerWithEmail(String name, String email,String password) async{

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;


      //store user data dalam Firestore

      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'profileImage': '', //update dkt profile nanti
        'preferences': null, // user has not selected preferences yet
      });

      return user;
    }
    catch(e){
      print('Register error : $e');
      return null;
    }
  }


    //Login dgn email and password
    Future<User?> loginWithEmail(String email, String password) async{
        try{
          UserCredential result = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password
          );
          return result.user;
        }
        catch (e){
          print('Login error $e');
          return null;
        }


    }


    //Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      // Save user to Firestore if not exist
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'profileImage': user.photoURL ?? '',
            'preferences': null,
          });
        }
      }

      return user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }


  // Method to show the confirmation dialog
  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        const Color kPrimaryColor = Color.fromRGBO(41, 70, 158, 1);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 12, 12, 16),

          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: kPrimaryColor, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),

          // ✅ Proper usage of `content:`
          content: Text(
            'Are you sure you want to log out?',
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }




// Logout
  Future<void> signOut(BuildContext context) async {
    try {
      // Show the logout confirmation dialog
      bool shouldLogout = await _showLogoutDialog(context);

      if (shouldLogout) {
        // Sign out of Firebase Auth
        await FirebaseAuth.instance.signOut();

        // Sign out from Google
        await GoogleSignIn().signOut();

        // Show a SnackBar with success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green, // Green background for success
          ),
        );

        // Navigate to the login screen after signing out
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()), // Ensure LoginScreen is correct
        );
      }
    } catch (e) {
      print("Error during sign-out: $e");
      // Show a SnackBar with error message (red background)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error during logout. Please try again.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red, // Red background for error
        ),
      );

    }
  }


  // ✅ Delete Account from Firestore and FirebaseAuth
  static Future<void> deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      if (uid != null && user != null) {
        // 🗑️ Delete Firestore user document
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // ✅ Refresh token to ensure user is authenticated recently
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        // 🔐 Delete Firebase Auth user account
        await refreshedUser!.delete();

        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Account deleted successfully'),
          ),
        );
      }
    } catch (e) {
      print('Delete account issue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to delete account. Try again.'),
        ),
      );
    }
  }




}







