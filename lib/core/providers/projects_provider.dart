import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class UserProjectsData {
  final List<dynamic> projects;
  final List<dynamic> materialOrders;

  const UserProjectsData({
    this.projects = const [],
    this.materialOrders = const [],
  });
}

final userProjectsProvider = FutureProvider.family<UserProjectsData, String>((ref, userId) async {
  if (userId.isEmpty) return const UserProjectsData();
  return fetchUserProjects(userId);
});

Future<UserProjectsData> fetchUserProjects(String userId) async {
  try {
    final responses = await Future.wait([
      http.get(Uri.parse('$apiBaseUrl/users/$userId/projects')).timeout(const Duration(seconds: 12)),
      http.get(Uri.parse('$apiBaseUrl/buyer/inquiries?buyerId=$userId')).timeout(const Duration(seconds: 12)),
    ]);

    List<dynamic> projects = [];
    List<dynamic> materialOrders = [];

    if (responses[0].statusCode == 200) {
      final decoded = jsonDecode(responses[0].body);
      if (decoded is List) {
        projects = decoded;
      } else if (decoded is Map && decoded['projects'] is List) {
        projects = decoded['projects'];
      }
    }

    if (responses[1].statusCode == 200) {
      final decoded = jsonDecode(responses[1].body);
      final List<dynamic> inquiries = decoded['inquiries'] ?? (decoded is List ? decoded : []);
      materialOrders = inquiries.where((i) {
        final status = i['status'];
        final deliveryStatus = i['delivery_status'];
        final isClosed = status == 'Completed' || (status == 'Closed' && deliveryStatus == 'Delivered');
        return !isClosed && (
          status == 'Closed' ||
          status == 'Accepted' ||
          status == 'New' ||
          status == 'Viewed' ||
          status == 'Contacted' ||
          status == 'Quote Sent'
        );
      }).toList();
    }

    return UserProjectsData(
      projects: projects,
      materialOrders: materialOrders,
    );
  } catch (e) {
    debugPrint('fetchUserProjects error: $e');
    return const UserProjectsData();
  }
}
