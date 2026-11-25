import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/bento.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:construction_app/core/api_http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../../core/utils/project_progress_helper.dart';
import '../auth/auth_provider.dart';
import 'provider_layout.dart';

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

  Future<void> _confirmDeleteCancelledProject(String projectId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Project', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$title"? All associated tasks, quotes, and tracking records will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(Uri.parse('$apiBaseUrl/projects/$projectId'));
        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully'), backgroundColor: Colors.green),
          );
          _fetchProjects();
        } else {
          final data = jsonDecode(response.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to delete project'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        debugPrint('Error deleting project: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Could not delete project.'), backgroundColor: Colors.red),
        );
      }
    }
  }


  // ===========================================================================
  // Stage groups (tab filters and counters use the same rules)
  // ===========================================================================

  static const _pendingStages = ['finished pending approval', 'pending approval', 'planning & approvals', 'planning', 'pending'];
  static const _finishedStages = ['completed', 'finished'];

  static String _stageOf(dynamic p) => (p['currentStage'] as String? ?? 'Design & Planning').toLowerCase().trim();

  static bool _isPending(dynamic p) => _pendingStages.contains(_stageOf(p));
  static bool _isFinished(dynamic p) => _finishedStages.contains(_stageOf(p));
  static bool _isCancelled(dynamic p) => _stageOf(p) == 'cancelled';
  static bool _isOngoing(dynamic p) => !_isPending(p) && !_isFinished(p) && !_isCancelled(p);

  List<dynamic> _filtered(bool Function(dynamic) stageTest) {
    final q = _searchQuery.toLowerCase();
    return _projects.where((p) {
      if (!stageTest(p)) return false;
      if (q.isEmpty) return true;
      final title = (p['title'] as String? ?? '').toLowerCase();
      final location = (p['location'] as String? ?? '').toLowerCase();
      final client = (p['user']?['name'] as String? ?? '').toLowerCase();
      return title.contains(q) || location.contains(q) || client.contains(q);
    }).toList();
  }

  String _formatRupees(num value) => '₹${NumberFormat.decimalPattern('en_IN').format(value.round())}';

  ({String label, Color color, IconData icon}) _statusOf(dynamic p) {
    final s = _stageOf(p);
    if (s == 'cancelled') return (label: 'Cancelled', color: Bento.red, icon: Icons.cancel_rounded);
    if (s == 'on hold') return (label: 'On hold', color: const Color(0xFFD97706), icon: Icons.pause_circle_rounded);
    if (_isFinished(p)) return (label: 'Finished', color: Bento.green, icon: Icons.check_circle_rounded);
    if (s == 'finished pending approval') return (label: 'In review', color: Bento.violet, icon: Icons.fact_check_rounded);
    if (_isPending(p)) return (label: 'Pending', color: const Color(0xFFD97706), icon: Icons.schedule_rounded);
    return (label: 'Ongoing', color: Bento.accent, icon: Icons.construction_rounded);
  }

  // ===========================================================================
  // UI (bento)
  // ===========================================================================

  Widget _buildProjectCard(BuildContext context, dynamic project) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = (project['title'] ?? 'Untitled job').toString();
    final location = (project['location'] ?? '').toString();
    final client = (project['user']?['name'] ?? 'Client').toString();
    final projectId = project['id']?.toString() ?? '';
    final value = (project['quoteAmount'] as num?) ?? (project['budget'] as num?) ?? 0;
    final status = _statusOf(project);
    final progress = ProjectProgressHelper.calculateFromProject(project).progressValue;
    final tasks = project['tasks'] is List ? (project['tasks'] as List) : const [];
    final doneTasks = tasks.where((t) => (t is Map) && (t['status']?.toString().toLowerCase() == 'completed' || t['status']?.toString().toLowerCase() == 'done')).length;

    String dateStr = status.label;
    if (_isFinished(project) || _isCancelled(project) || _stageOf(project) == 'finished pending approval') {
      final updated = project['updatedAt'] ?? project['updated_at'];
      if (updated != null) dateStr = updated.toString().split('T')[0];
    } else {
      dateStr = (project['timeline'] ?? 'Active').toString();
    }

    return BentoCard(
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await context.push('/provider-job/$projectId');
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
                    const SizedBox(height: 3),
                    Text(
                      location.isEmpty ? client : '$client · $location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Bento.muted(dark)),
                    ),
                    const SizedBox(height: 7),
                    BentoPill(label: status.label, color: status.color, icon: status.icon),
                  ],
                ),
              ),
              if (_isCancelled(project))
                BentoCircleButton(
                  icon: Icons.delete_outline_rounded,
                  color: Bento.red,
                  tooltip: 'Delete project',
                  onPressed: () => _confirmDeleteCancelledProject(projectId, title),
                )
              else
                Icon(Icons.chevron_right_rounded, color: Bento.muted(dark)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Bento.surfaceAlt(dark), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _metaItem(dark, 'Contract', value > 0 ? _formatRupees(value) : '—', Icons.account_balance_wallet_rounded),
                _metaDivider(dark),
                _metaItem(dark, 'Tasks', tasks.isEmpty ? '—' : '$doneTasks/${tasks.length}', Icons.checklist_rounded),
                _metaDivider(dark),
                _metaItem(dark, _isOngoing(project) ? 'Timeline' : 'Updated', dateStr, Icons.event_rounded),
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
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Bento.text(dark))),
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

  Widget _buildProjectsTab(String emptyTitle, bool Function(dynamic) stageTest) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final list = _filtered(stageTest);
    final total = list.fold<double>(0, (sum, p) => sum + (((p['quoteAmount'] as num?) ?? (p['budget'] as num?) ?? 0).toDouble()));

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
                  child: list.isEmpty
                      ? BentoEmptyState(
                          icon: Icons.construction_rounded,
                          title: _searchQuery.isNotEmpty ? 'No matching jobs' : emptyTitle,
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Try a different title, client or location.'
                              : 'Quote on new leads to win your next project.',
                          actionLabel: _searchQuery.isEmpty ? 'Find leads' : null,
                          onAction: _searchQuery.isEmpty ? () => ref.read(providerTabProvider.notifier).setTab(2) : null,
                        )
                      : Row(
                          children: [
                            Text(
                              '${list.length} job${list.length == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Bento.muted(dark)),
                            ),
                            const Spacer(),
                            Text('Value ', style: TextStyle(fontSize: 13, color: Bento.muted(dark))),
                            Text(
                              _formatRupees(total),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Bento.text(dark)),
                            ),
                          ],
                        ),
                ),
              ),
              if (list.isNotEmpty)
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
                            (context, i) => _buildProjectCard(context, list[i]),
                            childCount: list.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: Bento.gap),
                              child: _buildProjectCard(context, list[i]),
                            ),
                            childCount: list.length,
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
    ref.listen<int>(providerTabProvider, (prev, next) {
      if (next == 1 && prev != 1) {
        _fetchProjects();
      }
    });

    final counts = [
      _projects.where(_isOngoing).length,
      _projects.where(_isPending).length,
      _projects.where(_isFinished).length,
      _projects.where(_isCancelled).length,
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
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My jobs',
                          style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1, color: Bento.text(dark)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isLoading ? 'Loading your jobs…' : '${_projects.length} total · ${counts[0]} on site now',
                          style: TextStyle(fontSize: 13, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: BentoPillTabs(
                      controller: _tabController,
                      labels: const ['Ongoing', 'Pending', 'Finished', 'Cancelled'],
                      counts: counts,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: BentoSearchField(
                      hint: 'Search by job, client or location',
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                            child: const ShimmerProjectList(itemCount: 4),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProjectsTab('No ongoing jobs', _isOngoing),
                              _buildProjectsTab('Nothing pending approval', _isPending),
                              _buildProjectsTab('No finished jobs yet', _isFinished),
                              _buildProjectsTab('No cancelled jobs', _isCancelled),
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
