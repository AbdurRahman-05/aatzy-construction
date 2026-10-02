import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../widgets/ad_poster_popup_dialog.dart';

class AdPopupService {
  static final Set<String> _shownAdIdsInSession = {};
  static bool _isChecking = false;

  /// Fetches active ads targeted to [role] ('CONSUMER' or 'PROVIDER')
  /// and shows the ad poster popup dialog if an active ad is found.
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
        final List<dynamic> adsList = data['ads'] ?? [];

        if (adsList.isNotEmpty) {
          // Look for an ad with a poster image first, or the newest active ad
          final targetAd = adsList.firstWhere(
            (ad) =>
                (ad['isActive'] ?? true) &&
                ad['imageUrl'] != null &&
                ad['imageUrl'].toString().trim().isNotEmpty,
            orElse: () => adsList.firstWhere(
              (ad) => ad['isActive'] ?? true,
              orElse: () => null,
            ),
          );

          if (targetAd != null) {
            final adId = targetAd['id']?.toString() ?? '';

            if (force || !_shownAdIdsInSession.contains(adId)) {
              _shownAdIdsInSession.add(adId);

              if (context.mounted) {
                await AdPosterPopupDialog.show(context, Map<String, dynamic>.from(targetAd));
              }
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
