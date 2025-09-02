import 'package:cloud_firestore/cloud_firestore.dart';

class DeletePlacesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Delete a place document by its ID from the `melaka` collection.
  Future<void> deletePlace(String docId) async {
    try {
      await _db.collection('melaka_places').doc(docId).delete();
      print("Place with ID $docId deleted successfully.");
    } catch (e) {
      print("Error deleting place: $e");
      rethrow;
    }
  }
}
