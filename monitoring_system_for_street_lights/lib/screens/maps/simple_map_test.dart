import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SimpleMapTest extends StatefulWidget {
  const SimpleMapTest({super.key});

  @override
  State<SimpleMapTest> createState() => _SimpleMapTestState();
}

class _SimpleMapTestState extends State<SimpleMapTest> {
  late GoogleMapController mapController;
  static const LatLng _kochi = LatLng(10.8505, 76.2711);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print('Simple map created successfully');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Map Test'),
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(target: _kochi, zoom: 14.0),
        markers: {
          const Marker(
            markerId: MarkerId('kochi'),
            position: _kochi,
            infoWindow: InfoWindow(title: 'Kochi', snippet: 'Test Location'),
          ),
        },
        // Performance optimizations
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        rotateGesturesEnabled: false,
        tiltGesturesEnabled: false,
        liteModeEnabled: true,
        minMaxZoomPreference: const MinMaxZoomPreference(10.0, 16.0),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map is working!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
