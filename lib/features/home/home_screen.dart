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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Custom header and top app bar
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name 👋',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: isDark ? Colors.white : const Color(0xFF064354),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Let\'s build your dream project today',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.9),
                  child: Icon(Icons.notifications_outlined, color: primaryColor),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Create Project Action Banner
                _buildCreateProjectBanner(context, isDark, primaryColor),
                const SizedBox(height: 24),

                // Ongoing Projects Section
                _buildOngoingProjectsSection(isDark, primaryColor),
                const SizedBox(height: 24),

                // Tools & Services section
                _buildToolsSection(isDark, primaryColor),
                const SizedBox(height: 24),

                // Recent Showcases Section
                _buildRecentShowcasesSection(isDark, primaryColor),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProjectBanner(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/create_project_banner.png',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Text & Button details
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final created = await context.push('/create-project');
                  if (created == true) {
                    setState(() => _isLoading = true);
                    _fetchProjects();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Estimate cost, request material quotes & start construction',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingProjectsSection(bool isDark, Color primaryColor) {
    final activeProjects = _projects.where((project) {
      final stage = (project['currentStage'] as String? ?? '').toLowerCase();
      return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ongoing Construction',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
            ),
            TextButton(
              onPressed: () => ref.read(mainTabProvider.notifier).state = 1, // index 1
              child: Text(
                'View All',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (activeProjects.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.architecture_rounded, size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No Active Construction Site',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start a new cost estimation and find contractor quotes!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),
              ],
            ),
          )
        else
          Column(
            children: activeProjects.map((project) {
              final tasks = project['tasks'] as List? ?? [];
              final completedCount = tasks.where((t) => t['status'] == 'Completed').length;
              final totalCount = tasks.length;
              final currentStage = project['currentStage'] ?? 'Design & Planning';
              final quoteCount = project['_count']?['quotes'] as int? ?? 0;

              String stageText = currentStage;
              Color stageColor = Colors.blue;
              IconData stageIcon = Icons.construction_rounded;

              if (currentStage == 'Design & Planning') {
                if (quoteCount == 0) {
                  stageText = 'Awaiting Quotes';
                  stageColor = Colors.orange.shade700;
                  stageIcon = Icons.hourglass_empty_rounded;
                } else {
                  stageText = '$quoteCount Quotes Received';
                  stageColor = Colors.green.shade600;
                  stageIcon = Icons.mark_chat_unread_rounded;
                }
              } else {
                switch (currentStage.toLowerCase()) {
                  case 'completed':
                  case 'finished':
                    stageColor = Colors.green;
                    stageIcon = Icons.check_circle_rounded;
                    break;
                  case 'finished pending approval':
                    stageColor = Colors.amber.shade800;
                    stageIcon = Icons.rate_review_rounded;
                    break;
                  case 'on hold':
                    stageColor = Colors.orange;
                    stageIcon = Icons.pause_circle_filled_rounded;
                    break;
                  case 'cancelled':
                    stageColor = Colors.red;
                    stageIcon = Icons.cancel_rounded;
                    break;
                  default:
                    stageColor = Colors.blue;
                    stageIcon = Icons.construction_rounded;
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
                elevation: 0.3,
                color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stageColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(stageIcon, color: stageColor, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    stageText,
                                    style: TextStyle(color: stageColor, fontWeight: FontWeight.bold, fontSize: 9.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.red.shade400),
                            const SizedBox(width: 2),
                            Text(
                              project['location'] ?? 'N/A',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                            ),
                            const Spacer(),
                            const Icon(Icons.currency_rupee_rounded, size: 13, color: Colors.green),
                            Text(
                              ((project['budget'] as num? ?? 0.0).toDouble()).toStringAsFixed(0),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green, fontSize: 13),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              totalCount > 0 ? 'Tasks Done: $completedCount/$totalCount' : 'Current Stage Progress',
                              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            minHeight: 4.5,
                          ),
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

  Widget _buildToolsSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workspace Tools',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildPremiumToolCard(
              context,
              title: 'Cost Estimator',
              subtitle: 'Calculate build costs & layouts',
              icon: Icons.calculate_rounded,
              color: Colors.green,
              onTap: () => context.push('/cost-estimation'),
              isDark: isDark,
            ),
            _buildPremiumToolCard(
              context,
              title: 'B2B Marketplace',
              subtitle: 'Bulk building materials sourcing',
              icon: Icons.storefront_rounded,
              color: Colors.blue,
              onTap: () => context.push('/b2b-products'),
              isDark: isDark,
            ),
            _buildPremiumToolCard(
              context,
              title: 'Material Quotes',
              subtitle: 'Track your material requests',
              icon: Icons.assignment_rounded,
              color: Colors.orange,
              onTap: () => context.push('/b2b-my-inquiries'),
              isDark: isDark,
            ),
            _buildPremiumToolCard(
              context,
              title: 'Market Trends',
              subtitle: 'Commodity price index tracker',
              icon: Icons.trending_up_rounded,
              color: Colors.teal,
              onTap: () => context.push('/b2b-news'),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      elevation: 0.3,
      color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 9.5, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentShowcasesSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Builder Showcases',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.2),
            ),
            TextButton(
              onPressed: () => ref.read(mainTabProvider.notifier).state = 2, // index 2
              child: Text(
                'View All',
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_isLoadingSocial)
          const Center(child: CircularProgressIndicator())
        else if (_socialPosts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No showcases found.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _socialPosts.length > 3 ? 3 : _socialPosts.length, // Show top 3
            itemBuilder: (context, index) {
              final post = _socialPosts[index];
              return _buildHomeSocialPostCard(post, isDark, primaryColor);
            },
          ),
      ],
    );
  }

  Widget _buildHomeSocialPostCard(dynamic post, bool isDark, Color primaryColor) {
    final postId = post['id'] ?? '';
    final provider = post['provider'] ?? {};
    final providerId = provider['id'] ?? '';
    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final category = provider['category'] ?? 'Contractor';
    final title = post['title'] ?? 'Work Showcase';
    final description = post['description'] ?? '';
    final imageData = post['imageData'] as String?;

    final isLiked = _likedPostIds.contains(postId);
    final likes = _likeCounts[postId] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0.3,
      color: isDark ? const Color(0xFF1F2C34).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    radius: 16,
                    child: Text(
                      businessName.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          category,
                          style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),

          // Main image
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
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: MemoryImage(base64Decode(imageData.split(',').last)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Actions
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isLiked ? Colors.red : Colors.grey.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likes',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
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
}
