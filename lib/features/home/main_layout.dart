import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import '../../services/services_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';
import '../project/projects_list_screen.dart';
import '../../core/wallpaper_background.dart';
import '../../core/services/ad_popup_service.dart';
import '../../core/widgets/bento.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'welcome_intent_sheet.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _showEntryPopups());
  }

  /// On every app open: the "What are you planning?" page first. If the
  /// customer stays on Home ("Just exploring" / close), the admin ad popup
  /// follows; if they pick a goal, we take them there without an ad.
  Future<void> _showEntryPopups() async {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    final intent = await WelcomeIntentSheet.maybeShow(
      context,
      userId: auth.id,
      userName: auth.name,
    );
    if (!mounted) return;

    if (intent == null || intent == UserIntent.exploring) {
      AdPopupService.checkAndShowAd(context, role: 'CONSUMER');
      return;
    }
    _openIntent(intent);
  }

  void _openIntent(UserIntent intent) {
    String createProject(String type, String service) =>
        '/create-project?type=${Uri.encodeQueryComponent(type)}&service=${Uri.encodeQueryComponent(service)}';

    switch (intent) {
      case UserIntent.buildHouse:
        context.push(createProject('Residential Villa', 'Construction'));
      case UserIntent.renovate:
        context.push(createProject('Renovation & Remodel', 'Renovations/Remodeling'));
      case UserIntent.interiors:
        context.push(createProject('Residential Villa', 'Interiors & Finishing'));
      case UserIntent.buyMaterials:
        context.push('/b2b-materials');
      case UserIntent.exploring:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabProvider);

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
          bottomNavigationBar: BentoNavBar(
            currentIndex: currentIndex,
            onTap: (i) => ref.read(mainTabProvider.notifier).setTab(i),
            items: const [
              BentoNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'Home'),
              BentoNavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, label: 'Projects'),
              BentoNavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Market'),
              BentoNavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat'),
              BentoNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
