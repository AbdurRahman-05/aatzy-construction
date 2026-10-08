import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_provider.dart';
import '../../core/constants.dart';
import '../../core/providers/projects_provider.dart';
import '../../core/wallpaper_background.dart';
import '../b2b/services/b2b_api_service.dart';
import 'package:image_picker/image_picker.dart';
import '../b2b/presentation/widgets/custom_image.dart';
import 'main_layout.dart';
import '../providers/provider_layout.dart';
import '../../core/full_screen_image_viewer.dart';
import '../../core/providers/social_feed_provider.dart';
import '../../core/widgets/shimmer_loading.dart';

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
  bool _isFetching = false;
  bool _hasFetchedConsumer = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfileData();
    });
  }

  ImageProvider? _resolveImageProvider(String? imgStr) {
    if (imgStr == null || imgStr.trim().isEmpty) return null;
    final trimmed = imgStr.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }
    final bytes = Base64ImageCache.decode(trimmed);
    if (bytes.isNotEmpty) {
      return MemoryImage(bytes);
    }
    return null;
  }

  Future<void> _fetchProfileData() async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final auth = ref.read(authProvider);
      final prefs = await SharedPreferences.getInstance();
      final effectiveId = auth.id ?? prefs.getString('auth_id');
      final effectiveRole = auth.role ?? prefs.getString('auth_role');

      if (effectiveId == null) {
        return;
      }

      if (effectiveRole != 'PROVIDER') {
        _hasFetchedConsumer = true;
        if (mounted) setState(() => _isLoading = true);
        // Sync consumer profile photo from auth state
        final savedConsumerImage = auth.profileImage ?? prefs.getString('auth_profileImage');
        if (savedConsumerImage != null && savedConsumerImage.isNotEmpty) {
          if (mounted && _profileImage != savedConsumerImage) {
            setState(() {
              _profileImage = savedConsumerImage;
            });
          }
        }
        try {
          final futures = <Future<dynamic>>[];
          futures.add(http.get(Uri.parse('$apiBaseUrl/users/$effectiveId')).timeout(const Duration(seconds: 25)));
          futures.add(ref.refresh(userProjectsProvider(effectiveId).future));
          final results = await Future.wait(futures);
          final userRes = results[0] as http.Response;
          if (mounted && userRes.statusCode == 200) {
            final data = jsonDecode(userRes.body);
            final newImg = data['profileImage'] as String?;
            if (newImg != null && newImg.isNotEmpty && newImg != auth.profileImage) {
              if (mounted) {
                setState(() {
                  _profileImage = newImg;
                });
              }
              ref.read(authProvider.notifier).updateProfileImage(newImg);
            }
          }
        } catch (e) {
          debugPrint('Error fetching consumer profile: $e');
        } finally {
          _isFetching = false;
          if (mounted) setState(() => _isLoading = false);
        }
        return;
      }

      // Phase 1: Fetch primary profile data to render the screen ASAP
      if (_providerData == null && mounted) {
        setState(() => _isLoading = true);
      }

      try {
        final profileRes = await http.get(Uri.parse('$apiBaseUrl/providers/$effectiveId/profile'));
        if (mounted && profileRes.statusCode == 200) {
          final decoded = jsonDecode(profileRes.body);
          setState(() {
            _providerData = decoded['provider'];
            _profileImage = _providerData?['profileImage'] ?? auth.profileImage ?? prefs.getString('auth_profileImage');
            _isLoading = false; // Render the UI immediately!
          });
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error fetching primary profile data: $e');
        if (mounted) setState(() => _isLoading = false);
      }

      // Phase 2: Fetch other tabs/details in the background asynchronously
      _fetchBackgroundDetails(effectiveId);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _pickConsumerProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final auth = ref.read(authProvider);
        final hasImage = (_profileImage != null && _profileImage!.isNotEmpty) ||
            (auth.profileImage != null && auth.profileImage!.isNotEmpty);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a picture for your customer profile',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0D9488), size: 22),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: const Text('Pick an image from your photo album', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImagePick(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  subtitle: const Text('Use your device camera', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImagePick(ImageSource.camera);
                  },
                ),
                if (hasImage) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700, fontSize: 15)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeProfilePhoto();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      setState(() {
        _profileImage = dataUrl;
      });

      // Update in Riverpod AuthNotifier & SharedPreferences
      ref.read(authProvider.notifier).updateProfileImage(dataUrl);

      final auth = ref.read(authProvider);
      if (auth.id != null) {
        http.patch(
          Uri.parse('$apiBaseUrl/users/${auth.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'profileImage': dataUrl}),
        ).then((res) {
          if (res.statusCode == 200) {
            debugPrint('User profile picture saved to backend');
          }
        }).catchError((err) {
          debugPrint('Failed to save profile picture to backend: $err');
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update picture: $e')),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    setState(() {
      _profileImage = null;
    });

    ref.read(authProvider.notifier).updateProfileImage(null);

    final auth = ref.read(authProvider);
    if (auth.id != null) {
      http.patch(
        Uri.parse('$apiBaseUrl/users/${auth.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'profileImage': null}),
      ).catchError((err) {
        debugPrint('Failed to remove profile photo on backend: $err');
        return http.Response('', 500);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAvatarWidget(String? imageSource, String name, double size) {
    final initialLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    if (imageSource != null && imageSource.trim().isNotEmpty) {
      final trimmed = imageSource.trim();
      if (trimmed.startsWith('data:image')) {
        try {
          final commaIdx = trimmed.indexOf(',');
          final base64Str = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
          final bytes = base64Decode(base64Str);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildAvatarInitial(initialLetter, size),
            ),
          );
        } catch (e) {
          return _buildAvatarInitial(initialLetter, size);
        }
      } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            trimmed,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildAvatarInitial(initialLetter, size),
          ),
        );
      }
    }
    return _buildAvatarInitial(initialLetter, size);
  }

  Widget _buildAvatarInitial(String letter, double size) {
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.44,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0D9488),
        ),
      ),
    );
  }

  Widget _buildPortfolioImageWidget(
    dynamic rawImage, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (rawImage == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 28)),
      );
    }

    final str = rawImage.toString().trim();
    if (str.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 28)),
      );
    }

    if (str.startsWith('http://') || str.startsWith('https://')) {
      return Image.network(
        str,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28)),
        ),
      );
    }

    try {
      final bytes = Base64ImageCache.decode(str);
      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error decoding portfolio image: $e');
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 28)),
    );
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
        final activeLeadsCount = leadsList?.where((lead) {
          final status = lead is Map ? (lead['status'] ?? 'New') : 'New';
          return ['New', 'Viewed', 'Contacted', 'Quote Sent'].contains(status);
        }).length ?? 0;
        setState(() {
          _supplierLeadsCount = activeLeadsCount;
        });
      }
    } catch (e) {
      debugPrint('Error background fetching supplier leads: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(providerTabProvider, (previous, next) {
      if (next == 4) {
        _fetchProfileData();
      }
    });

    ref.listen(authProvider, (previous, next) {
      final userChanged = previous?.id != next.id;
      if (userChanged) {
        _hasFetchedConsumer = false;
        _providerData = null;
      }
      final shouldFetchProvider = next.role == 'PROVIDER' && _providerData == null;
      final shouldFetchConsumer = next.role != 'PROVIDER' && !_hasFetchedConsumer;
      if (next.id != null && (userChanged || shouldFetchProvider || shouldFetchConsumer)) {
        _fetchProfileData();
      }
    });

    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);

    if (auth.role == 'PROVIDER') {
      if (_providerData == null && !_isFetching && auth.id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _providerData == null && !_isFetching) {
            _fetchProfileData();
          }
        });
      }
    } else {
      if (!_hasFetchedConsumer && !_isFetching && auth.id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasFetchedConsumer && !_isFetching) {
            _fetchProfileData();
          }
        });
      }
    }

    if (auth.role != 'PROVIDER') {
      return _buildConsumerProfile(context, auth, isDark);
    }

    final name = _providerData?['businessName'] ?? auth.businessName ?? auth.name ?? 'Guest Provider';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation(context);
      },
      child: WallpaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _isLoading ? null : AppBar(
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              onPressed: () => _handleBackNavigation(context),
              tooltip: 'Back to Dashboard',
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: isDark ? const Color(0xFF121B22) : Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _showSettingsBottomSheet(context),
              ),
            ],
          ),
        body: _isLoading
            ? const ShimmerUserProfile()
            : DefaultTabController(
                length: 4,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildProviderHeader(primaryColor, isDark),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.center,
                            indicatorColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF002E3B),
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF002E3B),
                            unselectedLabelColor: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.grey.shade600,
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
      ),
    );
  }

  Widget _buildProviderHeader(Color primaryColor, bool isDark) {
    final auth = ref.watch(authProvider);
    final name = _providerData?['businessName'] ?? auth.businessName ?? auth.name ?? 'Provider Business';
    final owner = _providerData?['ownerName'] ?? auth.name ?? 'Provider';
    final experience = _providerData?['experience'] ?? 0;
    final rating = (_providerData?['avgRating'] as num?)?.toDouble() ?? 0.0;
    final categoryRaw = _providerData?['category'] as String?;
    final categories = (categoryRaw != null && categoryRaw.isNotEmpty)
        ? categoryRaw.split(',')
        : ['General Construction'];
    final bio = (_providerData?['bio'] as String?) ?? '';
    final reviewsCount = (_providerData?['reviews'] as List?)?.length ?? 0;
    final gst = _providerData?['gstNumber'] as String? ?? auth.gstNumber ?? '';
    final displayImage = _profileImage ?? auth.profileImage;
    final avatarImageProvider = _resolveImageProvider(displayImage);

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
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFF0F172A).withValues(alpha: 0.08),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2DD4BF), const Color(0xFF0F9B8E)]
                        : [const Color(0xFF002E3B), const Color(0xFF002E3B)],
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
                              border: Border.all(
                                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF002E3B),
                                width: 2,
                              ),
                              color: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A).withValues(alpha: 0.08),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: avatarImageProvider,
                                child: avatarImageProvider == null
                                    ? Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
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
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0D9488) : const Color(0xFF002E3B),
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
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (gst.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.verified_user_rounded, color: primaryColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'GST: $gst',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                                    color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                  child: Text(
                                    cTrim,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1D4ED8),
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
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ABOUT COMPANY',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bio.isNotEmpty ? bio : 'No bio provided yet.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashboardMetric(
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'Completed',
                          value: '$_completedProjectsCount',
                          color: Colors.green,
                          onTap: () => ref.read(providerTabProvider.notifier).setTab(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDashboardMetric(
                          icon: Icons.storefront_rounded,
                          label: 'B2B Products',
                          value: '${_supplierProducts.length}',
                          color: Colors.blue,
                          onTap: () => context.push('/b2b-materials'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDashboardMetric(
                          icon: Icons.leaderboard_rounded,
                          label: 'Active Leads',
                          value: '${_serviceLeadsCount + _supplierLeadsCount}',
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF002E3B),
                          onTap: () => ref.read(providerTabProvider.notifier).setTab(2),
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
                          color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFF002E3B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.3) : const Color(0xFF002E3B).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF002E3B),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              ' ($reviewsCount)',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey,
                                fontSize: 11,
                              ),
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
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFF0F172A).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0F172A).withValues(alpha: 0.08),
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
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(bool isDark) {
    if (_portfolio.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.architecture_rounded,
                size: 44,
                color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF002E3B),
              ),
              const SizedBox(height: 12),
              Text(
                'No Showcase Projects Yet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addPortfolioImage,
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Add Project Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF0D9488) : const Color(0xFF002E3B),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
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
          final uploadAccent = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF002E3B);
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: uploadAccent.withValues(alpha: isDark ? 0.45 : 0.35),
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
                      color: uploadAccent.withValues(alpha: isDark ? 0.18 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_rounded,
                      color: uploadAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF002E3B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Showcase new work',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final img = _portfolio[index - 1];
        final rawImg = img['imageData'] ?? img['imageUrl'] ?? img['image'];
        return Card(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: InkWell(
            onTap: () => _showPostDetailModal(context, img),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPortfolioImageWidget(
                        rawImg,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
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
                      img['title'] ?? 'Showcase Project',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.construction_rounded, size: 44, color: Colors.blue),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
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
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
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
                      BuildMartImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                        image: MemoryImage(Base64ImageCache.decode(tempBase64!)),
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
                    icon: Icon(
                      Icons.add_a_photo,
                      color: Theme.of(dialogContext).brightness == Brightness.dark
                          ? const Color(0xFF2DD4BF)
                          : null,
                    ),
                    label: Text(
                      'Select Photo',
                      style: TextStyle(
                        color: Theme.of(dialogContext).brightness == Brightness.dark
                            ? const Color(0xFF2DD4BF)
                            : null,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: Theme.of(dialogContext).brightness == Brightness.dark
                          ? const BorderSide(color: Color(0xFF2DD4BF))
                          : null,
                    ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF002E3B),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (tempBase64 == null || titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image and title')));
                  return;
                }
                Navigator.pop(ctx);
                
                setState(() => _isLoading = true);
                final auth = ref.read(authProvider);
                final prefs = await SharedPreferences.getInstance();
                final effectiveId = auth.id ?? prefs.getString('auth_id');
                if (effectiveId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider session not found. Please log in again.')));
                    setState(() => _isLoading = false);
                  }
                  return;
                }
                try {
                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/providers/$effectiveId/portfolio'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'imageData': tempBase64,
                    }),
                  );
                  if (response.statusCode == 201) {
                    try {
                      final createdItem = jsonDecode(response.body);
                      setState(() {
                        _portfolio.insert(0, createdItem);
                      });
                    } catch (_) {}
                    ref.invalidate(socialFeedProvider);
                    _fetchBackgroundDetails(effectiveId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo added to portfolio!')));
                    }
                  } else {
                    debugPrint('Add portfolio failed with status: ${response.statusCode}, body: ${response.body}');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save portfolio photo (${response.statusCode})')));
                    }
                  }
                } catch (e) {
                  debugPrint('Add portfolio error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
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
                  child: BuildMartImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
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
    final reviews = (_providerData?['reviews'] as List?) ?? [];
    
    if (reviews.isEmpty) {
      return const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Icon(Icons.star_outline_rounded, size: 40, color: Colors.grey),
              SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
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
          elevation: 2,
          shadowColor: Colors.black12,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      reviewer,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  )),
                ),
                if (r['project'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      'Project: ${r['project']['title'] ?? ''} (${r['project']['type'] ?? ''})',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1D4ED8),
                        fontSize: 11,
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
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      fontSize: 13,
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
    final auth = ref.watch(authProvider);
    final email = _providerData?['email'] ?? auth.email;
    final phone = _providerData?['phone'];
    final address = _providerData?['address'];
    final ownerName = _providerData?['ownerName'] ?? auth.name ?? 'Provider';
    final experience = _providerData?['experience'] ?? 0;
    
    final businessType = _providerData?['businessType'] ?? '';
    final gst = _providerData?['gstNumber'] ?? auth.gstNumber ?? '';
    final website = _providerData?['website'] ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Services Provider Info',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Divider(
                  height: 24,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                ),
                _buildInfoRow(Icons.person_rounded, 'Owner / User', ownerName, isDark),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.work_history_rounded, 'Professional Experience', '$experience Years', isDark),
                if (address != null && address.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on_rounded, 'Business Address', address, isDark),
                ],
                if (email != null && email.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email_rounded, 'Email Address', email, isDark),
                ],
                if (phone != null && phone.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone_rounded, 'Contact Number', phone, isDark),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shadowColor: Colors.black12,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Material Supplier Info',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Divider(
                  height: 24,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                ),
                _buildInfoRow(Icons.business_center_rounded, 'Supplier Business Type', businessType.isNotEmpty ? businessType : 'Service & Supplier', isDark),
                if (gst.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.verified_user_rounded, 'GST Identification Number', gst, isDark),
                ],
                if (website.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.language_rounded, 'Official Business Website', website, isDark),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPostDetailModal(BuildContext context, dynamic img) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dynamic rawImg = img['imageData'] ?? img['imageUrl'] ?? img['image'];
    final postAvatarImage = _resolveImageProvider(_profileImage ?? ref.read(authProvider).profileImage);
    final bName = _providerData?['businessName'] ?? ref.read(authProvider).businessName ?? 'Provider';
    final imageId = img['id'];

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Post Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: postAvatarImage,
                        child: postAvatarImage == null
                            ? Text(
                                bName.isNotEmpty ? bName[0].toUpperCase() : 'P',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (imageId != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete Photo',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmDeletePortfolioImage(context, imageId),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                // Post Image with zoom action
                GestureDetector(
                  onTap: () {
                    if (rawImg != null) {
                      final str = rawImg.toString();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            base64Image: str.startsWith('http') ? null : str,
                            imageUrl: str.startsWith('http') ? str : null,
                            title: img['title'] ?? 'Showcase Detail',
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.1,
                        child: _buildPortfolioImageWidget(rawImg, fit: BoxFit.cover),
                      ),
                      Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, color: Colors.white, size: 15),
                            SizedBox(width: 4),
                            Text(
                              'Tap to zoom',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Post Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        img['title'] ?? 'Showcase Project',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (img['description'] != null && img['description'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          img['description'].toString().trim(),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (rawImg != null) {
                              final str = rawImg.toString();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    base64Image: str.startsWith('http') ? null : str,
                                    imageUrl: str.startsWith('http') ? str : null,
                                    title: img['title'] ?? 'Showcase Detail',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.fullscreen_rounded, size: 20),
                          label: const Text(
                            'View Fullscreen',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF0D9488) : const Color(0xFF002E3B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletePortfolioImage(BuildContext context, dynamic imageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to remove this photo from your showcase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await _deletePortfolioImage(imageId);
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePortfolioImage(dynamic imageId) async {
    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = auth.id ?? prefs.getString('auth_id');
    if (effectiveId == null) return;

    try {
      final res = await http.delete(
        Uri.parse('$apiBaseUrl/providers/$effectiveId/portfolio?imageId=$imageId'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _portfolio.removeWhere((item) => item['id'] == imageId);
        });
        ref.invalidate(socialFeedProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo removed from showcase')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting portfolio photo: $e');
    }
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

  void _handleBackNavigation(BuildContext context) {
    final auth = ref.read(authProvider);
    if (auth.role == 'PROVIDER') {
      final tabNotifier = ref.read(providerTabProvider.notifier);
      final handled = tabNotifier.handleBack();
      if (handled) return;
      if (ref.read(providerTabProvider) != 0) {
        tabNotifier.setTab(0);
        return;
      }
    } else {
      final tabNotifier = ref.read(mainTabProvider.notifier);
      final handled = tabNotifier.handleBack();
      if (handled) return;
      if (ref.read(mainTabProvider) != 0) {
        tabNotifier.setTab(0);
        return;
      }
    }
    if (context.canPop()) {
      context.pop();
    }
  }

  Widget _buildConsumerProfile(BuildContext context, AuthState auth, bool isDark) {
    final name = auth.name ?? 'test';
    final email = auth.email ?? 'test@gmail.com';
    final userId = auth.id ?? '02458';
    final formattedId = 'CUST-${userId.length > 5 ? userId.substring(userId.length - 5).toUpperCase() : userId.padLeft(5, '0').toUpperCase()}';

    final userProjectsAsync = auth.id != null ? ref.watch(userProjectsProvider(auth.id!)) : null;
    final userProjectsData = userProjectsAsync?.value;
    final projects = userProjectsData?.projects ?? [];
    final orders = userProjectsData?.materialOrders ?? [];
    final inquiries = userProjectsData?.inquiries ?? [];

    if (_isLoading || (userProjectsAsync != null && userProjectsAsync.isLoading && projects.isEmpty)) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const SafeArea(
          child: ShimmerUserProfile(isConsumer: true),
        ),
      );
    }

    int calculatedQuotes = 0;
    for (var p in projects) {
      calculatedQuotes += (p['_count']?['quotes'] as int? ?? (p['quotes'] as List?)?.length ?? 0);
    }
    final int projectsCount = projects.length;
    final int quotesCount = calculatedQuotes;
    final int ordersCount = orders.length;
    final int inquiriesCount = inquiries.length;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isTabletOrLaptop = screenWidth >= 700;
    final horizontalPadding = isTabletOrLaptop ? 24.0 : (isSmallScreen ? 12.0 : 16.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleBackNavigation(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'My Account',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/settings'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              size: 20,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hero Account Profile Card (Teal Gradient with QR Code)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F766E),
                        Color(0xFF0D9488),
                        Color(0xFF14B8A6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background Architectural watermark pattern
                        Positioned(
                          right: -10,
                          bottom: -15,
                          child: Opacity(
                            opacity: 0.12,
                            child: const Icon(
                              Icons.location_city_rounded,
                              size: 160,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
                          child: Row(
                            children: [
                              // Avatar + Details (QR code removed per request)
                              Expanded(
                                child: Row(
                                  children: [
                                    // Interactive Avatar (tap to pick/take/remove photo)
                                    GestureDetector(
                                      onTap: _pickConsumerProfileImage,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: isSmallScreen ? 64 : 74,
                                            height: isSmallScreen ? 64 : 74,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.85),
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.14),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: _buildAvatarWidget(
                                              _profileImage ?? auth.profileImage,
                                              name,
                                              isSmallScreen ? 64 : 74,
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(5.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F766E),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // User Name, Email, and Customer & Account ID Badges
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 18 : 21,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 11.5 : 13,
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'CUSTOMER',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.badge_outlined, size: 12, color: Colors.white),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formattedId,
                                                      style: const TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.4,
                                                      ),
                                                    ),
                                                  ],
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

                              const SizedBox(width: 8),

                              // Quick Camera Edit Icon Button
                              GestureDetector(
                                onTap: _pickConsumerProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_back_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4-Metric User Stats Container (Projects, Quotes, Orders, Inquiries)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 10,
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildAccountStatItem(
                        icon: Icons.description_outlined,
                        count: projectsCount.toString().padLeft(2, '0'),
                        label: 'Projects\nCreated',
                        color: const Color(0xFF0D9488),
                        bg: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.15) : const Color(0xFFF0FDFA),
                        isSmallScreen: isSmallScreen,
                        isDark: isDark,
                        onTap: () => context.push('/dashboard'),
                      ),
                      _buildAccountStatItem(
                        icon: Icons.assignment_outlined,
                        count: quotesCount.toString().padLeft(2, '0'),
                        label: 'Quotes\nRequested',
                        color: const Color(0xFF2563EB),
                        bg: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                        isSmallScreen: isSmallScreen,
                        isDark: isDark,
                        onTap: () => context.push('/dashboard'),
                      ),
                      _buildAccountStatItem(
                        icon: Icons.inventory_2_outlined,
                        count: ordersCount.toString().padLeft(2, '0'),
                        label: 'Orders\nPlaced',
                        color: const Color(0xFFEA580C),
                        bg: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.15) : const Color(0xFFFFF7ED),
                        isSmallScreen: isSmallScreen,
                        isDark: isDark,
                        onTap: () => context.push('/b2b-materials'),
                      ),
                      _buildAccountStatItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        count: inquiriesCount.toString().padLeft(2, '0'),
                        label: 'Inquiries\nMade',
                        color: const Color(0xFF9333EA),
                        bg: isDark ? const Color(0xFF9333EA).withValues(alpha: 0.15) : const Color(0xFFFAF5FF),
                        isSmallScreen: isSmallScreen,
                        isDark: isDark,
                        onTap: () => context.push('/b2b-my-inquiries'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Settings, Help & Support, and Logout Actions Menu Card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildAccountActionTile(
                        icon: Icons.settings_outlined,
                        iconColor: const Color(0xFF0D9488),
                        iconBg: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.15) : const Color(0xFFF0FDFA),
                        title: 'Settings',
                        subtitle: 'Manage your profile and preferences',
                        isDark: isDark,
                        onTap: () => context.push('/settings'),
                      ),
                      Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                      ),
                      _buildAccountActionTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.15) : const Color(0xFFEFF6FF),
                        title: 'Help & Support',
                        subtitle: 'Get help and contact support team',
                        isDark: isDark,
                        onTap: () => context.push('/help-support'),
                      ),
                      Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                      ),
                      _buildAccountActionTile(
                        icon: Icons.logout_rounded,
                        iconColor: const Color(0xFFDC2626),
                        iconBg: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.15) : const Color(0xFFFEF2F2),
                        title: 'Logout',
                        titleColor: const Color(0xFFDC2626),
                        subtitle: 'Sign out from your account',
                        trailingColor: const Color(0xFFDC2626),
                        isDark: isDark,
                        onTap: () => _confirmLogout(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom Security & Trust Banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : null,
                    gradient: isDark
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF0FDFA),
                              Color(0xFFEFF6FF),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFCCFBF1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.3) : const Color(0xFF99F6E4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.2 : 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFF0D9488), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your data is safe with us',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'We use advanced security to protect your information.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/banner_building.jpg',
                          width: isSmallScreen ? 75 : 90,
                          height: isSmallScreen ? 55 : 65,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.apartment_rounded, size: 45, color: Color(0xFF0D9488)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountStatItem({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
    required Color bg,
    required bool isSmallScreen,
    bool isDark = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: isSmallScreen ? 14 : 16, color: color),
                    ),
                    const SizedBox(width: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        count,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 9.5 : 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? trailingColor,
    bool isDark = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14.5,
          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: trailingColor ?? (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text('Are you sure you want to log out from your account?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121B22) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.tabBar != tabBar;
  }
}



