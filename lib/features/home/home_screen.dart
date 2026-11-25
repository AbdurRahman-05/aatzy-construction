import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/projects_provider.dart';
import '../../core/providers/social_feed_provider.dart';
import '../../core/providers/notifications_provider.dart';
import '../auth/auth_provider.dart';
import '../providers/provider_profile_screen.dart';
import 'main_layout.dart';
import 'widgets/user_tutorial_dialog.dart';
import '../../core/utils/project_progress_helper.dart';
import '../../core/constants.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/home_ad_slot.dart';

/// Customer home — "Bento" layout (charcoal + brand teal).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _projects = [];
  List<dynamic> _materialOrders = [];
  List<dynamic> _socialPosts = [];
  bool _isLoading = true;
  bool _isLoadingSocial = true;
  int _activeTabIndex = 0;

  static const _closedStages = ['completed', 'finished', 'cancelled'];

  static const List<Map<String, dynamic>> _expertCategories = [
    {
      'title': 'Architects',
      'subtitle': 'Floor plans, 3D elevations & Vastu',
      'icon': Icons.architecture_rounded,
      'color': Color(0xFF8B5CF6),
      'route': '/providers/Design%20%26%20Planning',
    },
    {
      'title': 'Builders',
      'subtitle': 'Turnkey & civil work',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF3B82F6),
      'route': '/providers/Builder%2FGeneral%20Contractor',
    },
    {
      'title': 'Promoters',
      'subtitle': 'Plots & layouts',
      'icon': Icons.real_estate_agent_rounded,
      'color': Color(0xFF10B981),
      'route': '/providers/Commercial%20Builder',
    },
    {
      'title': 'Interiors',
      'subtitle': 'Kitchens & decor',
      'icon': Icons.chair_rounded,
      'color': Color(0xFFE11D48),
      'route': '/providers/Interiors%20%26%20Finishing',
    },
    {
      'title': 'LED Walls',
      'subtitle': 'Digital displays',
      'icon': Icons.smart_display_rounded,
      'color': Color(0xFF06B6D4),
      'route': '/providers/LED%20Walls%20%26%20Digital%20Displays',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkShowTutorial();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProjects();
    });
  }

  void _checkShowTutorial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.role == 'CONSUMER' || auth.role == null) {
        UserTutorialDialog.show(context, userId: auth.id);
      }
    });
  }

  Future<void> _fetchProjects() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _isLoadingSocial = true;
      });
    }
    final auth = ref.read(authProvider);
    try {
      final futures = <Future<dynamic>>[];
      if (auth.id != null) {
        futures.add(ref.refresh(userProjectsProvider(auth.id!).future));
      }
      futures.add(ref.refresh(socialFeedProvider.future));
      ref.invalidate(homeAdsProvider('CLIENT'));
      await Future.wait(futures);
    } catch (e) {
      debugPrint('HomeScreen fetch error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingSocial = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Derived data
  // ---------------------------------------------------------------------------

  List<dynamic> get _activeProjects => _projects.where((p) {
        final stage = (p['currentStage'] as String? ?? '').toLowerCase().trim();
        return !_closedStages.contains(stage);
      }).toList();

  int _quoteCountOf(dynamic p) {
    final counted = p['_count']?['quotes'];
    if (counted is int) return counted;
    final list = p['quotes'];
    return list is List ? list.length : 0;
  }

  int get _totalQuotes => _projects.fold<int>(0, (sum, p) => sum + _quoteCountOf(p));

  String _formatBudget(dynamic budget) {
    final n = budget is num ? budget : num.tryParse(budget?.toString() ?? '');
    if (n == null || n <= 0) return '—';
    return '₹${NumberFormat.decimalPattern('en_IN').format(n.round())}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 22) return 'Good evening';
    return 'Good night';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return '☀️';
    if (h >= 12 && h < 17) return '🌤️';
    if (h >= 17 && h < 22) return '🌆';
    return '🌙';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.id != next.id && next.id != null) {
        _fetchProjects();
      }
    });

    final auth = ref.watch(authProvider);
    if (!auth.isInitialized) {
      _isLoading = true;
    } else if (auth.id != null) {
      final projectsAsync = ref.watch(userProjectsProvider(auth.id!));
      final projData = projectsAsync.asData?.value ?? projectsAsync.value;
      if (projData != null) {
        _projects = projData.projects;
        _materialOrders = [
          ...projData.materialOrders,
          ...projData.purchasedHistory,
        ];
      }
      if (projectsAsync.isLoading && _projects.isEmpty) {
        _isLoading = true;
      }
    }

    final socialAsync = ref.watch(socialFeedProvider);
    final socialData = socialAsync.asData?.value ?? socialAsync.value;
    if (socialData != null) {
      _socialPosts = socialData;
    }
    if (socialAsync.isLoading && _socialPosts.isEmpty) {
      _isLoadingSocial = true;
    }

    final width = MediaQuery.of(context).size.width;
    final hPad = width >= 700 ? 24.0 : (width < 360 ? 14.0 : 18.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: Bento.accent,
          onRefresh: _fetchProjects,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(auth.name ?? 'Guest', auth.profileImage),
                      const SizedBox(height: 20),
                      _buildHero(),
                      const SizedBox(height: Bento.gap),
                      _buildActionGrid(),
                      const SizedBox(height: Bento.gap),
                      // Sponsored banner slot (Admin Panel -> Ads Manager -> "Home Page Banner")
                      const HomeAdSlot(side: 'CLIENT', padding: EdgeInsets.only(bottom: Bento.gap)),
                      _buildOverviewStrip(),
                      const SizedBox(height: 30),
                      _buildExperts(),
                      const SizedBox(height: Bento.gap),
                      _buildMaterialsTile(),
                      const SizedBox(height: 30),
                      _buildMyActivity(),
                      const SizedBox(height: 30),
                      _buildInspirations(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(String name, String? profileImage) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(notificationsProvider).where((n) => n.isUnread).length;
    final firstName = name.trim().split(' ').first;
    final today = DateFormat('EEE, d MMM').format(DateTime.now());

    return Row(
      children: [
        BentoPressable(
          onTap: () => ref.read(mainTabProvider.notifier).setTab(4),
          child: BentoAvatar(name: name, image: profileImage, size: 46),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$today · ${_greeting()} ${_greetingEmoji()}',
                style: TextStyle(fontSize: 12.5, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                firstName.isEmpty ? 'Welcome' : firstName,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Bento.text(dark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        BentoBadgeButton(
          icon: Icons.notifications_none_rounded,
          count: unread,
          onTap: () => context.push('/notifications'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Hero — active project, or "start your journey"
  // ---------------------------------------------------------------------------

  Widget _buildHero() {
    if (_isLoading) {
      return ShimmerHomeOverview(isSmallScreen: MediaQuery.of(context).size.width < 360);
    }
    final active = _activeProjects;
    return active.isEmpty ? _buildJourneyHero() : _buildProjectHero(active.first, active.length);
  }

  Widget _buildProjectHero(dynamic project, int activeCount) {
    final title = (project['title'] ?? 'My Project').toString();
    final location = (project['location'] ?? '').toString();
    final stage = (project['currentStage'] ?? 'Planning').toString();
    final isOnHold = stage.toLowerCase().trim() == 'on hold';
    final progress = ProjectProgressHelper.calculateFromProject(project);
    final percent = (progress.progressValue * 100).round();
    final quotes = _quoteCountOf(project);

    return BentoCard(
      gradient: Bento.inkGradient,
      padding: EdgeInsets.zero,
      onTap: () => context.push('/project-detail/${project['id']}'),
      child: Stack(
        children: [
          const Positioned(right: -60, top: -70, child: BentoGlow(size: 220)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BentoPill(
                      label: 'ACTIVE PROJECT',
                      color: Bento.accentLight,
                      background: Bento.accentLight.withValues(alpha: 0.16),
                      icon: Icons.bolt_rounded,
                    ),
                    const Spacer(),
                    BentoPill(
                      label: isOnHold ? 'On hold' : stage,
                      color: isOnHold ? const Color(0xFFFBBF24) : Colors.white,
                      background: Colors.white.withValues(alpha: 0.1),
                      icon: isOnHold ? Icons.pause_rounded : Icons.flag_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 2),
                      child: Text('%', style: TextStyle(color: Bento.accentLight, fontSize: 22, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text('complete', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatBudget(project['budget']),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const Text('budget', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BentoProgressBar(
                  value: progress.progressValue,
                  trackColor: Colors.white.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.request_quote_rounded, size: 15, color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      quotes == 1 ? '1 quote received' : '$quotes quotes received',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (activeCount > 1)
                      GestureDetector(
                        onTap: () => ref.read(mainTabProvider.notifier).setTab(1),
                        child: Text(
                          '+${activeCount - 1} more',
                          style: const TextStyle(color: Bento.accentLight, fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      )
                    else
                      const Row(
                        children: [
                          Text('Open', style: TextStyle(color: Bento.accentLight, fontSize: 12.5, fontWeight: FontWeight.w800)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, color: Bento.accentLight, size: 15),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyHero() {
    const steps = ['Estimate', 'Quotes', 'Builder', 'Build'];
    return BentoCard(
      gradient: Bento.inkGradient,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(right: -50, top: -60, child: BentoGlow(size: 200)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BentoPill(
                            label: 'YOUR NEXT STEP',
                            color: Bento.accentLight,
                            background: Bento.accentLight.withValues(alpha: 0.16),
                            icon: Icons.auto_awesome_rounded,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Build your\ndream project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Get an estimate, compare quotes from verified builders and track every stage.',
                            style: TextStyle(color: Colors.white60, fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/images/banner_building.jpg',
                        width: 92,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(width: 92, height: 112),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (int i = 0; i < steps.length; i++) ...[
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: i == 0 ? Bento.accentGradient : null,
                          color: i == 0 ? null : Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          steps[i],
                          style: TextStyle(
                            color: i == 0 ? Colors.white : Colors.white60,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 1.5,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                BentoButton(label: 'Create estimate', onTap: () => context.push('/create-project')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Action grid — New project (tall) + Compare quotes + Cost estimate
  // ---------------------------------------------------------------------------

  Widget _buildActionGrid() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final quotes = _totalQuotes;

    return SizedBox(
      height: 186,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BentoCard(
              gradient: Bento.accentGradient,
              padding: const EdgeInsets.all(18),
              onTap: () => context.push('/create-project'),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    bottom: -22,
                    child: Icon(Icons.foundation_rounded, size: 110, color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                      ),
                      const Spacer(),
                      const Text(
                        'New\nproject',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimate in minutes',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Bento.gap),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _miniActionTile(
                    icon: Icons.compare_arrows_rounded,
                    color: Bento.violet,
                    title: 'Compare quotes',
                    caption: quotes == 0 ? 'No quotes yet' : '$quotes received',
                    badge: quotes > 0 ? '$quotes' : null,
                    onTap: _handleCompareQuotesTap,
                    dark: dark,
                  ),
                ),
                const SizedBox(height: Bento.gap),
                Expanded(
                  child: _miniActionTile(
                    icon: Icons.calculate_rounded,
                    color: Bento.green,
                    title: 'Cost estimate',
                    caption: 'Plan your budget',
                    onTap: () => context.push('/cost-estimation'),
                    dark: dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String caption,
    required VoidCallback onTap,
    required bool dark,
    String? badge,
  }) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          BentoIconBubble(icon: icon, color: color, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Bento.text(dark), letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: TextStyle(fontSize: 11, color: Bento.muted(dark)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(gradient: Bento.accentGradient, borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Overview strip
  // ---------------------------------------------------------------------------

  Widget _buildOverviewStrip() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final stats = [
      (_activeProjects.length, 'Active', Bento.green),
      (_projects.length, 'Estimates', Bento.blue),
      (_totalQuotes, 'Quotes', Bento.accentLight),
      (_materialOrders.length, 'Orders', Bento.violet),
    ];

    return BentoCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      onTap: () => context.push('/dashboard'),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoading ? '–' : '${stats[i].$1}',
                    style: TextStyle(
                      fontSize: 22,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Bento.text(dark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: stats[i].$3, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          stats[i].$2,
                          style: TextStyle(fontSize: 11, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (i < stats.length - 1)
              Container(width: 1, height: 30, margin: const EdgeInsets.only(right: 10), color: Bento.border(dark)),
          ],
          Icon(Icons.chevron_right_rounded, color: Bento.muted(dark)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Experts bento grid
  // ---------------------------------------------------------------------------

  Widget _buildExperts() {
    final cats = _expertCategories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoSectionHeader(
          title: 'Find experts',
          subtitle: 'Verified architects, builders & pros',
          actionLabel: 'See all',
          onAction: () => ref.read(mainTabProvider.notifier).setTab(2),
        ),
        SizedBox(
          height: 176,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 6, child: _expertTile(cats[0], large: true)),
              const SizedBox(width: Bento.gap),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(child: _expertTile(cats[1])),
                    const SizedBox(height: Bento.gap),
                    Expanded(child: _expertTile(cats[2])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Bento.gap),
        SizedBox(
          height: 82,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _expertTile(cats[3])),
              const SizedBox(width: Bento.gap),
              Expanded(child: _expertTile(cats[4])),
              const SizedBox(width: Bento.gap),
              Expanded(child: _allExpertsTile()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expertTile(Map<String, dynamic> cat, {bool large = false}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = cat['color'] as Color;
    final icon = cat['icon'] as IconData;

    return BentoCard(
      color: dark ? Color.alphaBlend(color.withValues(alpha: 0.14), Bento.surface(true)) : Color.alphaBlend(color.withValues(alpha: 0.08), Colors.white),
      padding: EdgeInsets.all(large ? 16 : 12),
      onTap: () => context.push(cat['route'] as String),
      child: Stack(
        children: [
          Positioned(
            right: large ? -14 : -10,
            bottom: large ? -16 : -14,
            child: Icon(icon, size: large ? 96 : 54, color: color.withValues(alpha: 0.13)),
          ),
          if (large)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BentoIconBubble(icon: icon, color: color, size: 40),
                const Spacer(),
                Text(
                  cat['title'] as String,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Bento.text(dark)),
                ),
                const SizedBox(height: 3),
                Text(
                  cat['subtitle'] as String,
                  style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          else
            Row(
              children: [
                BentoIconBubble(icon: icon, color: color, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat['title'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Bento.text(dark), letterSpacing: -0.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _allExpertsTile() {
    return BentoCard(
      gradient: Bento.inkGradient,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/providers/All'),
      child: const Row(
        children: [
          Expanded(
            child: Text(
              'All\nexperts',
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.15, fontWeight: FontWeight.w900),
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: Bento.accentLight, size: 18),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Materials tile
  // ---------------------------------------------------------------------------

  Widget _buildMaterialsTile() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      padding: EdgeInsets.zero,
      color: dark ? const Color(0xFF0F2A27) : Bento.accentSoft,
      showBorder: false,
      onTap: () => context.push('/b2b-products'),
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 116),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buy materials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: dark ? Colors.white : Bento.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Cement, steel & more at wholesale prices',
                        style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : const Color(0xFF134E4A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Shop now',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Bento.accentText(dark)),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 15, color: Bento.accentText(dark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(Bento.radius),
                  bottomRight: Radius.circular(Bento.radius),
                ),
                child: Image.asset(
                  'assets/images/cart_3d.jpg',
                  width: 118,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 118),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. My activity
  // ---------------------------------------------------------------------------

  Widget _buildMyActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoSectionHeader(
          title: 'My activity',
          actionLabel: 'View all',
          onAction: () {
            if (_activeTabIndex == 1) {
              context.push('/b2b-materials?tab=2');
            } else if (_activeTabIndex == 2) {
              context.push('/b2b-my-inquiries');
            } else {
              ref.read(mainTabProvider.notifier).setTab(1);
            }
          },
        ),
        BentoSegmented(
          labels: const ['Projects', 'Orders', 'Inquiries'],
          icons: const [Icons.home_work_rounded, Icons.inventory_2_rounded, Icons.forum_rounded],
          index: _activeTabIndex,
          onChanged: (i) => setState(() => _activeTabIndex = i),
        ),
        const SizedBox(height: Bento.gap),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(_activeTabIndex), child: _buildActivityContent()),
        ),
      ],
    );
  }

  Widget _buildActivityContent() {
    if (_activeTabIndex == 0) {
      if (_isLoading) return const ShimmerProjectList(itemCount: 2);
      final list = _activeProjects;
      if (list.isEmpty) {
        return _emptyState(
          title: 'No active projects yet',
          subtitle: 'Start a project to track construction progress here.',
          image: 'assets/images/construction_paused.png',
          cta: 'Start new project',
          onTap: () => context.push('/create-project'),
        );
      }
      return Column(children: list.take(3).map(_projectItem).toList());
    }

    if (_activeTabIndex == 1) {
      if (_isLoading) return const ShimmerOrderList(itemCount: 2);
      if (_materialOrders.isEmpty) {
        return _emptyState(
          title: 'No orders yet',
          subtitle: 'Buy materials at wholesale prices from verified suppliers.',
          image: 'assets/images/no_materials_orders.png',
          cta: 'Shop materials',
          onTap: () => context.push('/b2b-products'),
        );
      }
      return Column(children: _materialOrders.take(3).map(_orderItem).toList());
    }

    return _emptyState(
      title: 'Your inquiries',
      subtitle: 'See quotes from suppliers for the materials you asked about.',
      image: 'assets/images/construction_paused.png',
      cta: 'Open inquiries',
      onTap: () => context.push('/b2b-my-inquiries'),
    );
  }

  Widget _projectItem(dynamic project) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = (project['title'] ?? 'Project').toString();
    final location = (project['location'] ?? '').toString();
    final stage = (project['currentStage'] ?? 'Planning').toString();
    final isOnHold = stage.toLowerCase().trim() == 'on hold';
    final progress = ProjectProgressHelper.calculateFromProject(project);
    final percent = (progress.progressValue * 100).round();
    final icons = [Icons.home_rounded, Icons.business_rounded, Icons.storefront_rounded];
    final icon = icons[(project['id']?.toString() ?? '').hashCode.abs() % icons.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: Bento.gap),
      child: BentoCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push('/project-detail/${project['id']}'),
        child: Column(
          children: [
            Row(
              children: [
                BentoIconBubble(icon: icon, color: isOnHold ? const Color(0xFFF59E0B) : Bento.accent, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Bento.text(dark), letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location.isEmpty ? stage : '$location · $stage',
                        style: TextStyle(fontSize: 11.5, color: Bento.muted(dark)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatBudget(project['budget']),
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Bento.text(dark)),
                    ),
                    if (isOnHold)
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: BentoPill(label: 'On hold', color: Color(0xFFD97706), icon: Icons.pause_rounded),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: BentoProgressBar(value: progress.progressValue, height: 7)),
                const SizedBox(width: 10),
                Text(
                  '$percent%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Bento.accentText(dark)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderItem(dynamic order) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = (order['title'] ?? order['product_name'] ?? 'Material').toString();
    final status = (order['status'] ?? 'New').toString();
    final deliveryStatus = order['delivery_status'];
    final isDelivered = status == 'Completed' || (status == 'Closed' && deliveryStatus == 'Delivered');

    return Padding(
      padding: const EdgeInsets.only(bottom: Bento.gap),
      child: BentoCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push(isDelivered ? '/b2b-materials?tab=2' : '/b2b-materials'),
        child: Row(
          children: [
            BentoIconBubble(
              icon: isDelivered ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
              color: isDelivered ? Bento.green : Bento.violet,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  BentoPill(
                    label: isDelivered ? 'Delivered' : status,
                    color: isDelivered ? const Color(0xFF059669) : Bento.blue,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Bento.muted(dark)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required String title,
    required String subtitle,
    required String image,
    required String cta,
    required VoidCallback onTap,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              image,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => BentoIconBubble(icon: Icons.inbox_rounded, color: Bento.accentLight, size: 78),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Bento.text(dark)),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), height: 1.35),
                ),
                const SizedBox(height: 10),
                BentoButton(label: cta, onTap: onTap, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Builder inspirations
  // ---------------------------------------------------------------------------

  Widget _buildInspirations() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoSectionHeader(
          title: 'Builder inspirations',
          subtitle: 'Recent work from Connectzy partners',
          actionLabel: 'Explore',
          onAction: () => ref.read(mainTabProvider.notifier).setTab(2),
        ),
        if (_isLoadingSocial || _isLoading)
          const ShimmerSocialFeed(itemCount: 3)
        else if (_socialPosts.isEmpty)
          BentoCard(
            child: Center(
              child: Text('No showcases yet.', style: TextStyle(color: Bento.muted(dark), fontSize: 12.5)),
            ),
          )
        else
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _socialPosts.length > 6 ? 6 : _socialPosts.length,
              separatorBuilder: (_, _) => const SizedBox(width: Bento.gap),
              itemBuilder: (context, index) => _inspirationCard(_socialPosts[index]),
            ),
          ),
      ],
    );
  }

  Widget _inspirationCard(dynamic post) {
    final provider = post['provider'] ?? {};
    final builderName = (provider['businessName'] ?? provider['ownerName'] ?? 'Partner').toString();
    final title = (post['title'] ?? 'Showcase').toString();
    final rawCategory = (provider['category'] ?? 'Construction').toString();
    final category = rawCategory.split(',').first.trim();
    final providerId = (provider['id'] ?? '').toString();
    final imageData = (post['imageData'] as String?)?.trim() ?? '';

    Widget image;
    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      image = Image.network(imageData, fit: BoxFit.cover, errorBuilder: (_, _, _) => _imageFallback());
    } else if (imageData.isNotEmpty) {
      final bytes = Base64ImageCache.decode(imageData);
      image = bytes.isEmpty
          ? _imageFallback()
          : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => _imageFallback());
    } else {
      image = _imageFallback();
    }

    return SizedBox(
      width: 210,
      child: BentoCard(
        padding: EdgeInsets.zero,
        onTap: providerId.isEmpty
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProviderProfileScreen(providerId: providerId)),
                ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: BentoPill(label: category, color: Colors.white, background: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          builderName,
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Bento.accentLight, size: 13),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Bento.surfaceAlt(dark),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Bento.muted(dark), size: 36),
    );
  }

  // ---------------------------------------------------------------------------
  // Compare quotes flow (unchanged behaviour)
  // ---------------------------------------------------------------------------

  void _handleCompareQuotesTap() {
    final activeProjects = _activeProjects;

    if (activeProjects.isEmpty) {
      if (_projects.isEmpty) {
        context.push('/create-project');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active projects available for quote comparison.'),
            backgroundColor: Bento.ink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (activeProjects.length == 1) {
      context.push('/compare-quotes/${activeProjects.first['id']}');
      return;
    }
    _showProjectPickerBottomSheet(activeProjects);
  }

  void _showProjectPickerBottomSheet(List<dynamic> activeProjects) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: Bento.surface(dark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Bento.border(dark), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Which project?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Bento.text(dark)),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick the project whose quotes you want to compare.',
                style: TextStyle(fontSize: 12.5, color: Bento.muted(dark)),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: activeProjects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final p = activeProjects[idx];
                    final pid = p['id'] ?? '';
                    final title = (p['title'] ?? 'Project ${idx + 1}').toString();
                    final location = (p['location'] ?? '').toString();
                    final quotes = _quoteCountOf(p);

                    return BentoCard(
                      padding: const EdgeInsets.all(12),
                      color: Bento.surfaceAlt(dark),
                      showBorder: false,
                      radius: Bento.radiusSm,
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/compare-quotes/$pid');
                      },
                      child: Row(
                        children: [
                          const BentoIconBubble(icon: Icons.compare_arrows_rounded, color: Bento.violet, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Bento.text(dark)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (location.isNotEmpty)
                                  Text(
                                    location,
                                    style: TextStyle(fontSize: 11.5, color: Bento.muted(dark)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          BentoPill(
                            label: quotes == 1 ? '1 quote' : '$quotes quotes',
                            color: quotes > 0 ? const Color(0xFF059669) : Bento.muted(dark),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
