import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved configurations from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final overrideUrl = prefs.getString('api_base_url_override');

  if (overrideUrl != null && overrideUrl.isNotEmpty) {
    String sanitized = overrideUrl.trim();
    while (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    apiBaseUrl = sanitized;
  } else {
    apiBaseUrl = "https://aatzy-construction.vercel.app/api";
  }

  // Fetch Google Client ID from backend
  String webClientId = prefs.getString('google_client_id_override') ?? '';
  try {
    final response = await http.get(Uri.parse('$apiBaseUrl/users/google-client-id'))
        .timeout(const Duration(seconds: 2));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fetchedId = data['clientId'] as String? ?? '';
      if (fetchedId.isNotEmpty) {
        webClientId = fetchedId;
        await prefs.setString('google_client_id_override', fetchedId);
      }
    }
  } catch (e) {
    debugPrint('Failed to fetch Google Client ID from backend: $e');
  }

  // Initialize Google Sign-In singleton once at startup
  try {
    if (kIsWeb) {
      if (webClientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(clientId: webClientId);
      } else {
        debugPrint('Google Sign-In Web: No Client ID configured yet.');
      }
    } else {
      if (webClientId.isNotEmpty) {
        await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      } else {
        await GoogleSignIn.instance.initialize();
      }
    }
  } catch (e) {
    debugPrint('Failed to initialize Google Sign-In: $e');
  }

  runApp(const ProviderScope(child: ConstructionApp()));
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

class ConstructionApp extends ConsumerWidget {
  const ConstructionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Construction Platform',
      scrollBehavior: const SmoothScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          color: isDark ? const Color(0xFF121B22) : Colors.grey.shade100,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SmoothScrollBehavior extends MaterialScrollBehavior {
  const SmoothScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
      default:
        return const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    }
  }
}
