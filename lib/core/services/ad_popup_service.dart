import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../widgets/ad_poster_popup_dialog.dart';

class AdPopupService {
  static final Set<String> _shownAdIdsInSession = {};
  static bool _isChecking = false;

  /// Fetches active ads targeted to [role] ('CONSUMER' or 'PROVIDER')
  /// and shows the ad poster popup dialog with all matching active ads.
  static Future<void> checkAndShowAd(
    BuildContext context, {
    required String role,
    bool force = false,
  }) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final isProvider = role.toUpperCase().contains('PROVIDER');
      final targetParam = isProvider ? 'PROVIDER' : 'CLIENT';

      final response = await http
          .get(Uri.parse('$apiBaseUrl/ads?target=$targetParam&activeOnly=true'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawAds = data['ads'] ?? [];

        final List<Map<String, dynamic>> activeAds = [];
        for (final item in rawAds) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final isActive = map['isActive'] ?? true;
            if (isActive) {
              activeAds.add(map);
            }
          }
        }

        if (activeAds.isNotEmpty) {
          // Check if at least one ad in this batch has not been shown in the current session
          final hasUnshownAd = activeAds.any((ad) {
            final id = ad['id']?.toString() ?? '';
            return id.isNotEmpty && !_shownAdIdsInSession.contains(id);
          });

          if (force || hasUnshownAd) {
            // Mark all active ads as shown in this session so they aren't repeatedly spammed
            for (final ad in activeAds) {
              final id = ad['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                _shownAdIdsInSession.add(id);
              }
            }

            if (context.mounted) {
              await AdPosterPopupDialog.showList(context, activeAds);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AdPopupService] Check ad error: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Reset session cache so ads can be shown again on fresh login
  static void resetSession() {
    _shownAdIdsInSession.clear();
  }
}
