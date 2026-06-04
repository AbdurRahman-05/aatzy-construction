import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  int _selectedTrackingTab = 0; // 0 for Schedule/Plan, 1 for Daily Logs
  late ConfettiController _confettiController;

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
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This will delete all tasks, quotes, and tracking progress. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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

  Future<void> _showEditProjectDialog() async {
    if (_project == null) return;

    final titleController = TextEditingController(text: _project!['title']);
    final budgetController = TextEditingController(text: _project!['budget']?.toString());
    final locationController = TextEditingController(text: _project!['location']);
    final timelineController = TextEditingController(text: _project!['timeline']);
    final plotSizeController = TextEditingController(text: _project!['plotSize']?.toString());
    final typeController = TextEditingController(text: _project!['type']);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Project Details'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Project Title'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: budgetController,
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
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: timelineController,
                    decoration: const InputDecoration(labelText: 'Timeline (e.g. 6 months)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: plotSizeController,
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
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Category / Services (comma separated)'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context); // Close dialog
                setState(() => _isLoading = true);

                try {
                  final response = await http.patch(
                    Uri.parse('$apiBaseUrl/projects/${widget.projectId}'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': titleController.text.trim(),
                      'budget': double.parse(budgetController.text.trim()),
                      'location': locationController.text.trim(),
                      'timeline': timelineController.text.trim(),
                      'plotSize': double.parse(plotSizeController.text.trim()),
                      'type': typeController.text.trim(),
                    }),
                  );

                  if (response.statusCode == 200) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Project updated successfully'), backgroundColor: Colors.green),
                    );
                    _fetchProjectDetails();
                  } else {
                    final data = jsonDecode(response.body);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['error'] ?? 'Failed to update project'), backgroundColor: Colors.red),
                    );
                    setState(() => _isLoading = false);
                  }
                } catch (e) {
                  debugPrint('Error updating project: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection error. Failed to update.'), backgroundColor: Colors.red),
                  );
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    budgetController.dispose();
    locationController.dispose();
    timelineController.dispose();
    plotSizeController.dispose();
    typeController.dispose();
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

  Future<void> _showCompletionReviewDialog(BuildContext context) async {
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
              title: const Text('Rate & Review Service Provider'),
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
                            localRating >= starValue ? Icons.star : Icons.star_border,
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
                  child: const Text('Cancel'),
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
                  child: const Text('Submit Completion'),
                ),
              ],
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      commentController.dispose();
    });

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  offset: const Offset(0, 10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Project Completed!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Thank you for choosing $providerName for your construction project! Your rating and feedback have been successfully submitted.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx); // Close dialog
                      Navigator.pop(context); // Go back from project detail screen
                      context.push('/create-project'); // Open create new project screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Create New Project",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
    final title = _project?['title'] ?? 'Project Details';
    final type = _project?['type'] ?? 'N/A';
    final location = _project?['location'] ?? 'N/A';
    final plotSize = _project?['plotSize']?.toString() ?? '0';
    final double budget = (_project?['budget'] as num? ?? 0.0).toDouble();
    final timeline = _project?['timeline'] ?? 'N/A';
    final currentStage = _project?['currentStage'] ?? 'Design & Planning';
    final quotesList = _project?['quotes'] as List? ?? [];
    final quotesCount = quotesList.length;

    final List<String> servicesList = type != 'N/A' 
        ? List<String>.from(type.split(',').map((s) => s.trim()))
        : ['Design & Planning', 'Construction'];

    final acceptedQuote = quotesList.firstWhere(
      (q) => q['isAccepted'] == true,
      orElse: () => null,
    );
    final hasAcceptedQuote = acceptedQuote != null;

    final tasksList = _project?['tasks'] as List? ?? [];
    double totalSpent = 0.0;
    double totalQuotedTasks = 0.0;
    for (var t in tasksList) {
      totalQuotedTasks += (t['quotedCost'] as num? ?? 0.0).toDouble();
      if (t['status'] == 'Completed') {
        totalSpent += (t['quotedCost'] as num? ?? 0.0).toDouble();
      }
    }
    final completedTasksWithCost = tasksList.where((t) {
      return t['status'] == 'Completed' && (t['quotedCost'] as num? ?? 0.0) > 0;
    }).toList();
    
    final double projectCostBasis = hasAcceptedQuote
        ? (acceptedQuote['estimatedCost'] as num? ?? 0.0).toDouble()
        : budget;
    final double remainingBudget = budget - totalQuotedTasks;

    final completedCount = tasksList.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasksList.length;

    double progressValue = 0.0;
    if (totalCount > 0) {
      progressValue = completedCount / totalCount;
    } else {
      // Fallback stage-based progress if no tasks exist yet
      if (currentStage == 'Design & Planning') {
        progressValue = quotesCount > 0 ? 0.25 : 0.05;
      } else if (currentStage == 'Tracking' || currentStage == 'Execution') {
        progressValue = 0.5;
      } else if (currentStage == 'Finished Pending Approval') {
        progressValue = 0.9;
      } else if (currentStage == 'Completed') {
        progressValue = 1.0;
      } else {
        progressValue = 0.15;
      }
    }

    return Stack(
      children: [
        WallpaperBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          actions: [
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditProjectDialog();
                } else if (val == 'delete') {
                  _showDeleteConfirmationDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit Project'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Project'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
                ? const Center(child: Text('Project details not found.'))
                : RefreshIndicator(
        onRefresh: _fetchProjectDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Completion Verification Banner
              if (currentStage == 'Finished Pending Approval') ...[
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade300, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: Colors.amber.shade800, size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Verify Project Completion',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The provider has marked this project as finished! Do you agree that the project has been fully and satisfactorily completed? Please verify and leave a review.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showCompletionReviewDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve & Review'),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => _updateProjectStage('Tracking'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject Completion'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Overview Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Budget', style: TextStyle(color: Colors.grey)),
                          Text('₹$budget', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Location', style: TextStyle(color: Colors.grey)),
                          Text(location, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Category', style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Plot Size', style: TextStyle(color: Colors.grey)),
                          Text('$plotSize sq ft', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Timeline', style: TextStyle(color: Colors.grey)),
                          Text(timeline, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text('Project Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progressValue, minHeight: 10, borderRadius: const BorderRadius.all(Radius.circular(5))),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  String progressStageText = hasAcceptedQuote 
                      ? 'Current Stage: Execution Tracking ($currentStage)' 
                      : 'Current Stage: $currentStage';
                  Color progressStageColor = Colors.blue;
                  
                  if (!hasAcceptedQuote && currentStage == 'Design & Planning') {
                    if (quotesCount == 0) {
                      progressStageText = 'Current Stage: Waiting for Quotes';
                      progressStageColor = Colors.orange.shade700;
                    } else {
                      progressStageText = 'Current Stage: $quotesCount ${quotesCount == 1 ? 'Quote' : 'Quotes'} Received';
                      progressStageColor = Colors.green.shade600;
                    }
                  }
                  
                  return Text(
                    progressStageText,
                    style: TextStyle(fontWeight: FontWeight.w500, color: progressStageColor),
                  );
                }
              ),
              
              const SizedBox(height: 24),
              if (!hasAcceptedQuote) ...[
                Text('Recommended Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (currentStage == "Design & Planning") ...[
                  _buildServiceRecommendation(context, 'Architects', 'Design & Planning'),
                  _buildServiceRecommendation(context, 'Structural Engineers', 'Engineering (MEP)'),
                ],
                const SizedBox(height: 24),
              ],
              
              if (hasAcceptedQuote) ...[
                _buildProjectTrackingCard(context, quotesList, servicesList, _project?['updates'] as List? ?? []),
                const SizedBox(height: 24),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quotes Received', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    if (quotesCount > 0)
                      ElevatedButton(
                        onPressed: () async {
                          final result = await context.push('/compare-quotes/${widget.projectId}');
                          if (result == true) {
                            _fetchProjectDetails();
                          }
                        },
                        child: const Text('Compare'),
                      )
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.request_quote, color: Colors.orange),
                    title: Text(quotesCount == 0 
                        ? 'No Quotes Yet' 
                        : quotesCount == 1 
                            ? '1 Quote Available' 
                            : '$quotesCount Quotes Available'),
                    subtitle: Text(quotesCount == 0 
                        ? 'Quotes from service providers will show here' 
                        : 'Review and accept to proceed'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () async {
                      final result = await context.push('/compare-quotes/${widget.projectId}');
                      if (result == true) {
                        _fetchProjectDetails();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text('Cost Tracking', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: Colors.orange,
                                value: totalQuotedTasks > 0 ? totalQuotedTasks : 0.1,
                                title: totalQuotedTasks > 0 ? 'Allocated (₹${totalQuotedTasks.toStringAsFixed(0)})' : 'No Quotes',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: remainingBudget >= 0 ? Colors.green : Colors.red,
                                value: remainingBudget > 0 ? remainingBudget : 0.1,
                                title: remainingBudget > 0 ? 'Remaining (₹${remainingBudget.toStringAsFixed(0)})' : 'Over Limit',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCostRow('Customer Estimated Budget', '₹${budget.toStringAsFixed(2)}', Colors.black54),
                      const Divider(),
                      _buildCostRow('Total Quoted Contract Basis', '₹${projectCostBasis.toStringAsFixed(2)}', Colors.black),
                      const Divider(),
                      _buildCostRow('Total Allocated Quoted Tasks', '₹${totalQuotedTasks.toStringAsFixed(2)}', Colors.orange),
                      const Divider(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCostRow('Remaining Project Budget', '₹${remainingBudget.toStringAsFixed(2)}', remainingBudget >= 0 ? Colors.green : Colors.red),
                          const SizedBox(height: 4),
                          Text(
                            'Calculation: ₹${budget.toStringAsFixed(0)} (Total Budget) - ₹${totalQuotedTasks.toStringAsFixed(0)} (Quoted Tasks) = ₹${remainingBudget.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildCostRow('Total Cash Spent (Completed Tasks)', '₹${totalSpent.toStringAsFixed(2)}', Colors.blueGrey),
                      if (completedTasksWithCost.isNotEmpty) ...[
                        const Divider(height: 32, thickness: 1.2),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Completed Expenses Breakdown:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...completedTasksWithCost.map((t) {
                          final title = t['title'] ?? 'Completed Task';
                          final costVal = (t['quotedCost'] as num? ?? 0.0).toDouble();
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${costVal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              )
            ],
          ),
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
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceRecommendation(BuildContext context, String title, String category) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.architecture, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Find professionals for this stage'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => context.push('/providers/$category'),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }

  Widget _buildProjectTrackingCard(BuildContext context, List<dynamic> quotesList, List<String> servicesList, List<dynamic> updates) {
    final acceptedQuote = quotesList.firstWhere(
      (q) => q['isAccepted'] == true,
      orElse: () => null,
    );

    if (acceptedQuote == null) return const SizedBox.shrink();

    final provider = acceptedQuote['provider'] ?? {};
    final providerName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final tasks = _project?['tasks'] as List? ?? [];
    final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
    final totalCount = tasks.length;
    final progressPercent = totalCount > 0 ? completedCount / totalCount : 0.0;

    final Map<String, List<dynamic>> groupedTasks = {};
    for (final task in tasks) {
      final stage = task['stage'] ?? 'General Planning';
      groupedTasks.putIfAbsent(stage, () => []).add(task);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Project Tracking Process',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the progress of your project stages based on your selected requirements.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            // Tab / Segment Selector
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTrackingTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTrackingTab == 0 ? Theme.of(context).primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '📊 Execution Plan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTrackingTab == 0 ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedTrackingTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTrackingTab == 1 ? Theme.of(context).primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '📝 Daily Logs',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedTrackingTab == 1 ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_selectedTrackingTab == 0) ...[
              // Execution Plan Tab
              if (tasks.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${(progressPercent * 100).toInt()}% Done ($completedCount/$totalCount)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (tasks.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pending_actions, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Plan Pending Creation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your provider ($providerName) will post the step-by-step project plan soon.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...groupedTasks.entries.map((entry) {
                  final stageName = entry.key;
                  final stageTasks = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.06),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
                          child: Text(
                            stageName.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stageTasks.length,
                          separatorBuilder: (context, idx) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final task = stageTasks[idx];
                            final tTitle = task['title'] ?? 'Untitled Step';
                            final tDuration = task['duration'] ?? 1;
                            final tStatus = task['status'] ?? 'Todo';
                            final hasPhoto = task['photoUrl'] != null && (task['photoUrl'] as String).isNotEmpty;

                            IconData statusIcon = Icons.circle_outlined;
                            Color statusColor = Colors.grey;
                            if (tStatus == 'In Progress') {
                              statusIcon = Icons.play_circle_fill;
                              statusColor = Colors.blue;
                            } else if (tStatus == 'Completed') {
                              statusIcon = Icons.check_circle;
                              statusColor = Colors.green;
                            }

                            return ListTile(
                              dense: true,
                              onTap: hasPhoto ? () => _showCompletionPhotoDialog(task) : null,
                              leading: Icon(statusIcon, color: statusColor, size: 22),
                              title: Text(
                                tTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration: tStatus == 'Completed' ? TextDecoration.lineThrough : null,
                                  color: tStatus == 'Completed' ? Colors.grey : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Estimated: $tDuration days • Status: ',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        TextSpan(
                                          text: tStatus,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: tStatus == 'Completed'
                                                ? Colors.green
                                                : tStatus == 'In Progress'
                                                    ? Colors.blue
                                                    : Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final quoted = (task['quotedCost'] as num? ?? 0.0).toDouble();
                                      if (quoted <= 0.0) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Quoted Task Price: ₹${quoted.toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },
                                  ),
                                  if (hasPhoto) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.photo_library, size: 12, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Completion photo attached (Tap to view)',
                                          style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ]
            ] else ...[
              // Daily Logs Tab
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Construction Logs',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (updates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No logs posted by provider yet.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
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

                    Color statusColor = Colors.blue;
                    if (upStatus == 'Completed') statusColor = Colors.green;
                    if (upStatus == 'Milestone Reached') statusColor = Colors.orange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  upStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (upNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              upNotes,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Verified Log',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                upTime,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCompletionPhotoDialog(Map<String, dynamic> task) {
    final title = task['title'] ?? 'Task Details';
    final photoUrl = task['photoUrl'] as String?;

    if (photoUrl == null || photoUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proof of Completion attached by provider:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(photoUrl.split(',').last),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
