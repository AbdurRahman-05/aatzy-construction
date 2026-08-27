import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../auth/auth_provider.dart';

class ProviderProjectsScreen extends ConsumerStatefulWidget {
  const ProviderProjectsScreen({super.key});

  @override
  ConsumerState<ProviderProjectsScreen> createState() => _ProviderProjectsScreenState();
}

class _ProviderProjectsScreenState extends ConsumerState<ProviderProjectsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _projects = [];
  bool _isLoading = true;
  String _searchQuery = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchProjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/projects'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _projects = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching provider projects: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _filterProjectsByStage(List<String> stages) {
    return _projects.where((project) {
      final stage = (project['currentStage'] as String? ?? 'Design & Planning').toLowerCase();
      final title = (project['title'] as String? ?? '').toLowerCase();
      final location = (project['location'] as String? ?? '').toLowerCase();
      final clientName = (project['user']?['name'] as String? ?? '').toLowerCase();
      
      final matchesStage = stages.any((s) => s.toLowerCase() == stage);
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || 
                            location.contains(_searchQuery.toLowerCase()) ||
                            clientName.contains(_searchQuery.toLowerCase());
      
      return matchesStage && matchesSearch;
    }).toList();
  }

  Widget _buildProjectCard(BuildContext context, dynamic project, {required bool isSmallScreen, bool isGrid = false}) {
    final title = project['title'] ?? 'Untitled Job';
    final currentStage = project['currentStage'] ?? 'Design & Planning';
    final budget = (project['budget'] as num? ?? 0.0).toDouble();
    final location = project['location'] ?? 'N/A';
    final projectId = project['id']?.toString() ?? '';
    final clientName = project['user']?['name'] ?? 'Client';
    
    final tasks = project['tasks'] as List? ?? [];
    final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasks.length;

    final isCompleted = currentStage.toString().toLowerCase() == 'completed' || currentStage.toString().toLowerCase() == 'finished';
    final isCancelled = currentStage.toString().toLowerCase() == 'cancelled';
    final isPendingApproval = currentStage.toString().toLowerCase() == 'finished pending approval';
    
    final int colorIndex = projectId.hashCode.abs() % 3;
    final List<Color> colors = [const Color(0xFF10B981), const Color(0xFF0F766E), const Color(0xFF3B82F6)];
    final Color cardColor = isCancelled ? const Color(0xFFEF4444) : (isCompleted ? const Color(0xFF10B981) : colors[colorIndex]);
    final IconData icon = [Icons.business_center_rounded, Icons.apartment_rounded, Icons.construction_rounded][colorIndex];

    double progress = 0.0;
    if (totalCount > 0) {
      progress = completedCount / totalCount;
    } else {
      if (currentStage == 'Design & Planning') {
        progress = 0.15;
      } else if (currentStage == 'Tracking' || currentStage == 'Execution') {
        progress = 0.5;
      } else if (currentStage == 'Finished Pending Approval') {
        progress = 0.9;
      } else if (currentStage == 'Completed' || currentStage == 'Finished') {
        progress = 1.0;
      } else {
        progress = 0.25;
      }
    }

    String dateStr = 'Active';
    if (isCompleted || isCancelled || isPendingApproval) {
      final updated = project['updatedAt'] ?? project['updated_at'];
      if (updated != null) {
        dateStr = updated.toString().split('T')[0];
      } else {
        dateStr = isCompleted ? 'Finished' : (isPendingApproval ? 'In Review' : 'Cancelled');
      }
    }

    final leftBarWidth = isSmallScreen ? 74.0 : 86.0;

    return GestureDetector(
      onTap: () async {
        await context.push('/provider-job/${project['id']}');
        _fetchProjects();
      },
      child: Container(
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(color: cardColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column (Color Block & Progress)
              Container(
                width: leftBarWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cardColor.withValues(alpha: 0.85), cardColor],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 5 : 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 22),
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      'DONE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: isSmallScreen ? 7.5 : 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Right Column (Details)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top: Title & Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isSmallScreen ? 13.5 : 15,
                                    color: const Color(0xFF1E1E2D),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 3),
                                    Text(
                                      clientName,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.location_on_rounded, size: 11, color: Colors.grey.shade400),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? Colors.red.shade50
                                  : (isCompleted
                                      ? Colors.green.shade50
                                      : (isPendingApproval ? Colors.amber.shade50 : const Color(0xFFEEF2FF))),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCancelled
                                    ? Colors.red.shade200
                                    : (isCompleted
                                        ? Colors.green.shade200
                                        : (isPendingApproval ? Colors.amber.shade300 : const Color(0xFFC7D2FE))),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCancelled
                                      ? Icons.cancel_rounded
                                      : (isCompleted
                                          ? Icons.check_circle_rounded
                                          : (isPendingApproval ? Icons.rate_review_rounded : Icons.sync_rounded)),
                                  color: isCancelled
                                      ? Colors.red
                                      : (isCompleted
                                          ? Colors.green.shade700
                                          : (isPendingApproval ? Colors.amber.shade900 : const Color(0xFF4F46E5))),
                                  size: 10,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isCancelled
                                      ? 'Cancelled'
                                      : (isCompleted
                                          ? 'Finished'
                                          : (isPendingApproval ? 'Pending' : 'Ongoing')),
                                  style: TextStyle(
                                    color: isCancelled
                                        ? Colors.red
                                        : (isCompleted
                                            ? Colors.green.shade700
                                            : (isPendingApproval ? Colors.amber.shade900 : const Color(0xFF4F46E5))),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Bottom: Budget & Deadline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('CONTRACT VALUE',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 1),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('₹ ${budget.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: isSmallScreen ? 11.5 : 12.5,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 6), color: Colors.grey.shade200),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('STAGE',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_rounded, size: 10, color: Colors.grey.shade600),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            dateStr,
                                            style: TextStyle(
                                                color: Colors.grey.shade800,
                                                fontSize: isSmallScreen ? 10 : 11,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsTab(String title, List<String> stages, double screenWidth) {
    final filtered = _filterProjectsByStage(stages);

    double totalValue = 0.0;
    for (var p in filtered) {
      totalValue += (p['budget'] as num? ?? 0.0).toDouble();
    }
    
    if (filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No projects found in this category',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isSmall = availableWidth < 380;
        
        int crossAxisCount = 1;
        if (availableWidth >= 1050) {
          crossAxisCount = 3;
        } else if (availableWidth >= 660) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final horizontalPadding = availableWidth >= 700 ? 24.0 : (isSmall ? 12.0 : 16.0);

        return RefreshIndicator(
          onRefresh: _fetchProjects,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmall ? 10 : 14,
                      vertical: isSmall ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: isSmall ? 16 : 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: isSmall ? 12.5 : 13.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${filtered.length}',
                            style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: isSmall ? 10 : 11, fontWeight: FontWeight.w500),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '₹${totalValue.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: isSmall ? 13 : 14, color: Colors.green.shade800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: crossAxisCount > 1
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 148,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProjectCard(context, filtered[index], isSmallScreen: isSmall, isGrid: true),
                          childCount: filtered.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProjectCard(context, filtered[index], isSmallScreen: isSmall, isGrid: false),
                          childCount: filtered.length,
                        ),
                      ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabItem(IconData icon, String label, int count, Color color, {required bool isSmallScreen}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 14 : 16, color: Colors.black87),
          SizedBox(width: isSmallScreen ? 4 : 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmallScreen ? 11.5 : 13, color: Colors.black87)),
          SizedBox(width: isSmallScreen ? 6 : 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(count.toString(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ongoingCount = _projects.where((p) => !['completed', 'finished', 'cancelled', 'finished pending approval'].contains((p['currentStage'] as String? ?? '').toLowerCase())).length;
    final pendingCount = _projects.where((p) => (p['currentStage'] as String? ?? '').toLowerCase() == 'finished pending approval').length;
    final finishedCount = _projects.where((p) => ['completed', 'finished'].contains((p['currentStage'] as String? ?? '').toLowerCase())).length;
    final cancelledCount = _projects.where((p) => (p['currentStage'] as String? ?? '').toLowerCase() == 'cancelled').length;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isTabletOrLaptop = screenWidth >= 700;
    final horizontalPadding = isTabletOrLaptop ? 24.0 : (isSmallScreen ? 12.0 : 16.0);

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Banner
                        Container(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, isSmallScreen ? 12 : 18, horizontalPadding, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PROJECTS & JOBS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0F766E), letterSpacing: 1.2)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'My Projects',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 22 : (isTabletOrLaptop ? 32 : 28),
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF1E1E2D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Track and manage all your assigned construction jobs.',
                                      style: TextStyle(fontSize: isSmallScreen ? 11.5 : 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Image.asset(
                                'assets/images/build_plan_achieve.jpg',
                                height: isSmallScreen ? 65 : (isTabletOrLaptop ? 100 : 85),
                                width: isSmallScreen ? 65 : (isTabletOrLaptop ? 100 : 85),
                                fit: BoxFit.contain,
                                color: const Color(0xFFF9FAFB),
                                colorBlendMode: BlendMode.darken,
                                errorBuilder: (context, error, stackTrace) => SizedBox(height: isSmallScreen ? 65 : 85, width: isSmallScreen ? 65 : 85),
                              ),
                            ],
                          ),
                        ),

                        // Custom TabBar
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          height: isSmallScreen ? 38 : 42,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            dividerColor: Colors.transparent,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                            tabs: [
                              Tab(child: _buildTabItem(Icons.play_arrow_rounded, 'Ongoing', ongoingCount, const Color(0xFF0F766E), isSmallScreen: isSmallScreen)),
                              Tab(child: _buildTabItem(Icons.access_time_rounded, 'Pending', pendingCount, Colors.orange, isSmallScreen: isSmallScreen)),
                              Tab(child: _buildTabItem(Icons.check_circle_rounded, 'Finished', finishedCount, Colors.green, isSmallScreen: isSmallScreen)),
                              Tab(child: _buildTabItem(Icons.cancel_rounded, 'Cancelled', cancelledCount, Colors.red, isSmallScreen: isSmallScreen)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Search and Filter Bar
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: TextField(
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: isSmallScreen ? 'Search jobs...' : 'Search jobs by title, client, or site...',
                                      hintStyle: TextStyle(fontSize: isSmallScreen ? 11.5 : 13),
                                      prefixIcon: const Icon(Icons.search, size: 18),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 42,
                                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCFBF1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_list, size: 16, color: Color(0xFF0F766E)),
                                    if (!isSmallScreen) ...[
                                      const SizedBox(width: 6),
                                      const Text('Filter', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProjectsTab('Ongoing Jobs', ['Design & Planning', 'Tracking', 'Execution', 'On Hold'], screenWidth),
                              _buildProjectsTab('Pending Client Approval', ['Finished Pending Approval'], screenWidth),
                              _buildProjectsTab('Finished Jobs', ['Completed', 'Finished'], screenWidth),
                              _buildProjectsTab('Cancelled Jobs', ['Cancelled'], screenWidth),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
