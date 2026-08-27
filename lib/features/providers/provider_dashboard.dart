import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/providers/notifications_provider.dart';
import '../auth/auth_provider.dart';
import '../b2b/services/b2b_api_service.dart';
import 'provider_layout.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _profileData;
  Uint8List? _cachedProfileImageBytes;
  List<dynamic> _projects = [];
  List<dynamic> _materialLeads = [];
  List<dynamic> _supplierProducts = [];
  bool _isLoading = true;
  int _dashboardTab = 0; // 0: Overview, 1: Financials
  int _selectedYear = 2026;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchStats() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats')),
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/projects')),
        http.get(Uri.parse('$apiBaseUrl/supplier/leads?supplierId=${auth.id}')),
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/profile')),
        B2BApiService().get('/supplier/products', queryParameters: {'supplierId': auth.id!}),
      ]);

      final res0 = responses[0] as http.Response;
      final res1 = responses[1] as http.Response;
      final res2 = responses[2] as http.Response;
      final res3 = responses[3] as http.Response;
      final resProds = responses[4] as B2BApiResponse;

      if (res0.statusCode == 200 && res1.statusCode == 200) {
        List<dynamic> matLeads = [];
        if (res2.statusCode == 200) {
          final decoded = jsonDecode(res2.body);
          matLeads = decoded['leads'] ?? [];
        }

        Map<String, dynamic>? profData;
        String? profImg;
        if (res3.statusCode == 200) {
          profData = jsonDecode(res3.body)['provider'];
          profImg = profData?['profileImage'];
        }

        List<dynamic> prodsList = [];
        if (resProds.success && resProds.data != null) {
          prodsList = resProds.data['products'] ?? [];
        }

        Uint8List? cachedBytes;
        if (profImg != null && profImg.isNotEmpty) {
          try {
            cachedBytes = base64Decode(profImg.split(',').last);
          } catch (e) {
            debugPrint('Error decoding profile image: $e');
          }
        }

        if (mounted) {
          setState(() {
            _stats = jsonDecode(res0.body);
            _projects = jsonDecode(res1.body);
            _materialLeads = matLeads;
            _profileData = profData;
            _cachedProfileImageBytes = cachedBytes;
            _supplierProducts = prodsList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);
    final businessName = _profileData?['businessName'] ?? auth.businessName ?? 'local traders';
    final ownerName = _profileData?['ownerName'] ?? auth.name ?? 'test';
    final avgRating = (_profileData?['avgRating'] ?? 4.8) as num;
    final reviewCount = (_profileData?['reviewCount'] ?? 120) as num;

    // Calculate financials
    double totalRevenue = 0.0;
    double totalMaterialExpenses = 0.0;
    double totalLaborExpenses = 0.0;

    for (final project in _projects) {
      final tasks = project['tasks'] as List? ?? [];
      double projRevenue = 0.0;
      double projMaterials = 0.0;
      for (final t in tasks) {
        projRevenue += (t['quotedCost'] as num? ?? 0.0).toDouble();
        projMaterials += (t['taskCost'] as num? ?? 0.0).toDouble();
      }
      final projLabor = projRevenue * 0.12; // 12% labor cost estimate

      totalRevenue += projRevenue;
      totalMaterialExpenses += projMaterials;
      totalLaborExpenses += projLabor;
    }

    final totalExpenses = totalMaterialExpenses + totalLaborExpenses;
    final totalProfit = totalRevenue - totalExpenses;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;

    final notifications = ref.watch(notificationsProvider);
    final unreadNotifs = notifications.where((n) => n.isUnread).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _isLoading ? null : AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () {},
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/logo.png',
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.apartment_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'BuildMart Console',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with dynamic unread counter badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadNotifs',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // User Avatar with green online dot
          GestureDetector(
            onTap: () => ref.read(providerTabProvider.notifier).setTab(4),
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 4),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: _cachedProfileImageBytes != null
                        ? MemoryImage(_cachedProfileImageBytes!)
                        : null,
                    child: _cachedProfileImageBytes == null
                        ? Text(
                            businessName.isNotEmpty ? businessName[0].toUpperCase() : 'P',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 14),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12.0 : 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Hero Provider Welcome Banner Card
                      _buildHeroWelcomeCard(
                        businessName: businessName,
                        ownerName: ownerName,
                        avgRating: avgRating,
                        reviewCount: reviewCount,
                        isSmallScreen: isSmallScreen,
                      ),
                      const SizedBox(height: 16),

                      // 2. Material Sourcing Sales Carousel Banner (Self-contained, smooth, zero re-render)
                      MaterialSourcingCarouselWidget(isSmallScreen: isSmallScreen),
                      const SizedBox(height: 16),

                      // 3. Segmented Switcher (Overview vs Financials)
                      _buildSegmentedPillSwitcher(isSmallScreen),
                      const SizedBox(height: 16),

                      // Overview Tab Content
                      if (_dashboardTab == 0) ...[
                        // 4. 3 Key Metrics Row (Active Leads, Active Jobs, Ongoing Deals)
                        _buildKeyMetricsRow(isSmallScreen),
                        const SizedBox(height: 20),

                        // 5. Running Project Stages Timeline Card
                        _buildRunningProjectStagesCard(isSmallScreen),
                        const SizedBox(height: 20),

                        // 6. Two Column Cards: Ongoing Deals & Hot Market Enquiries
                        _buildDealsAndEnquiriesRow(isSmallScreen, screenWidth),
                        const SizedBox(height: 20),

                        // 7. Supplier Management Console
                        _buildSupplierManagementConsole(isSmallScreen),
                        const SizedBox(height: 32),
                      ]
                      // Financials Tab Content
                      else ...[
                        _buildFinanceStats(totalRevenue, totalExpenses, totalProfit),
                        const SizedBox(height: 20),
                        _buildFinanceChart(),
                        const SizedBox(height: 24),
                        _buildProjectProfitabilitySection(isDark, primaryColor),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  // ==========================================
  // 1. HERO PROVIDER WELCOME BANNER CARD
  // ==========================================
  Widget _buildHeroWelcomeCard({
    required String businessName,
    required String ownerName,
    required num avgRating,
    required num reviewCount,
    required bool isSmallScreen,
  }) {
    final auth = ref.read(authProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A5C67), Color(0xFF0D7A87), Color(0xFF0A5C67)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A5C67).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Circular Team / Business Avatar with online green check badge
          Stack(
            children: [
              Container(
                width: isSmallScreen ? 56 : 68,
                height: isSmallScreen ? 56 : 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                ),
                child: ClipOval(
                  child: _cachedProfileImageBytes != null
                      ? Image.memory(
                          _cachedProfileImageBytes!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/banner_building.jpg',
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/banner_building.jpg',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),

          // Center: Business details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'PORTAL ACTIVE • VERIFIED PROVIDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  businessName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 15 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  'User: $ownerName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: isSmallScreen ? 10.5 : 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${avgRating.toStringAsFixed(1)} ($reviewCount)',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'Jan 2023',
                          style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Right: Verified Badge + View Profile Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 12),
                  SizedBox(width: 3),
                  Text(
                    'Verified',
                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (auth.id != null) {
                    context.push('/provider-profile/${auth.id}');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF063E46),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View Profile',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. SEGMENTED SWITCHER (Overview vs Financials)
  // ==========================================
  Widget _buildSegmentedPillSwitcher(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dashboardTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _dashboardTab == 0 ? const Color(0xFFF1F5F9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      size: 16,
                      color: _dashboardTab == 0 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _dashboardTab == 0 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dashboardTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _dashboardTab == 1 ? const Color(0xFFF1F5F9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: _dashboardTab == 1 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Financials',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: _dashboardTab == 1 ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. 3 KEY METRIC STAT CARDS
  // ==========================================
  Widget _buildKeyMetricsRow(bool isSmallScreen) {
    final activeMaterialLeadsCount = _materialLeads.where((lead) {
      final status = lead['status'] ?? 'New';
      return ['New', 'Viewed', 'Contacted', 'Quote Sent'].contains(status);
    }).length;
    final activeLeadsCount = (_stats?['activeLeads'] ?? 0) + activeMaterialLeadsCount;

    final ongoingMaterialJobsCount = _materialLeads.where((lead) {
      final status = lead['status'] ?? 'New';
      final deliveryStatus = lead['delivery_status'] ?? 'Pending';
      return status == 'Accepted' || (status == 'Closed' && deliveryStatus != 'Delivered');
    }).length;

    final runningProjects = _projects.where((p) {
      final stage = (p['currentStage'] as String? ?? '').toLowerCase().trim();
      return !['completed', 'finished', 'cancelled'].contains(stage);
    }).length;
    final activeJobsCount = runningProjects + ongoingMaterialJobsCount;

    final ongoingDealsCount = ongoingMaterialJobsCount;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'ACTIVE LEADS',
            value: '$activeLeadsCount',
            subtitle: 'Inquiries listed',
            icon: Icons.people_alt_outlined,
            iconColor: const Color(0xFF0F766E),
            iconBg: const Color(0xFFCCFBF1),
            cardBg: Colors.white,
            onTap: () => ref.read(providerTabProvider.notifier).setTab(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'ACTIVE JOBS',
            value: '$activeJobsCount',
            subtitle: 'Sites under work',
            icon: Icons.business_center_outlined,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            cardBg: Colors.white,
            onTap: () => ref.read(providerTabProvider.notifier).setTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'ONGOING DEALS',
            value: '$ongoingDealsCount',
            subtitle: 'Active orders',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
            cardBg: Colors.white,
            onTap: () => context.push('/b2b-materials'),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color cardBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 5. RUNNING PROJECT STAGES TIMELINE CARD
  // ==========================================
  Widget _buildRunningProjectStagesCard(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Running Project Stages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          const Text(
            'Track site progress timeline',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Stepper Row with Building Illustration
          Row(
            children: [
              // 4-Step Stepper
              Expanded(
                flex: 7,
                child: Row(
                  children: [
                    _buildMilestoneItem('Planning', Icons.architecture_rounded, 'Completed', const Color(0xFF10B981), isSmallScreen),
                    _buildMilestoneConnector(true),
                    _buildMilestoneItem('Execution', Icons.apartment_rounded, 'Completed', const Color(0xFF10B981), isSmallScreen),
                    _buildMilestoneConnector(true),
                    _buildMilestoneItem('Finishing', Icons.person_outline_rounded, 'In Progress', const Color(0xFF2563EB), isSmallScreen),
                    _buildMilestoneConnector(false),
                    _buildMilestoneItem('Handover', Icons.flag_outlined, 'Upcoming', const Color(0xFF94A3B8), isSmallScreen),
                  ],
                ),
              ),

              // Right: Construction Site Graphic with Crane
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/crane_3d.jpg',
                    height: 70,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.apartment_rounded, size: 55, color: Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Project Status Sub-Card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.celebration_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'All Projects Executed!',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Great job! There are no outstanding works on site. Check customer inquiries to start new ones.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => ref.read(providerTabProvider.notifier).setTab(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A5C67),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Explore Client Leads',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
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
    );
  }

  Widget _buildMilestoneItem(String label, IconData icon, String status, Color statusColor, bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 26 : 30,
          height: isSmallScreen ? 26 : 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor.withValues(alpha: 0.1),
            border: Border.all(color: statusColor, width: 1.5),
          ),
          child: Icon(icon, size: isSmallScreen ? 13 : 15, color: statusColor),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            status,
            style: TextStyle(
              fontSize: isSmallScreen ? 7.5 : 8.5,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 24),
        color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
      ),
    );
  }

  // ==========================================
  // 6. TWO COLUMN CARDS: ONGOING DEALS & HOT MARKET ENQUIRIES (Equal Heights)
  // ==========================================
  Widget _buildDealsAndEnquiriesRow(bool isSmallScreen, double screenWidth) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Ongoing Deals Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Ongoing Deals',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/b2b-materials'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('View All', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_rounded, size: 7.5, color: Color(0xFF2563EB)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 24,
                        child: const Text(
                          'Track in-progress processes and shipments',
                          style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Truck Graphic & Empty State
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF64748B), size: 26),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No Ongoing Deals',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 34,
                          child: const Text(
                            'Active material negotiations and shipments will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Right: Hot Market Enquiries Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hot Market Enquiries',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 24,
                        child: const Text(
                          'Opportunities in your service areas',
                          style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Graphic & Empty State
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.saved_search_rounded, color: Color(0xFF2563EB), size: 26),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No inquiries in your area',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 34,
                          child: const Text(
                            "We'll notify you when new opportunities are available.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 7. SUPPLIER MANAGEMENT CONSOLE
  // ==========================================
  Widget _buildSupplierManagementConsole(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier Management Console',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 2),
        const Text(
          'Utilities to update items and quotes',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Card 1: My Products (Soft Blue)
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/supplier-products'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _supplierProducts.isNotEmpty ? 'My Products (${_supplierProducts.length})' : 'My Products',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Update rates & items',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Card 2: Material Leads (Soft Green)
            Expanded(
              child: GestureDetector(
                onTap: () => context.push('/b2b-materials'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.description_outlined, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Material Leads',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Submit B2B quotes',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF065F46),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceStats(double revenue, double expenses, double profit) {
    final double profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    
    final formattedRevenue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(revenue);
    final formattedExpenses = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(expenses);
    final formattedProfit = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(profit);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Total Revenue',
                formattedRevenue,
                Colors.blue,
                Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Est. Expenses',
                formattedExpenses,
                Colors.orange,
                Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Net Profit',
                formattedProfit,
                Colors.green,
                Icons.currency_rupee_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Profit Margin',
                '${profitMargin.toStringAsFixed(1)}%',
                Colors.purple,
                Icons.percent_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceCard(String title, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyProfits = List<double>.filled(12, 0.0);
    final monthlyRevenues = List<double>.filled(12, 0.0);

    for (final project in _projects) {
      final createdAtStr = project['createdAt'] as String?;
      if (createdAtStr == null) continue;
      final dt = DateTime.tryParse(createdAtStr);
      if (dt == null || dt.year != _selectedYear) continue;

      final tasks = project['tasks'] as List? ?? [];
      double revenue = 0.0;
      double materialCost = 0.0;
      for (final t in tasks) {
        revenue += (t['quotedCost'] as num? ?? 0.0).toDouble();
        materialCost += (t['taskCost'] as num? ?? 0.0).toDouble();
      }
      final laborCost = revenue * 0.12;
      final profit = revenue - (materialCost + laborCost);

      monthlyProfits[dt.month - 1] += profit;
      monthlyRevenues[dt.month - 1] += revenue;
    }

    double maxVal = 1000.0;
    for (int i = 0; i < 12; i++) {
      if (monthlyProfits[i] > maxVal) maxVal = monthlyProfits[i];
      if (monthlyRevenues[i] > maxVal) maxVal = monthlyRevenues[i];
    }
    maxVal = (maxVal * 1.15).clamp(100.0, double.infinity);

    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Profit & Revenue',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isDense: true,
                      style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, fontSize: 12.5),
                      items: [2025, 2026, 2027].map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = monthNames[group.x.toInt()];
                        final String type = rodIndex == 0 ? 'Revenue' : 'Profit';
                        return BarTooltipItem(
                          '$month\n$type: ₹${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 12) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthNames[idx],
                              style: const TextStyle(color: Colors.grey, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthlyRevenues[index],
                          color: Colors.blue.shade400,
                          width: 5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: monthlyProfits[index],
                          color: Colors.green.shade400,
                          width: 5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegendIndicator(Colors.blue.shade400, 'Quoted Revenue'),
                const SizedBox(width: 24),
                _buildChartLegendIndicator(Colors.green.shade400, 'Est. Net Profit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProjectProfitabilitySection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project-wise Profitability',
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 18, 
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Finance overview across active works',
              style: TextStyle(
                fontSize: 11, 
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_projects.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No project financials recorded yet.'),
            ),
          )
        else
          Column(
            children: _projects.map((proj) {
              final title = proj['title'] ?? 'N/A';
              final stage = proj['currentStage'] ?? 'N/A';
              final tasks = proj['tasks'] as List? ?? [];
              double revenue = 0.0;
              double materials = 0.0;
              for (final t in tasks) {
                revenue += (t['quotedCost'] as num? ?? 0.0).toDouble();
                materials += (t['taskCost'] as num? ?? 0.0).toDouble();
              }
              final labor = revenue * 0.12;
              final expenses = materials + labor;
              final profit = revenue - expenses;
              final isProfit = profit >= 0;
              final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

              final formattedRevenue = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(revenue);
              final formattedExpenses = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(expenses);
              final formattedProfit = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(profit.abs());

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
                      color: Colors.black.withValues(alpha: 0.02),
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
                      await context.push('/provider-job/${proj['id']}');
                      _fetchStats();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  stage.toUpperCase(),
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('QUOTED COST', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text(formattedRevenue, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blue)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TOTAL COST', style: TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text(formattedExpenses, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.orange)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isProfit ? 'PROFIT' : 'LOSS', style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${isProfit ? "+" : "-"}$formattedProfit',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: isProfit ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Materials: ₹${materials.toStringAsFixed(0)} • Labor: ₹${labor.toStringAsFixed(0)}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${margin.toStringAsFixed(1)}% Margin',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: isProfit ? Colors.green : Colors.red,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
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
}

class MaterialSourcingCarouselWidget extends StatefulWidget {
  final bool isSmallScreen;
  const MaterialSourcingCarouselWidget({super.key, required this.isSmallScreen});

  @override
  State<MaterialSourcingCarouselWidget> createState() => _MaterialSourcingCarouselWidgetState();
}

class _MaterialSourcingCarouselWidgetState extends State<MaterialSourcingCarouselWidget> {
  int _carouselIndex = 0;
  final PageController _carouselPageController = PageController();
  Timer? _carouselTimer;

  final List<Map<String, dynamic>> slides = const [
    {
      'tag': 'B2B MERCHANT',
      'title': 'Material Sourcing Sales',
      'desc': 'List materials on BuildMart and secure bulk wholesale orders directly.',
      'btn': 'Manage Materials',
      'route': '/supplier-products',
      'colors': [Color(0xFFEA580C), Color(0xFFF59E0B)],
      'icon': Icons.shopping_cart_rounded,
    },
    {
      'tag': 'BULK SUPPLY',
      'title': 'Wholesale Procurement',
      'desc': 'Direct factory prices with scheduled bulk supply for project sites.',
      'btn': 'Explore B2B Leads',
      'route': '/b2b-materials',
      'colors': [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      'icon': Icons.local_shipping_rounded,
    },
    {
      'tag': 'VERIFIED BUILDER',
      'title': 'Showcase Your Projects',
      'desc': 'Upload photos of completed sites to get inquiries from premium clients.',
      'btn': 'Post Showcase',
      'route': '/services',
      'colors': [Color(0xFF0F766E), Color(0xFF14B8A6)],
      'icon': Icons.architecture_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselPageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselPageController.hasClients && mounted) {
        final nextPage = (_carouselIndex + 1) % slides.length;
        _carouselPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.isSmallScreen ? 162 : 168,
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (idx) {
              if (mounted) setState(() => _carouselIndex = idx);
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              final colors = slide['colors'] as List<Color>;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 12 : 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Center Content Details
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              slide['tag'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            slide['desc'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9.5,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => context.push(slide['route'] as String),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slide['btn'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFF0F172A)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: 3D Illustration Icon in Concentric Circles
                    Expanded(
                      flex: 4,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.95),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 28,
                              color: colors.first,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (idx) {
            final isSelected = _carouselIndex == idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: isSelected ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

