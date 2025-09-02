import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<List<dynamic>> searchPlaces({
  required String keyword,
  required LatLng location,
  required String apiKey,
}) async {
  final url =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=5000&keyword=$keyword&key=$apiKey';

  final response = await http.get(Uri.parse(url));
  final data = json.decode(response.body);

  if (data['status'] == 'OK') {
    return data['results'];
  } else {
    throw Exception('Failed to fetch search results: ${data['status']}');
  }
}
