import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _kCityKey = 'user_detected_city';
  static const String _kLocationKey = 'user_detected_location';
  static const String _kLatKey = 'user_latitude';
  static const String _kLngKey = 'user_longitude';

  String? _cachedLocation;
  String? _cachedCity;

  /// Detect live device location via GPS, reverse geocode to city and state, and cache locally.
  Future<String?> detectAndSaveLocation({bool forceRefresh = false}) async {
    try {
      if (kIsWeb) {
        return await getSavedLocation();
      }

      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services disabled on device.');
        return await getSavedLocation();
      }

      // 2. Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permissions denied by user.');
          return await getSavedLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions permanently denied.');
        return await getSavedLocation();
      }

      // 3. Acquire live GPS coordinates with 8s timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLatKey, position.latitude);
      await prefs.setDouble(_kLngKey, position.longitude);

      // 4. Reverse geocode to City & State
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = (place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea) ?? 'Chennai';
        final state = place.administrativeArea ?? 'Tamil Nadu';

        final formattedLocation = '$city, $state';
        _cachedCity = city;
        _cachedLocation = formattedLocation;

        await prefs.setString(_kCityKey, city);
        await prefs.setString(_kLocationKey, formattedLocation);

        debugPrint('[LocationService] Live location detected: $formattedLocation (lat: ${position.latitude}, lng: ${position.longitude})');
        return formattedLocation;
      }
    } catch (e) {
      debugPrint('[LocationService] Error detecting location: $e');
    }

    return await getSavedLocation();
  }

  /// Get saved location or return default
  Future<String> getSavedLocation() async {
    if (_cachedLocation != null && _cachedLocation!.isNotEmpty) {
      return _cachedLocation!;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocationKey);
    if (saved != null && saved.isNotEmpty) {
      _cachedLocation = saved;
      return saved;
    }
    return 'Chennai, Tamil Nadu';
  }

  /// Get saved city or return default
  Future<String> getSavedCity() async {
    if (_cachedCity != null && _cachedCity!.isNotEmpty) {
      return _cachedCity!;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kCityKey);
    if (saved != null && saved.isNotEmpty) {
      _cachedCity = saved;
      return saved;
    }
    return 'Chennai';
  }
}
