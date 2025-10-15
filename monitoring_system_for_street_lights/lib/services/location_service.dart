import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print(
          'Location services are disabled. Please enable location services.',
        );
        // Try to open location settings
        await Geolocator.openLocationSettings();
        return null;
      }

      // Check location permissions using permission_handler for better control
      PermissionStatus status = await Permission.location.status;

      if (status.isDenied) {
        // Request permission
        status = await Permission.location.request();
      }

      if (status.isDenied) {
        print('Location permissions are denied');
        return null;
      }

      if (status.isPermanentlyDenied) {
        print(
          'Location permissions are permanently denied. Please enable in settings.',
        );
        // Open app settings
        await openAppSettings();
        return null;
      }

      // Get current position with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15), // Increased timeout
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Convert coordinates to address
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String address = '';

        // Start with district (subAdministrativeArea) - this is the main city/district
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          address = place.subAdministrativeArea!;
        }
        // If no district, use locality
        else if (place.locality != null && place.locality!.isNotEmpty) {
          address = place.locality!;
        }
        // Fallback to subLocality
        else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address = place.subLocality!;
        }

        // Add state (administrativeArea)
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) {
            address += ', ${place.administrativeArea!}';
          } else {
            address = place.administrativeArea!;
          }
        }

        return address.isEmpty ? 'Unknown Location' : address;
      }

      return 'Address not found';
    } catch (e) {
      print('Error getting address: $e');
      return 'Error getting address';
    }
  }

  // Convert address to coordinates
  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        return {
          'latitude': locations[0].latitude,
          'longitude': locations[0].longitude,
        };
      }

      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final status = await Permission.location.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }
}
