import 'dart:async';
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

    // Fast path: a previous OS-level fix returns instantly (no GPS wait).
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) _cached = last;
    } catch (_) {}

    // Try for a fresh fix, but don't block forever. On timeout, keep whatever
    // last-known position we already have (may be null).
    try {
      _cached = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } on TimeoutException {
      debugPrint('LocationService: fresh fix timed out — using last known');
    } catch (e) {
      debugPrint('LocationService.getLocation error: $e');
    }
    return _cached;
  }

  static void clearCache() => _cached = null;
}
