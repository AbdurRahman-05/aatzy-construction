import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../../services/services_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';
import '../project/projects_list_screen.dart';
import '../../core/wallpaper_background.dart';

class MainTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final mainTabProvider = NotifierProvider<MainTabNotifier, int>(MainTabNotifier.new);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  final screens = const [
    HomeScreen(),
    ProjectsListScreen(),
    ServicesScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabProvider);

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (idx) => ref.read(mainTabProvider.notifier).state = idx,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.business), label: 'Projects'),
            NavigationDestination(icon: Icon(Icons.grid_view), label: 'Services'),
            NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
