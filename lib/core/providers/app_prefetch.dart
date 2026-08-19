import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_provider.dart';
import 'ads_provider.dart';
import 'social_feed_provider.dart';
import 'projects_provider.dart';
import 'provider_data_provider.dart';

/// Pre-fetches all critical app data in parallel during the splash screen
Future<void> prefetchAppData(WidgetRef ref) async {
  try {
    // Warm up public feeds & ads immediately in RAM
    ref.read(adsProvider.future);
    ref.read(socialFeedProvider.future);

    final auth = ref.read(authProvider);
    if (auth.id != null) {
      if (auth.role == 'PROVIDER') {
        ref.read(providerDashboardProvider(auth.id!).future);
      } else {
        ref.read(userProjectsProvider(auth.id!).future);
      }
    }
  } catch (e) {
    debugPrint('App prefetch error: $e');
  }
}
