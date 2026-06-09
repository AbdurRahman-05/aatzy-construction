import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
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
  String? _profileImage;
  List<dynamic> _projects = [];
  List<dynamic> _materialLeads = [];
  List<dynamic> _supplierProducts = [];
  bool _isLoading = true;
  int _dashboardTab = 0; // 0: General, 1: Finance
  int _selectedYear = 2026;

  @override
  void initState() {
    super.initState();
    _fetchStats();
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

        if (mounted) {
          setState(() {
            _stats = jsonDecode(res0.body);
            _projects = jsonDecode(res1.body);
            _materialLeads = matLeads;
            _profileData = profData;
            _profileImage = profImg;
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
    final businessName = _profileData?['businessName'] ?? auth.businessName ?? 'Your Business';
    final ownerName = _profileData?['ownerName'] ?? auth.name ?? 'Founder';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Premium transparent top app bar
                  SliverAppBar(
                    pinned: false,
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text(
                      'BuildMart Portal',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _fetchStats,
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Welcome Profile Banner Card
                        _buildWelcomeCard(businessName, ownerName, isDark, primaryColor),
                        const SizedBox(height: 20),

                        // Sliding Tab Selector
                        _buildPillTabSelector(isDark, primaryColor),
                        const SizedBox(height: 20),

                        // General Tab Content
                        if (_dashboardTab == 0) ...[
                          _buildGeneralOverviewSection(isDark, primaryColor),
                          const SizedBox(height: 24),
                          _buildActiveJobsSection(isDark, primaryColor),
                          const SizedBox(height: 24),
                          _buildRecentLeadsSection(isDark, primaryColor),
                          const SizedBox(height: 24),
                          _buildB2BToolsSection(isDark, primaryColor),
                          const SizedBox(height: 30),
                        ]
                        // Finance Tab Content
                        else ...[
                          _buildFinanceStats(totalRevenue, totalExpenses, totalProfit),
                          const SizedBox(height: 20),
                          _buildFinanceChart(),
                          const SizedBox(height: 24),
                          _buildProjectProfitabilitySection(isDark, primaryColor),
                          const SizedBox(height: 30),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(String businessName, String ownerName, bool isDark, Color primaryColor) {
    final avatarText = businessName.isNotEmpty ? businessName[0].toUpperCase() : 'B';
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F9B8E), const Color(0xFF0E5E6F)]
              : [const Color(0xFF064354), const Color(0xFF0B7C8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Photo with gradient ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                  ? MemoryImage(base64Decode(_profileImage!.split(',').last))
                  : null,
              child: _profileImage == null || _profileImage!.isEmpty
                  ? Text(
                      avatarText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Business details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Founder: $ownerName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabSelector(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _dashboardTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _dashboardTab == 0
                      ? primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: _dashboardTab == 0
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _dashboardTab == 0 ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade700),
                        fontSize: 13,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _dashboardTab == 1
                      ? primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      size: 18,
                      color: _dashboardTab == 1
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Financials',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _dashboardTab == 1 ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade700),
                        fontSize: 13,
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

  Widget _buildGeneralOverviewSection(bool isDark, Color primaryColor) {
    final activeLeadsCount = (_stats?['activeLeads'] ?? 0) + _materialLeads.length;
    final runningProjects = _projects.where((p) => p['currentStage'] != 'Completed').length;
    
    return Row(
      children: [
        Expanded(
          child: _buildGlowMetricCard(
            'Total Leads',
            '$activeLeadsCount',
            isDark ? const Color(0xFF0E5E6F) : const Color(0xFF007E8A),
            Icons.flash_on_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlowMetricCard(
            'Active Jobs',
            '$runningProjects',
            isDark ? const Color(0xFF3B6B4C) : const Color(0xFF2E7D32),
            Icons.assignment_turned_in_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildGlowMetricCard(String title, String count, Color baseColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: baseColor.withValues(alpha: 0.25),
                child: Icon(icon, color: baseColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: baseColor,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobsSection(bool isDark, Color primaryColor) {
    final activeJobs = (_stats?['activeJobs'] as List? ?? [])
        .where((job) => ![
              'completed',
              'finished',
              'finished pending approval',
              'cancelled'
            ].contains((job['currentStage'] as String? ?? '').toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Running Project Stages',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
            ),
            if (activeJobs.isNotEmpty)
              Text(
                '${activeJobs.length} active',
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeJobs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.celebration_rounded, size: 32, color: Colors.green),
                ),
                const SizedBox(height: 16),
                const Text(
                  'All Projects Executed!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Great job! There are no outstanding works on site. Check customer inquiries to start new ones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(providerTabProvider.notifier).setTab(2),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Explore Client Leads'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: activeJobs.map((job) {
              final stage = job['currentStage'] ?? 'Planning';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0.5,
                color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await context.push('/provider-job/${job['id']}');
                    _fetchStats();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.handyman_rounded, color: primaryColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Client: ${job['userName']}',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                stage,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStageProgressBar(stage),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStageProgressBar(String stage) {
    final stages = ['Planning', 'Foundation', 'Structure', 'Finishing', 'Completed'];
    final currentIdx = stages.indexWhere((s) => s.toLowerCase() == stage.toLowerCase());
    
    return Column(
      children: [
        Row(
          children: List.generate(stages.length, (idx) {
            final isDone = idx <= currentIdx;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDone ? Colors.green : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (idx < stages.length - 1) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stage: $stage', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
            const Text('Target: Completed', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentLeadsSection(bool isDark, Color primaryColor) {
    final List<Map<String, dynamic>> combinedLeads = [];
    final serviceLeads = _stats?['recentLeads'] as List? ?? [];
    
    for (final lead in serviceLeads) {
      combinedLeads.add({
        'isMaterial': false,
        'id': lead['id'],
        'title': lead['title'] ?? 'Service Project',
        'subtitle': 'By ${lead['userName'] ?? 'Client'}',
        'location': lead['location'] ?? 'N/A',
        'date': lead['createdAt'] != null ? DateTime.tryParse(lead['createdAt'].toString()) : null,
        'raw': lead,
      });
    }

    for (final lead in _materialLeads) {
      combinedLeads.add({
        'isMaterial': true,
        'id': lead['id'],
        'title': lead['title'] ?? lead['product_name'] ?? 'Material Requirement',
        'subtitle': 'By ${lead['buyer_name'] ?? 'Buyer Client'}',
        'location': lead['location'] ?? 'N/A',
        'date': lead['created_at'] != null ? DateTime.tryParse(lead['created_at'].toString()) : null,
        'raw': lead,
      });
    }

    combinedLeads.sort((a, b) {
      if (a['date'] == null && b['date'] == null) return 0;
      if (a['date'] == null) return 1;
      if (b['date'] == null) return -1;
      return b['date'].compareTo(a['date']);
    });

    final recentCombined = combinedLeads.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hot Market Enquiries',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        if (recentCombined.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No inquiries in your area at the moment.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
              ),
            ),
          )
        else
          Column(
            children: recentCombined.map((lead) {
              final isMaterial = lead['isMaterial'] as bool;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0.3,
                color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: isMaterial ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                    child: Icon(
                      isMaterial ? Icons.local_shipping_outlined : Icons.engineering_outlined,
                      color: isMaterial ? Colors.green : Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lead['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMaterial ? Colors.green.withValues(alpha: 0.08) : Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMaterial ? 'Material' : 'Service',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isMaterial ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.red.shade400),
                        const SizedBox(width: 2),
                        Text(
                          lead['location'],
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          lead['subtitle'],
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    if (isMaterial) {
                      context.push('/supplier-leads');
                    } else {
                      context.push('/provider-lead/${lead['id']}');
                    }
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildB2BToolsSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier Management Console',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3C72).withValues(alpha: 0.8), const Color(0xFF2A5298).withValues(alpha: 0.8)]
                        : [Colors.blue.shade800, Colors.blue.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/supplier-products'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 28, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _supplierProducts.isNotEmpty ? 'My Products (${_supplierProducts.length})' : 'My Products',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Update rates & items',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F9B8E).withValues(alpha: 0.8), const Color(0xFF0D7A71).withValues(alpha: 0.8)]
                        : [const Color(0xFF064354), const Color(0xFF0C8A9B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/supplier-leads'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.inbox_rounded, size: 28, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text(
                            'Material Leads',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submit B2B quotes',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Total Revenue',
                '₹${revenue.toStringAsFixed(0)}',
                Colors.blue,
                Icons.trending_up_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Est. Expenses',
                '₹${expenses.toStringAsFixed(0)}',
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
                '₹${profit.toStringAsFixed(0)}',
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Profit & Revenue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isDense: true,
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 13),
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
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                              style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 12),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProjectProfitabilitySection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project-wise Profitability',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        if (_projects.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
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

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0.3,
                color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    await context.push('/provider-job/${proj['id']}');
                    _fetchStats();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                stage,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
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
                                  const Text('Quoted Cost', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Cost', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('₹${expenses.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isProfit ? 'Profit' : 'Loss', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${isProfit ? "+" : ""}₹${profit.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isProfit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Materials: ₹${materials.toStringAsFixed(0)} • Labor: ₹${labor.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${margin.toStringAsFixed(1)}% Margin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isProfit ? Colors.green : Colors.red,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
