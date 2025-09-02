import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> clearViewedHistory(String uid) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'viewed': [],
  });
}
