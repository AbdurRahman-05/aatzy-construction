import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../b2b/services/b2b_api_service.dart';

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

    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/profile')),
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/portfolio')),
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/projects')),
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats')),
        B2BApiService().get('/supplier/products', queryParameters: {'supplierId': auth.id!}),
        B2BApiService().get('/supplier/leads', queryParameters: {'supplierId': auth.id!}),
      ]);

      if (mounted) {
        final res0 = responses[0] as http.Response;
        final res1 = responses[1] as http.Response;
        final res2 = responses[2] as http.Response;
        final res3 = responses[3] as http.Response;
        final resProds = responses[4] as B2BApiResponse;
        final resLeads = responses[5] as B2BApiResponse;

        setState(() {
          if (res0.statusCode == 200) {
            _providerData = jsonDecode(res0.body)['provider'];
            _profileImage = _providerData?['profileImage'];
          }
          if (res1.statusCode == 200) {
            _portfolio = jsonDecode(res1.body)['images'] ?? [];
          }
          if (res2.statusCode == 200) {
            final projectsList = jsonDecode(res2.body) as List;
            _completedProjectsCount = projectsList.where((p) => p['currentStage'] == 'Completed').length;
          }
          if (res3.statusCode == 200) {
            final statsObj = jsonDecode(res3.body);
            _serviceLeadsCount = statsObj['activeLeads'] ?? 0;
          }
          if (resProds.success && resProds.data != null) {
            _supplierProducts = resProds.data['products'] ?? [];
          }
          if (resLeads.success && resLeads.data != null) {
            final leadsList = resLeads.data['leads'] as List?;
            _supplierLeadsCount = leadsList?.length ?? 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching provider profile data: $e');
      if (mounted) setState(() => _isLoading = false);
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
                            indicatorColor: primaryColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: primaryColor,
                            unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                            tabs: const [
                              Tab(icon: Icon(Icons.photo_library_outlined, size: 22)),
                              Tab(icon: Icon(Icons.storefront_outlined, size: 22)),
                              Tab(icon: Icon(Icons.star_outline_rounded, size: 24)),
                              Tab(icon: Icon(Icons.info_outline_rounded, size: 22)),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Profile photo and metrics
          Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.orange, Colors.amber],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF121B22) : Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                        ? MemoryImage(base64Decode(_profileImage!.split(',').last))
                        : null,
                    child: _profileImage == null || _profileImage!.isEmpty
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Metrics
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricItem('Completed', '$_completedProjectsCount'),
                    _buildMetricItem('B2B Products', '${_supplierProducts.length}'),
                    _buildMetricItem('Total Leads', '${_serviceLeadsCount + _supplierLeadsCount}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Business name & Verification Badge
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.2),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 2),
              Text(
                '${rating.toStringAsFixed(1)} ($reviewsCount reviews)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          // Profession / Category Labels
          const SizedBox(height: 2),
          Text(
            categories.map((c) => c.trim()).where((c) => c.isNotEmpty).join(' • '),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF0F9B8E) : Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 6),
          // Bio Text
          Text(
            bio,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          // Owner & Experience
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              children: [
                const TextSpan(text: 'Founder: '),
                TextSpan(text: owner, style: const TextStyle(fontWeight: FontWeight.w600)),
                const TextSpan(text: '  |  '),
                TextSpan(text: '$experience Years Experience', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await context.push('/provider-profile-edit');
                _fetchProfileData();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPortfolioTab(bool isDark) {
    if (_portfolio.isEmpty) {
      return const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No Portfolio Posts Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Add images to your portfolio by tapping "Edit Profile".',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: _portfolio.length,
      itemBuilder: (context, index) {
        final img = _portfolio[index];
        final bytes = base64Decode(img['imageData'].split(',').last);
        return InkWell(
          onTap: () => _showPostDetailModal(context, img),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                bytes,
                fit: BoxFit.cover,
              ),
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.layers_outlined,
                  color: Colors.white,
                  size: 16,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
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
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No Catalog Products Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.push('/supplier-add-product').then((_) => _fetchProfileData()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add B2B Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: _supplierProducts.length,
      itemBuilder: (context, index) {
        final prod = _supplierProducts[index];
        final imgs = prod['images'] as List?;
        final imgUrl = (imgs != null && imgs.isNotEmpty)
            ? imgs[0] as String
            : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=300';
            
        return InkWell(
          onTap: () => _showProductDetailsDialog(context, prod),
          child: Image.network(
            imgUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
            ),
          ),
        );
      },
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
            ],
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
                    color: Colors.amber,
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
                _buildInfoRow(Icons.person_rounded, 'Owner / Founder', ownerName),
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
      color: isDark ? const Color(0xFF121B22) : const Color(0xFFF4EFE6),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
