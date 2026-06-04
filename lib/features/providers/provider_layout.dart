import 'package:flutter/material.dart';
import 'provider_dashboard.dart';
import 'provider_projects_screen.dart';
import 'provider_leads_screen.dart';
import '../home/profile_screen.dart';
import '../../core/wallpaper_background.dart';

class ProviderLayout extends StatefulWidget {
  const ProviderLayout({super.key});

  @override
  State<ProviderLayout> createState() => _ProviderLayoutState();
}

class _ProviderLayoutState extends State<ProviderLayout> {
  int _currentIndex = 0;

  final screens = [
    const ProviderDashboard(),
    const ProviderProjectsScreen(),
    const ProviderLeadsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
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
