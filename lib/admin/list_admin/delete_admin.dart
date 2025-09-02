import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> deleteAdminViaHttp({
  required BuildContext context,
  required String adminToDeleteUid,
  required String idToken,
}) async {
  final url = Uri.parse('https://deleteadminbyuid-deleteadminbyuid-asb6wdryia-uc.a.run.app'); // Replace with actual URL

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({'uid': adminToDeleteUid}),
  );

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? colorScheme.surfaceVariant : Colors.green[50],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Admin deleted successfully',
                style: TextStyle(color: isDark ? Colors.white : Colors.green[900]),
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? colorScheme.surfaceVariant : Colors.red[50],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Error: ${response.statusCode} - ${response.body}',
                style: TextStyle(color: isDark ? Colors.white : Colors.red[900]),
              ),
            ),
          ],
        ),
      ),
    );
    throw Exception('Failed to delete admin: ${response.body}');
  }

}
