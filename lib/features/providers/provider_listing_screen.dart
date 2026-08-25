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

  final List<String> _popularCategories = const [
    'All',
    'Builder/General Contractor',
    'Design & Planning',
    'Construction',
    'Commercial Builder',
    'Interiors & Finishing',
    'Plumbing',
    'Electrical Contractor',
    'Civil Engineer',
  ];

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
        if (mounted) {
          setState(() {
            _providers = data['providers'] ?? [];
            _isLoading = false;
          });
        }
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1E293B), size: 28),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
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
                  backgroundColor: const Color(0xFF4F46E5),
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

    return Column(
      children: [
        // Top Search Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Search contractors, trades, or locations...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // Horizontal Category Filter Chips
        Container(
          height: 48,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: _popularCategories.length,
            itemBuilder: (context, idx) {
              final cat = _popularCategories[idx];
              final isSelected = _activeCategoryFilter.toLowerCase() == cat.toLowerCase() ||
                  (_activeCategoryFilter == 'All' && cat == 'All');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _activeCategoryFilter = cat;
                      });
                      _fetchProviders();
                    }
                  },
                  selectedColor: const Color(0xFF4F46E5),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
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
                              });
                              _fetchProviders();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFF4F46E5)),
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
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredProviders.length,
                  itemBuilder: (context, index) {
                    final provider = filteredProviders[index];
                    final id = provider['id'] ?? '';
                    final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Verified Contractor';
                    final isVerified = provider['isVerified'] ?? false;
                    final experience = provider['experience'] ?? 0;
                    final address = provider['address'] ?? '';
                    final bio = provider['bio'] ?? '';
                    final avgRating = provider['avgRating'] ?? 0.0;
                    final reviewCount = provider['reviewCount'] ?? 0;
                    final profileImage = provider['profileImage'] as String? ?? '';
                    final category = provider['category'] ?? _activeCategoryFilter;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            if (id.isNotEmpty) {
                              context.push('/provider-profile/$id');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar / Initial with Verification Badge
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: const Color(0xFFEEF2FF),
                                      backgroundImage: profileImage.isNotEmpty
                                          ? MemoryImage(base64Decode(profileImage.split(',').last))
                                          : null,
                                      child: profileImage.isEmpty
                                          ? Text(
                                              businessName.isNotEmpty ? businessName.substring(0, 1).toUpperCase() : 'P',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF4F46E5),
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (isVerified)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),

                                // Main Info Block
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              businessName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                                          ],
                                        ],
                                      ),
                                       const SizedBox(height: 3),
                                       // Category tag + Experience (with multi-category support and overflow safety)
                                       Builder(
                                         builder: (context) {
                                           final catList = category.toString().split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
                                           final primaryCat = catList.isNotEmpty ? catList.first : 'Contractor';
                                           final extraCount = catList.length > 1 ? catList.length - 1 : 0;

                                           return Row(
                                             children: [
                                               Flexible(
                                                 child: Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                   decoration: BoxDecoration(
                                                     color: const Color(0xFFF1F5F9),
                                                     borderRadius: BorderRadius.circular(6),
                                                   ),
                                                   child: Text(
                                                     primaryCat,
                                                     style: const TextStyle(
                                                       fontSize: 10.5,
                                                       fontWeight: FontWeight.bold,
                                                       color: Color(0xFF475569),
                                                     ),
                                                     maxLines: 1,
                                                     overflow: TextOverflow.ellipsis,
                                                   ),
                                                 ),
                                               ),
                                               if (extraCount > 0) ...[
                                                 const SizedBox(width: 4),
                                                 Container(
                                                   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                   decoration: BoxDecoration(
                                                     color: const Color(0xFFEEF2FF),
                                                     borderRadius: BorderRadius.circular(6),
                                                   ),
                                                   child: Text(
                                                     '+$extraCount',
                                                     style: const TextStyle(
                                                       fontSize: 9.5,
                                                       fontWeight: FontWeight.bold,
                                                       color: Color(0xFF4F46E5),
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                               const SizedBox(width: 6),
                                               Text(
                                                 '$experience yrs exp',
                                                 style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                                               ),
                                             ],
                                           );
                                         },
                                       ),
                                      if (address.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 13),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                address,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (bio.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                          bio,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                            fontSize: 11.5,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 7),
                                      
                                      // Ratings & Reviews
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: Color(0xFFF59E0B),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            avgRating > 0 ? avgRating.toStringAsFixed(1) : '4.8',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            avgRating > 0 
                                                ? '($reviewCount reviews)'
                                                : '(Verified)',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // View profile action button
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

