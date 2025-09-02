import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'bottom_sheet_direction.dart';
import 'route_options.dart';

class DirectionPage extends StatefulWidget {
  final LatLng destination;
  final String destinationName;
  final String imageUrl;
  final double rating;

  const DirectionPage({
    super.key,
    required this.destination,
    required this.destinationName,
    required this.imageUrl,
    required this.rating,
  });

  @override
  State<DirectionPage> createState() => _DirectionPageState();
}

class _DirectionPageState extends State<DirectionPage> {
  final Completer<GoogleMapController> _controller = Completer();  // Controller for Google Map
  LatLng? _fromLocation;           // User's current location
  final Set<Marker> _markers = {}; // Markers on the map
  final Set<Polyline> _polylines = {}; // Route lines on the map

  String _selectedMode = 'driving';   // Travel mode (e.g. driving, walking)
  String _travelDuration = '';        // Time to reach destination
  String _travelDistance = '';        // Distance to destination
  bool _isSheetVisible = true;        // Bottom sheet visibility
  MapType _currentMapType = MapType.normal;  // Map type (normal/satellite/etc)

  final String googleAPIKey = ''; // Replace with your API key
  List<RouteOption> _routeOptions = [];  // List of available route options
  int _selectedRouteIndex = 0;           // Index of selected route

  bool _isLoading = false;
  double _sheetHeightFactor = 0.6;       // Height factor for map padding when bottom sheet opens

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Start by getting user location
  }

  /// Get user's current GPS location using Geolocator
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _showErrorDialog('Please enable location services.');

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
          return _showErrorDialog('Location permission is required.');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      _fromLocation = LatLng(position.latitude, position.longitude);

      _setMarkers(); // Place markers on map

      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(_fromLocation!, 14));

      await _getDirections(); // Load route directions
    } catch (e) {
      _showErrorDialog('Failed to get location.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Place markers for origin and destination
  void _setMarkers() {
    _markers.clear();

    if (_fromLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('from'),
        position: _fromLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: widget.destination,
      infoWindow: InfoWindow(title: widget.destinationName),
    ));
  }

  /// Fetch direction data from Google Directions API
  Future<void> _getDirections() async {
    if (_fromLocation == null) return;
    setState(() => _isLoading = true);

    final origin = '${_fromLocation!.latitude},${_fromLocation!.longitude}';
    final destination = '${widget.destination.latitude},${widget.destination.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$_selectedMode&alternatives=true&key=$googleAPIKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        _polylines.clear();
        _routeOptions.clear();

        final routes = data['routes'];

        for (int i = 0; i < routes.length; i++) {
          final route = routes[i];
          final leg = route['legs'][0];
          final duration = leg['duration']['text'];
          final summary = route['summary'];

          _routeOptions.add(RouteOption(
            duration: duration,
            summary: summary.isNotEmpty ? summary : 'Route ${i + 1}',
            isFastest: i == 0,
          ));

          if (i == _selectedRouteIndex) {
            final points = PolylinePoints().decodePolyline(route['overview_polyline']['points']);
            final polylineCoordinates = points.map((e) => LatLng(e.latitude, e.longitude)).toList();

            _polylines.add(Polyline(
              polylineId: PolylineId('route_$i'),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
              patterns: _selectedMode == 'walking'
                  ? [PatternItem.dot, PatternItem.gap(10)]
                  : <PatternItem>[], // ✅ Use empty list if not walking
            ));



            _travelDistance = leg['distance']['text'];
            _travelDuration = leg['duration']['text'];

            _adjustMapCamera(); // Zoom and fit route into view
          }
        }
      } else {
        _showErrorDialog('Directions not found: ${data['status']}');
      }
    } catch (e) {
      _showErrorDialog('Failed to fetch directions.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Adjust camera bounds based on polyline + bottom sheet height
  Future<void> _adjustMapCamera() async {
    if (_polylines.isEmpty) return;

    final controller = await _controller.future;
    final polyline = _polylines.first.points;
    final bounds = _createBounds(polyline);

    final padding = MediaQuery.of(context).size.height * _sheetHeightFactor;

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
  }

  /// Calculate LatLngBounds that include all route points
  LatLngBounds _createBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (LatLng p in points) {
      minLat = minLat == null ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = maxLat == null ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = minLng == null ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = maxLng == null ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  /// Display error messages in dialog
  Future<void> _showErrorDialog(String message) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  /// Toggle map type
  void _setMapType(MapType type) => setState(() => _currentMapType = type);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent layout shift on keyboard
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isPhone = screenWidth < 600;

            return Text(
              'Route Direction',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isPhone ? 16 : 20, // 👈 Adjust size based on screen
              ),
            );
          },
        ),
        backgroundColor: const Color.fromRGBO(41, 70, 158, 1.0),
        centerTitle: true, // 👈 Center the title
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Map with dynamic bottom padding
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              bottom: _isSheetVisible
                  ? MediaQuery.of(context).size.height * _sheetHeightFactor
                  : 0.0,
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: widget.destination, zoom: 14),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: _currentMapType,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) => _controller.complete(controller),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
            ),
          ),

          //map type
          // 🔄 Map Type Toggle Icon Button
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton(
              heroTag: "mapTypeButton",
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () async {
                final selectedType = await showMenu<MapType>(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 80, 16, 0), // Adjust position
                  items: [
                    const PopupMenuItem(
                      value: MapType.normal,
                      child: Text('Normal'),
                    ),
                    const PopupMenuItem(
                      value: MapType.satellite,
                      child: Text('Satellite'),
                    ),
                    const PopupMenuItem(
                      value: MapType.terrain,
                      child: Text('Terrain'),
                    ),
                    const PopupMenuItem(
                      value: MapType.hybrid,
                      child: Text('Hybrid'),
                    ),
                  ],
                );

                if (selectedType != null) {
                  setState(() => _currentMapType = selectedType);
                }
              },
              tooltip: 'Change Map Type',
              child: const Icon(Icons.layers, color: Colors.black),
            ),
          ),





          // Loading spinner
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Bottom direction sheet
          if (_isSheetVisible)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setState(() => _sheetHeightFactor = notification.extent);
                Future.delayed(const Duration(milliseconds: 100), _adjustMapCamera);
                return true;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.2,
                maxChildSize: 0.7,
                builder: (context, scrollController) => DirectionBottomSheet(
                  scrollController: scrollController,
                  fromLocation: _fromLocation,
                  toLocation: widget.destination,
                  toName: widget.destinationName,
                  travelDistance: _travelDistance,
                  travelDuration: _travelDuration,
                  selectedMode: _selectedMode,
                  routeOptions: _routeOptions,
                  selectedRouteIndex: _selectedRouteIndex,
                  onModeChanged: (mode) async {
                    setState(() {
                      _selectedMode = mode;
                      _selectedRouteIndex = 0;
                    });
                    await _getDirections();
                  },
                  onRouteSelected: (index) async {
                    setState(() => _selectedRouteIndex = index);
                    await _getDirections();
                  },
                  onCloseSheet: () {
                    setState(() {
                      _isSheetVisible = false;
                      _sheetHeightFactor = 0.0;
                    });
                    _adjustMapCamera();
                  },
                  googleApiKey: googleAPIKey,
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !_isSheetVisible
          ? FloatingActionButton(
              onPressed: () => setState(() => _isSheetVisible = true),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.menu),
              tooltip: 'Show Directions',
      )
          : null,
    );
  }
}
