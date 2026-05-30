import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _cached;

  static Position? get cached => _cached;

  /// Requests permission then returns the device GPS position.
  /// Returns null if permission is denied or location unavailable.
  static Future<Position?> getLocation() async {
    if (_cached != null) return _cached;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: GPS service disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: permission denied');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: permission permanently denied');
      return null;
    }

    try {
      _cached = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _cached;
    } catch (e) {
      debugPrint('LocationService.getLocation error: $e');
      return null;
    }
  }

  static void clearCache() => _cached = null;
}
