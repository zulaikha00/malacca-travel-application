import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// This function is used by Admins or Super Admins to delete any user's Firebase Auth account.
/// [userToDeleteUid] is the UID of the user to delete.
/// [idToken] is the ID token of the currently logged-in admin/super admin.
Future<void> deleteUserViaHttp({
  required String userToDeleteUid,
  required String idToken,
}) async {
  final url = Uri.parse('https://deleteuserbyuid-deleteuserbyuid-asb6wdryia-uc.a.run.app');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'uid': userToDeleteUid}),
  );

  if (response.statusCode == 200) {
    print('✅ User deleted successfully');
  } else {
    print('❌ Error: ${response.statusCode} - ${response.body}');
    throw Exception('Failed to delete user: ${response.body}');
  }
}
