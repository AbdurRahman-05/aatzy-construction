import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';

class ProviderListingScreen extends StatefulWidget {
  final String category;
  const ProviderListingScreen({super.key, required this.category});

  @override
  State<ProviderListingScreen> createState() => _ProviderListingScreenState();
}

class _ProviderListingScreenState extends State<ProviderListingScreen> {
  List<dynamic> _providers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _activeCategoryFilter = 'All';
  int _currentPage = 1;

  final Map<String, int> _completedCounts = {};

  final List<Map<String, dynamic>> _popularCategories = const [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'color': Color(0xFF6366F1),
      'bg': Color(0xFFEEF2FF),
      'border': Color(0xFFC7D2FE),
    },
    {
      'name': 'Builder/General Contractor',
      'icon': Icons.apartment_rounded,
      'color': Color(0xFF0284C7),
      'bg': Color(0xFFF0F9FF),
      'border': Color(0xFFBAE6FD),
    },
    {
      'name': 'Design & Planning',
      'icon': Icons.draw_rounded,
      'color': Color(0xFF16A34A),
      'bg': Color(0xFFF0FDF4),
      'border': Color(0xFFBBF7D0),
    },
    {
      'name': 'Construction',
      'icon': Icons.construction_rounded,
      'color': Color(0xFFEA580C),
      'bg': Color(0xFFFFF7ED),
      'border': Color(0xFFFED7AA),
    },
    {
      'name': 'Commercial',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFFDB2777),
      'bg': Color(0xFFFDF2F8),
      'border': Color(0xFFFBCFE8),
    },
    {
      'name': 'Interiors & Finishing',
      'icon': Icons.chair_rounded,
      'color': Color(0xFF9333EA),
      'bg': Color(0xFFFAF5FF),
      'border': Color(0xFFE9D5FF),
    },
    {
      'name': 'Plumbing',
      'icon': Icons.plumbing_rounded,
      'color': Color(0xFF0891B2),
      'bg': Color(0xFFECFEFF),
      'border': Color(0xFFA5F3FC),
    },
  ];

  static const int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _activeCategoryFilter = widget.category;
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isAll = _activeCategoryFilter.trim().isEmpty || _activeCategoryFilter.trim().toLowerCase() == 'all';
      final uri = isAll
          ? Uri.parse('$apiBaseUrl/providers')
          : Uri.parse('$apiBaseUrl/providers?category=${Uri.encodeComponent(_activeCategoryFilter)}');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['providers'] ?? [];
        if (mounted) {
          setState(() {
            _providers = list;
            _isLoading = false;
          });
        }
        _fetchActualCompletedProjects(list);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error (${response.statusCode}). Failed to load providers.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchActualCompletedProjects(List<dynamic> providers) async {
    for (final p in providers) {
      final id = p['id']?.toString() ?? '';
      if (id.isEmpty) continue;

      if (p['completedProjects'] != null && p['completedProjects'] is num) {
        if (mounted) {
          setState(() {
            _completedCounts[id] = (p['completedProjects'] as num).toInt();
          });
        }
        continue;
      }

      // Fetch actual completed projects from database
      try {
        final res = await http
            .get(Uri.parse('$apiBaseUrl/providers/$id/projects'))
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body);
          if (list is List) {
            final count = list.where((proj) {
              final s = (proj['currentStage'] as String? ?? '').toLowerCase().trim();
              return s == 'completed' || s == 'finished';
            }).length;
            if (mounted) {
              setState(() {
                _completedCounts[id] = count;
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching completed projects for $id: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (widget.category.toLowerCase() == 'all')
        ? 'Find Contractors'
        : widget.category;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1E293B), size: 28),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/services');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1)),
            onPressed: _fetchProviders,
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchProviders,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredProviders = _providers.where((p) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final name = (p['businessName'] ?? p['ownerName'] ?? '').toString().toLowerCase();
      final cat = (p['category'] ?? '').toString().toLowerCase();
      final address = (p['address'] ?? '').toString().toLowerCase();
      final bio = (p['bio'] ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q) || address.contains(q) || bio.contains(q);
    }).toList();

    final totalPages = (filteredProviders.length / _itemsPerPage).ceil();
    final safeCurrentPage = totalPages > 0 ? _currentPage.clamp(1, totalPages) : 1;
    final startIndex = (safeCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredProviders.length);
    final displayedProviders = (startIndex < filteredProviders.length)
        ? filteredProviders.sublist(startIndex, endIndex)
        : <dynamic>[];

    return Column(
      children: [
        // Top Search Bar & Filter Action Button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 1;
                    }),
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Search contractors, trades, or locations...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF6366F1)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () => setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                              }),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Filter Button on Right
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Color(0xFF6366F1), size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),

        // Horizontal Category Filter Chips
        Container(
          height: 52,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: _popularCategories.length,
            itemBuilder: (context, idx) {
              final cat = _popularCategories[idx];
              final name = cat['name'] as String;
              final icon = cat['icon'] as IconData;
              final color = cat['color'] as Color;
              final bg = cat['bg'] as Color;
              final border = cat['border'] as Color;
              final isSelected = _activeCategoryFilter.toLowerCase() == name.toLowerCase() ||
                  (_activeCategoryFilter == 'All' && name == 'All');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _activeCategoryFilter = name;
                      _currentPage = 1;
                    });
                    _fetchProviders();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1) : bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Providers List / Empty State
        Expanded(
          child: filteredProviders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.engineering_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 14),
                        const Text(
                          'No Contractors Found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _activeCategoryFilter == 'All'
                              ? 'No verified contractors match your current search.'
                              : 'No contractors registered under "$_activeCategoryFilter" yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        if (_activeCategoryFilter != 'All' || _searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _activeCategoryFilter = 'All';
                                _searchQuery = '';
                                _currentPage = 1;
                              });
                              _fetchProviders();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              side: const BorderSide(color: Color(0xFF6366F1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Show All Contractors', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  itemCount: displayedProviders.length + (totalPages > 1 ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Pagination Bar as the last item in the list
                    if (index == displayedProviders.length) {
                      return _buildPaginationBar(totalPages);
                    }

                    final provider = displayedProviders[index];
                    return _buildProviderCard(provider, startIndex + index);
                  },
                ),
        ),
      ],
    );
  }

  // Card Palette configurations matching reference (Purple, Sky Blue, Mint Green, Amber/Orange)
  List<CardPalette> get _palettes => const [
        CardPalette(
          bg: Color(0xFFF7F5FF),
          border: Color(0xFFE9D5FF),
          accent: Color(0xFF6366F1),
          gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          tagBg: Color(0xFFF3E8FF),
          tagText: Color(0xFF7E22CE),
        ),
        CardPalette(
          bg: Color(0xFFF0F9FF),
          border: Color(0xFFBAE6FD),
          accent: Color(0xFF0284C7),
          gradient: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          tagBg: Color(0xFFE0F2FE),
          tagText: Color(0xFF0369A1),
        ),
        CardPalette(
          bg: Color(0xFFF0FDF4),
          border: Color(0xFFBBF7D0),
          accent: Color(0xFF16A34A),
          gradient: [Color(0xFF22C55E), Color(0xFF16A34A)],
          tagBg: Color(0xFFDCFCE7),
          tagText: Color(0xFF15803D),
        ),
        CardPalette(
          bg: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          accent: Color(0xFFEA580C),
          gradient: [Color(0xFFF97316), Color(0xFFEA580C)],
          tagBg: Color(0xFFFFEDD5),
          tagText: Color(0xFFC2410C),
        ),
      ];

  Widget _buildProviderCard(Map<String, dynamic> provider, int index) {
    final palette = _palettes[index % _palettes.length];

    final id = provider['id']?.toString() ?? '';
    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Verified Contractor';
    final isVerified = provider['isVerified'] == true || provider['isVerified'] == 1 || provider['isVerified'] == 'true';
    final experience = (provider['experience'] as num?)?.toInt() ?? 0;
    final address = (provider['address'] as String?)?.trim() ?? '';
    final bio = (provider['bio'] as String?)?.trim() ?? '';
    final avgRating = (provider['avgRating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (provider['reviewCount'] as num?)?.toInt() ?? 0;
    final profileImage = provider['profileImage'] as String? ?? '';
    final category = provider['category'] ?? _activeCategoryFilter;

    // Strictly show the actual completed projects count stored in database
    final projectsCount = _completedCounts[id] ??
        ((provider['completedProjects'] as num?)?.toInt()) ??
        ((provider['projectsCount'] as num?)?.toInt()) ??
        0;

    final catList = category.toString().split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    final primaryCat = catList.isNotEmpty ? catList.first : 'Contractor';
    final extraCount = catList.length > 1 ? catList.length - 1 : 0;

    final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Architectural Silhouette
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            width: 200,
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(
                'assets/images/provider_card_city.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),

          // Foreground Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Avatar & Projects Counter
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Square Gradient Avatar with Online Green Badge
                    Stack(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: palette.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: profileImage.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    base64Decode(profileImage.split(',').last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Projects Count Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.business_center_outlined, size: 11, color: palette.accent),
                              const SizedBox(width: 3),
                              Text(
                                '$projectsCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Projects',
                            style: TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Middle Info Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Business Title & Top-Right Verified Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              businessName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 3),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Tags Row: Category, +extra, Experience
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: palette.tagBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              primaryCat,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: palette.tagText,
                              ),
                            ),
                          ),
                          if (extraCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: palette.tagBg.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+$extraCount',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: palette.tagText,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                            ),
                            child: Text(
                              '$experience yrs exp',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Address / Location Row
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 13),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address.isNotEmpty ? address : 'Tamil Nadu',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Bio text
                      Text(
                        bio.isNotEmpty ? bio : 'none',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Rating & "View Profile ->" Action Button
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 2),
                          Text(
                            avgRating > 0 ? avgRating.toStringAsFixed(1) : '4.8',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviewCount > 0 ? '($reviewCount reviews)' : '(Verified)',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),

                          // White "View Profile ->" Pill Button
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (id.isNotEmpty) {
                                context.push('/provider-profile/$id');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Profile',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: palette.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: palette.accent),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Far Right Circular Next Arrow Button
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    if (id.isNotEmpty) {
                      context.push('/provider-profile/$id');
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic Bottom Pagination Controls
  Widget _buildPaginationBar(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    // Generate dynamic page list matching total available pages
    final List<dynamic> pageItems = [];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pageItems.add(i);
      }
    } else {
      if (_currentPage <= 3) {
        pageItems.addAll([1, 2, 3, '...', totalPages]);
      } else if (_currentPage >= totalPages - 2) {
        pageItems.addAll([1, '...', totalPages - 2, totalPages - 1, totalPages]);
      } else {
        pageItems.addAll([1, '...', _currentPage - 1, _currentPage, _currentPage + 1, '...', totalPages]);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Chevron Box
          _buildPageBox(
            child: Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: _currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
            ),
            isEnabled: _currentPage > 1,
            onTap: () {
              if (_currentPage > 1) {
                setState(() => _currentPage--);
              }
            },
          ),
          const SizedBox(width: 6),

          // Dynamic Page Numbers
          ...pageItems.map((item) {
            if (item is int) {
              final isSelected = _currentPage == item;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildPageBox(
                  child: Text(
                    '$item',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12.5,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  isSelected: isSelected,
                  onTap: () => setState(() => _currentPage = item),
                ),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
              );
            }
          }),

          const SizedBox(width: 6),

          // Right Chevron Box
          _buildPageBox(
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
            ),
            isEnabled: _currentPage < totalPages,
            onTap: () {
              if (_currentPage < totalPages) {
                setState(() => _currentPage++);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageBox({
    required Widget child,
    bool isSelected = false,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isEnabled ? Colors.white : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isEnabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class CardPalette {
  final Color bg;
  final Color border;
  final Color accent;
  final List<Color> gradient;
  final Color tagBg;
  final Color tagText;

  const CardPalette({
    required this.bg,
    required this.border,
    required this.accent,
    required this.gradient,
    required this.tagBg,
    required this.tagText,
  });
}
