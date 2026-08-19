import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ProviderDashboardData {
  final Map<String, dynamic> stats;
  final List<dynamic> activeJobs;
  final List<dynamic> supplierLeads;
  final Map<String, dynamic> profile;

  const ProviderDashboardData({
    this.stats = const {},
    this.activeJobs = const [],
    this.supplierLeads = const [],
    this.profile = const {},
  });
}

final providerDashboardProvider = FutureProvider.family<ProviderDashboardData, String>((ref, providerId) async {
  if (providerId.isEmpty) return const ProviderDashboardData();
  return fetchProviderDashboard(providerId);
});

Future<ProviderDashboardData> fetchProviderDashboard(String providerId) async {
  try {
    final responses = await Future.wait([
      http.get(Uri.parse('$apiBaseUrl/providers/$providerId/stats')).timeout(const Duration(seconds: 4)),
      http.get(Uri.parse('$apiBaseUrl/providers/$providerId/projects')).timeout(const Duration(seconds: 4)),
      http.get(Uri.parse('$apiBaseUrl/supplier/leads?supplierId=$providerId')).timeout(const Duration(seconds: 4)),
      http.get(Uri.parse('$apiBaseUrl/providers/$providerId/profile')).timeout(const Duration(seconds: 4)),
    ]);

    Map<String, dynamic> stats = {};
    List<dynamic> activeJobs = [];
    List<dynamic> supplierLeads = [];
    Map<String, dynamic> profile = {};

    if (responses[0].statusCode == 200) {
      stats = jsonDecode(responses[0].body);
    }
    if (responses[1].statusCode == 200) {
      activeJobs = jsonDecode(responses[1].body);
    }
    if (responses[2].statusCode == 200) {
      final data = jsonDecode(responses[2].body);
      supplierLeads = data['leads'] ?? [];
    }
    if (responses[3].statusCode == 200) {
      profile = jsonDecode(responses[3].body);
    }

    return ProviderDashboardData(
      stats: stats,
      activeJobs: activeJobs,
      supplierLeads: supplierLeads,
      profile: profile,
    );
  } catch (e) {
    debugPrint('fetchProviderDashboard error: $e');
    return const ProviderDashboardData();
  }
}
