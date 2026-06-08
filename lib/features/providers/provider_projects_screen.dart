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
      
      final matchesStage = stages.any((s) => s.toLowerCase() == stage);
      final matchesSearch = title.contains(_searchQuery.toLowerCase()) || 
                            location.contains(_searchQuery.toLowerCase());
      
      return matchesStage && matchesSearch;
    }).toList();
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'completed':
      case 'finished':
        return Colors.green;
      case 'finished pending approval':
        return Colors.amber.shade800;
      case 'on hold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStageIcon(String stage) {
    switch (stage.toLowerCase()) {
      case 'completed':
      case 'finished':
        return Icons.check_circle;
      case 'finished pending approval':
        return Icons.rate_review;
      case 'on hold':
        return Icons.pause_circle_filled;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.construction;
    }
  }

  Widget _buildProjectCard(dynamic project) {
    final title = project['title'] ?? 'N/A';
    final currentStage = project['currentStage'] ?? 'Design & Planning';
    final budget = (project['budget'] as num? ?? 0.0).toDouble();
    final location = project['location'] ?? 'N/A';
    final clientName = project['user']?['name'] ?? 'Client';
    
    final tasks = project['tasks'] as List? ?? [];
    final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasks.length;
    
    double progress = 0.0;
    if (totalCount > 0) {
      progress = completedCount / totalCount;
    } else {
      if (currentStage == 'Design & Planning') {
        progress = 0.2;
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

    final stageColor = _getStageColor(currentStage);
    final stageIcon = _getStageIcon(currentStage);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.push('/provider-job/${project['id']}');
          _fetchProjects(); // Refresh when returning
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stageIcon, color: stageColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          currentStage,
                          style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.blueGrey.shade600),
                  const SizedBox(width: 4),
                  Text('Client: $clientName', style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(location, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.attach_money, size: 16, color: Colors.green),
                  Text(
                    budget.toStringAsFixed(0),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalCount > 0 ? 'Progress: $completedCount/$totalCount Tasks' : 'Stage Progress',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% Done',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stageColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(stageColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsTab(List<String> stages) {
    final filtered = _filterProjectsByStage(stages);
    
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

    return RefreshIndicator(
      onRefresh: _fetchProjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildProjectCard(filtered[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Projects'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 16),
                    SizedBox(width: 6),
                    Text('Ongoing'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16),
                    SizedBox(width: 6),
                    Text('Pending Approval'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16),
                    SizedBox(width: 6),
                    Text('Finished'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, size: 16),
                    SizedBox(width: 6),
                    Text('Cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search projects by title or location...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProjectsTab(['Design & Planning', 'Tracking', 'Execution', 'On Hold']),
                        _buildProjectsTab(['Finished Pending Approval']),
                        _buildProjectsTab(['Completed', 'Finished']),
                        _buildProjectsTab(['Cancelled']),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
