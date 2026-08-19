import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

final socialFeedProvider = FutureProvider<List<dynamic>>((ref) async {
  return fetchSocialFeed();
});

Future<List<dynamic>> fetchSocialFeed() async {
  try {
    final response = await http.get(Uri.parse('$apiBaseUrl/social/feed')).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['images'] ?? [];
    }
  } catch (e) {
    debugPrint('fetchSocialFeed error: $e');
  }
  return [];
}
