import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../b2b/services/b2b_api_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _profileImage;
  Map<String, dynamic>? _providerData;
  List<dynamic> _portfolio = [];
  int _completedProjectsCount = 0;
  List<dynamic> _supplierProducts = [];
  int _supplierLeadsCount = 0;
  int _serviceLeadsCount = 0;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  Future<void> _fetchProfileData() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) return;

    if (auth.role != 'PROVIDER') {
      // Fetch consumer profile details if any
      return;
    }

    // Phase 1: Fetch primary profile data to render the screen ASAP
    setState(() => _isLoading = true);

    try {
      final profileRes = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/profile'));
      if (mounted && profileRes.statusCode == 200) {
        setState(() {
          _providerData = jsonDecode(profileRes.body)['provider'];
          _profileImage = _providerData?['profileImage'];
          _isLoading = false; // Render the UI immediately!
        });
      }
    } catch (e) {
      debugPrint('Error fetching primary profile data: $e');
      if (mounted) setState(() => _isLoading = false);
    }

    // Phase 2: Fetch other tabs/details in the background asynchronously
    _fetchBackgroundDetails(auth.id!);
  }

  Future<void> _fetchBackgroundDetails(String providerId) async {
    // 1. Fetch portfolio
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/providers/$providerId/portfolio'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _portfolio = jsonDecode(res.body)['images'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error background fetching portfolio: $e');
    }

    // 2. Fetch projects (for completed projects count)
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/providers/$providerId/projects'));
      if (res.statusCode == 200 && mounted) {
        final projectsList = jsonDecode(res.body) as List;
        setState(() {
          _completedProjectsCount = projectsList.where((p) => p['currentStage'] == 'Completed').length;
        });
      }
    } catch (e) {
      debugPrint('Error background fetching projects: $e');
    }

    // 3. Fetch stats
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/providers/$providerId/stats'));
      if (res.statusCode == 200 && mounted) {
        final statsObj = jsonDecode(res.body);
        setState(() {
          _serviceLeadsCount = statsObj['activeLeads'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error background fetching stats: $e');
    }

    // 4. Fetch supplier products
    try {
      final res = await B2BApiService().get('/supplier/products', queryParameters: {'supplierId': providerId});
      if (res.success && res.data != null && mounted) {
        setState(() {
          _supplierProducts = res.data['products'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error background fetching supplier products: $e');
    }

    // 5. Fetch supplier leads
    try {
      final res = await B2BApiService().get('/supplier/leads', queryParameters: {'supplierId': providerId});
      if (res.success && res.data != null && mounted) {
        final leadsList = res.data['leads'] as List?;
        setState(() {
          _supplierLeadsCount = leadsList?.length ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error background fetching supplier leads: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);

    if (auth.role != 'PROVIDER') {
      return _buildConsumerProfile(context, auth, isDark);
    }

    final name = auth.businessName ?? auth.name ?? 'Guest Provider';

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 4,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        pinned: true,
                        floating: true,
                        backgroundColor: isDark ? const Color(0xFF121B22) : Colors.transparent,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => _showSettingsBottomSheet(context),
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: _buildProviderHeader(primaryColor, isDark),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.center,
                            indicatorColor: const Color(0xFF002E3B),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: const Color(0xFF002E3B),
                            unselectedLabelColor: isDark ? Colors.white54 : Colors.grey.shade600,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 16),
                                    SizedBox(width: 6),
                                    Text('Showcase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.storefront_outlined, size: 16),
                                    SizedBox(width: 6),
                                    Text('Materials', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_outline_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Reviews', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Text('Ledger', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          isDark,
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _buildPortfolioTab(isDark),
                      _buildSupplierProductsTab(isDark),
                      _buildReviewsTab(isDark),
                      _buildInfoTab(isDark),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProviderHeader(Color primaryColor, bool isDark) {
    if (_providerData == null) return const SizedBox();

    final name = _providerData!['businessName'] ?? 'Unknown Business';
    final owner = _providerData!['ownerName'] ?? 'N/A';
    final experience = _providerData!['experience'] ?? 0;
    final rating = _providerData!['avgRating'] ?? 0.0;
    final categories = (_providerData!['category'] as String? ?? 'General').split(',');
    final bio = _providerData!['bio'] ?? 'No bio provided.';
    final reviewsCount = (_providerData!['reviews'] as List?)?.length ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF002E3B), Color(0xFF002E3B)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF002E3B), width: 2),
                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                                    ? MemoryImage(base64Decode(_profileImage!.split(',').last))
                                    : null,
                                child: _profileImage == null || _profileImage!.isEmpty
                                    ? Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF002E3B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.engineering_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.verified_user_rounded, color: Colors.green, size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'User: $owner  •  $experience Yrs Exp',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: categories.take(2).map((c) {
                                final cTrim = c.trim();
                                if (cTrim.isEmpty) return const SizedBox();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Text(
                                    cTrim,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF38BDF8) : Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF002E3B)),
                            const SizedBox(width: 6),
                            Text(
                              'ABOUT COMPANY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bio,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashboardMetric(
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'Completed',
                          value: '$_completedProjectsCount',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDashboardMetric(
                          icon: Icons.storefront_rounded,
                          label: 'B2B Products',
                          value: '${_supplierProducts.length}',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDashboardMetric(
                          icon: Icons.leaderboard_rounded,
                          label: 'Active Leads',
                          value: '${_serviceLeadsCount + _supplierLeadsCount}',
                          color: const Color(0xFF002E3B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF002E3B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF002E3B).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFF002E3B), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              ' ($reviewsCount)',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await context.push('/provider-profile-edit');
                            _fetchProfileData();
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Edit Provider Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                            ),
                          ),
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
    );
  }

  Widget _buildDashboardMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(bool isDark) {
    if (_portfolio.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.architecture_rounded, size: 54, color: Color(0xFF002E3B)),
              const SizedBox(height: 16),
              const Text(
                'No Showcase Projects Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addPortfolioImage,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Add Project Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002E3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _portfolio.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF002E3B).withValues(alpha: 0.4),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: _addPortfolioImage,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002E3B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF002E3B), size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002E3B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Showcase new work',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final img = _portfolio[index - 1];
        final bytes = base64Decode(img['imageData'].split(',').last);
        return Card(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: InkWell(
            onTap: () => _showPostDetailModal(context, img),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Image.memory(
                    bytes,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      img['title'] ?? 'Showcase Project',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSupplierProductsTab(bool isDark) {
    if (_supplierProducts.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.construction_rounded, size: 54, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'No Catalog Products Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/supplier-add-product').then((_) => _fetchProfileData()),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                label: const Text('Add B2B Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _supplierProducts.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.blue.withValues(alpha: 0.4),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: () => context.push('/supplier-add-product').then((_) => _fetchProfileData()),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_box_rounded, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add Product',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'List B2B Materials',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final prod = _supplierProducts[index - 1];
        final imgs = prod['images'] as List?;
        final imgUrl = (imgs != null && imgs.isNotEmpty)
            ? imgs[0] as String
            : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=300';
        final price = prod['price_per_unit'] ?? 0;
        final unit = prod['unit_type'] ?? 'Unit';

        return Card(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: InkWell(
            onTap: () => _showProductDetailsDialog(context, prod),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹$price/$unit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      prod['name'] ?? 'Product Name',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Future<void> _addPortfolioImage() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? tempBase64;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Add Project Photo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tempBase64 != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(tempBase64!.split(',').last)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1000,
                        maxHeight: 1000,
                        imageQuality: 75,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        final base64 = base64Encode(bytes);
                        setModalState(() {
                          tempBase64 = 'data:image/jpeg;base64,$base64';
                        });
                      }
                    },
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Select Photo'),
                  ),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Project Title')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description (Optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (tempBase64 == null || titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image and title')));
                  return;
                }
                Navigator.pop(ctx);
                
                setState(() => _isLoading = true);
                final auth = ref.read(authProvider);
                try {
                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/providers/${auth.id}/portfolio'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'imageData': tempBase64,
                    }),
                  );
                  if (response.statusCode == 201) {
                    _fetchProfileData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo added to portfolio!')));
                    }
                  }
                } catch (e) {
                  debugPrint('Add portfolio error: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('ADD PHOTO'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetailsDialog(BuildContext context, dynamic prod) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imgs = prod['images'] as List?;
    final imgUrl = (imgs != null && imgs.isNotEmpty)
        ? imgs[0] as String
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=600';
    
    final price = prod['price_per_unit'] ?? 0;
    final unit = prod['unit_type'] ?? 'Unit';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          prod['name'] ?? 'Product Info',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 1.2,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate: ₹$price / $unit',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        prod['description'] ?? 'No description provided.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/supplier-add-product', extra: prod).then((_) {
                          _fetchProfileData();
                        });
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text(
                        'Edit Product Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildReviewsTab(bool isDark) {
    if (_providerData == null) return const SizedBox();
    final reviews = _providerData!['reviews'] as List? ?? [];
    
    if (reviews.isEmpty) {
      return const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No Reviews Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, idx) {
        final r = reviews[idx];
        final rating = r['rating'] ?? 5;
        final comment = r['comment'] ?? '';
        final reviewer = r['user']?['name'] ?? 'Anonymous';
        final date = r['createdAt'] != null
            ? DateTime.tryParse(r['createdAt'])?.toLocal().toString().substring(0, 10) ?? ''
            : '';

        return Card(
          elevation: 0.5,
          color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reviewer,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFF002E3B),
                    size: 15,
                  )),
                ),
                if (r['project'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Project: ${r['project']['title'] ?? ''} (${r['project']['type'] ?? ''})',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(bool isDark) {
    if (_providerData == null) return const SizedBox();
    
    final email = _providerData!['email'];
    final phone = _providerData!['phone'];
    final address = _providerData!['address'];
    final ownerName = _providerData!['ownerName'] ?? 'N/A';
    final experience = _providerData!['experience'] ?? 0;
    
    final businessType = _providerData!['businessType'] ?? '';
    final gst = _providerData!['gstNumber'] ?? '';
    final website = _providerData!['website'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Card(
          elevation: 0.5,
          color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Services Provider Info',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.person_rounded, 'Owner / User', ownerName),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.work_history_rounded, 'Professional Experience', '$experience Years'),
                if (address != null && address.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on_rounded, 'Business Address', address),
                ],
                if (email != null && email.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email_rounded, 'Email Address', email),
                ],
                if (phone != null && phone.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone_rounded, 'Contact Number', phone),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0.5,
          color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Material Supplier Info',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.business_center_rounded, 'Supplier Business Type', businessType.isNotEmpty ? businessType : 'Service & Supplier'),
                if (gst.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.verified_user_rounded, 'GST Identification Number', gst),
                ],
                if (website.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.language_rounded, 'Official Business Website', website),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPostDetailModal(BuildContext context, dynamic img) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bytes = base64Decode(img['imageData'].split(',').last);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Post Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                          ? MemoryImage(base64Decode(_profileImage!.split(',').last))
                          : null,
                      child: _profileImage == null || _profileImage!.isEmpty
                          ? Text(
                              (_providerData?['businessName'] ?? 'P')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _providerData?['businessName'] ?? 'Provider',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Post Image
              AspectRatio(
                aspectRatio: 1.1,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                ),
              ),
              // Post Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      img['title'] ?? 'Showcase Detail',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    if (img['description'] != null && img['description'].toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        img['description'],
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          fontSize: 12.5,
                          height: 1.4,
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
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Account Settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/help-support');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsumerProfile(BuildContext context, AuthState auth, bool isDark) {
    final name = auth.name ?? 'Guest User';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            auth.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: Colors.grey), 
            title: const Text('Settings'), 
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Colors.grey), 
            title: const Text('Help & Support'), 
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/help-support'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), 
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverAppBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
