List<Map<String, dynamic>> filterPlacesByPreferences({
  required List<Map<String, dynamic>> allPlaces,
  required List<String> preferences,
}) {
  return allPlaces.where((place) {
    final types = List<String>.from(place['types'] ?? []);
    final firstType = types.isNotEmpty ? types.first.toLowerCase() : '';

    // Check if the first type matches any user preference
    return preferences.any((pref) => firstType == pref.toLowerCase());
  }).toList();
}
