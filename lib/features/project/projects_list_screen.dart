import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/wallpaper_background.dart';
import '../../core/providers/projects_provider.dart';
import '../auth/auth_provider.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = "";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProjects();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    final auth = ref.read(authProvider);
    if (auth.id != null) {
      ref.invalidate(userProjectsProvider(auth.id!));
    }
  }

  List<dynamic> _filterProjectsByStage(List<String> stages, List<dynamic> projects) {
    return projects.where((project) {
      final stage = (project['currentStage'] as String? ?? 'Design & Planning').toLowerCase();
      final title = (project['title'] as String? ?? '').toLowerCase();
      final location = (project['location'] as String? ?? '').toLowerCase();
      
      final matchesStage = stages.any((s) => s.toLowerCase() == stage);
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || 
                            location.contains(_searchQuery.toLowerCase());
      
      return matchesStage && matchesSearch;
    }).toList();
  }

  Widget _buildProjectCard(BuildContext context, dynamic project, {required bool isSmallScreen, bool isGrid = false}) {
    final title = project['title'] ?? 'N/A';
    final currentStage = project['currentStage'] ?? 'Design & Planning';
    final budget = project['budget']?.toString() ?? '10,000';
    final location = project['location'] ?? 'N/A';
    final projectId = project['id']?.toString() ?? '';
    final quoteCount = project['_count']?['quotes'] as int? ?? 0;
    
    final tasks = project['tasks'] as List? ?? [];
    final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasks.length;

    final isCompleted = currentStage.toString().toLowerCase() == 'completed' || currentStage.toString().toLowerCase() == 'finished';
    final isCancelled = currentStage.toString().toLowerCase() == 'cancelled';
    
    final int colorIndex = projectId.hashCode.abs() % 3;
    final List<Color> colors = [const Color(0xFF10B981), const Color(0xFF3B82F6), const Color(0xFF8B5CF6)];
    final Color cardColor = isCancelled ? const Color(0xFFEF4444) : (isCompleted ? colors[colorIndex] : const Color(0xFF10B981));
    final IconData icon = [Icons.home_rounded, Icons.business_rounded, Icons.storefront_rounded][colorIndex];

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
      } else if (currentStage == 'Completed' || currentStage == 'Finished') {
        progress = 1.0;
      } else {
        progress = 0.15;
      }
    }

    String dateStr = 'Upcoming';
    if (isCompleted || isCancelled) {
      final updated = project['updatedAt'] ?? project['updated_at'];
      if (updated != null) {
        dateStr = updated.toString().split('T')[0];
      } else {
        dateStr = isCompleted ? 'Finished' : 'Cancelled';
      }
    }

    final leftBarWidth = isSmallScreen ? 74.0 : 86.0;

    return GestureDetector(
      onTap: () async {
        await context.push('/project-detail/${project['id']}');
        _fetchProjects();
      },
      child: Container(
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(color: cardColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: isSmallScreen ? 20 : 24),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 18 : 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    'DONE',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: isSmallScreen ? 7.5 : 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
            // Right Column (Details)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 11,
                  vertical: isSmallScreen ? 7 : 8,
                ),
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
                                  Icon(Icons.location_on_rounded, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 3),
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
                            color: isCancelled ? Colors.red.shade50 : (isCompleted ? Colors.green.shade50 : Colors.indigo.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isCancelled ? Colors.red.shade200 : (isCompleted ? Colors.green.shade200 : Colors.indigo.shade200), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCancelled ? Icons.cancel_rounded : (isCompleted ? Icons.check_circle_rounded : Icons.sync_rounded), 
                                color: isCancelled ? Colors.red : (isCompleted ? Colors.green.shade700 : Colors.indigo),
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isCancelled ? 'Cancelled' : (isCompleted ? 'Finished' : 'Ongoing'),
                                style: TextStyle(
                                  color: isCancelled ? Colors.red : (isCompleted ? Colors.green.shade700 : Colors.indigo),
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
                                Text('TOTAL BUDGET', style: TextStyle(color: Colors.grey.shade500, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 1),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text('₹ $budget', style: TextStyle(color: Colors.green.shade700, fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.w900)),
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
                                Text('DEADLINE', style: TextStyle(color: Colors.grey.shade500, fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month_rounded, size: 10, color: Colors.grey.shade600),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(dateStr, style: TextStyle(color: Colors.grey.shade800, fontSize: isSmallScreen ? 10.5 : 11.5, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildProjectsTab(String title, List<String> stages, List<dynamic> projects, double screenWidth) {
    final filtered = _filterProjectsByStage(stages, projects);

    double totalValue = 0.0;
    for (var p in filtered) {
      totalValue += (p['budget'] as num? ?? 10000).toDouble();
    }
    
    if (filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: Colors.grey.shade400),
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
        
        // Cards need at least ~320px width to render comfortably.
        // Adapt columns based on true layout constraints:
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
                          mainAxisExtent: 142,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProjectCard(context, filtered[index], isSmallScreen: isSmall, isGrid: true),
                          childCount: filtered.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => SizedBox(
                            height: 142,
                            child: _buildProjectCard(context, filtered[index], isSmallScreen: isSmall, isGrid: false),
                          ),
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
    final auth = ref.watch(authProvider);
    final projectsAsync = auth.id != null ? ref.watch(userProjectsProvider(auth.id!)) : null;
    final projectsData = projectsAsync?.asData?.value ?? projectsAsync?.value;
    final projects = projectsData?.projects ?? const [];
    final isLoading = projectsAsync != null ? (projectsAsync.isLoading && projectsData == null) : false;

    final ongoingCount = projects.where((p) => !['completed', 'finished', 'cancelled', 'finished pending approval'].contains((p['currentStage'] as String? ?? '').toLowerCase())).length;
    final pendingCount = projects.where((p) => (p['currentStage'] as String? ?? '').toLowerCase() == 'finished pending approval').length;
    final finishedCount = projects.where((p) => ['completed', 'finished'].contains((p['currentStage'] as String? ?? '').toLowerCase())).length;
    final cancelledCount = projects.where((p) => (p['currentStage'] as String? ?? '').toLowerCase() == 'cancelled').length;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isTabletOrLaptop = screenWidth >= 700;
    final horizontalPadding = isTabletOrLaptop ? 24.0 : (isSmallScreen ? 12.0 : 16.0);

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
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
                                    const Text('PROJECTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.2)),
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
                                      'Track and manage all your projects in one place.',
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
                              Tab(child: _buildTabItem(Icons.play_arrow_rounded, 'Ongoing', ongoingCount, Colors.indigo, isSmallScreen: isSmallScreen)),
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
                                      hintText: isSmallScreen ? 'Search projects...' : 'Search projects by title or location...',
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
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.filter_list, size: 16, color: Colors.indigo.shade900),
                                    if (!isSmallScreen) ...[
                                      const SizedBox(width: 6),
                                      Text('Filter', style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
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
                              _buildProjectsTab('Ongoing Projects', ['Design & Planning', 'Tracking', 'Execution', 'On Hold'], projects, screenWidth),
                              _buildProjectsTab('Pending Approval', ['Finished Pending Approval'], projects, screenWidth),
                              _buildProjectsTab('Finished Projects', ['Completed', 'Finished'], projects, screenWidth),
                              _buildProjectsTab('Cancelled Projects', ['Cancelled'], projects, screenWidth),
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
