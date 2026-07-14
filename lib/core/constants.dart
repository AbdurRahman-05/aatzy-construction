import 'dart:typed_data';
import 'dart:convert';

String apiBaseUrl = "https://aatzy-construction.vercel.app/api";

class Base64ImageCache {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List decode(String base64Str) {
    if (base64Str.isEmpty) return Uint8List(0);
    final cleanStr = base64Str.trim().split(',').last;
    final cached = _cache[cleanStr];
    if (cached != null) return cached;
    
    try {
      final decoded = base64Decode(cleanStr);
      _cache[cleanStr] = decoded;
      return decoded;
    } catch (_) {
      return Uint8List(0);
    }
  }
}
