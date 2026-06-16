import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../chat/chat_detail_screen.dart';
import '../../core/wallpaper_background.dart';
import '../b2b/services/b2b_api_service.dart';
import '../../core/full_screen_image_viewer.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  Map<String, dynamic>? _provider;
  List<dynamic> _portfolio = [];
  List<dynamic> _supplierProducts = [];
  int _completedProjectsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  Future<void> _fetchProviderData() async {
    setState(() => _isLoading = true);
    try {
      final profileRes = await http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/profile'));
      if (mounted && profileRes.statusCode == 200) {
        setState(() {
          _provider = jsonDecode(profileRes.body)['provider'];
          _isLoading = false; // Render UI immediately!
        });
      }
    } catch (e) {
      debugPrint('Error fetching provider profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }

    _fetchBackgroundDetails();
  }

  Future<void> _fetchBackgroundDetails() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/portfolio'));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _portfolio = jsonDecode(res.body)['images'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching portfolio: $e');
    }

    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/projects'));
      if (res.statusCode == 200 && mounted) {
        final projectsList = jsonDecode(res.body) as List;
        setState(() {
          _completedProjectsCount = projectsList.where((p) => p['currentStage'] == 'Completed').length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching projects: $e');
    }

    try {
      final res = await B2BApiService().get('/supplier/products', queryParameters: {'supplierId': widget.providerId});
      if (res.success && res.data != null && mounted) {
        setState(() {
          _supplierProducts = res.data['products'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching supplier products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _provider == null
                ? const Center(child: Text('Provider not found'))
                : DefaultTabController(
                    length: 4,
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            title: Text(
                              _provider!['businessName'] ?? 'Provider Details',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            pinned: true,
                            floating: true,
                            backgroundColor: isDark ? const Color(0xFF121B22) : Colors.transparent,
                            actions: [
                              IconButton(
                                icon: const Icon(Icons.share_rounded),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile link copied to clipboard')),
                                  );
                                },
                              )
                            ],
                          ),
                          SliverToBoxAdapter(
                            child: _buildProfileHeader(primaryColor, isDark),
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
                                        Text('About', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildProfileHeader(Color primaryColor, bool isDark) {
    final name = _provider!['businessName'] ?? 'Unknown Business';
    final owner = _provider!['ownerName'] ?? 'N/A';
    final experience = _provider!['experience'] ?? 0;
    final rating = _provider!['avgRating'] ?? 0.0;
    final categories = (_provider!['category'] as String? ?? 'General').split(',');
    final bio = _provider!['bio'] ?? 'No bio provided.';
    final reviewsCount = (_provider!['reviews'] as List?)?.length ?? 0;
    final profileImage = _provider!['profileImage'];

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
                                backgroundImage: profileImage != null && profileImage.toString().isNotEmpty
                                    ? MemoryImage(base64Decode(profileImage.toString().split(',').last))
                                    : null,
                                child: profileImage == null || profileImage.toString().isEmpty
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
                          icon: Icons.star_rounded,
                          label: 'Rating ($reviewsCount)',
                          value: rating.toStringAsFixed(1),
                          color: const Color(0xFF002E3B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showQuoteModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Request Quote', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          final businessName = _provider!['businessName'] ?? 'Provider';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                partnerId: widget.providerId,
                                partnerName: businessName,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded, color: primaryColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _showWriteReviewModal(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        child: Icon(Icons.rate_review_outlined, color: primaryColor, size: 18),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(bool isDark) {
    if (_portfolio.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No Portfolio Posts Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'This provider hasn\'t added project images to their showcase yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
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
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _portfolio.length,
      itemBuilder: (context, index) {
        final img = _portfolio[index];
        final bytes = base64Decode(img['imageData'].split(',').last);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
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
              const Icon(Icons.storefront_rounded, size: 54, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'No Catalog Products Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'This provider hasn\'t listed B2B construction materials yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
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
      itemCount: _supplierProducts.length,
      itemBuilder: (context, index) {
        final prod = _supplierProducts[index];
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
                GestureDetector(
                  onTap: () {
                    // Tapping remote network image allows full-screen preview
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrl: imgUrl,
                          title: prod['name'] ?? 'Product Image',
                        ),
                      ),
                    );
                  },
                  child: AspectRatio(
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
                        final businessName = _provider?['businessName'] ?? 'Provider';
                        final prodName = prod['name'] ?? 'Product';
                        final priceStr = '₹$price/$unit';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              partnerId: widget.providerId,
                              partnerName: businessName,
                              initialMessage: 'Hi, I am interested in your listed product: "$prodName" ($priceStr). Could you please share more details about its availability and delivery timeline?',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text(
                        'Inquire About Product',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
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
    final reviews = _provider!['reviews'] as List? ?? [];
    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No Reviews Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              const Text(
                'Be the first to leave a feedback rating for this provider.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFF002E3B),
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(bool isDark) {
    final experience = _provider!['experience'] ?? 0;
    final address = _provider!['address'] ?? 'No address provided.';
    final email = _provider!['email'] ?? 'No email provided.';
    final phone = _provider!['phone'] ?? 'No phone provided.';
    final completedCount = _completedProjectsCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provider Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.business_center_rounded, 'Experience', '$experience Years in Industry'),
          _buildInfoRow(Icons.email_rounded, 'Email Address', email),
          _buildInfoRow(Icons.phone_android_rounded, 'Phone Number', phone),
          _buildInfoRow(Icons.location_on_rounded, 'Headquarters', address),
          _buildInfoRow(Icons.task_alt_rounded, 'Completed Work Site Audits', '$completedCount Projects'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF002E3B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                      backgroundImage: _provider!['profileImage'] != null && _provider!['profileImage'].toString().isNotEmpty
                          ? MemoryImage(base64Decode(_provider!['profileImage'].split(',').last))
                          : null,
                      child: _provider!['profileImage'] == null || _provider!['profileImage'].toString().isEmpty
                          ? Text(
                              (_provider!['businessName'] ?? 'P')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _provider!['businessName'] ?? 'Provider',
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
              // Post Image - Clickable for FullScreen zoom
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        base64Image: img['imageData'],
                        title: img['title'] ?? 'Showcase Detail',
                      ),
                    ),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                  ),
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

  void _showQuoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Request Quote', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Describe your requirements',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote request sent!')));
              },
              child: const Text('Submit Request'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewModal(BuildContext context) {
    final commentController = TextEditingController();
    int selectedRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Write a Review',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap stars to select rating:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= selectedRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFF002E3B),
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your review comments',
                      hintText: 'Share your experience working with this provider...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please write a comment.')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _submitReview(selectedRating, commentController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit Review'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(int rating, String comment) async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/providers/${widget.providerId}/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': auth.id,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        _fetchProviderData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to backend.')),
      );
    }
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
      color: isDark ? const Color(0xFF121B22) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
