import 'dart:convert';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _projects = [];
  List<dynamic> _materialOrders = [];
  List<dynamic> _socialPosts = [];
  bool _isLoading = false;
  bool _isLoadingSocial = false;
  int _activeTabIndex = 0;

  final Color _slateDark = const Color(0xFF111827); // Dark button color from design

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
    final auth = ref.read(authProvider);
    if (auth.id != null) {
      ref.invalidate(userProjectsProvider(auth.id!));
    }
    ref.invalidate(socialFeedProvider);
  }

  Future<void> _handleRefresh() async {
    final auth = ref.read(authProvider);
    final futures = <Future<dynamic>>[];
    if (auth.id != null) {
      futures.add(ref.refresh(userProjectsProvider(auth.id!).future));
    }
    futures.add(ref.refresh(socialFeedProvider.future));
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.id != null) {
      final projectsAsync = ref.watch(userProjectsProvider(auth.id!));
      final projData = projectsAsync.asData?.value ?? projectsAsync.value;
      if (projData != null) {
        _projects = projData.projects;
        _materialOrders = projData.materialOrders;
      }
      _isLoading = projectsAsync.isLoading && _projects.isEmpty;
    }

    final socialAsync = ref.watch(socialFeedProvider);
    final socialData = socialAsync.asData?.value ?? socialAsync.value;
    if (socialData != null) {
      _socialPosts = socialData;
    }
    _isLoadingSocial = socialAsync.isLoading && _socialPosts.isEmpty;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isTabletOrLaptop = screenWidth >= 700;
    final horizontalPadding = isTabletOrLaptop ? 24.0 : (isSmallScreen ? 12.0 : 18.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: RefreshIndicator(
          color: _slateDark,
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(auth.name ?? 'Guest', isSmallScreen),
                      const SizedBox(height: 20),
                      _buildConstructionOverview(isSmallScreen, screenWidth),
                      const SizedBox(height: 28),
                      _buildWhatAreYouLookingFor(isSmallScreen, screenWidth),
                      const SizedBox(height: 28),
                      _buildBanner(isSmallScreen, screenWidth),
                      const SizedBox(height: 28),
                      _buildQuickActions(isSmallScreen, screenWidth),
                      const SizedBox(height: 28),
                      _buildMyActivity(isSmallScreen, screenWidth),
                      const SizedBox(height: 28),
                      _buildBuilderInspirations(isSmallScreen, screenWidth),
                      const SizedBox(height: 80),
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

  Widget _buildHeader(String name, bool isSmallScreen) {
    final todayStr = DateFormat('EEEE, MMM d').format(DateTime.now());
    
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => n.isUnread).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 20 : 24,
              backgroundColor: _slateDark,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'T',
                style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 17 : 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, $name 👋',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Let\'s build something great today.',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(Icons.notifications_none_rounded, color: Colors.black87, size: isSmallScreen ? 20 : 24),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: isSmallScreen ? 15 : 18, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      todayStr,
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => context.push('/create-project'),
              icon: Icon(Icons.add_rounded, size: isSmallScreen ? 15 : 18, color: Colors.white),
              label: Text(
                isSmallScreen ? 'New Project' : 'Start New Project',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _slateDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 16, vertical: isSmallScreen ? 8 : 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConstructionOverview(bool isSmallScreen, double screenWidth) {
    int activeProjects = _projects.where((p) {
      final stage = (p['currentStage'] as String? ?? '').toLowerCase();
      return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
    }).length;

    int estimatesCreated = _projects.length;
    int quotesReceived = 0;
    for (var p in _projects) {
      quotesReceived += (p['_count']?['quotes'] as int? ?? 0);
    }
    int ordersPlaced = _materialOrders.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Construction Overview',
                  style: TextStyle(fontSize: isSmallScreen ? 14.5 : 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/dashboard'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Dashboard', style: TextStyle(fontSize: isSmallScreen ? 11.5 : 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewCard('Projects', 'Active', activeProjects.toString(), Icons.business_rounded, Colors.green, isSmallScreen),
              _buildOverviewCard('Estimates', 'Created', estimatesCreated.toString(), Icons.calculate_outlined, Colors.blue, isSmallScreen),
              _buildOverviewCard('Quotes', 'Received', quotesReceived.toString(), Icons.assignment_outlined, Colors.orange, isSmallScreen),
              _buildOverviewCard('Orders', 'Placed', ordersPlaced.toString(), Icons.inventory_2_outlined, Colors.purple, isSmallScreen),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String subtitle, String value, IconData icon, Color color, bool isSmallScreen) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 14, horizontal: isSmallScreen ? 2 : 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isSmallScreen ? 20 : 26),
            SizedBox(height: isSmallScreen ? 4 : 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: isSmallScreen ? 16 : 19, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, style: TextStyle(fontSize: isSmallScreen ? 8.5 : 10, fontWeight: FontWeight.w600, color: Colors.black87)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(subtitle, style: TextStyle(fontSize: isSmallScreen ? 8.5 : 10, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(bool isSmallScreen, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50.withValues(alpha: 0.5), Colors.blue.shade50.withValues(alpha: 0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOUR NEXT STEP',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.orange, letterSpacing: 1),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start Your Construction Journey',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 17 : 20,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create estimate, get quotes and build your dream project.',
                            style: TextStyle(fontSize: isSmallScreen ? 11.5 : 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () => context.push('/create-project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _slateDark,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 18, vertical: isSmallScreen ? 8 : 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Create Estimate',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 13),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: isSmallScreen ? 14 : 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: Image.asset(
                        'assets/images/banner_building.jpg',
                        height: isSmallScreen ? 90 : 115,
                        fit: BoxFit.contain,
                        color: Colors.white.withValues(alpha: 0.01),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.construction, size: isSmallScreen ? 65 : 85, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepIcon(Icons.calculate_outlined, 'Estimate', Colors.orange, isSmallScreen),
                    _buildStepLine(isSmallScreen),
                    _buildStepIcon(Icons.engineering_outlined, 'Get Quotes', Colors.blue, isSmallScreen),
                    _buildStepLine(isSmallScreen),
                    _buildStepIcon(Icons.handshake_outlined, 'Select Builder', Colors.teal, isSmallScreen),
                    _buildStepLine(isSmallScreen),
                    _buildStepIcon(Icons.foundation_outlined, 'Start Project', Colors.purple, isSmallScreen),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, String label, Color color, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
            color: Colors.white,
          ),
          child: Icon(icon, color: color, size: isSmallScreen ? 15 : 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: isSmallScreen ? 7.5 : 9, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isSmallScreen) {
    return Expanded(
      child: Container(
        height: 1,
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 6).copyWith(bottom: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = (constraints.constrainWidth() / 4).floor();
            return Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                count > 0 ? count : 1,
                (index) => const SizedBox(
                  width: 2, height: 1,
                  child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWhatAreYouLookingFor(bool isSmallScreen, double screenWidth) {
    final categories = [
      {
        'title': 'Architecture',
        'badge': 'Design & Plans',
        'subtitle': '2D/3D Floor Plans, Elevations, Structural Layouts & Vastu',
        'icon': Icons.architecture_rounded,
        'gradient': const [Color(0xFF6F42C1), Color(0xFF8B5CF6)],
        'accent': const Color(0xFF6F42C1),
        'bg': const Color(0xFFF5F3FF),
        'tags': ['3D Design', 'Vastu', 'Approvals'],
        'route': '/providers/Design & Planning',
        'buttonText': 'Find Architects',
      },
      {
        'title': 'Builders',
        'badge': 'Turnkey & Civil',
        'subtitle': 'Verified Residential & Commercial General Contractors',
        'icon': Icons.apartment_rounded,
        'gradient': const [Color(0xFF0284C7), Color(0xFF2563EB)],
        'accent': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
        'tags': ['Turnkey', 'Renovation', 'Civil Work'],
        'route': '/providers/Builder/General Contractor',
        'buttonText': 'Find Builders',
      },
      {
        'title': 'Promoters',
        'badge': 'Land & Plots',
        'subtitle': 'Approved Layouts, Gated Communities & Joint Ventures',
        'icon': Icons.real_estate_agent_rounded,
        'gradient': const [Color(0xFF059669), Color(0xFF10B981)],
        'accent': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
        'tags': ['Plots', 'DTCP/RERA', 'Villas'],
        'route': '/providers/Commercial Builder',
        'buttonText': 'Find Promoters',
      },
      {
        'title': 'Interiors',
        'badge': 'Modular & Decor',
        'subtitle': 'Modular Kitchens, Custom Woodwork, Lighting & Styling',
        'icon': Icons.chair_rounded,
        'gradient': const [Color(0xFFEA580C), Color(0xFFF97316)],
        'accent': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFF7ED),
        'tags': ['Modular Kitchen', 'Woodwork', 'Decor'],
        'route': '/providers/Interiors & Finishing',
        'buttonText': 'Find Designers',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Pill Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 11,
            vertical: isSmallScreen ? 4 : 4.5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFC7D2FE),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: isSmallScreen ? 13 : 15,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'NEED EXPERTS FOR YOUR PROJECT?',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: const Color(0xFF2563EB),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Section Header: Title on Left, See More on Right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What do you look for?',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 19 : 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hire verified architects, builders, promoters & pros.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11.5 : 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // See More / Market Button
            GestureDetector(
              onTap: () => ref.read(mainTabProvider.notifier).state = 2,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See More',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11.5 : 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Cards layout: Horizontal scrollable carousel
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...categories.map((cat) {
                return Container(
                  width: isSmallScreen ? 230 : 255,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildLookingForCard(cat, isSmallScreen, false),
                );
              }),
              // "Explore 30+ More in Market" end card
              _buildMarketEndCard(isSmallScreen),
            ],
          ),
        ),

        const SizedBox(height: 14),
        // Interactive "Go to Market" Banner
        _buildMarketPromotionBanner(isSmallScreen),
      ],
    );
  }

  Widget _buildLookingForCard(Map<String, dynamic> cat, bool isSmallScreen, bool isExpanded) {
    final title = cat['title'] as String;
    final badge = cat['badge'] as String;
    final subtitle = cat['subtitle'] as String;
    final icon = cat['icon'] as IconData;
    final gradient = cat['gradient'] as List<Color>;
    final accent = cat['accent'] as Color;
    final bg = cat['bg'] as Color;
    final tags = cat['tags'] as List<String>;
    final route = cat['route'] as String;
    final buttonText = cat['buttonText'] as String;

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Subtle background decoration glow
              Positioned(
                top: -24,
                right: -24,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.12),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Icon + Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 9 : 11),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9.5 : 10.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16.5 : 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Subtitle / Description
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 14),

                    // Tags
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: isSmallScreen ? 14 : 16),

                    // Bottom Action Button
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 8.5 : 9.5,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                fontSize: isSmallScreen ? 11.5 : 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketEndCard(bool isSmallScreen) {
    return GestureDetector(
      onTap: () => ref.read(mainTabProvider.notifier).state = 2,
      child: Container(
        width: isSmallScreen ? 170 : 190,
        margin: const EdgeInsets.only(right: 4),
        padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF38BDF8),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Explore 30+\nMore Services',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Survey, MEP, Legal,\nBorewell, Materials',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 9.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Go to Market',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 11,
                    color: Color(0xFF0F172A),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketPromotionBanner(bool isSmallScreen) {
    return GestureDetector(
      onTap: () => ref.read(mainTabProvider.notifier).state = 2,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background glow effect
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.35),
                      const Color(0xFF6366F1).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 12 : 14,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: const Color(0xFF38BDF8),
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Looking for materials or specialized services?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: isSmallScreen ? 11.5 : 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Explore wholesale raw materials & 30+ service categories.',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: isSmallScreen ? 9.5 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSmallScreen ? 'Market' : 'Go to Market',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: isSmallScreen ? 10.5 : 11.5,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Color(0xFF0F172A),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isSmallScreen, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E1E2D),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.auto_awesome, size: isSmallScreen ? 15 : 18, color: Colors.purple.shade300),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Everything you need, right at your fingertips.',
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(mainTabProvider.notifier).state = 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('All Actions', style: TextStyle(fontSize: isSmallScreen ? 10.5 : 12, color: Colors.indigo.shade900, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded, size: 14, color: Colors.indigo.shade900),
                  ],
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        if (screenWidth >= 1050)
          Row(
            children: [
              _buildQuickActionCard('Cost Estimate', 'Calculate project\ncost in minutes', 'Get Started', Icons.calculate_rounded, Colors.green.shade500, 'assets/images/calc_3d.jpg', () => context.push('/cost-estimation'), isSmallScreen),
              const SizedBox(width: 14),
              _buildQuickActionCard('Find Contractor', 'Connect with\nverified builders', 'Explore', Icons.engineering_rounded, Colors.blue.shade600, 'assets/images/crane_3d.jpg', () => context.push('/providers/All'), isSmallScreen),
              const SizedBox(width: 14),
              _buildQuickActionCard('Compare Quotes', 'Review & compare\nbest quotes', 'Compare Now', Icons.assignment_outlined, Colors.orange.shade500, 'assets/images/quote_3d.jpg', _handleCompareQuotesTap, isSmallScreen),
              const SizedBox(width: 14),
              _buildQuickActionCard('Buy Materials', 'Get materials at\nbest prices', 'Shop Now', Icons.shopping_cart_outlined, Colors.purple.shade500, 'assets/images/cart_3d.jpg', () => context.push('/b2b-products'), isSmallScreen),
            ],
          )
        else ...[
          Row(
            children: [
              _buildQuickActionCard('Cost Estimate', 'Calculate project\ncost in minutes', 'Get Started', Icons.calculate_rounded, Colors.green.shade500, 'assets/images/calc_3d.jpg', () => context.push('/cost-estimation'), isSmallScreen),
              SizedBox(width: isSmallScreen ? 10 : 16),
              _buildQuickActionCard('Find Contractor', 'Connect with\nverified builders', 'Explore', Icons.engineering_rounded, Colors.blue.shade600, 'assets/images/crane_3d.jpg', () => context.push('/providers/All'), isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 16),
          Row(
            children: [
              _buildQuickActionCard('Compare Quotes', 'Review & compare\nbest quotes', 'Compare Now', Icons.assignment_outlined, Colors.orange.shade500, 'assets/images/quote_3d.jpg', _handleCompareQuotesTap, isSmallScreen),
              SizedBox(width: isSmallScreen ? 10 : 16),
              _buildQuickActionCard('Buy Materials', 'Get materials at\nbest prices', 'Shop Now', Icons.shopping_cart_outlined, Colors.purple.shade500, 'assets/images/cart_3d.jpg', () => context.push('/b2b-products'), isSmallScreen),
            ],
          ),
        ],
      ],
    );
  }

  void _handleCompareQuotesTap() {
    if (_projects.isEmpty) {
      context.push('/create-project');
      return;
    }
    if (_projects.length == 1) {
      context.push('/compare-quotes/${_projects.first['id']}');
      return;
    }
    _showProjectPickerBottomSheet();
  }

  void _showProjectPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Project to Compare Quotes',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose which construction project you want to review bids for:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _projects.length,
                itemBuilder: (context, idx) {
                  final p = _projects[idx];
                  final pid = p['id'] ?? '';
                  final title = p['title'] ?? 'Project ${idx + 1}';
                  final location = p['location'] ?? 'N/A';
                  final quotes = p['quotes'] as List? ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_outlined, color: Color(0xFF4F46E5), size: 20),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        location,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: quotes.isNotEmpty ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${quotes.length} ${quotes.length == 1 ? 'quote' : 'quotes'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: quotes.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/compare-quotes/$pid');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, String subtitle, String buttonText, IconData icon, Color color, String imagePath, VoidCallback onTap, bool isSmallScreen) {
    final imageSize = isSmallScreen ? 40.0 : 46.0;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, color.withValues(alpha: 0.04), color.withValues(alpha: 0.08)],
                ),
              ),
              padding: EdgeInsets.all(isSmallScreen ? 11 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Icon on left, 3D image on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 7 : 9),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 22),
                      ),
                      Image.asset(
                        imagePath,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isSmallScreen ? 13.5 : 14.5,
                      color: const Color(0xFF1E1E2D),
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Container(width: 18, height: 2.5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 5),
                  // Subtitle (pure high contrast without overlapping background)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFF4B5563),
                      fontSize: isSmallScreen ? 10 : 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  // Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          buttonText,
                          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: isSmallScreen ? 10.5 : 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 9),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyActivity(bool isSmallScreen, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildActivityTab('Projects', 0, isSmallScreen),
                    _buildActivityTab('Quotes', 1, isSmallScreen),
                    _buildActivityTab('Orders', 2, isSmallScreen),
                    _buildActivityTab('Inquiries', 3, isSmallScreen),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => ref.read(mainTabProvider.notifier).state = 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade700),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 14),
        _buildActivityContent(isSmallScreen),
      ],
    );
  }

  Widget _buildActivityContent(bool isSmallScreen) {
    if (_activeTabIndex == 0) {
      final activeProjectsList = _projects.where((p) {
        final stage = (p['currentStage'] as String? ?? '').toLowerCase();
        return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
      }).toList();
      if (activeProjectsList.isEmpty && !_isLoading) {
        return _buildActivityEmptyState('No active projects yet', 'Start a new project to track your\nconstruction progress here.', Icons.foundation, 'assets/images/construction_paused.png', 'Start New Project', () => context.push('/create-project'), isSmallScreen);
      }
      return _isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: activeProjectsList.take(3).map((p) => _buildProjectListItem(p, isSmallScreen)).toList());
    } else if (_activeTabIndex == 2) {
      if (_materialOrders.isEmpty && !_isLoading) {
        return _buildActivityEmptyState('No active orders', 'Purchase materials at wholesale prices.', Icons.inventory_2, 'assets/images/no_materials_orders.png', 'Shop Materials', () => context.push('/b2b-products'), isSmallScreen);
      }
      return _isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: _materialOrders.take(3).map((o) => _buildOrderListItem(o, isSmallScreen)).toList());
    } else {
      return _buildActivityEmptyState('Nothing to show yet', 'No records found for this category.', Icons.inbox, 'assets/images/construction_paused.png', 'Explore', () => ref.read(mainTabProvider.notifier).state = 2, isSmallScreen);
    }
  }

  Widget _buildProjectListItem(dynamic project, bool isSmallScreen) {
    final title = project['title'] ?? 'N/A';
    final currentStage = project['currentStage'] ?? 'Planning';
    final location = project['location'] ?? 'N/A';
    final budget = project['budget']?.toString() ?? '10,000';
    final projectId = project['id']?.toString() ?? '';
    
    final isCompleted = currentStage.toString().toLowerCase() == 'completed' || currentStage.toString().toLowerCase() == 'finished';
    final isCancelled = currentStage.toString().toLowerCase() == 'cancelled';
    
    final int colorIndex = projectId.hashCode.abs() % 3;
    final List<Color> colors = [Colors.green, Colors.blue, Colors.purple];
    final Color cardColor = isCancelled ? Colors.red : (isCompleted ? colors[colorIndex] : Colors.green);
    final IconData icon = [Icons.home_rounded, Icons.business_rounded, Icons.storefront_rounded][colorIndex];

    final progressText = isCompleted ? '100% Done' : (isCancelled ? '15% Done' : '50% Done');
    final progressValue = isCompleted ? 1.0 : (isCancelled ? 0.15 : 0.5);

    return GestureDetector(
      onTap: () => context.push('/project-detail/${project['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: cardColor, width: 4)),
            ),
            padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 11),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: cardColor, size: isSmallScreen ? 20 : 24),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: isSmallScreen ? 13.5 : 15, color: const Color(0xFF1E1E2D)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('₹ $budget', style: TextStyle(fontWeight: FontWeight.w900, fontSize: isSmallScreen ? 13 : 15, color: Colors.green)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 11, color: Colors.grey.shade500),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: isSmallScreen ? 10.5 : 11.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Completed', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                                )
                              else if (isCancelled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Cancelled', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isCompleted ? 'Finished' : 'Stage: $currentStage',
                            style: TextStyle(color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600, fontSize: 10.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isCompleted ? 'Progress: Completed' : 'Stage Progress', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
                    Text(progressText, style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderListItem(dynamic order, bool isSmallScreen) {
    final title = order['title'] ?? order['product_name'] ?? 'Material';
    final status = order['status'] ?? 'New';
    return GestureDetector(
      onTap: () => context.push('/b2b-materials'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.inventory_2_rounded, color: Colors.purple.shade700, size: isSmallScreen ? 18 : 22),
            ),
            SizedBox(width: isSmallScreen ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12.5 : 14)),
                  const SizedBox(height: 2),
                  Text('Status: $status', style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityEmptyState(String title, String subtitle, IconData fallbackIcon, String imageAsset, String actionText, VoidCallback onTap, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Image.asset(
              imageAsset,
              height: isSmallScreen ? 70 : 90,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: isSmallScreen ? 50 : 70, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: isSmallScreen ? 10.5 : 11.5, color: Colors.grey.shade600, height: 1.3),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                  label: Text(actionText, style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _slateDark,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivityTab(String label, int index, bool isSmallScreen) {
    bool isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 9 : 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? _slateDark : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildBuilderInspirations(bool isSmallScreen, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Builder Inspirations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => ref.read(mainTabProvider.notifier).state = 2, // feed tab
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Explore Feed', style: TextStyle(fontSize: isSmallScreen ? 11.5 : 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade700),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoadingSocial)
          const Center(child: CircularProgressIndicator())
        else if (_socialPosts.isEmpty)
          Center(child: Text('No showcases found.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)))
        else
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _socialPosts.length > 5 ? 5 : _socialPosts.length,
              itemBuilder: (context, index) {
                final post = _socialPosts[index];
                final provider = post['provider'] ?? {};
                final builderName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
                final location = provider['city'] ?? 'Location';
                final title = post['title'] ?? 'Showcase';
                
                final category = provider['category'] ?? 'Construction';
                Color tagColor = Colors.green;
                if (category.toLowerCase().contains('interior')) tagColor = Colors.orange;
                if (category.toLowerCase().contains('commercial')) tagColor = Colors.blue;

                return _buildInspirationCard(
                  title, 
                  builderName, 
                  location, 
                  'Contact for details', 
                  category, 
                  tagColor,
                  post['imageData'] as String?,
                  provider['id'] ?? '',
                  isSmallScreen,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInspirationCard(String title, String builder, String location, String price, String category, Color tagColor, String? imageData, String providerId, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        if (providerId.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderProfileScreen(providerId: providerId)));
        }
      },
      child: Container(
        width: isSmallScreen ? 220 : 250,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: imageData != null
                        ? Image.memory(
                            base64Decode(imageData.contains(',') ? imageData.split(',').last : imageData), 
                            fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.grey)
                          )
                        : Center(child: Icon(Icons.image_outlined, color: Colors.grey.shade500, size: 36)),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: isSmallScreen ? 12.5 : 13.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Icon(Icons.bookmark_border_rounded, size: 16, color: Colors.grey.shade500),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(child: Text(builder, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 3),
                        const Icon(Icons.verified, color: Colors.blue, size: 11),
                      ],
                    ),
                    Text(location, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(price, style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w900, color: Colors.green)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

