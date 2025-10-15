import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';

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
  LatLng _selectedLocation = const LatLng(13.0827, 80.2707); // Chennai default
  String _selectedAddress = '';
  bool _isLoading = false;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
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
          'Select Location',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        actions: [
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
          SizedBox(width: 16.w),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15.0,
            ),
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Address Info Card
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Container(
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
          ),

          // Confirm Button
          Positioned(
            bottom: 24.h,
            left: 16.w,
            right: 16.w,
            child: Container(
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
                  onTap: _selectedAddress.isNotEmpty ? _confirmLocation : null,
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
