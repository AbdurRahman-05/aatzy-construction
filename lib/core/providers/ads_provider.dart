import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

final adsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return fetchAds();
});

Future<List<Map<String, dynamic>>> fetchAds() async {
  try {
    final response = await http.get(Uri.parse('$apiBaseUrl/ads')).timeout(const Duration(seconds: 4));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> fetched = data['ads'] ?? [];
      if (fetched.isNotEmpty) {
        return fetched.map((ad) {
          return {
            'title': ad['title'] ?? '',
            'desc': ad['desc'] ?? '',
            'badge': ad['badge'] ?? '',
            'icon': parseAdIcon(ad['icon'] ?? ''),
            'gradient': parseAdGradient(ad['gradient'] ?? ''),
          };
        }).toList();
      }
    }
  } catch (e) {
    debugPrint('AdsProvider fetch error: $e');
  }
  return defaultPromoAds;
}

const List<Map<String, dynamic>> defaultPromoAds = [
  {
    'title': 'Explore Verified Quotes',
    'desc': 'Publish your project requirement and get transparent competitive contractor bids.',
    'icon': Icons.verified_rounded,
    'gradient': [Color(0xFF0F9B8E), Color(0xFF0E5E6F)],
    'badge': 'GET STARTED',
  },
  {
    'title': 'Premium Construction Ads',
    'desc': 'Looking to scale? Post custom ads inside your Buildzy administrator dashboard.',
    'icon': Icons.campaign_rounded,
    'gradient': [Color(0xFF064354), Color(0xFF0B7C8E)],
    'badge': 'SPONSORED',
  }
];

IconData parseAdIcon(String name) {
  switch (name) {
    case 'verified_user_rounded': return Icons.verified_user_rounded;
    case 'security_rounded': return Icons.security_rounded;
    case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
    case 'compare_arrows_rounded': return Icons.compare_arrows_rounded;
    case 'calculate_rounded': return Icons.calculate_rounded;
    case 'photo_library_rounded': return Icons.photo_library_rounded;
    case 'storefront_rounded': return Icons.storefront_rounded;
    case 'flash_on_rounded': return Icons.flash_on_rounded;
    case 'construction_rounded': return Icons.construction_rounded;
    case 'home_rounded': return Icons.home_rounded;
    default: return Icons.star_rounded;
  }
}

List<Color> parseAdGradient(String str) {
  if (str.isEmpty) return const [Color(0xFF064354), Color(0xFF0B7C8E)];
  final parts = str.split(',');
  if (parts.length >= 2) {
    try {
      final c1 = Color(int.parse(parts[0].trim().replaceFirst('#', '0xFF')));
      final c2 = Color(int.parse(parts[1].trim().replaceFirst('#', '0xFF')));
      return [c1, c2];
    } catch (_) {}
  }
  return const [Color(0xFF064354), Color(0xFF0B7C8E)];
}
