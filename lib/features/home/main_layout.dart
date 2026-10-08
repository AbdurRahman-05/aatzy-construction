import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../../services/services_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';
import '../project/projects_list_screen.dart';
import '../../core/wallpaper_background.dart';
import '../../core/services/ad_popup_service.dart';

class MainTabNotifier extends Notifier<int> {
  final List<int> _history = [0];

  @override
  int build() {
    _history.clear();
    _history.add(0);
    return 0;
  }

  @override
  set state(int value) {
    if (super.state != value) {
      if (value == 0) {
        _history.clear();
        _history.add(0);
      } else {
        _history.remove(value);
        _history.add(value);
      }
      super.state = value;
    }
  }

  void setTab(int index) => state = index;

  bool handleBack() {
    if (_history.length > 1) {
      _history.removeLast();
      super.state = _history.last;
      return true;
    } else if (super.state != 0) {
      super.state = 0;
      _history.clear();
      _history.add(0);
      return true;
    }
    return false;
  }
}

final mainTabProvider = NotifierProvider<MainTabNotifier, int>(MainTabNotifier.new);

// Vivid blue accent — clearly visible on any background
const _kNavAccent = Color(0xFF1F6FEB);

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  static const screens = [
    HomeScreen(),
    ProjectsListScreen(),
    ServicesScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AdPopupService.checkAndShowAd(context, role: 'CONSUMER');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(mainTabProvider.notifier).handleBack();
      },
      child: WallpaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(isTablet ? 32 : 16, 0, isTablet ? 32 : 16, 12),
            child: Center(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 720 : 560),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      height: 68,
                      decoration: BoxDecoration(
                        // Frosted glass fill
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.42)
                            : Colors.white.withValues(alpha: 0.52),
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
                              _buildNavItem(context, ref,
                                  index: 0,
                                  icon: Icons.grid_view_rounded,
                                  activeIcon: Icons.grid_view_rounded,
                                  label: 'Home',
                                  currentIndex: currentIndex,
                                  isDark: isDark,
                                  isNarrow: isNarrow),
                              _buildNavItem(context, ref,
                                  index: 1,
                                  icon: Icons.apartment_outlined,
                                  activeIcon: Icons.apartment_rounded,
                                  label: 'Projects',
                                  currentIndex: currentIndex,
                                  isDark: isDark,
                                  isNarrow: isNarrow),
                              _buildNavItem(context, ref,
                                  index: 2,
                                  icon: Icons.storefront_outlined,
                                  activeIcon: Icons.storefront_rounded,
                                  label: 'Market',
                                  currentIndex: currentIndex,
                                  isDark: isDark,
                                  isNarrow: isNarrow),
                              _buildNavItem(context, ref,
                                  index: 3,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  activeIcon: Icons.chat_bubble_rounded,
                                  label: 'Chat',
                                  currentIndex: currentIndex,
                                  isDark: isDark,
                                  isNarrow: isNarrow),
                              _buildNavItem(context, ref,
                                  index: 4,
                                  icon: Icons.person_outline_rounded,
                                  activeIcon: Icons.person_rounded,
                                  label: 'Profile',
                                  currentIndex: currentIndex,
                                  isDark: isDark,
                                  isNarrow: isNarrow),
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
    bool isNarrow = false,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => ref.read(mainTabProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 14, vertical: 8),
        decoration: BoxDecoration(
          // Glowing glass pill for active tab
          color: isSelected
              ? _kNavAccent.withValues(alpha: isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(
                  color: _kNavAccent.withValues(alpha: isDark ? 0.38 : 0.22),
                  width: 1.0,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kNavAccent.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                size: isNarrow ? 20 : 22,
                color: isSelected
                    ? _kNavAccent
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF8C8C8C)),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isNarrow ? 10 : 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? _kNavAccent
                    : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF8C8C8C)),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
