import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider_dashboard.dart';
import 'provider_projects_screen.dart';
import 'provider_leads_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/profile_screen.dart';
import '../../core/wallpaper_background.dart';

class ProviderTabNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setTab(int idx) {
    state = idx;
  }
}

final providerTabProvider = NotifierProvider<ProviderTabNotifier, int>(ProviderTabNotifier.new);

class ProviderLayout extends ConsumerWidget {
  const ProviderLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(providerTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = const [
      ProviderDashboard(),
      ProviderProjectsScreen(),
      ProviderLeadsScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Center(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      height: 68,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.42)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.13)
                              : Colors.white.withValues(alpha: 0.82),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.55),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(
                                context,
                                ref,
                                index: 0,
                                icon: Icons.dashboard_outlined,
                                activeIcon: Icons.dashboard_rounded,
                                label: 'Home',
                                currentIndex: currentIndex,
                                isDark: isDark,
                                isNarrow: isNarrow,
                              ),
                              _buildNavItem(
                                context,
                                ref,
                                index: 1,
                                icon: Icons.apartment_outlined,
                                activeIcon: Icons.apartment_rounded,
                                label: 'Projects',
                                currentIndex: currentIndex,
                                isDark: isDark,
                                isNarrow: isNarrow,
                              ),
                              _buildNavItem(
                                context,
                                ref,
                                index: 2,
                                icon: Icons.people_outline_rounded,
                                activeIcon: Icons.people_rounded,
                                label: 'Leads',
                                currentIndex: currentIndex,
                                isDark: isDark,
                                isNarrow: isNarrow,
                              ),
                              _buildNavItem(
                                context,
                                ref,
                                index: 3,
                                icon: Icons.chat_bubble_outline_rounded,
                                activeIcon: Icons.chat_bubble_rounded,
                                label: 'Chat',
                                currentIndex: currentIndex,
                                isDark: isDark,
                                isNarrow: isNarrow,
                              ),
                              _buildNavItem(
                                context,
                                ref,
                                index: 4,
                                icon: Icons.person_outline_rounded,
                                activeIcon: Icons.person_rounded,
                                label: 'Profile',
                                currentIndex: currentIndex,
                                isDark: isDark,
                                isNarrow: isNarrow,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
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
    required bool isDark,
    required bool isNarrow,
  }) {
    final isSelected = currentIndex == index;
    const activeColor = Color(0xFF0F766E);

    return GestureDetector(
      onTap: () => ref.read(providerTabProvider.notifier).setTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: isNarrow ? 20 : 22,
              color: isSelected
                  ? activeColor
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: isNarrow ? 10 : 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
