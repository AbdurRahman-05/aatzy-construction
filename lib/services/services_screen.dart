import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';
import '../features/providers/provider_profile_screen.dart';
import 'category_social_feed_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _selectedTab = 0; // 0 for Services, 1 for Social
  List<dynamic> _socialPosts = [];
  bool _isLoadingSocial = false;
  final Set<String> _likedPostIds = {};
  final Map<String, int> _likeCounts = {};

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Land & Legal', 'icon': Icons.landscape},
    {'name': 'Finance & Approvals', 'icon': Icons.account_balance},
    {'name': 'Survey & Analysis', 'icon': Icons.map},
    {'name': 'Design & Planning', 'icon': Icons.architecture},
    {'name': 'Construction', 'icon': Icons.construction},
    {'name': 'Engineering (MEP)', 'icon': Icons.engineering},
    {'name': 'Materials & Supply', 'icon': Icons.inventory},
    {'name': 'Utilities', 'icon': Icons.power},
    {'name': 'Interiors & Finishing', 'icon': Icons.format_paint},
    {'name': 'Project Management', 'icon': Icons.assignment},
    {'name': 'Inspection & Compliance', 'icon': Icons.fact_check},
    {'name': 'Smart & Security', 'icon': Icons.security},
    {'name': 'Logistics & Equipment', 'icon': Icons.local_shipping},
    {'name': 'Insurance', 'icon': Icons.shield},
  ];

  @override
  void initState() {
    super.initState();
    _fetchSocialFeed();
  }

  Future<void> _fetchSocialFeed() async {
    setState(() => _isLoadingSocial = true);
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
      debugPrint('Error fetching social feed: $e');
      if (mounted) setState(() => _isLoadingSocial = false);
    }
  }

  Map<String, List<dynamic>> _groupPostsByCategory() {
    Map<String, List<dynamic>> groups = {};
    for (var post in _socialPosts) {
      final provider = post['provider'] ?? {};
      final category = provider['category'] ?? 'General';
      if (!groups.containsKey(category)) {
        groups[category] = [];
      }
      groups[category]!.add(post);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Services & Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedTab == 1) {
                _fetchSocialFeed();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Styled Premium Tab Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.miscellaneous_services_outlined,
                            size: 18,
                            color: _selectedTab == 0 ? Colors.white : Colors.grey.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Services',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.white : Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dynamic_feed_outlined,
                            size: 18,
                            color: _selectedTab == 1 ? Colors.white : Colors.grey.shade800,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Social Feed',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.white : Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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

          Expanded(
            child: _selectedTab == 0 ? _buildServicesGrid() : _buildSocialFeedView(),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return InkWell(
          onTap: () => context.push('/providers/${cat['name']}'),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'] as IconData, size: 40, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  cat['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialFeedView() {
    if (_isLoadingSocial) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedPosts = _groupPostsByCategory();

    if (groupedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No portfolio posts found.',
              style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: categories.length,
      itemBuilder: (context, catIdx) {
        final categoryName = categories[catIdx]['name'] as String;
        final posts = groupedPosts[categoryName] ?? [];

        if (posts.isEmpty) {
          return const SizedBox.shrink(); // Don't show categories without posts
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header with View All Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategorySocialFeedScreen(
                            categoryName: categoryName,
                            posts: posts,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: const [
                        Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Carousel of Instagram-like Posts
            SizedBox(
              height: 290,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                itemBuilder: (context, postIdx) {
                  final post = posts[postIdx];
                  return _buildCarouselPostCard(post, categoryName);
                },
              ),
            ),
            const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }

  Widget _buildCarouselPostCard(dynamic post, String categoryName) {
    final postId = post['id'] ?? '';
    final provider = post['provider'] ?? {};
    final providerId = provider['id'] ?? '';
    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final title = post['title'] ?? 'Work Showcase';
    final imageData = post['imageData'] as String?;

    final isLiked = _likedPostIds.contains(postId);
    final likes = _likeCounts[postId] ?? 0;

    return Container(
      width: 230,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Header Row
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
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        businessName.substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        businessName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Image Section
            if (imageData != null)
              Expanded(
                child: InkWell(
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
                  child: Image.memory(
                    base64Decode(imageData.split(',').last),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),

            // Bottom Actions & Title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey.shade700,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$likes likes',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
