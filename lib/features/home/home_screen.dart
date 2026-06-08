import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../providers/provider_profile_screen.dart';
import 'main_layout.dart'; // import tab provider

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _projects = [];
  List<dynamic> _socialPosts = [];
  bool _isLoading = true;
  bool _isLoadingSocial = true;
  final Set<String> _likedPostIds = {};
  final Map<String, int> _likeCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _fetchSocialFeed();
  }

  Future<void> _fetchProjects() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/users/${auth.id}/projects'));
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
      debugPrint('Error fetching projects: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSocialFeed() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/social/feed'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _socialPosts = data['images'] ?? [];
            _isLoadingSocial = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingSocial = false);
      }
    } catch (e) {
      debugPrint('Error fetching home social feed: $e');
      if (mounted) setState(() => _isLoadingSocial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.name ?? 'Guest';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome back, $name!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Create Project Action
            InkWell(
              onTap: () async {
                final created = await context.push('/create-project');
                if (created == true) {
                  setState(() {
                    _isLoading = true;
                  });
                  _fetchProjects();
                }
              },
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // AI Generated Background Image
                      Positioned.fill(
                        child: Image.asset(
                          'assets/create_project_banner.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Dark gradient overlay for text readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.black.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Text & Icon
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Create New Project',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Start planning your dream home',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 14,
                                    ),
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
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ongoing Projects', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // Navigate to Projects list tab (index 1)
                    ref.read(mainTabProvider.notifier).state = 1;
                  },
                  child: const Text('View All'),
                )
              ],
            ),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_projects.where((project) {
              final stage = (project['currentStage'] as String? ?? '').toLowerCase();
              return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
            }).isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No active projects yet. Click above to start!'),
              ))
            else
              ..._projects.where((project) {
                final stage = (project['currentStage'] as String? ?? '').toLowerCase();
                return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
              }).map((project) {
                final tasks = project['tasks'] as List? ?? [];
                final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
                final totalCount = tasks.length;
                final currentStage = project['currentStage'] ?? 'Design & Planning';
                final quoteCount = project['_count']?['quotes'] as int? ?? 0;
                
                String stageText = currentStage;
                Color stageColor = Colors.blue;
                IconData stageIcon = Icons.construction;
                
                if (currentStage == 'Design & Planning') {
                  if (quoteCount == 0) {
                    stageText = 'Waiting for Quotes';
                    stageColor = Colors.orange.shade700;
                    stageIcon = Icons.hourglass_empty;
                  } else {
                    stageText = '$quoteCount ${quoteCount == 1 ? 'Quote' : 'Quotes'} Received';
                    stageColor = Colors.green.shade600;
                    stageIcon = Icons.mark_chat_unread;
                  }
                } else {
                  switch (currentStage.toLowerCase()) {
                    case 'completed':
                    case 'finished':
                      stageColor = Colors.green;
                      stageIcon = Icons.check_circle;
                      break;
                    case 'finished pending approval':
                      stageColor = Colors.amber.shade800;
                      stageIcon = Icons.rate_review;
                      break;
                    case 'on hold':
                      stageColor = Colors.orange;
                      stageIcon = Icons.pause_circle_filled;
                      break;
                    case 'cancelled':
                      stageColor = Colors.red;
                      stageIcon = Icons.cancel;
                      break;
                    default:
                      stageColor = Colors.blue;
                      stageIcon = Icons.construction;
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      await context.push('/project-detail/${project['id']}');
                      _fetchProjects();
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
                                  project['title'] ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stageColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(stageIcon, color: stageColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      stageText,
                                      style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(project['location'] ?? 'N/A', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              const Spacer(),
                              const Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                              Text(
                                ((project['budget'] as num? ?? 0.0).toDouble()).toStringAsFixed(0),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalCount > 0 ? 'Progress: $completedCount/$totalCount Tasks' : 'Stage Progress',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              Text(
                                '${(progress * 100).toInt()}% Done',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            Text('Tools & Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildToolCard(
                  context,
                  title: 'Cost Estimator',
                  subtitle: 'Instant construction costs',
                  icon: Icons.calculate_outlined,
                  color: Colors.green,
                  onTap: () => context.push('/cost-estimation'),
                ),
                _buildToolCard(
                  context,
                  title: 'Material Sourcing',
                  subtitle: 'Bulk B2B Marketplace',
                  icon: Icons.storefront_outlined,
                  color: Colors.blue,
                  onTap: () => context.push('/b2b-products'),
                ),
                _buildToolCard(
                  context,
                  title: 'Quotes & Inquiries',
                  subtitle: 'Track material requests',
                  icon: Icons.contact_mail_outlined,
                  color: Colors.orange,
                  onTap: () => context.push('/b2b-my-inquiries'),
                ),
                _buildToolCard(
                  context,
                  title: 'Price News & Trends',
                  subtitle: 'Live commodity price index',
                  icon: Icons.trending_up_rounded,
                  color: Colors.teal,
                  onTap: () => context.push('/b2b-news'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Showcases', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // Navigate to Services / Social Feed tab (index 2)
                    ref.read(mainTabProvider.notifier).state = 2;
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoadingSocial
                ? const Center(child: CircularProgressIndicator())
                : _socialPosts.isEmpty
                    ? const Text('No recent showcases found.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _socialPosts.length > 5 ? 5 : _socialPosts.length, // Show up to 5 recent posts
                        itemBuilder: (context, index) {
                          final post = _socialPosts[index];
                          return _buildHomeSocialPostCard(post);
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeSocialPostCard(dynamic post) {
    final postId = post['id'] ?? '';
    final provider = post['provider'] ?? {};
    final providerId = provider['id'] ?? '';
    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final category = provider['category'] ?? 'General';
    final title = post['title'] ?? 'Work Showcase';
    final description = post['description'] ?? '';
    final imageData = post['imageData'] as String?;

    final isLiked = _likedPostIds.contains(postId);
    final likes = _likeCounts[postId] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Provider Info
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 16,
                    child: Text(
                      businessName.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          category,
                          style: TextStyle(fontSize: 10.5, color: Colors.blue.shade600, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Post image
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
              child: ClipRRect(
                child: Image.memory(
                  base64Decode(imageData.split(',').last),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
            ),

          // Actions and details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_likedPostIds.contains(postId)) {
                                _likedPostIds.remove(postId);
                                _likeCounts[postId] = likes - 1;
                              } else {
                                _likedPostIds.add(postId);
                                _likeCounts[postId] = likes + 1;
                              }
                            });
                          },
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
