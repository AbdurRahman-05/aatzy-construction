import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/ads_carousel.dart';
import '../../core/providers/projects_provider.dart';
import '../../core/providers/social_feed_provider.dart';
import '../auth/auth_provider.dart';
import '../providers/provider_profile_screen.dart';
import 'main_layout.dart'; // import tab provider

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

    final name = auth.name ?? 'Guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryOrange;
    final todayStr = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryOrange, width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryOrange,
                child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hey $name 👋',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isDark ? Colors.white : const Color(0xFF111111),
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Here\'s your construction update',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2730) : const Color(0xFFE8E8E5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              todayStr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF111111),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? const Color(0xFF1B2730) : Colors.white,
              child: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryOrange, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Hero Project Card & KPI Grid
                _buildActiveProjectHeroCard(context, isDark),
                const SizedBox(height: 24),

                // Consumer Quick Action Bar
                _buildQuickActionsGrid(context, isDark),
                const SizedBox(height: 28),

                // Create Project Action Banner
                _buildCreateProjectBanner(context, isDark, primaryColor),
                const SizedBox(height: 28),

                // Sponsored Ads Carousel
                const AppAdsCarousel(),
                const SizedBox(height: 28),

                // Ongoing Projects Section
                _buildOngoingProjectsSection(isDark, primaryColor),
                const SizedBox(height: 28),

                // Closed Deals Section (Material Orders)
                _buildClosedDealsSection(isDark, primaryColor),
                const SizedBox(height: 28),

                // Tools & Services section
                _buildToolsSection(isDark, primaryColor),
                const SizedBox(height: 28),

                // Recent Showcases Section
                _buildRecentShowcasesSection(isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveProjectHeroCard(BuildContext context, bool isDark) {
    final ongoingProjects = _projects.where((p) {
      final stage = (p['currentStage'] as String? ?? '').toLowerCase().trim();
      return stage != 'completed' &&
             stage != 'finished' &&
             stage != 'finished pending approval' &&
             stage != 'cancelled';
    }).toList();

    if (ongoingProjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2730) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8E8E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.architecture_rounded, size: 36, color: AppTheme.primaryOrange),
            ),
            const SizedBox(height: 14),
            Text(
              'No Ongoing Sites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no active ongoing construction sites. Start a new project or explore contractor quotes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => context.push('/create-project'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Start Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    final project = ongoingProjects.first;
    final title = project['title'] ?? 'Ongoing Construction';
    final location = project['location'] ?? 'Location';
    final currentStage = project['currentStage'] ?? 'Design & Planning';
    final budget = (project['budget'] as num? ?? 0.0).toDouble();

    final tasks = (project['tasks'] as List? ?? []);
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => (t['status'] as String? ?? '').toLowerCase() == 'completed').length;
    
    double progress = 0.0;
    if (totalTasks > 0) {
      progress = (completedTasks / totalTasks).clamp(0.0, 1.0);
    } else {
      if (currentStage.toLowerCase() == 'execution' || currentStage.toLowerCase() == 'tracking') {
        progress = 0.4;
      } else {
        progress = 0.1;
      }
    }
    final progressPercent = (progress * 100).toInt();

    double totalSpent = 0.0;
    for (var t in tasks) {
      if ((t['status'] as String? ?? '').toLowerCase() == 'completed') {
        totalSpent += (t['quotedCost'] as num? ?? t['taskCost'] as num? ?? 0.0).toDouble();
      }
    }

    final formattedBudget = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(budget);

    final formattedSpent = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(totalSpent);

    return InkWell(
      onTap: () {
        if (project['id'] != null) {
          context.push('/project-detail/${project['id']}');
        }
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2730) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8E8E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.business_rounded, color: AppTheme.primaryOrange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111111),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 3),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                      SizedBox(width: 5),
                      Text(
                        'Ongoing Site',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Completion Percentage Callout & Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111111),
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Stage: $currentStage',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8E8E5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // KPI Cards Row inside Active Project Card
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Budget', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373))),
                        const SizedBox(height: 4),
                        Text(formattedBudget, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111111))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spent', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373))),
                        const SizedBox(height: 4),
                        Text(formattedSpent, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111111))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tasks', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF737373))),
                        const SizedBox(height: 4),
                        Text(totalTasks > 0 ? '$completedTasks/$totalTasks' : '0', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111111))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCircularActionItem(context, isDark, icon: Icons.calculate_rounded, label: 'Cost Estimate', onTap: () => context.push('/cost-estimation')),
              const SizedBox(width: 16),
              _buildCircularActionItem(context, isDark, icon: Icons.engineering_rounded, label: 'Find Contractor', onTap: () => context.push('/providers/All')),
              const SizedBox(width: 16),
              _buildCircularActionItem(context, isDark, icon: Icons.compare_arrows_rounded, label: 'Compare Quotes', onTap: () {
                if (_projects.isNotEmpty) {
                  context.push('/compare-quotes/${_projects.first['id']}');
                } else {
                  context.push('/create-project');
                }
              }),
              const SizedBox(width: 16),
              _buildCircularActionItem(context, isDark, icon: Icons.storefront_rounded, label: 'Buy Materials', onTap: () => context.push('/b2b-products')),
              const SizedBox(width: 16),
              _buildCircularActionItem(context, isDark, icon: Icons.assignment_rounded, label: 'My Inquiries', onTap: () => context.push('/b2b-my-inquiries')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularActionItem(BuildContext context, bool isDark, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2730) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE8E8E5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProjectBanner(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      height: 145,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Image/Gradient Mesh
            Positioned.fill(
              child: Image.asset(
                'assets/create_project_banner.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Elegant gradient fallback
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [const Color(0xFF064354), const Color(0xFF0E5E6F)]
                            : [const Color(0xFF064354), const Color(0xFF0B7C8E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Multi-layer high-contrast overlay gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.15),
                    ],
                  ),
                ),
              ),
            ),
            // Ambient glow effect inside banner
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                key: const ValueKey('ambient_glow'),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F9B8E).withValues(alpha: 0.25),
                ),
              ),
            ),
            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final created = await context.push('/create-project');
                  if (created == true) {
                    setState(() => _isLoading = true);
                    _fetchProjects();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
                  child: Row(
                    children: [
                      // Floating plus sign with gold ring
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9B8E).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0F9B8E), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F9B8E).withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Initiate Construction',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Estimate cost, request material quotes & start execution',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Mini feature chips
                            Row(
                              children: [
                                _buildMiniBannerChip('✓ Cost Estimator'),
                                const SizedBox(width: 8),
                                _buildMiniBannerChip('✓ Verified Quotes'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white12,
                        ),
                        child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBannerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildClosedDealsSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Material Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Track quotes, ongoing shipments & closed deals',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/b2b-materials'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: primaryColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: primaryColor),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_materialOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryColor.withValues(alpha: 0.06),
                  child: Icon(Icons.local_shipping_outlined, size: 30, color: primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Material Orders yet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your active requests, negotiations, and completed shipments will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          )
        else
          Column(
            children: _materialOrders.map((order) {
              final title = order['title'] ?? order['product_name'] ?? 'Material Inquiry';
              final supplierName = order['supplier_name'] ?? 'Supplier';
              final quantityVal = order['quantity'] != null ? double.parse(order['quantity'].toString()) : 0.0;
              final unitStr = order['unit'] ?? 'Units';
              final status = order['status'] ?? 'New';
              final deliveryStatus = order['delivery_status'] ?? 'Pending';

              String statusLabel = '';
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.hourglass_top_rounded;

              if (status == 'Quote Sent') {
                statusLabel = 'Quote Received';
                statusColor = Colors.purple;
                statusIcon = Icons.mark_email_unread_outlined;
              } else if (status == 'New' || status == 'Viewed' || status == 'Contacted') {
                statusLabel = 'Waiting Quote';
                statusColor = Colors.orange;
                statusIcon = Icons.hourglass_empty_rounded;
              } else if (status == 'Accepted') {
                statusLabel = 'Quote Accepted';
                statusColor = Colors.teal;
                statusIcon = Icons.handshake_outlined;
              } else if (status == 'Closed' || status == 'Completed') {
                if (deliveryStatus == 'Delivered' || status == 'Completed') {
                  statusLabel = 'Closed Deal';
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle_outline_rounded;
                } else {
                  statusLabel = 'Ongoing ($deliveryStatus)';
                  statusColor = Colors.blue;
                  switch (deliveryStatus.toString().toLowerCase()) {
                    case 'packed':
                      statusIcon = Icons.inventory_2_outlined;
                      break;
                    case 'dispatched':
                      statusIcon = Icons.local_shipping_outlined;
                      break;
                    default:
                      statusIcon = Icons.hourglass_top_rounded;
                      break;
                  }
                }
              } else {
                statusLabel = status;
                statusColor = Colors.grey;
                statusIcon = Icons.info_outline;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.push('/b2b-materials'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: primaryColor.withValues(alpha: 0.1),
                                child: Icon(statusIcon, color: primaryColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Supplier: $supplierName • Qty: $quantityVal $unitStr',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.15), width: 1),
                                ),
                                child: Text(
                                  statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (status == 'Closed' || status == 'Completed') ...[
                            const SizedBox(height: 18),
                            // Delivery Steps
                            _buildDeliveryStepProgress(deliveryStatus, isDark, primaryColor),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDeliveryStepProgress(String currentStatus, bool isDark, Color primaryColor) {
    final statusLower = currentStatus.toLowerCase();
    
    int activeStep = 0;
    if (statusLower == 'packed') activeStep = 1;
    if (statusLower == 'dispatched') activeStep = 2;
    if (statusLower == 'delivered') activeStep = 3;

    final steps = ['Ordered', 'Packed', 'Dispatched', 'Delivered'];
    final stepIcons = [
      Icons.check_circle_rounded,
      Icons.inventory_2_rounded,
      Icons.local_shipping_rounded,
      Icons.done_all_rounded
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        final isCompleted = index <= activeStep;
        final isActive = index == activeStep;
        final color = isCompleted 
            ? (index == 3 ? Colors.green : primaryColor) 
            : (isDark ? Colors.white24 : Colors.grey.shade300);

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? color.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border.all(
                        color: color,
                        width: isActive ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(
                      stepIcons[index],
                      size: 12,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                      color: isCompleted 
                          ? (isDark ? Colors.white : Colors.black87) 
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              if (index < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: index < activeStep 
                        ? primaryColor 
                        : (isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOngoingProjectsSection(bool isDark, Color primaryColor) {
    final activeProjects = _projects.where((project) {
      final stage = (project['currentStage'] as String? ?? '').toLowerCase();
      return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ongoing Sites',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 18, 
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Track active construction stages',
                  style: TextStyle(
                    fontSize: 11, 
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => ref.read(mainTabProvider.notifier).state = 1, // index 1 (Projects screen)
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: primaryColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: primaryColor, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 12, color: primaryColor),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (activeProjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryColor.withValues(alpha: 0.06),
                  child: Icon(Icons.architecture_rounded, size: 30, color: primaryColor),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Construction Site',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start a new cost estimation and find contractor quotes!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          )
        else
          Column(
            children: activeProjects.map((project) {
              final tasks = project['tasks'] as List? ?? [];
              final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
              final totalCount = tasks.length;
              final currentStage = project['currentStage'] ?? 'Design & Planning';
              final quoteCount = project['_count']?['quotes'] as int? ?? 0;

              String stageText = currentStage;
              Color stageColor = Colors.blue;
              IconData stageIcon = Icons.construction_rounded;

              if (currentStage == 'Design & Planning') {
                if (quoteCount == 0) {
                  stageText = 'Awaiting Quotes';
                  stageColor = Colors.orange.shade700;
                  stageIcon = Icons.hourglass_empty_rounded;
                } else {
                  stageText = '$quoteCount Quotes';
                  stageColor = Colors.green.shade600;
                  stageIcon = Icons.mark_chat_unread_rounded;
                }
              } else {
                switch (currentStage.toLowerCase()) {
                  case 'completed':
                  case 'finished':
                    stageColor = Colors.green;
                    stageIcon = Icons.check_circle_rounded;
                    break;
                  case 'finished pending approval':
                    stageColor = Colors.amber.shade800;
                    stageIcon = Icons.rate_review_rounded;
                    break;
                  case 'on hold':
                    stageColor = Colors.orange;
                    stageIcon = Icons.pause_circle_filled_rounded;
                    break;
                  case 'cancelled':
                    stageColor = Colors.red;
                    stageIcon = Icons.cancel_rounded;
                    break;
                  default:
                    stageColor = Colors.blue;
                    stageIcon = Icons.construction_rounded;
                }
              }

              double progress = 0.0;
              if (totalCount > 0) {
                progress = completedCount / totalCount;
              } else {
                if (currentStage == 'Design & Planning') {
                  progress = quoteCount > 0 ? 0.25 : 0.05;
                } else if (currentStage == 'Tracking' || currentStage == 'Execution') {
                  progress = 0.5;
                } else if (currentStage == 'Finished Pending Approval') {
                  progress = 0.9;
                } else if (currentStage == 'Completed') {
                  progress = 1.0;
                } else {
                  progress = 0.15;
                }
              }

              final formattedBudget = NumberFormat.currency(
                locale: 'en_IN',
                symbol: '₹',
                decimalDigits: 0,
              ).format((project['budget'] as num? ?? 0.0).toDouble());

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.08) 
                        : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      await context.push('/project-detail/${project['id']}');
                      _fetchProjects();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Breathing Pulse Dot + Title
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: stageColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: stageColor.withValues(alpha: 0.4),
                                            blurRadius: 4,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        project['title'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900, 
                                          fontSize: 15.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stageColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: stageColor.withValues(alpha: 0.15), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(stageIcon, color: stageColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      stageText,
                                      style: TextStyle(
                                        color: stageColor, 
                                        fontWeight: FontWeight.w900, 
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Location & Budget Chips
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 13, color: Colors.red.shade400),
                                    const SizedBox(width: 3),
                                    Text(
                                      project['location'] ?? 'N/A',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.grey.shade700, 
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formattedBudget,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.green, 
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, thickness: 1, color: Colors.black12),
                          const SizedBox(height: 14),
                          // Progress Text Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalCount > 0 ? 'Tasks Completed: $completedCount/$totalCount' : 'Current Stage Progress',
                                style: TextStyle(
                                  fontSize: 11, 
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.w900, 
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Beautiful Modern Custom Gradient Linear Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(
                                  height: 6,
                                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryColor.withValues(alpha: 0.7),
                                          primaryColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildToolsSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workspace Console',
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 18, 
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Quick access building utilities',
              style: TextStyle(
                fontSize: 11, 
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _buildPremiumToolCard(
              context,
              title: 'Cost Estimator',
              subtitle: 'Compute build expense & rooms layout',
              icon: Icons.calculate_outlined,
              color: const Color(0xFF10B981),
              onTap: () => context.push('/cost-estimation'),
              isDark: isDark,
            ),
            _buildPremiumToolCard(
              context,
              title: 'Material Sourcing',
              subtitle: 'Direct builders wholesale pricing',
              icon: Icons.storefront_outlined,
              color: Colors.blueAccent,
              onTap: () => context.push('/b2b-products'),
              isDark: isDark,
            ),
            _buildPremiumToolCard(
              context,
              title: 'Material Quotes',
              subtitle: 'Track material requests & inquiries',
              icon: Icons.assignment_outlined,
              color: Colors.amber.shade800,
              onTap: () => context.push('/b2b-materials'),
              isDark: isDark,
            ),
            _buildPremiumToolCard(
              context,
              title: 'Market Trends',
              subtitle: 'Commodity price index & stats tracker',
              icon: Icons.trending_up_rounded,
              color: Colors.purple,
              onTap: () => context.push('/b2b-news'),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08) 
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Visual side indicator stripe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: Container(
                  color: color,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded, 
                          size: 14, 
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade500, 
                        fontSize: 9.5, 
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildRecentShowcasesSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Builder Showcases',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 18, 
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Recent projects completed by contractors',
                  style: TextStyle(
                    fontSize: 11, 
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => ref.read(mainTabProvider.notifier).state = 2, // index 2 (Services screen)
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: primaryColor.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'Explore Feed',
                    style: TextStyle(
                      color: primaryColor, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.feed_outlined, size: 12, color: primaryColor),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSocial)
          const Center(child: CircularProgressIndicator())
        else if (_socialPosts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No showcases found.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _socialPosts.length > 3 ? 3 : _socialPosts.length, // Show top 3
            itemBuilder: (context, index) {
              final post = _socialPosts[index];
              return _buildHomeSocialPostCard(post, isDark, primaryColor);
            },
          ),
      ],
    );
  }

  Widget _buildHomeSocialPostCard(dynamic post, bool isDark, Color primaryColor) {
    final provider = post['provider'] ?? {};
    final providerId = provider['id'] ?? '';
    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final category = provider['category'] ?? 'Contractor';
    final title = post['title'] ?? 'Work Showcase';
    final description = post['description'] ?? '';
    final imageData = post['imageData'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.08) 
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            InkWell(
              onTap: () {
                if (providerId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderProfileScreen(providerId: providerId),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      radius: 18,
                      child: Text(
                        businessName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: primaryColor, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                businessName,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8.5, 
                                color: primaryColor, 
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            // Main image
            if (imageData != null)
              InkWell(
                onTap: () {
                  if (providerId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderProfileScreen(providerId: providerId),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(Base64ImageCache.decode(imageData)),
                        fit: BoxFit.cover,
                      ),
                  ),
                ),
              ),

            // Actions & details
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDark ? Colors.white60 : Colors.grey.shade600, 
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
