// lib/utils/search_utils.dart

List<Map<String, dynamic>> filterPlacesByName(
    List<Map<String, dynamic>> places,
    String query,
    ) {
  return places
      .where((place) =>
      (place['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()))
      .toList();
}
