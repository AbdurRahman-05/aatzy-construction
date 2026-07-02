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


  final List<Map<String, dynamic>> categories = const [
    // --- Original Categories ---
    {'name': 'Land & Legal', 'icon': Icons.landscape},
    {'name': 'Finance & Approvals', 'icon': Icons.account_balance},
    {'name': 'Survey & Analysis', 'icon': Icons.map},
    {'name': 'Design & Planning', 'icon': Icons.architecture},
    {'name': 'Construction', 'icon': Icons.construction},
    {'name': 'Engineering (MEP)', 'icon': Icons.engineering},
    {'name': 'Materials & Supply', 'icon': Icons.inventory},
    {'name': 'Utilities', 'icon': Icons.power},
    {'name': 'Borewell', 'icon': Icons.water_drop},
    {'name': 'Interiors & Finishing', 'icon': Icons.format_paint},
    {'name': 'Project Management', 'icon': Icons.assignment},
    {'name': 'Inspection & Compliance', 'icon': Icons.fact_check},
    {'name': 'Smart & Security', 'icon': Icons.security},
    {'name': 'Logistics & Equipment', 'icon': Icons.local_shipping},
    {'name': 'Insurance', 'icon': Icons.shield},

    // --- Construction Services (from reference) ---
    {'name': 'Blacksmith', 'icon': Icons.hardware},
    {'name': 'Bricklayer/Stonemason', 'icon': Icons.view_module},
    {'name': 'Builder/General Contractor', 'icon': Icons.apartment},
    {'name': 'Cabinet Maker', 'icon': Icons.kitchen},
    {'name': 'Carpenter', 'icon': Icons.carpenter},
    {'name': 'Cement / Concrete', 'icon': Icons.foundation},
    {'name': 'Commercial Builder', 'icon': Icons.domain},
    {'name': 'Construction (Other)', 'icon': Icons.build_circle},
    {'name': 'Construction Project Management', 'icon': Icons.assignment_turned_in},
    {'name': 'Counter Top', 'icon': Icons.countertops},
    {'name': 'Demolition Contractor', 'icon': Icons.delete_sweep},
    {'name': 'Drainage', 'icon': Icons.water_damage},
    {'name': 'Drywall', 'icon': Icons.grid_on},
    {'name': 'Electrical Contractor', 'icon': Icons.electrical_services},
    {'name': 'Electrician - Commercial', 'icon': Icons.bolt},
    {'name': 'Elevator', 'icon': Icons.elevator},
    {'name': 'Energy Services', 'icon': Icons.energy_savings_leaf},
    {'name': 'Environmental Services', 'icon': Icons.eco},
    {'name': 'Fences', 'icon': Icons.fence},
    {'name': 'Fireplace & Oven Builder', 'icon': Icons.fireplace},
    {'name': 'Flooring', 'icon': Icons.layers},
    {'name': 'Garage Doors', 'icon': Icons.garage},
    {'name': 'Glass', 'icon': Icons.window},
    {'name': 'Ground Work', 'icon': Icons.terrain},
    {'name': 'Handyman', 'icon': Icons.handyman},
    {'name': 'Heating Engineer', 'icon': Icons.thermostat},
    {'name': 'HVAC - Heating & Air', 'icon': Icons.hvac},
    {'name': 'Interior Design - Commercial', 'icon': Icons.business_center},
    {'name': 'Interior Design - Residential', 'icon': Icons.chair},
    {'name': 'Kitchen Construction', 'icon': Icons.soup_kitchen},
    {'name': 'Metal Work', 'icon': Icons.precision_manufacturing},
    {'name': 'Painter', 'icon': Icons.format_paint_outlined},
    {'name': 'Pest Control', 'icon': Icons.pest_control},
    {'name': 'Plasterer', 'icon': Icons.imagesearch_roller},
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Pools, Spas & Saunas', 'icon': Icons.pool},
    {'name': 'Power Generator', 'icon': Icons.power},
    {'name': 'Power Washing', 'icon': Icons.cleaning_services},
    {'name': 'Protective Coatings/Sealants', 'icon': Icons.format_color_fill},
    {'name': 'Renovations/Remodeling', 'icon': Icons.home_repair_service},
    {'name': 'Restoration', 'icon': Icons.restore},
    {'name': 'Roofing & Gutters', 'icon': Icons.roofing},
    {'name': 'Septic Systems', 'icon': Icons.water},
    {'name': 'Shutters & Awnings', 'icon': Icons.blinds},
    {'name': 'Solar', 'icon': Icons.solar_power},
    {'name': 'Tile Worker', 'icon': Icons.grid_view},
    {'name': 'Waterproofing-Weatherproofing', 'icon': Icons.umbrella},
    {'name': 'Window Treatments', 'icon': Icons.curtains},
    {'name': 'Windows & Doors', 'icon': Icons.door_sliding},
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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

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
              color: Colors.grey.shade100.withValues(alpha: 0.9),
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
                        color: _selectedTab == 0 ? primaryColor : Colors.transparent,
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
                        color: _selectedTab == 1 ? primaryColor : Colors.transparent,
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
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
                Icon(cat['icon'] as IconData, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      children: [
                        Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.primary)),
                        Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
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
    final provider = post['provider'] ?? {};
    final providerId = provider['id'] ?? '';
    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
    final title = post['title'] ?? 'Work Showcase';
    final imageData = post['imageData'] as String?;

    return Container(
      width: 230,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        businessName.substring(0, 1).toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
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
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
