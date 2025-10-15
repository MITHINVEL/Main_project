import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapDiagnosticScreen extends StatefulWidget {
  const MapDiagnosticScreen({super.key});
  @override
  State<MapDiagnosticScreen> createState() => _MapDiagnosticScreenState();
}

class _MapDiagnosticScreenState extends State<MapDiagnosticScreen> {
  GoogleMapController? _mapController;
  bool _mapInitialized = false;
  String _diagnosticInfo = '';
  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    List<String> results = [];
    // Test 1: Geocoding API
    try {
      List<Location> locations = await locationFromAddress('Kochi, Kerala');
      if (locations.isNotEmpty) {
        results.add('✅ Geocoding API: Working (${locations.length} results)');
      } else {
        results.add('❌ Geocoding API: No results');
      }
    } catch (e) {
      results.add('❌ Geocoding API Error: $e');
    }
    // Test 2: Reverse Geocoding
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        10.8505,
        76.2711,
      );
      if (placemarks.isNotEmpty) {
        results.add('✅ Reverse Geocoding: Working');
      } else {
        results.add('❌ Reverse Geocoding: No results');
      }
    } catch (e) {
      results.add('❌ Reverse Geocoding Error: $e');
    }

    setState(() {
      _diagnosticInfo = results.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Diagnostics'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Diagnostic Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Diagnostics:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  _diagnosticInfo.isEmpty
                      ? 'Running tests...'
                      : _diagnosticInfo,
                ),
                const SizedBox(height: 16),
                Text('Map Initialized: ${_mapInitialized ? "✅ Yes" : "❌ No"}'),
                const SizedBox(height: 8),
                const Text(
                  'API Key: AIzaSyCPgP9XU9Rtmxf5YpMn4HE372LJ-WvVM8I',
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          // Simple Map Test
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  setState(() {
                    _mapInitialized = true;
                  });
                  print('Diagnostic map created successfully');
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(10.8505, 76.2711), // Kochi
                  zoom: 12.0,
                ),
                markers: {
                  const Marker(
                    markerId: MarkerId('test'),
                    position: LatLng(10.8505, 76.2711),
                    infoWindow: InfoWindow(title: 'Test Location'),
                  ),
                },
                mapType: MapType.normal,
                myLocationEnabled: false,
                zoomControlsEnabled: false, // Disable to reduce overhead
                compassEnabled: false, // Disable to reduce memory
                rotateGesturesEnabled: false, // Disable to reduce memory
                tiltGesturesEnabled: false, // Disable to reduce memory
                liteModeEnabled: true, // Enable lite mode
                minMaxZoomPreference: const MinMaxZoomPreference(
                  10.0,
                  16.0,
                ), // Limit zoom
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runDiagnostics,
                    child: const Text('Retest APIs'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            const LatLng(10.8505, 76.2711),
                            15.0,
                          ),
                        );
                      }
                    },
                    child: const Text('Focus Map'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
