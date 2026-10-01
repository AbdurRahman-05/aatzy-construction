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

  /// Major cities in Tamil Nadu for quick selection
  static const List<String> majorCities = [
    'Madurai',
    'Dindigul',
    'Chennai',
    'Coimbatore',
    'Tiruchirappalli',
    'Salem',
    'Tirunelveli',
    'Theni',
    'Erode',
    'Tiruppur',
    'Thanjavur',
    'Vellore',
    'Virudhunagar',
    'Sivaganga',
    'Ramanathapuram',
    'Kanyakumari',
  ];

  /// Comprehensive mapping of Tamil Nadu cities and their constituent areas/localities
  static const Map<String, List<String>> cityAreas = {
    'Madurai': [
      'madurai', 'mattuthavani', 'matuthavani', 'anna nagar', 'simmakkal', 'goripalayam',
      'koodal nagar', 'sellur', 'villapuram', 'thirunagar', 'tirunagar', 'othakadai',
      'otthakadai', 'avaniyapuram', 'thiruparankundram', 'teppakulam', 'arapalayam',
      'ss colony', 's.s. colony', 'ponmeni', 'kalavasal', 'chinthamani', 'melur',
      'vadipatti', 'usilampatti', 'thirumangalam', 'sholavandan', 'alagar kovil',
      'tallakulam', 'narayanapuram', 'bibikulam', 'iyer bungalow', 'pasumalai'
    ],
    'Dindigul': [
      'dindigul', 'palani', 'kodaikanal', 'natham', 'oddanchatram', 'nilakottai',
      'vedasandur', 'chinnalapatti', 'batlagundu', 'begambur', 'guziliamparai',
      'semanampatti', 'sirumalai', 'reddiarchatram', 'ayyampalayam', 'dindugal'
    ],
    'Chennai': [
      'chennai', 'madras', 'adyar', 'velachery', 'guindy', 'tambaram', 'chromepet',
      'mylapore', 'porur', 'vadapalani', 'sholinganallur', 'thiruvanmiyur', 'omr', 'ecr',
      'perambur', 'ambattur', 'avadi', 'royapettah', 'triplicane', 'egmore', 'nungambakkam',
      'alwarpet', 'saidapet', 'kilpauk', 'kodambakkam', 'medavakkam', 'royapuram',
      't nagar', 't. nagar', 'besant nagar', 'pallavaram', 'kolathur', 'madipakkam',
      'perungudi', 'thuraipakkam', 'navalur', 'siruseri'
    ],
    'Coimbatore': [
      'coimbatore', 'kovai', 'gandhipuram', 'rs puram', 'r.s. puram', 'peelamedu',
      'saravanampatti', 'saibaba colony', 'singanallur', 'pollachi', 'mettupalayam',
      'sulur', 'kuniyamuthur', 'thudiyalur', 'kovaipudur', 'race course', 'ganapathy',
      'ondipudur', 'kinathukadavu'
    ],
    'Tiruchirappalli': [
      'tiruchirappalli', 'tiruchirapalli', 'trichy', 'thillai nagar', 'srirangam',
      'ponmalai', 'golden rock', 'k k nagar', 'kk nagar', 'tiruverumbur', 'bhel',
      'manapparai', 'lalgudi', 'woraiyur', 'cantonment'
    ],
    'Salem': [
      'salem', 'attur', 'mettur', 'yercaud', 'omalur', 'sankari', 'hasthampatti',
      'shevapet', 'suramangalam', 'ammapet', 'edappadi'
    ],
    'Tirunelveli': [
      'tirunelveli', 'nellai', 'palayamkottai', 'tenkasi', 'ambasamudram',
      'sankarankovil', 'vallioor', 'vannarpettai', 'thachanallur'
    ],
    'Erode': [
      'erode', 'bhavani', 'perundurai', 'gobichettipalayam', 'sathyamangalam',
      'anthiyur', 'chithode', 'thindal'
    ],
    'Tiruppur': [
      'tiruppur', 'tirupur', 'avinashi', 'palladam', 'dharapuram', 'kangeyam',
      'udumalaipettai', 'udumalpet'
    ],
    'Vellore': [
      'vellore', 'katpadi', 'gudiyatham', 'arcot', 'ranipet', 'walajapet',
      'tirupattur', 'ambur', 'vaniyambadi'
    ],
    'Thanjavur': [
      'thanjavur', 'tanjore', 'kumbakonam', 'papanasam', 'pattukkottai', 'orathanadu'
    ],
    'Theni': [
      'theni', 'periyakulam', 'bodinayakanur', 'bodi', 'cumbum', 'uthamapalayam',
      'andipatti', 'chinnamanur'
    ],
    'Virudhunagar': [
      'virudhunagar', 'sivakasi', 'rajapalayam', 'srivilliputhur', 'aruppukkottai',
      'sattur', 'kariyapatti'
    ],
    'Sivaganga': [
      'sivaganga', 'karaikudi', 'devakottai', 'manamadurai', 'thiruppuvanam', 'singampunari'
    ],
    'Ramanathapuram': [
      'ramanathapuram', 'ramnad', 'rameswaram', 'paramakudi', 'kilakarai', 'mudukulathur'
    ],
    'Kanyakumari': [
      'kanyakumari', 'nagercoil', 'thuckalay', 'marthandam', 'colachel', 'kuzhithurai'
    ],
    'Namakkal': ['namakkal', 'tiruchengode', 'rasipuram', 'paramathi velur'],
    'Karur': ['karur', 'kulithalai', 'aravakkurichi', 'velur'],
    'Cuddalore': ['cuddalore', 'chidambaram', 'panruti', 'vriddhachalam', 'neveli', 'neyveli'],
    'Villupuram': ['villupuram', 'tindivanam', 'gingee', 'kallakurichi'],
    'Kanchipuram': ['kanchipuram', 'kancheepuram', 'sriperumbudur', 'chengalpattu', 'walajabad'],
    'Tiruvallur': ['tiruvallur', 'thiruvallur', 'ponneri', 'gummidipoondi', 'tiruttani'],
    'Tiruvannamalai': ['tiruvannamalai', 'arani', 'polur', 'chengampattu', 'vandavasi'],
    'Pudukkottai': ['pudukkottai', 'aranthangi', 'viralimalai'],
    'Krishnagiri': ['krishnagiri', 'hosur', 'denkanikottai'],
    'Dharmapuri': ['dharmapuri', 'harur', 'palacode'],
    'Nilgiris': ['nilgiris', 'ooty', 'udhagamandalam', 'coonoor', 'kotagiri', 'gudalur'],
    'Bengaluru': ['bengaluru', 'bangalore', 'whitefield', 'koramangala', 'indiranagar', 'electronic city', 'hsr layout']
  };

  /// Extracts the canonical city name from any text or area name
  static String? extractCityName(String? text) {
    if (text == null) return null;
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[\.,\-\/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;

    // 1. Direct match with city keys
    for (final city in cityAreas.keys) {
      final reg = RegExp('\\b${city.toLowerCase()}\\b');
      if (reg.hasMatch(cleaned)) {
        return city;
      }
    }

    // 2. Check area names
    for (final entry in cityAreas.entries) {
      for (final area in entry.value) {
        final reg = RegExp('\\b${area.toLowerCase()}\\b');
        if (reg.hasMatch(cleaned)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// Converts any location or area text strictly into "City, State" format
  /// e.g. "Mattuthavani" -> "Madurai, Tamil Nadu"
  /// e.g. "Palani" -> "Dindigul, Tamil Nadu"
  /// e.g. "Madurai" -> "Madurai, Tamil Nadu"
  static String resolveToCityState(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Madurai, Tamil Nadu';
    }
    final trimmed = input.trim();
    final city = extractCityName(trimmed);
    if (city != null) {
      final state = city == 'Bengaluru' ? 'Karnataka' : 'Tamil Nadu';
      return '$city, $state';
    }

    // If no city matched from dictionary, ensure State is appended if not present
    if (!trimmed.toLowerCase().contains('tamil nadu') && !trimmed.toLowerCase().contains('karnataka')) {
      return '$trimmed, Tamil Nadu';
    }
    return trimmed;
  }

  /// Detect live device location via GPS, resolve strictly to City & State, and cache locally.
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

      // 4. Reverse geocode to City & State (Strict City Resolution)
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final subAdmin = place.subAdministrativeArea ?? '';
        final locality = place.locality ?? '';
        final subLocality = place.subLocality ?? '';
        final rawState = place.administrativeArea?.isNotEmpty == true ? place.administrativeArea! : 'Tamil Nadu';

        // 1. Try to resolve city from subAdministrativeArea (District in India: Madurai, Dindigul, Chennai)
        String? resolvedCity = extractCityName(subAdmin);

        // 2. If not found, check locality (might be city or recognized area)
        resolvedCity ??= extractCityName(locality);

        // 3. If not found, check subLocality
        resolvedCity ??= extractCityName(subLocality);

        // 4. Fallback if geocoding returns an unmapped name
        if (resolvedCity == null) {
          final candidate = subAdmin.isNotEmpty ? subAdmin : (locality.isNotEmpty ? locality : 'Madurai');
          resolvedCity = candidate;
        }

        final state = resolvedCity == 'Bengaluru' ? 'Karnataka' : rawState;
        final formattedLocation = '$resolvedCity, $state';
        _cachedCity = resolvedCity;
        _cachedLocation = formattedLocation;

        await prefs.setString(_kCityKey, resolvedCity);
        await prefs.setString(_kLocationKey, formattedLocation);

        debugPrint('[LocationService] Live city resolved: $formattedLocation (from subAdmin: "$subAdmin", locality: "$locality", subLocality: "$subLocality")');
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
    return 'Madurai, Tamil Nadu';
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
    return 'Madurai';
  }
}
