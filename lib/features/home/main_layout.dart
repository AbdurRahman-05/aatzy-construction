import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../../services/services_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';
import '../project/projects_list_screen.dart';
import '../../core/wallpaper_background.dart';
import '../../core/theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2730) : Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8E8E5),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, ref, index: 0, icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home', currentIndex: currentIndex),
                _buildNavItem(context, ref, index: 1, icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, label: 'Projects', currentIndex: currentIndex),
                _buildNavItem(context, ref, index: 2, icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Market', currentIndex: currentIndex),
                _buildNavItem(context, ref, index: 3, icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat', currentIndex: currentIndex),
                _buildNavItem(context, ref, index: 4, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', currentIndex: currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ref.read(mainTabProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected
                  ? AppTheme.primaryOrange
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373)),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryOrange
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
