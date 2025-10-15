import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/location_service.dart';
import '../../widgets/web_map_view.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(
    10.8505,
    76.2711,
  ); // Kochi, Kerala default
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _mapInitialized = false;
  bool _useManualEntry = false; // Fallback for when map fails
  bool _showMapFailureMessage = false;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<Location> _searchResults = [];
  
  // Auto-fallback timer
  Timer? _mapInitTimer;

  @override
  void initState() {
    super.initState();
    print('LocationPickerScreen initializing...');
    _initializeLocation();
    _testGoogleMapsAPI();
    
    // Auto-fallback if map doesn't initialize in 8 seconds
    _mapInitTimer = Timer(const Duration(seconds: 8), () {
      if (!_mapInitialized && mounted) {
        setState(() {
          _showMapFailureMessage = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Map tiles not loading. Use WebView or Manual Entry.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'WebView',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => WebMapView(
                    latitude: _selectedLocation.latitude,
                    longitude: _selectedLocation.longitude,
                    address: _selectedAddress,
                  ),
                ));
              },
            ),
          ),
        );
      }
    });
  }

  // Test Google Maps API
  void _testGoogleMapsAPI() async {
    try {
      print('Testing Google Maps API...');
      // Test if we can get location data
      List<Location> testLocations = await locationFromAddress('Kochi, Kerala');
      if (testLocations.isNotEmpty) {
        print(
          'Google Maps API is working! Found ${testLocations.length} locations for Kochi',
        );
      } else {
        print('Google Maps API returned no results');
      }
    } catch (e) {
      print('Google Maps API test failed: $e');
    }
  }

  void _initializeLocation() {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _selectedAddress = widget.initialAddress ?? '';
      _updateMarker();
    } else {
      // Use default Kerala location and get current location
      _selectedLocation = const LatLng(10.8505, 76.2711); // Kochi, Kerala
      _updateMarker();
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      Position? position = await LocationService.getCurrentLocation();
      if (position != null) {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _updateMarker();
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_selectedLocation),
        );
        await _updateAddress();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _selectedAddress.isNotEmpty
                ? _selectedAddress
                : 'Tap to select',
          ),
        ),
      );
    });
  }

  Future<void> _updateAddress() async {
    String address = await LocationService.getAddressFromCoordinates(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
    );
    setState(() {
      _selectedAddress = address;
    });
    _updateMarker();
  }

  void _onMapTap(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });

    _updateMarker();
    await _updateAddress();

    setState(() => _isLoading = false);
  }

  void _confirmLocation() {
    Navigator.of(context).pop({
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress,
    });
  }

  // Search for location
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      _searchResults = await locationFromAddress(query);

      if (_searchResults.isNotEmpty) {
        // Take the first result
        final location = _searchResults.first;
        final latLng = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedLocation = latLng;
        });

        _updateMarker();
        await _updateAddress();

        // Animate camera to the searched location
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));

        // Clear search
        _searchController.clear();
        FocusScope.of(context).unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Expanded(child: Text('Location found and selected!')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No location found for "$query"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.arrow_back,
              color: const Color(0xFF2D3748),
              size: 20.sp,
            ),
          ),
        ),
        title: Text(
          'Select Street Light Location',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        actions: [
          // Test Search Button
          IconButton(
            onPressed: () async {
              try {
                print('Testing search for "Kochi"...');
                List<Location> locations = await locationFromAddress(
                  'Kochi, Kerala',
                );
                print('Search results: ${locations.length} locations found');
                if (locations.isNotEmpty) {
                  print(
                    'First result: ${locations.first.latitude}, ${locations.first.longitude}',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Search works! Found ${locations.length} locations',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search failed - no results'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                print('Search error: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Search error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.search, color: Colors.green, size: 20.sp),
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.my_location,
                color: const Color(0xFF667EEA),
                size: 20.sp,
              ),
            ),
          ),
          // Debug button to test map functionality
          IconButton(
            onPressed: () {
              print('Map initialized: $_mapInitialized');
              print('Selected location: $_selectedLocation');
              print('Markers count: ${_markers.length}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Map Status: ${_mapInitialized ? "Loaded" : "Loading..."}',
                  ),
                  backgroundColor: _mapInitialized
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.bug_report, color: Colors.orange, size: 20.sp),
            ),
          ),
          // Toggle between map and manual entry
          IconButton(
            onPressed: () {
              setState(() {
                _useManualEntry = !_useManualEntry;
                if (_useManualEntry) {
                  _latController.text = _selectedLocation.latitude
                      .toStringAsFixed(6);
                  _lngController.text = _selectedLocation.longitude
                      .toStringAsFixed(6);
                  _addressController.text = _selectedAddress;
                }
              });
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _useManualEntry
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _useManualEntry ? Icons.map : Icons.edit_location,
                color: _useManualEntry ? Colors.blue : Colors.grey,
                size: 20.sp,
              ),
            ),
          ),
          // Open WebView fallback (Google Maps web) in case native map is blank
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => WebMapView(
                    latitude: _selectedLocation.latitude,
                    longitude: _selectedLocation.longitude,
                    address: _selectedAddress,
                  ),
                ),
              );
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.web, color: Colors.purple, size: 20.sp),
            ),
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: _useManualEntry ? _buildManualEntryView() : _buildMapView(),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for location (e.g., Kochi, Kerala)',
              hintStyle: TextStyle(
                color: const Color(0xFF718096),
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: const Color(0xFF667EEA),
                size: 20.sp,
              ),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(16.w),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF667EEA),
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchLocation(_searchController.text);
                        }
                      },
                      icon: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            onSubmitted: _searchLocation,
          ),
        ),

        // Address Info Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: const Color(0xFF667EEA),
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              if (_isLoading)
                Row(
                  children: [
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF667EEA),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Getting address...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  _selectedAddress.isNotEmpty
                      ? _selectedAddress
                      : 'Tap on the map to select location',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF718096),
                  ),
                ),
              SizedBox(height: 8.h),
              Text(
                'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
                'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFFA0AEC0),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Google Map - IMPORTANT: Use Expanded to give it proper height
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      setState(() {
                        _mapInitialized = true;
                      });
                      print('Google Map initialized successfully');
                      
                      // Cancel auto-fallback timer since map loaded successfully
                      _mapInitTimer?.cancel();

                      // Move camera to selected location after initialization
                      Future.delayed(const Duration(milliseconds: 1000), () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_selectedLocation, 15.0),
                        );
                      });
                    },
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    onTap: _onMapTap,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    trafficEnabled: false,
                    buildingsEnabled: true,
                    indoorViewEnabled: false,
                    // Disable lite mode to show actual map tiles
                    liteModeEnabled: false,
                    minMaxZoomPreference: const MinMaxZoomPreference(
                      8.0,
                      20.0,
                    ),
                    cameraTargetBounds: CameraTargetBounds.unbounded,
                    mapType: MapType.normal,
                  ),

                  // Loading overlay
                  if (!_mapInitialized)
                    Container(
                      color: Colors.grey.withOpacity(0.5),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF667EEA),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Loading Google Maps...',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            if (_showMapFailureMessage) ...[
                              SizedBox(height: 16.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                margin: EdgeInsets.symmetric(horizontal: 20.w),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Map tiles not loading?',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Use WebView (🌐) or Manual Entry (📝) buttons above',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Info Bar
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF667EEA),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Search for location or tap on the map to select',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildManualEntryView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Map not loading? Use manual entry as backup',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Address Field
          Text(
            'Address',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: 'Enter street address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _selectedAddress = value;
              });
            },
          ),

          SizedBox(height: 20.h),

          // Coordinates Row
          Row(
            children: [
              // Latitude
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _latController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '10.850515',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        final lat = double.tryParse(value);
                        if (lat != null && lat >= -90 && lat <= 90) {
                          setState(() {
                            _selectedLocation = LatLng(
                              lat,
                              _selectedLocation.longitude,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              // Longitude
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Longitude',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _lngController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '76.271080',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        final lng = double.tryParse(value);
                        if (lng != null && lng >= -180 && lng <= 180) {
                          setState(() {
                            _selectedLocation = LatLng(
                              _selectedLocation.latitude,
                              lng,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Helper Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: Icon(Icons.my_location),
                  label: Text('Use Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (_addressController.text.isNotEmpty) {
                      _searchLocation(_addressController.text);
                    }
                  },
                  icon: Icon(Icons.search),
                  label: Text('Search Address'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Current Values Display
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Selection:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Address: ${_selectedAddress.isNotEmpty ? _selectedAddress : 'Not set'}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF718096),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF718096),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),

          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_selectedAddress.isNotEmpty || _useManualEntry)
              ? _confirmLocation
              : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: Colors.white, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    _mapInitTimer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }
}
