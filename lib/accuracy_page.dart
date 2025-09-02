import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'accuracy_test.dart';

class AccuracyTestPage extends StatelessWidget {
  const AccuracyTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recommendation Accuracy Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // ✅ Get current logged-in user
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              String uid = user.uid;

              // ✅ Run the recommendation tester
              final tester =RecommendationReportGenerator();
              await tester.generateScenarioReport(uid);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Excel file generated for UID: $uid')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ No user is currently logged in.')),
              );
            }
          },
          child: Text('Generate Accuracy Report for Current User'),
        ),
      ),
    );
  }
}
