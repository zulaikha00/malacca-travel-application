import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'direction_maps.dart'; // ✅ Page to open on tap

class NearbyPlacesTab extends StatefulWidget {
  final String title;
  final LatLng location;
  final String googleApiKey;
  final ScrollController controller;

  const NearbyPlacesTab({
    super.key,
    required this.title,
    required this.location,
    required this.googleApiKey,
    required this.controller,
  });

  @override
  State<NearbyPlacesTab> createState() => _NearbyPlacesTabState();
}

class _NearbyPlacesTabState extends State<NearbyPlacesTab> {
  List<dynamic> _places = [];
  bool _loading = true;
  String _selectedType = 'restaurant';

  final Map<String, IconData> placeTypeIcons = {
    'restaurant': Icons.restaurant,
    'hospital': Icons.local_hospital,
    'school': Icons.school,
    'pharmacy': Icons.local_pharmacy,
    'cafe': Icons.local_cafe,
    'atm': Icons.atm,
    'gas_station': Icons.local_gas_station,
    'supermarket': Icons.shopping_cart,
    'mosque': Icons.mosque,
    'lodging': Icons.hotel,
  };

  @override
  void initState() {
    super.initState();
    _fetchNearbyPlaces(_selectedType);
  }

  Future<void> _fetchNearbyPlaces(String type) async {
    setState(() {
      _loading = true;
      _places = [];
    });

    final location = '${widget.location.latitude},${widget.location.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$location&radius=1500&type=$type&key=${widget.googleApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'];

        for (var place in results) {
          place['forced_type'] = type;
        }

        setState(() {
          _places = results;
        });
      } else {
        print('❌ API Error: ${data['status']}');
      }
    } catch (e) {
      print('❌ Error fetching $type: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 👆 Now scrollable horizontally if overflow
  Widget _buildTypeSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: placeTypeIcons.entries.map((entry) {
            final type = entry.key;
            final icon = entry.value;
            final isSelected = type == _selectedType;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedType = type);
                  _fetchNearbyPlaces(type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isPhone ? 50 : 64, // 📱 Smaller icon box on phone
                  height: isPhone ? 50 : 64,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.black87,
                      size: isPhone ? 22 : 28, // 📱 Smaller icon on phone
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildPlaceList(BuildContext context) {
    if (_places.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No nearby places found."),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return GridView.count(
      controller: widget.controller,
      crossAxisCount: isPhone ? 2 : 3, // 📱 2 per row on phone, 3 on bigger screens
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isPhone ? 3 / 4 : 4 / 3.5, // 📱 Taller on phones

      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: List.generate(_places.length, (index) {
        final place = _places[index];
        final name = place['name'] ?? 'Unnamed';
        final address = place['vicinity'] ?? 'No address';

        final photoRef = (place['photos'] != null && place['photos'].isNotEmpty)
            ? place['photos'][0]['photo_reference']
            : null;

        final imageUrl = photoRef != null
            ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${widget.googleApiKey}'
            : null;

        final LatLng target = LatLng(
          place['geometry']['location']['lat'],
          place['geometry']['location']['lng'],
        );

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DirectionPage(
                  destination: target,
                  destinationName: name,
                  imageUrl: imageUrl ?? 'https://via.placeholder.com/300',
                  rating: (place['rating'] ?? 0.0).toDouble(),
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isPhone ? 13 : 14, // 📱 Smaller text for phones
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isPhone ? 11 : 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildTypeSelector(),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildPlaceList(context),
        ),
      ],
    );
  }
}
