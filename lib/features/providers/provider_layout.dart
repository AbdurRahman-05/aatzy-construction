import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider_dashboard.dart';
import 'provider_projects_screen.dart';
import 'provider_leads_screen.dart';
import '../home/profile_screen.dart';
import '../../core/wallpaper_background.dart';

final providerTabProvider = StateProvider<int>((ref) => 0);

class ProviderLayout extends ConsumerWidget {
  const ProviderLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(providerTabProvider);

    final screens = [
      const ProviderDashboard(),
      const ProviderProjectsScreen(),
      const ProviderLeadsScreen(),
      const ProfileScreen(),
    ];

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: screens[currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (idx) => ref.read(providerTabProvider.notifier).state = idx,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.business_center), label: 'Projects'),
            NavigationDestination(icon: Icon(Icons.list_alt), label: 'Leads'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
