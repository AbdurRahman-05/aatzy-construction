import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved API URL override if available
  final prefs = await SharedPreferences.getInstance();
  final overrideUrl = prefs.getString('api_base_url_override');

  if (overrideUrl != null && overrideUrl.isNotEmpty) {
    apiBaseUrl = overrideUrl;
  } else {
    // Dynamically configure API URL based on physical vs emulator device
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.isPhysicalDevice) {
        // Physical phone uses USB ADB reverse mapping to 127.0.0.1
        apiBaseUrl = "http://127.0.0.1:3000/api";
      } else {
        // Emulator uses the standard Android virtual router loopback mapping (10.0.2.2)
        apiBaseUrl = "http://10.0.2.2:3000/api";
      }
    } else {
      // Fallback for iOS, Web, and Desktop
      apiBaseUrl = "http://127.0.0.1:3000/api";
    }
  }

  runApp(const ProviderScope(child: ConstructionApp()));
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
