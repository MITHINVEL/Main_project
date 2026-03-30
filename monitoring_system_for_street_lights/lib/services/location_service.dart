import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

      // Check location permissions using Geolocator
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        print(
          'Location permissions are permanently denied. Please enable in settings.',
        );
        // Open app settings
        await Geolocator.openAppSettings();
        return null;
      }

      // Try last known position first (instant, no GPS needed)
      Position? lastKnown = await Geolocator.getLastKnownPosition();

      // Try high accuracy with short timeout
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (_) {
        // High accuracy timed out, try lower accuracy
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (_) {
          // Both failed, return last known position if available
          if (lastKnown != null) {
            print('Using last known position');
            return lastKnown;
          }
          return null;
        }
      }
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
      final permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }
}
