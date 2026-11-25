import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/bento.dart';
import '../../core/wallpaper_background.dart';
import '../../core/providers/projects_provider.dart';
import '../../core/utils/project_progress_helper.dart';
import '../auth/auth_provider.dart';
import '../../core/widgets/shimmer_loading.dart';

class ProjectsListScreen extends ConsumerStatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  ConsumerState<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends ConsumerState<ProjectsListScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = "";
  late TabController _tabController;
  bool _isLoading = true;

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
    if (mounted) setState(() => _isLoading = true);
    final auth = ref.read(authProvider);
    try {
      if (auth.id != null) {
        ref.invalidate(userProjectsProvider(auth.id!));
        await ref.read(userProjectsProvider(auth.id!).future);
      }
    } catch (e) {
      debugPrint('ProjectsList fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static bool _isPendingStage(String? stage, [dynamic project]) {
    if (project is Map) {
      final quotes = project['quotes'];
      if (quotes is List && quotes.any((q) => q is Map && q['isAccepted'] == true)) {
        return false;
      }
    }
    if (stage == null || stage.trim().isEmpty) return true;
    final s = stage.trim().toLowerCase();
    if (s == 'tracking' ||
        s.contains('track') ||
        s.contains('execut') ||
        s == 'in progress' ||
        s == 'ongoing' ||
        s == 'on hold' ||
        s == 'hold') {
      return false;
    }
    if (s == 'design & planning') return false;
    return s == 'planning & approvals' ||
        s == 'planning' ||
        s == 'pending' ||
        s == 'pending approval' ||
        s == 'finished pending approval' ||
        s == 'new lead' ||
        s == 'lead' ||
        s == 'draft' ||
        s.contains('pending') ||
        (s.contains('planning') && !s.contains('design'));
  }

  static bool _isOnHoldStage(String? stage) {
    if (stage == null) return false;
    final s = stage.trim().toLowerCase();
    return s == 'on hold' || s == 'hold' || s == 'paused';
  }

  static bool _isFinishedStage(String? stage) {
    if (stage == null) return false;
    final s = stage.trim().toLowerCase();
    return s == 'completed' || s == 'finished';
  }

  static bool _isCancelledStage(String? stage) {
    if (stage == null) return false;
    final s = stage.trim().toLowerCase();
    return s == 'cancelled';
  }

  static bool _isOngoingStage(String? stage, [dynamic project]) {
    if (project is Map) {
      final quotes = project['quotes'];
      if (quotes is List && quotes.any((q) => q is Map && q['isAccepted'] == true)) {
        if (_isFinishedStage(stage) || _isCancelledStage(stage)) return false;
        return true;
      }
    }
    if (stage == null) return false;
    if (_isFinishedStage(stage) || _isCancelledStage(stage) || _isPendingStage(stage, project)) {
      return false;
    }
    return true;
  }

  List<dynamic> _filterProjects(bool Function(String?, dynamic) stageMatcher, List<dynamic> projects) {
    return projects.where((project) {
      final stage = project['currentStage'] as String?;
      final title = (project['title'] as String? ?? '').toLowerCase();
      final location = (project['location'] as String? ?? '').toLowerCase();
      
      final matchesStage = stageMatcher(stage, project);
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || 
                            location.contains(_searchQuery.toLowerCase());
      
      return matchesStage && matchesSearch;
    }).toList();
  }


  // ===========================================================================
  // UI (bento)
  // ===========================================================================

  String _formatRupees(num value) => '₹${NumberFormat.decimalPattern('en_IN').format(value.round())}';

  ({String label, Color color, IconData icon}) _statusOf(String stage, dynamic project) {
    if (_isCancelledStage(stage)) return (label: 'Cancelled', color: Bento.red, icon: Icons.cancel_rounded);
    if (_isOnHoldStage(stage)) return (label: 'On hold', color: const Color(0xFFD97706), icon: Icons.pause_circle_rounded);
    if (_isFinishedStage(stage)) return (label: 'Finished', color: Bento.green, icon: Icons.check_circle_rounded);
    if (_isPendingStage(stage, project)) return (label: 'Pending', color: const Color(0xFFD97706), icon: Icons.schedule_rounded);
    return (label: 'Ongoing', color: Bento.accent, icon: Icons.sync_rounded);
  }

  Widget _buildProjectCard(BuildContext context, dynamic project) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = (project['title'] ?? 'Project').toString();
    final stage = project['currentStage'] as String? ?? 'Planning & Approvals';
    final location = (project['location'] ?? '').toString();
    final budget = project['budget'] is num ? project['budget'] as num : num.tryParse('${project['budget']}') ?? 0;
    final status = _statusOf(stage, project);
    final progress = ProjectProgressHelper.calculateFromProject(project).progressValue;
    final quotes = (project['quotes'] is List) ? (project['quotes'] as List).length : (project['_count']?['quotes'] as int? ?? 0);

    String dateStr = project['timeline']?.toString() ?? 'Upcoming';
    if (_isFinishedStage(stage) || _isCancelledStage(stage)) {
      final updated = project['updatedAt'] ?? project['updated_at'];
      dateStr = updated != null ? updated.toString().split('T')[0] : status.label;
    }

    return BentoCard(
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await context.push('/project-detail/${project['id']}');
        _fetchProjects();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BentoProgressRing(value: progress, color: status.color, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Bento.text(dark)),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 13, color: Bento.muted(dark)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Bento.muted(dark)),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 7),
                    BentoPill(label: status.label, color: status.color, icon: status.icon),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Bento.muted(dark)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Bento.surfaceAlt(dark), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _metaItem(dark, 'Budget', budget > 0 ? _formatRupees(budget) : '—', Icons.account_balance_wallet_rounded),
                _metaDivider(dark),
                _metaItem(dark, _isFinishedStage(stage) || _isCancelledStage(stage) ? 'Closed' : 'Timeline', dateStr, Icons.event_rounded),
                _metaDivider(dark),
                _metaItem(dark, 'Quotes', '$quotes', Icons.request_quote_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(bool dark, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: Bento.muted(dark)),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Bento.text(dark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaDivider(bool dark) => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Bento.border(dark),
      );

  Widget _buildProjectsTab({
    required String emptyTitle,
    required bool Function(String?, dynamic) stageMatcher,
    required List<dynamic> projects,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filterProjects(stageMatcher, projects);
    final totalValue = filtered.fold<double>(0, (sum, p) => sum + ((p['budget'] as num?)?.toDouble() ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hPad = width >= 700 ? 24.0 : (width < 380 ? 14.0 : 18.0);
        final columns = width >= 1050 ? 3 : (width >= 660 ? 2 : 1);

        return RefreshIndicator(
          color: Bento.accent,
          onRefresh: _fetchProjects,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 12),
                sliver: SliverToBoxAdapter(
                  child: filtered.isEmpty
                      ? BentoEmptyState(
                          icon: Icons.home_work_rounded,
                          title: _searchQuery.isNotEmpty ? 'No matching projects' : emptyTitle,
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try a different title or location.'
                              : 'Start a project to get quotes from verified builders.',
                          actionLabel: _searchQuery.isEmpty ? 'New project' : null,
                          onAction: _searchQuery.isEmpty ? () => context.push('/create-project') : null,
                        )
                      : Row(
                          children: [
                            Text(
                              '${filtered.length} project${filtered.length == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Bento.muted(dark)),
                            ),
                            const Spacer(),
                            Text('Total ', style: TextStyle(fontSize: 13, color: Bento.muted(dark))),
                            Text(
                              _formatRupees(totalValue),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Bento.text(dark)),
                            ),
                          ],
                        ),
                ),
              ),
              if (filtered.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  sliver: columns > 1
                      ? SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: Bento.gap,
                            mainAxisSpacing: Bento.gap,
                            mainAxisExtent: 168,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _buildProjectCard(context, filtered[i]),
                            childCount: filtered.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: Bento.gap),
                              child: _buildProjectCard(context, filtered[i]),
                            ),
                            childCount: filtered.length,
                          ),
                        ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (prev?.id != next.id && next.id != null) {
        _fetchProjects();
      }
    });

    final auth = ref.watch(authProvider);
    final projectsAsync = auth.id != null ? ref.watch(userProjectsProvider(auth.id!)) : null;
    final projectsData = projectsAsync?.asData?.value ?? projectsAsync?.value;
    final projects = projectsData?.projects ?? const [];
    final isLoading = _isLoading || (projectsAsync != null && projectsAsync.isLoading && projects.isEmpty);

    final counts = [
      projects.where((p) => _isOngoingStage(p['currentStage'] as String?, p)).length,
      projects.where((p) => _isPendingStage(p['currentStage'] as String?, p)).length,
      projects.where((p) => _isFinishedStage(p['currentStage'] as String?)).length,
      projects.where((p) => _isCancelledStage(p['currentStage'] as String?)).length,
    ];

    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final hPad = width >= 700 ? 24.0 : (width < 380 ? 14.0 : 18.0);

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My projects',
                                style: TextStyle(
                                  fontSize: 28,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  color: Bento.text(dark),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isLoading
                                    ? 'Loading your projects…'
                                    : '${projects.length} total · ${counts[0]} ongoing',
                                style: TextStyle(fontSize: 13, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        BentoPressable(
                          onTap: () async {
                            await context.push('/create-project');
                            _fetchProjects();
                          },
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: Bento.accentGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Bento.accent.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text('New', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status tabs
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: BentoPillTabs(
                      controller: _tabController,
                      labels: const ['Ongoing', 'Pending', 'Finished', 'Cancelled'],
                      counts: counts,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: BentoSearchField(
                      hint: 'Search by title or location',
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),

                  Expanded(
                    child: isLoading
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                            child: const ShimmerProjectList(itemCount: 4),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProjectsTab(emptyTitle: 'No ongoing projects', stageMatcher: _isOngoingStage, projects: projects),
                              _buildProjectsTab(emptyTitle: 'No pending projects', stageMatcher: _isPendingStage, projects: projects),
                              _buildProjectsTab(
                                emptyTitle: 'No finished projects yet',
                                stageMatcher: (stage, project) => _isFinishedStage(stage),
                                projects: projects,
                              ),
                              _buildProjectsTab(
                                emptyTitle: 'No cancelled projects',
                                stageMatcher: (stage, project) => _isCancelledStage(stage),
                                projects: projects,
                              ),
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
