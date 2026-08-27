import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/full_screen_image_viewer.dart';
import '../chat/chat_detail_screen.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  String _costViewMode = 'Summary'; // 'Summary' or 'Detailed'
  int _selectedTrackingTab = 0; // 0 for Execution Plan & Tasks, 1 for Daily Logs
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> _recommendedServices = const [
    {
      'title': 'Land & Legal',
      'desc': 'Legal support &\ndocumentation',
      'icon': Icons.balance_rounded,
      'color': Color(0xFF10B981),
      'bg': Color(0xFFECFDF5),
    },
    {
      'title': 'Design & Planning',
      'desc': 'Architectural design\n& planning',
      'icon': Icons.architecture_rounded,
      'color': Color(0xFF3B82F6),
      'bg': Color(0xFFEFF6FF),
    },
    {
      'title': 'Construction',
      'desc': 'Quality construction\nservices',
      'icon': Icons.construction_rounded,
      'color': Color(0xFFF59E0B),
      'bg': Color(0xFFFFFBEB),
    },
    {
      'title': 'Interior Design',
      'desc': 'Stylish & functional\ninteriors',
      'icon': Icons.chair_rounded,
      'color': Color(0xFF8B5CF6),
      'bg': Color(0xFFFAF5FF),
    },
    {
      'title': 'Survey & Analysis',
      'desc': 'Site surveying &\nvaluation',
      'icon': Icons.explore_rounded,
      'color': Color(0xFF0284C7),
      'bg': Color(0xFFF0F9FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _fetchProjectDetails();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/projects/${widget.projectId}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _project = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching project details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Project', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this project? This will delete all tasks, quotes, and tracking progress. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(Uri.parse('$apiBaseUrl/projects/${widget.projectId}'));
        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          final data = jsonDecode(response.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to delete project'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error deleting project: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting project. Connection failed.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCancelConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Project', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to cancel this project? This will stop all tracking and execution progress. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cancel Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _updateProjectStage('Cancelled');
    }
  }

  Future<void> _showEditProjectDialog() async {
    if (_project == null) return;

    await showDialog(
      context: context,
      builder: (context) => _EditProjectDialog(
        project: _project!,
        projectId: widget.projectId,
        onUpdated: _fetchProjectDetails,
      ),
    );
  }

  Future<void> _updateProjectStage(String stage) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'currentStage': stage}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project updated to stage: $stage'), backgroundColor: Colors.green),
        );
        _fetchProjectDetails();
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to update project stage'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error updating project stage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection failed. Could not update project stage.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCompletionReviewDialog() async {
    final acceptedQuote = (_project?['quotes'] as List? ?? []).firstWhere(
      (q) => q['isAccepted'] == true,
      orElse: () => null,
    );
    if (acceptedQuote == null) return;
    final providerId = acceptedQuote['providerId'];
    final userId = _project?['userId'];

    int localRating = 5;
    final commentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Rate & Review Service Provider', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('How was your experience working with this provider?'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            localRating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setModalState(() {
                              localRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$localRating / 5 Stars',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Write a review/comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final comment = commentController.text.trim();
                    if (comment.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please write a comment')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, {
                      'rating': localRating,
                      'comment': comment,
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8)),
                  child: const Text('Submit Completion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final rating = result['rating'] as int;
      final comment = result['comment'] as String;

      setState(() => _isLoading = true);

      final providerName = acceptedQuote['provider']?['businessName'] ?? acceptedQuote['provider']?['ownerName'] ?? 'the provider';

      try {
        final reviewResponse = await http.post(
          Uri.parse('$apiBaseUrl/providers/$providerId/reviews'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'rating': rating,
            'comment': comment,
            'projectId': widget.projectId,
          }),
        );

        if (reviewResponse.statusCode == 201) {
          final projectResponse = await http.patch(
            Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'currentStage': 'Completed'}),
          );

          if (projectResponse.statusCode == 200) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _confettiController.play();
            _showThankYouDialog(context, providerName);
            _fetchProjectDetails();
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Review posted, but failed to complete project status'), backgroundColor: Colors.orange),
            );
            setState(() => _isLoading = false);
            _fetchProjectDetails();
          }
        } else {
          final data = jsonDecode(reviewResponse.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to submit review'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error completing project and review: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving completion. Connection failed.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showThankYouDialog(BuildContext context, String providerName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded, size: 48, color: Colors.green.shade600),
                ),
                const SizedBox(height: 16),
                const Text("Project Completed!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                Text(
                  "Thank you for choosing $providerName for your construction project! Your rating and review have been recorded.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      context.push('/create-project');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Create New Project", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _project?['title'] ?? 'My Home';
    final location = _project?['location'] ?? 'Royapram, Chennai';
    final plotSize = _project?['plotSize']?.toString() ?? '2000';
    final double budget = (_project?['budget'] as num? ?? 300000.0).toDouble();
    final timeline = _project?['timeline'] ?? '9 months (Mar 2025 – Dec 2025)';
    final currentStage = _project?['currentStage'] ?? 'Design & Planning';
    final projectIdFormatted = 'PRJ-${widget.projectId.length > 8 ? widget.projectId.substring(0, 8).toUpperCase() : widget.projectId.toUpperCase()}';

    final quotesList = _project?['quotes'] as List? ?? [];
    final tasksList = _project?['tasks'] as List? ?? [];

    final isCancelled = currentStage.toString().toLowerCase() == 'cancelled';
    final isCompleted = currentStage.toString().toLowerCase() == 'completed' || currentStage.toString().toLowerCase() == 'finished';

    double totalQuotedTasks = 0.0;
    double totalSpent = 0.0;
    for (var t in tasksList) {
      final taskCost = (t['quotedCost'] as num? ?? 0.0).toDouble();
      totalQuotedTasks += taskCost;
      if (t['status'] == 'Completed') {
        totalSpent += taskCost;
      }
    }
    final double remainingBudget = budget - totalQuotedTasks;

    final completedCount = tasksList.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasksList.length;

    double progressValue = 0.40;
    if (totalCount > 0) {
      progressValue = completedCount / totalCount;
    } else {
      if (currentStage == 'Design & Planning') {
        progressValue = 0.40;
      } else if (currentStage == 'Execution' || currentStage == 'Tracking') {
        progressValue = 0.65;
      } else if (isCompleted) {
        progressValue = 1.0;
      } else if (isCancelled) {
        progressValue = 0.40;
      }
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isTabletOrLaptop = screenWidth >= 700;
    final horizontalPadding = isTabletOrLaptop ? 24.0 : (isSmallScreen ? 12.0 : 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _project == null
                        ? const Center(child: Text('Project details not found.'))
                        : RefreshIndicator(
                            onRefresh: _fetchProjectDetails,
                            child: ListView(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
                              children: [
                                // Top Custom App Bar
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (context.canPop()) {
                                            context.pop();
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 18 : 20,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF0F172A),
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Project Overview',
                                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (val) {
                                          if (val == 'edit') {
                                            _showEditProjectDialog();
                                          } else if (val == 'delete') {
                                            _showDeleteConfirmationDialog();
                                          } else if (val == 'cancel') {
                                            _showCancelConfirmationDialog();
                                          }
                                        },
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF1E293B)),
                                        ),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                                                SizedBox(width: 8),
                                                Text('Edit Project'),
                                              ],
                                            ),
                                          ),
                                          if (isCancelled)
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Delete Project'),
                                                ],
                                              ),
                                            )
                                          else
                                            const PopupMenuItem(
                                              value: 'cancel',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.cancel_rounded, color: Colors.orange, size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Cancel Project'),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Pending Completion Approval Banner if any
                                if (currentStage == 'Finished Pending Approval') ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 24),
                                            SizedBox(width: 8),
                                            Text(
                                              'Verify Project Completion',
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF92400E)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'The provider has marked this project as finished! Please verify completion and leave a review.',
                                          style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: _showCompletionReviewDialog,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF16A34A),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('Approve & Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                            const SizedBox(width: 10),
                                            TextButton(
                                              onPressed: () => _updateProjectStage('Tracking'),
                                              child: const Text('Request Changes', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // 1. Hero Project Overview Card
                                _buildHeroOverviewCard(
                                  title: title,
                                  location: location,
                                  plotSize: plotSize,
                                  budget: budget,
                                  timeline: timeline,
                                  projectId: projectIdFormatted,
                                  isCancelled: isCancelled,
                                  isCompleted: isCompleted,
                                  isSmallScreen: isSmallScreen,
                                ),
                                const SizedBox(height: 16),

                                // 2. Project Progress Card (Gauge + Stepper + Execution Tasks + Logs)
                                _buildProjectProgressCard(
                                  progressValue: progressValue,
                                  currentStage: currentStage,
                                  isCancelled: isCancelled,
                                  isCompleted: isCompleted,
                                  isSmallScreen: isSmallScreen,
                                  tasks: tasksList,
                                  updates: _project?['updates'] as List? ?? [],
                                  acceptedQuote: quotesList.firstWhere(
                                    (q) => q['isAccepted'] == true,
                                    orElse: () => null,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 3. Recommended Services Horizontal Carousel
                                _buildRecommendedServicesSection(isSmallScreen),
                                const SizedBox(height: 16),

                                // 4. Quotes Received Card
                                _buildQuotesReceivedCard(quotesList, isSmallScreen),
                                const SizedBox(height: 16),

                                // 5. Cost Tracking Card (Donut Chart + Summary List)
                                _buildCostTrackingCard(
                                  budget: budget,
                                  totalQuotedTasks: totalQuotedTasks,
                                  remainingBudget: remainingBudget,
                                  totalSpent: totalSpent,
                                  hasQuotes: quotesList.isNotEmpty,
                                  isSmallScreen: isSmallScreen,
                                ),
                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.pink],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. HERO PROJECT OVERVIEW CARD
  // ==========================================
  Widget _buildHeroOverviewCard({
    required String title,
    required String location,
    required String plotSize,
    required double budget,
    required String timeline,
    required String projectId,
    required bool isCancelled,
    required bool isCompleted,
    required bool isSmallScreen,
  }) {
    final statusText = isCancelled ? 'Cancelled' : (isCompleted ? 'Finished' : 'Active');
    final statusColor = isCancelled ? const Color(0xFFEF4444) : (isCompleted ? const Color(0xFF3B82F6) : const Color(0xFF10B981));
    final statusBg = isCancelled ? const Color(0xFFFEF2F2) : (isCompleted ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row (Thumbnail + Details + Budget)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail with Status Pill
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/build_plan_achieve.jpg',
                      width: isSmallScreen ? 90 : 110,
                      height: isSmallScreen ? 80 : 92,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: isSmallScreen ? 90 : 110,
                        height: isSmallScreen ? 80 : 92,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.apartment_rounded, color: Colors.blue, size: 36),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Title & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: _showEditProjectDialog,
                          child: Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            location,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildCategoryTag('Residential', const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                        _buildCategoryTag('Custom Home', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Budget Metric Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Budget', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${budget.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('85% of Budget', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Container(
                    width: 75,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.85,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Specifications List Rows
          _buildSpecRow(Icons.location_on_outlined, 'Location', location),
          _buildSpecRow(Icons.grid_view_rounded, 'Category', 'Land & Legal, Survey & Analysis, Design'),
          _buildSpecRow(Icons.crop_free_rounded, 'Plot Size', '$plotSize sq ft'),
          _buildSpecRow(Icons.calendar_month_outlined, 'Timeline', timeline),
          _buildSpecRow(
            Icons.credit_card_rounded,
            'Project ID',
            projectId,
            isCopyable: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String title, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCopyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project ID copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
              child: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF64748B)),
            )
          else
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  // ==========================================
  // 2. PROJECT PROGRESS CARD (Gauge + Stepper + Tasks & Logs)
  // ==========================================
  Widget _buildProjectProgressCard({
    required double progressValue,
    required String currentStage,
    required bool isCancelled,
    required bool isCompleted,
    required bool isSmallScreen,
    required List<dynamic> tasks,
    required List<dynamic> updates,
    Map<String, dynamic>? acceptedQuote,
  }) {
    final int percentInt = (progressValue * 100).toInt();
    final gaugeSize = isSmallScreen ? 66.0 : 76.0;

    final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasks.length;

    final Map<String, List<dynamic>> groupedTasks = {};
    for (final task in tasks) {
      final stage = task['stage'] ?? 'General Planning';
      groupedTasks.putIfAbsent(stage, () => []).add(task);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Progress',
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          // Top Gauge & Stepper Row
          Row(
            children: [
              // Circular Donut Gauge
              SizedBox(
                width: gaugeSize,
                height: gaugeSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: gaugeSize,
                      height: gaugeSize,
                      child: CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: isSmallScreen ? 6.5 : 7.5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percentInt%',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Completed',
                          style: TextStyle(fontSize: isSmallScreen ? 7.0 : 8.0, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: isSmallScreen ? 6 : 8),

              // Vertical divider line
              Container(width: 1, height: isSmallScreen ? 52 : 62, color: const Color(0xFFF1F5F9)),
              SizedBox(width: isSmallScreen ? 6 : 8),

              // Right Stepper Milestone Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Current Stage',
                            style: TextStyle(fontSize: isSmallScreen ? 9.0 : 10.0, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.cancel_rounded, color: Color(0xFF2563EB), size: 10),
                                SizedBox(width: 2),
                                Text('Cancelled', style: TextStyle(fontSize: 9, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      currentStage,
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 4-Step Stepper with responsive width
                    Row(
                      children: [
                        _buildStepItem('Planning', Icons.calendar_today_rounded, true, isSmallScreen),
                        _buildStepConnector(true),
                        _buildStepItem('Design', Icons.edit_note_rounded, true, isSmallScreen),
                        _buildStepConnector(currentStage.toLowerCase().contains('execut') || currentStage.toLowerCase().contains('track') || isCompleted),
                        _buildStepItem('Execution', Icons.engineering_rounded, currentStage.toLowerCase().contains('execut') || currentStage.toLowerCase().contains('track') || isCompleted, isSmallScreen),
                        _buildStepConnector(isCompleted),
                        _buildStepItem('Handover', Icons.vpn_key_rounded, isCompleted, isSmallScreen),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Segmented Switcher for Execution Plan vs Daily Logs
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTrackingTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTrackingTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedTrackingTab == 0
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 14,
                            color: _selectedTrackingTab == 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Tasks & Milestones (${tasks.length})',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10.5 : 11.5,
                              fontWeight: FontWeight.w700,
                              color: _selectedTrackingTab == 0 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTrackingTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTrackingTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: _selectedTrackingTab == 1
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 14,
                            color: _selectedTrackingTab == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Daily Logs (${updates.length})',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10.5 : 11.5,
                              fontWeight: FontWeight.w700,
                              color: _selectedTrackingTab == 1 ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // TAB 0: Execution Plan & Tasks Created by Provider
          if (_selectedTrackingTab == 0) ...[
            if (tasks.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                      child: const Icon(Icons.assignment_outlined, color: Color(0xFF2563EB), size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Tasks Created Yet',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Once your contractor schedules the project milestones, step-by-step tasks will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Summary Progress Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$completedCount of $totalCount Tasks Completed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  Text(
                    '${(totalCount > 0 ? (completedCount / totalCount * 100).toInt() : 0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? completedCount / totalCount : 0.0,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 14),

              // Grouped Tasks by Stage
              ...groupedTasks.entries.map((entry) {
                final stageName = entry.key;
                final stageTasks = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stage Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.architecture_rounded, size: 16, color: Color(0xFF1D4ED8)),
                                const SizedBox(width: 6),
                                Text(
                                  stageName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                '${stageTasks.where((t) => t['status'] == 'Completed').length}/${stageTasks.length}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Tasks List for this stage
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stageTasks.length,
                        separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 14, endIndent: 14),
                        itemBuilder: (context, idx) {
                          final task = stageTasks[idx];
                          final tTitle = task['title'] ?? 'Task';
                          final tDuration = task['duration'] ?? 1;
                          final tStatus = task['status'] ?? 'Pending';
                          final tCost = (task['quotedCost'] as num? ?? 0.0).toDouble();
                          final hasPhoto = task['photoUrl'] != null && (task['photoUrl'] as String).isNotEmpty;

                          final isTaskDone = tStatus.toString().toLowerCase() == 'completed';
                          final isTaskInProgress = tStatus.toString().toLowerCase() == 'in progress' || tStatus.toString().toLowerCase() == 'in_progress';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Checkbox Status Icon
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  child: isTaskDone
                                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
                                      : isTaskInProgress
                                          ? const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF2563EB), size: 18)
                                          : const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF94A3B8), size: 18),
                                ),
                                const SizedBox(width: 10),

                                // Task Title & Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tTitle,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: isTaskDone ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                          decoration: isTaskDone ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          // Duration Tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.schedule_rounded, size: 10, color: Color(0xFF64748B)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '$tDuration d',
                                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Quoted Cost Tag
                                          if (tCost > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFDE68A)),
                                              ),
                                              child: Text(
                                                '₹${tCost.toStringAsFixed(0)}',
                                                style: const TextStyle(fontSize: 9.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          // Status Tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isTaskDone
                                                  ? const Color(0xFFECFDF5)
                                                  : isTaskInProgress
                                                      ? const Color(0xFFEFF6FF)
                                                      : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              tStatus,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: isTaskDone
                                                    ? const Color(0xFF10B981)
                                                    : isTaskInProgress
                                                        ? const Color(0xFF2563EB)
                                                        : const Color(0xFF64748B),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Photo proof thumbnail if present
                                      if (hasPhoto) ...[
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () => _showCompletionPhotoDialog(task),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(Icons.camera_alt_rounded, size: 12, color: Color(0xFF059669)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Proof Photo Attached (Tap to view)',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ] else ...[
            // TAB 1: Daily Logs
            if (updates.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                      child: const Icon(Icons.note_alt_outlined, color: Color(0xFF2563EB), size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No Daily Logs Yet',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified site logs and progress photos posted by your contractor will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: updates.length > 5 ? 5 : updates.length,
                itemBuilder: (context, idx) {
                  final update = updates[idx];
                  final upTitle = update['title'] ?? 'Update';
                  final upStatus = update['status'] ?? 'In Progress';
                  final upNotes = update['notes'] ?? '';
                  final upTime = update['createdAt'] != null
                      ? DateTime.tryParse(update['createdAt'])?.toLocal().toString().substring(0, 16) ?? ''
                      : '';

                  Color statusColor = const Color(0xFF2563EB);
                  if (upStatus == 'Completed') statusColor = const Color(0xFF10B981);
                  if (upStatus == 'Milestone Reached') statusColor = const Color(0xFFF59E0B);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                upTitle,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                upStatus,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                              ),
                            ),
                          ],
                        ),
                        if (upNotes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(upNotes, style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5, height: 1.3)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('✓ Verified Site Log', style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold)),
                            Text(upTime, style: TextStyle(color: Colors.grey.shade400, fontSize: 9.5)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],

          // Assigned Contractor Card if quote accepted
          if (acceptedQuote != null) ...[
            const SizedBox(height: 14),
            _buildAssignedProviderCard(acceptedQuote, isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedProviderCard(Map<String, dynamic> acceptedQuote, bool isSmallScreen) {
    final provider = acceptedQuote['provider'] ?? {};
    final providerName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final ownerName = provider['ownerName'] ?? 'Contractor';
    final phone = provider['phone']?.toString() ?? '';
    final rating = (provider['avgRating'] ?? provider['rating'] ?? 5.0) as num;
    final providerId = acceptedQuote['providerId'];
    final profileImage = provider['profileImage']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFDBEAFE),
            backgroundImage: profileImage != null && profileImage.isNotEmpty
                ? MemoryImage(base64Decode(profileImage.split(',').last))
                : null,
            child: profileImage == null || profileImage.isEmpty
                ? Text(
                    providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        providerName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 13),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner: $ownerName ${phone.isNotEmpty ? '• 📞 $phone' : ''} • ⭐ ${rating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (providerId != null)
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/provider-profile/$providerId'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Text('Profile', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          partnerId: providerId,
                          partnerName: providerName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCompletionPhotoDialog(Map<String, dynamic> task) {
    final title = task['title'] ?? 'Task Proof';
    final photoUrl = task['photoUrl'] as String?;

    if (photoUrl == null || photoUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proof of Completion attached by contractor (Tap to zoom):',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      base64Image: photoUrl,
                      title: title,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(photoUrl.split(',').last),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Failed to load image', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String label, IconData icon, bool isActive, bool isSmallScreen) {
    final circleSize = isSmallScreen ? 20.0 : 23.0;
    final iconSize = isSmallScreen ? 10.0 : 11.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 7.0 : 8.0,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 10),
        color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
    );
  }

  // ==========================================
  // 3. RECOMMENDED SERVICES CAROUSEL
  // ==========================================
  Widget _buildRecommendedServicesSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended Services',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            GestureDetector(
              onTap: () => context.push('/providers/All'),
              child: Row(
                children: const [
                  Text('View All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recommendedServices.length,
            itemBuilder: (context, index) {
              final service = _recommendedServices[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: service['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(service['icon'] as IconData, size: 20, color: service['color'] as Color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(
                        service['desc'] as String,
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () => context.push('/providers/${service['title']}'),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. QUOTES RECEIVED CARD
  // ==========================================
  Widget _buildQuotesReceivedCard(List<dynamic> quotesList, bool isSmallScreen) {
    final hasQuotes = quotesList.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quotes Received',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              GestureDetector(
                onTap: () => context.push('/compare-quotes/${widget.projectId}'),
                child: Row(
                  children: const [
                    Text('View All Quotes', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Left: Document 3D Illustration
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/quote_3d.jpg',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Right: Content & Action
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasQuotes ? '${quotesList.length} Quotes Available' : 'No Quotes Yet',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasQuotes
                          ? 'Review bids submitted by verified contractors.'
                          : 'Quotes from service providers will show here',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        if (hasQuotes) {
                          context.push('/compare-quotes/${widget.projectId}');
                        } else {
                          context.push('/providers/All');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.description_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              hasQuotes ? 'Compare Quotes' : 'Request Quotes',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. COST TRACKING CARD
  // ==========================================
  Widget _buildCostTrackingCard({
    required double budget,
    required double totalQuotedTasks,
    required double remainingBudget,
    required double totalSpent,
    required bool hasQuotes,
    required bool isSmallScreen,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cost Tracking',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              PopupMenuButton<String>(
                onSelected: (val) => setState(() => _costViewMode = val),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Summary', child: Text('Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                  PopupMenuItem(value: 'Detailed', child: Text('Detailed', style: TextStyle(fontSize: 13))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _costViewMode,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF475569)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Donut Chart & Legend
              Column(
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 16,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Remaining',
                              style: TextStyle(fontSize: 8.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '₹${budget.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('Remaining\n(₹${budget.toStringAsFixed(0)})', style: TextStyle(fontSize: 8.5, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('No Quotes', style: TextStyle(fontSize: 8.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Right: Metric Rows
              Expanded(
                child: Column(
                  children: [
                    _buildCostItem(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBg: const Color(0xFFF8FAFC),
                      title: 'Customer Estimated Budget',
                      amount: '₹${budget.toStringAsFixed(2)}',
                    ),
                    _buildCostItem(
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFF8FAFC),
                      title: 'Total Quoted Contract Basis',
                      amount: '₹${budget.toStringAsFixed(2)}',
                    ),
                    _buildCostItem(
                      icon: Icons.assignment_turned_in_outlined,
                      iconBg: const Color(0xFFFFFBEB),
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Total Allocated Quoted Tasks',
                      amount: '₹${totalQuotedTasks.toStringAsFixed(2)}',
                      amountColor: const Color(0xFFF59E0B),
                    ),
                    _buildCostItem(
                      icon: Icons.verified_user_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      title: 'Remaining Project Budget',
                      amount: '₹${remainingBudget.toStringAsFixed(2)}',
                      amountColor: const Color(0xFF10B981),
                      subtitle: 'Calculation: ₹${budget.toStringAsFixed(0)} (Total Budget) - ₹${totalQuotedTasks.toStringAsFixed(0)} (Quoted Tasks) = ₹${remainingBudget.toStringAsFixed(0)}',
                    ),
                    _buildCostItem(
                      icon: Icons.payments_outlined,
                      iconBg: const Color(0xFFF8FAFC),
                      title: 'Total Cash Spent (Completed Tasks)',
                      amount: '₹${totalSpent.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostItem({
    required IconData icon,
    required Color iconBg,
    Color iconColor = const Color(0xFF64748B),
    required String title,
    required String amount,
    Color amountColor = const Color(0xFF0F172A),
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                amount,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: amountColor),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 8.5, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditProjectDialog extends StatefulWidget {
  final Map<String, dynamic> project;
  final String projectId;
  final VoidCallback onUpdated;

  const _EditProjectDialog({
    required this.project,
    required this.projectId,
    required this.onUpdated,
  });

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  late TextEditingController _titleController;
  late TextEditingController _budgetController;
  late TextEditingController _locationController;
  late TextEditingController _timelineController;
  late TextEditingController _plotSizeController;
  late TextEditingController _typeController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project['title']);
    _budgetController = TextEditingController(text: widget.project['budget']?.toString());
    _locationController = TextEditingController(text: widget.project['location']);
    _timelineController = TextEditingController(text: widget.project['timeline']);
    _plotSizeController = TextEditingController(text: widget.project['plotSize']?.toString());
    _typeController = TextEditingController(text: widget.project['type']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _timelineController.dispose();
    _plotSizeController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text.trim(),
          'budget': double.parse(_budgetController.text.trim()),
          'location': _locationController.text.trim(),
          'timeline': _timelineController.text.trim(),
          'plotSize': double.parse(_plotSizeController.text.trim()),
          'type': _typeController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        widget.onUpdated();
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully'), backgroundColor: Colors.green),
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to update project'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error updating project: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Failed to update.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Project Details', style: TextStyle(fontWeight: FontWeight.bold)),
      content: _isSaving
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Project Title'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Budget (₹)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _timelineController,
                      decoration: const InputDecoration(labelText: 'Timeline (e.g. 9 months)'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _plotSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Plot Size (sq ft)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _typeController,
                      decoration: const InputDecoration(labelText: 'Category / Services'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
      actions: _isSaving
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _saveProject,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8)),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
    );
  }
}
