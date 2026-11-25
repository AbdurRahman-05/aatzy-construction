import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider_dashboard.dart';
import 'provider_projects_screen.dart';
import 'provider_leads_screen.dart';
import '../chat/chat_list_screen.dart';
import '../home/profile_screen.dart';
import '../../core/wallpaper_background.dart';
import '../../core/services/subscription_service.dart';
import '../subscription/widgets/provider_subscription_modal.dart';
import '../auth/auth_provider.dart';
import '../../core/services/ad_popup_service.dart';
import '../../core/providers/provider_data_provider.dart';
import '../../core/widgets/bento.dart';

class ProviderTabNotifier extends Notifier<int> {
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

  void setTab(int idx) {
    if (state == idx && idx == 2) {
      ref.read(providerLeadsRefreshTriggerProvider.notifier).trigger();
    }
    state = idx;
  }

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

final providerTabProvider = NotifierProvider<ProviderTabNotifier, int>(ProviderTabNotifier.new);

class ProviderLayout extends ConsumerStatefulWidget {
  const ProviderLayout({super.key});

  @override
  ConsumerState<ProviderLayout> createState() => _ProviderLayoutState();
}

class _ProviderLayoutState extends ConsumerState<ProviderLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.id != null) {
        ref.read(subscriptionProvider.notifier).fetchStatus(auth.id!);
      }
      if (mounted) {
        AdPopupService.checkAndShowAd(context, role: 'PROVIDER');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(providerTabProvider);

    final screens = const [
      ProviderDashboard(),
      ProviderProjectsScreen(),
      ProviderLeadsScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(providerTabProvider.notifier).handleBack();
      },
      child: WallpaperBackground(
        child: ProviderSubscriptionPaywallOverlay(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(
              index: currentIndex,
              children: screens,
            ),
            bottomNavigationBar: BentoNavBar(
              currentIndex: currentIndex,
              onTap: (i) => ref.read(providerTabProvider.notifier).setTab(i),
              items: const [
                BentoNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
                BentoNavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, label: 'Projects'),
                BentoNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Leads'),
                BentoNavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat'),
                BentoNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
