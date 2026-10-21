import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../engine/panchang/panchang_models.dart';

enum LocationPermissionState {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

class LocationFetchResult {
  final bool success;
  final GeoLocation? location;
  final String? errorMessage;
  final LocationPermissionState state;

  const LocationFetchResult({
    required this.success,
    this.location,
    this.errorMessage,
    required this.state,
  });

  factory LocationFetchResult.success(GeoLocation loc) => LocationFetchResult(
        success: true,
        location: loc,
        state: LocationPermissionState.granted,
      );

  factory LocationFetchResult.failure(LocationPermissionState state, String message) =>
      LocationFetchResult(
        success: false,
        errorMessage: message,
        state: state,
      );
}

/// Device location service handling permissions and GPS coordinate retrieval
/// for offline-first astronomical Panchang calculations.
class DeviceLocationService {
  static final DeviceLocationService _instance = DeviceLocationService._internal();
  factory DeviceLocationService() => _instance;
  DeviceLocationService._internal();

  /// Requests location permission if needed and retrieves the current device coordinates.
  Future<LocationFetchResult> fetchCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationFetchResult.failure(
          LocationPermissionState.serviceDisabled,
          'Location services are disabled on your device. Please enable GPS in device settings.',
        );
      }

      // 2. Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationFetchResult.failure(
            LocationPermissionState.denied,
            'Location permission was denied. You can still enter custom coordinates or choose a city manually.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationFetchResult.failure(
          LocationPermissionState.deniedForever,
          'Location permissions are permanently denied. Please enable them in app settings, or enter coordinates manually.',
        );
      }

      // 3. Retrieve current GPS position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes / 60.0;
      final geoLocation = GeoLocation.custom(
        latitude: position.latitude,
        longitude: position.longitude,
        name: 'Device Location (GPS)',
        stateOrCountry: 'Detected via GPS',
        timezoneOffsetHours: timezoneOffset,
        elevationMeters: position.altitude,
      );

      return LocationFetchResult.success(geoLocation);
    } catch (e) {
      debugPrint('Error fetching device location: $e');
      return LocationFetchResult.failure(
        LocationPermissionState.error,
        'Could not acquire GPS fix: ${e.toString()}',
      );
    }
  }

  /// Checks if location permission is already granted.
  Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }
}
