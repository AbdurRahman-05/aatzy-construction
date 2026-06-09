import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../chat/chat_detail_screen.dart';
import '../../core/wallpaper_background.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  Map<String, dynamic>? _provider;
  List<dynamic> _portfolio = [];
  int _completedProjectsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  Future<void> _fetchProviderData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/profile')),
        http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/portfolio')),
        http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/projects')),
      ]);

      if (mounted) {
        setState(() {
          if (responses[0].statusCode == 200) {
            _provider = jsonDecode(responses[0].body)['provider'];
          }
          if (responses[1].statusCode == 200) {
            _portfolio = jsonDecode(responses[1].body)['images'] ?? [];
          }
          if (responses[2].statusCode == 200) {
            final projectsList = jsonDecode(responses[2].body) as List;
            _completedProjectsCount = projectsList.where((p) => p['currentStage'] == 'Completed').length;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching provider data: $e');
      if (mounted) setState(() => _isLoading = false);
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
                    length: 3,
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
                                indicatorColor: primaryColor,
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: primaryColor,
                                unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                                tabs: const [
                                  Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Profile picture and metrics
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
                    backgroundImage: _provider!['profileImage'] != null && _provider!['profileImage'].toString().isNotEmpty
                        ? MemoryImage(base64Decode(_provider!['profileImage'].split(',').last))
                        : null,
                    child: _provider!['profileImage'] == null || _provider!['profileImage'].toString().isEmpty
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
                    _buildMetricItem('Rating', rating.toStringAsFixed(1)),
                    _buildMetricItem('Reviews', '$reviewsCount'),
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
          // Quick actions (buttons)
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
    final email = _provider!['email'];
    final phone = _provider!['phone'];
    final address = _provider!['address'];
    final ownerName = _provider!['ownerName'] ?? 'N/A';
    final experience = _provider!['experience'] ?? 0;

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
                  'Business Information',
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
                          color: Colors.amber,
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
      color: isDark ? const Color(0xFF121B22) : const Color(0xFFF4EFE6),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
