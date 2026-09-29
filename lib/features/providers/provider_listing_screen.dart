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

  // Page-based filter states
  String _selectedCity = 'All';
  bool _verifiedOnly = false;
  double _minRating = 0.0;
  int _minExperience = 0;
  String _sortBy = 'recommended';

  final Map<String, int> _completedCounts = {};

  int get _activeFiltersCount {
    int count = 0;
    if (_verifiedOnly) count++;
    if (_minRating > 0) count++;
    if (_minExperience > 0) count++;
    if (_selectedCity != 'All') count++;
    if (_sortBy != 'recommended') count++;
    if (_activeCategoryFilter.toLowerCase() != widget.category.toLowerCase()) count++;
    return count;
  }

  List<String> get _availableCities {
    final cities = <String>{};
    for (final p in _providers) {
      final addr = (p['address'] as String?)?.trim();
      if (addr != null && addr.isNotEmpty && addr.toLowerCase() != 'none') {
        final formatted = addr[0].toUpperCase() + addr.substring(1).toLowerCase();
        cities.add(formatted);
      }
    }
    return cities.toList()..sort();
  }

  static const List<String> _allCategoryNames = [
    'Blacksmith',
    'Borewell',
    'Bricklayer/Stonemason',
    'Builder/General Contractor',
    'Cabinet Maker',
    'Carpenter',
    'Cement / Concrete',
    'Commercial Builder',
    'Construction',
    'Construction (Other)',
    'Construction Project Management',
    'Counter Top',
    'Demolition Contractor',
    'Design & Planning',
    'Drainage',
    'Drywall',
    'Electrical Contractor',
    'Electrician - Commercial',
    'Elevator',
    'Energy Services',
    'Engineering (MEP)',
    'Environmental Services',
    'Fences',
    'Finance & Approvals',
    'Fireplace & Oven Builder',
    'Flooring',
    'Garage Doors',
    'Glass',
    'Ground Work',
    'Handyman',
    'Heating Engineer',
    'HVAC - Heating & Air',
    'Inspection & Compliance',
    'Insurance',
    'Interior Design - Commercial',
    'Interior Design - Residential',
    'Interiors & Finishing',
    'Kitchen Construction',
    'Land & Legal',
    'Logistics & Equipment',
    'Materials & Supply',
    'Metal Work',
    'Painter',
    'Pest Control',
    'Plasterer',
    'Plumbing',
    'Pools, Spas & Saunas',
    'Power Generator',
    'Power Washing',
    'Project Management',
    'Protective Coatings/Sealants',
    'Renovations/Remodeling',
    'Restoration',
    'Roofing & Gutters',
    'Septic Systems',
    'Shutters & Awnings',
    'Smart & Security',
    'Solar',
    'Survey & Analysis',
    'Tile Worker',
    'Utilities',
    'Waterproofing-Weatherproofing',
    'Window Treatments',
    'Windows & Doors',
  ];

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
    _activeCategoryFilter = Uri.decodeComponent(widget.category);
    _fetchProviders();
  }

  @override
  void didUpdateWidget(covariant ProviderListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _activeCategoryFilter = Uri.decodeComponent(widget.category);
      _fetchProviders();
    }
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
    final cleanCat = _activeCategoryFilter.trim();
    final title = (cleanCat.isEmpty || cleanCat.toLowerCase() == 'all')
        ? 'Find Contractors'
        : cleanCat;

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
      // 0. Active Category Matching
      final targetCat = _activeCategoryFilter.trim().toLowerCase();
      if (targetCat.isNotEmpty && targetCat != 'all') {
        final pCat = (p['category'] ?? '').toString().toLowerCase();
        final pCats = pCat.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
        final matches = pCats.any((c) => c == targetCat || c.contains(targetCat) || targetCat.contains(c));
        if (!matches) {
          return false;
        }
      }

      // 1. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final name = (p['businessName'] ?? p['ownerName'] ?? '').toString().toLowerCase();
        final cat = (p['category'] ?? '').toString().toLowerCase();
        final address = (p['address'] ?? '').toString().toLowerCase();
        final bio = (p['bio'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !cat.contains(q) && !address.contains(q) && !bio.contains(q)) {
          return false;
        }
      }

      // 2. City Filter
      if (_selectedCity != 'All' && _selectedCity.isNotEmpty) {
        final address = (p['address'] ?? '').toString().toLowerCase();
        if (!address.contains(_selectedCity.toLowerCase())) {
          return false;
        }
      }

      // 3. Verified Only
      if (_verifiedOnly) {
        final isVerified = p['isVerified'] == true || p['isVerified'] == 1 || p['isVerified'] == 'true';
        if (!isVerified) return false;
      }

      // 4. Minimum Rating
      if (_minRating > 0) {
        final rating = (p['avgRating'] is num) ? (p['avgRating'] as num).toDouble() : 0.0;
        if (rating < _minRating && !(rating == 0.0 && _minRating <= 4.8)) {
          return false;
        }
      }

      // 5. Minimum Experience
      if (_minExperience > 0) {
        final exp = (p['experience'] is num)
            ? (p['experience'] as num).toInt()
            : (int.tryParse(p['experience']?.toString() ?? '0') ?? 0);
        if (exp < _minExperience) return false;
      }

      return true;
    }).toList();

    // Sort filtered providers
    filteredProviders.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          final rA = (a['avgRating'] is num) ? (a['avgRating'] as num).toDouble() : 0.0;
          final rB = (b['avgRating'] is num) ? (b['avgRating'] as num).toDouble() : 0.0;
          return rB.compareTo(rA);
        case 'experience':
          final eA = (a['experience'] is num) ? (a['experience'] as num).toInt() : (int.tryParse(a['experience']?.toString() ?? '0') ?? 0);
          final eB = (b['experience'] is num) ? (b['experience'] as num).toInt() : (int.tryParse(b['experience']?.toString() ?? '0') ?? 0);
          return eB.compareTo(eA);
        case 'projects':
          final pA = _completedCounts[a['id']?.toString()] ?? ((a['completedProjects'] as num?)?.toInt() ?? (a['projectsCount'] as num?)?.toInt() ?? 0);
          final pB = _completedCounts[b['id']?.toString()] ?? ((b['completedProjects'] as num?)?.toInt() ?? (b['projectsCount'] as num?)?.toInt() ?? 0);
          return pB.compareTo(pA);
        case 'name':
          final nA = (a['businessName'] ?? a['ownerName'] ?? '').toString();
          final nB = (b['businessName'] ?? b['ownerName'] ?? '').toString();
          return nA.toLowerCase().compareTo(nB.toLowerCase());
        default:
          return 0;
      }
    });

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
              // Filter Button on Right with Active Filter Badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _activeFiltersCount > 0 ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                    width: _activeFiltersCount > 0 ? 1.6 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: _activeFiltersCount > 0 ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: _showFilterModal,
                      ),
                    ),
                    if (_activeFiltersCount > 0)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_activeFiltersCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal Category & Filter Chips Based on the Page
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            children: _buildHorizontalFilterChips(),
          ),
        ),

        // Active Filter Chips Bar (if filters are active)
        if (_activeFiltersCount > 0 || _searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Text(
                  'Active: ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_searchQuery.isNotEmpty)
                          _buildActiveFilterChip('Search: $_searchQuery', () => setState(() {
                            _searchQuery = '';
                            _currentPage = 1;
                          })),
                        if (_verifiedOnly)
                          _buildActiveFilterChip('Verified', () => setState(() {
                            _verifiedOnly = false;
                            _currentPage = 1;
                          })),
                        if (_minRating > 0)
                          _buildActiveFilterChip('★ ${_minRating.toStringAsFixed(1)}+', () => setState(() {
                            _minRating = 0.0;
                            _currentPage = 1;
                          })),
                        if (_minExperience > 0)
                          _buildActiveFilterChip('$_minExperience+ yrs exp', () => setState(() {
                            _minExperience = 0;
                            _currentPage = 1;
                          })),
                        if (_selectedCity != 'All')
                          _buildActiveFilterChip(_selectedCity, () => setState(() {
                            _selectedCity = 'All';
                            _currentPage = 1;
                          })),
                        if (_sortBy != 'recommended')
                          _buildActiveFilterChip('Sort: ${_getSortLabel(_sortBy)}', () => setState(() {
                            _sortBy = 'recommended';
                            _currentPage = 1;
                          })),
                        if (_activeCategoryFilter.trim().isNotEmpty && _activeCategoryFilter.toLowerCase() != 'all')
                          _buildActiveFilterChip(_activeCategoryFilter, () {
                            setState(() {
                              _activeCategoryFilter = 'All';
                              _currentPage = 1;
                            });
                            _fetchProviders();
                          }),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _resetAllFilters,
                          child: const Text(
                            'Clear All',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Results Count Header
        if (filteredProviders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Row(
              children: [
                Text(
                  '${filteredProviders.length} contractor${filteredProviders.length == 1 ? '' : 's'} available',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                if (_sortBy != 'recommended')
                  Text(
                    'Sorted: ${_getSortLabel(_sortBy)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                  ),
              ],
            ),
          ),

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
                          _activeFiltersCount > 0 || _searchQuery.isNotEmpty
                              ? 'No contractors match your active filters. Try resetting filters.'
                              : (_activeCategoryFilter == 'All'
                                  ? 'No verified contractors match your current search.'
                                  : 'No contractors registered under "$_activeCategoryFilter" yet.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                        if (_activeFiltersCount > 0 || _searchQuery.isNotEmpty || _activeCategoryFilter != 'All') ...[
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _resetAllFilters,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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

  void _resetAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCity = 'All';
      _verifiedOnly = false;
      _minRating = 0.0;
      _minExperience = 0;
      _sortBy = 'recommended';
      _currentPage = 1;
      final defaultCat = Uri.decodeComponent(widget.category);
      if (_activeCategoryFilter != defaultCat) {
        _activeCategoryFilter = defaultCat;
        _fetchProviders();
      }
    });
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'rating':
        return 'Highest Rated';
      case 'experience':
        return 'Most Experienced';
      case 'projects':
        return 'Most Projects';
      case 'name':
        return 'Name (A-Z)';
      default:
        return 'Recommended';
    }
  }

  Widget _buildFilterSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4338CA),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFF4338CA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color color = const Color(0xFF6366F1),
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHorizontalFilterChips() {
    final chips = <Widget>[];
    final isSpecificCategory = _activeCategoryFilter.trim().isNotEmpty &&
        _activeCategoryFilter.trim().toLowerCase() != 'all';

    if (isSpecificCategory) {
      // 1. Current Active Category Chip (Clearly selected so user knows this category is applied!)
      chips.add(_buildFilterChip(
        label: _activeCategoryFilter,
        icon: Icons.check_circle_rounded,
        isSelected: true,
        color: const Color(0xFF6366F1),
        onTap: () {
          _fetchProviders();
        },
      ));

      // 2. "All Contractors" Chip (allows clearing category filter)
      chips.add(_buildFilterChip(
        label: 'All Contractors',
        icon: Icons.grid_view_rounded,
        isSelected: false,
        onTap: () {
          setState(() {
            _activeCategoryFilter = 'All';
            _currentPage = 1;
          });
          _fetchProviders();
        },
      ));
    } else {
      // When viewing All Contractors
      final isAllSub = !_verifiedOnly && _minRating == 0.0 && _minExperience == 0 && _selectedCity == 'All';
      chips.add(_buildFilterChip(
        label: 'All Contractors',
        icon: Icons.grid_view_rounded,
        isSelected: isAllSub,
        onTap: () {
          setState(() {
            _activeCategoryFilter = 'All';
            _verifiedOnly = false;
            _minRating = 0.0;
            _minExperience = 0;
            _selectedCity = 'All';
            _currentPage = 1;
          });
          _fetchProviders();
        },
      ));
    }

    // 3. "Verified"
    chips.add(_buildFilterChip(
      label: 'Verified',
      icon: Icons.verified_rounded,
      isSelected: _verifiedOnly,
      color: const Color(0xFF10B981),
      onTap: () {
        setState(() {
          _verifiedOnly = !_verifiedOnly;
          _currentPage = 1;
        });
      },
    ));

    // 4. "★ 4.5+ Rating"
    chips.add(_buildFilterChip(
      label: '★ 4.5+',
      icon: Icons.star_rounded,
      isSelected: _minRating == 4.5,
      color: const Color(0xFFF59E0B),
      onTap: () {
        setState(() {
          _minRating = (_minRating == 4.5) ? 0.0 : 4.5;
          _currentPage = 1;
        });
      },
    ));

    // 5. "5+ Yrs Exp"
    chips.add(_buildFilterChip(
      label: '5+ Yrs Exp',
      icon: Icons.workspace_premium_rounded,
      isSelected: _minExperience == 5,
      color: const Color(0xFF0284C7),
      onTap: () {
        setState(() {
          _minExperience = (_minExperience == 5) ? 0 : 5;
          _currentPage = 1;
        });
      },
    ));

    // 6. "10+ Yrs Exp"
    chips.add(_buildFilterChip(
      label: '10+ Yrs Exp',
      icon: Icons.military_tech_rounded,
      isSelected: _minExperience == 10,
      color: const Color(0xFF8B5CF6),
      onTap: () {
        setState(() {
          _minExperience = (_minExperience == 10) ? 0 : 10;
          _currentPage = 1;
        });
      },
    ));

    // 7. Dynamic Cities
    for (final city in _availableCities) {
      final isSelected = _selectedCity.toLowerCase() == city.toLowerCase();
      chips.add(_buildFilterChip(
        label: city,
        icon: Icons.location_on_rounded,
        isSelected: isSelected,
        color: const Color(0xFFEA580C),
        onTap: () {
          setState(() {
            _selectedCity = isSelected ? 'All' : city;
            _currentPage = 1;
          });
        },
      ));
    }

    // 8. Popular Categories chips (allow switching directly between other categories!)
    for (final cat in _popularCategories.where((c) => c['name'] != 'All')) {
      final name = cat['name'] as String;
      if (name.toLowerCase() == _activeCategoryFilter.toLowerCase()) continue;
      final icon = cat['icon'] as IconData;
      chips.add(_buildFilterChip(
        label: name,
        icon: icon,
        isSelected: false,
        color: cat['color'] as Color? ?? const Color(0xFF6366F1),
        onTap: () {
          setState(() {
            _activeCategoryFilter = name;
            _currentPage = 1;
          });
          _fetchProviders();
        },
      ));
    }

    return chips;
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle pill
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Filter Contractors',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (_activeFiltersCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_activeFiltersCount',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _verifiedOnly = false;
                              _minRating = 0.0;
                              _minExperience = 0;
                              _selectedCity = 'All';
                              _sortBy = 'recommended';
                            });
                            setState(() {});
                          },
                          child: const Text(
                            'Reset All',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Scrollable Filter Sections
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Sort By
                          _buildFilterSectionTitle('Sort By'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChoiceChip('Recommended', _sortBy == 'recommended', () {
                                setModalState(() => _sortBy = 'recommended');
                              }),
                              _buildChoiceChip('★ Highest Rated', _sortBy == 'rating', () {
                                setModalState(() => _sortBy = 'rating');
                              }),
                              _buildChoiceChip('Most Experienced', _sortBy == 'experience', () {
                                setModalState(() => _sortBy = 'experience');
                              }),
                              _buildChoiceChip('Most Projects', _sortBy == 'projects', () {
                                setModalState(() => _sortBy = 'projects');
                              }),
                              _buildChoiceChip('Name (A-Z)', _sortBy == 'name', () {
                                setModalState(() => _sortBy = 'name');
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 2. Verified Only Switch
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verified Contractors Only',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Show businesses with verified documents',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _verifiedOnly,
                                  activeTrackColor: const Color(0xFF10B981),
                                  onChanged: (val) {
                                    setModalState(() => _verifiedOnly = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3. Minimum Rating
                          _buildFilterSectionTitle('Minimum Rating'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChoiceChip('Any', _minRating == 0.0, () {
                                setModalState(() => _minRating = 0.0);
                              }),
                              _buildChoiceChip('★ 3.5+', _minRating == 3.5, () {
                                setModalState(() => _minRating = 3.5);
                              }),
                              _buildChoiceChip('★ 4.0+', _minRating == 4.0, () {
                                setModalState(() => _minRating = 4.0);
                              }),
                              _buildChoiceChip('★ 4.5+', _minRating == 4.5, () {
                                setModalState(() => _minRating = 4.5);
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 4. Experience Level
                          _buildFilterSectionTitle('Experience'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChoiceChip('Any Experience', _minExperience == 0, () {
                                setModalState(() => _minExperience = 0);
                              }),
                              _buildChoiceChip('3+ Years', _minExperience == 3, () {
                                setModalState(() => _minExperience = 3);
                              }),
                              _buildChoiceChip('5+ Years', _minExperience == 5, () {
                                setModalState(() => _minExperience = 5);
                              }),
                              _buildChoiceChip('10+ Years', _minExperience == 10, () {
                                setModalState(() => _minExperience = 10);
                              }),
                              _buildChoiceChip('20+ Years', _minExperience == 20, () {
                                setModalState(() => _minExperience = 20);
                              }),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 5. Location / City
                          if (_availableCities.isNotEmpty) ...[
                            _buildFilterSectionTitle('Location / City'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildChoiceChip('All Locations', _selectedCity == 'All', () {
                                  setModalState(() => _selectedCity = 'All');
                                }),
                                ..._availableCities.map((city) {
                                  return _buildChoiceChip(city, _selectedCity.toLowerCase() == city.toLowerCase(), () {
                                    setModalState(() => _selectedCity = city);
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 6. Category Selection
                          _buildFilterSectionTitle('Category'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChoiceChip('All Categories', _activeCategoryFilter == 'All', () {
                                setModalState(() => _activeCategoryFilter = 'All');
                              }),
                              if (widget.category.toLowerCase() != 'all')
                                _buildChoiceChip(widget.category, _activeCategoryFilter == widget.category, () {
                                  setModalState(() => _activeCategoryFilter = widget.category);
                                }),
                              ..._allCategoryNames
                                  .where((c) => c != 'All' && c != widget.category)
                                  .map((catName) {
                                return _buildChoiceChip(
                                  catName,
                                  _activeCategoryFilter.toLowerCase() == catName.toLowerCase(),
                                  () {
                                    setModalState(() => _activeCategoryFilter = catName);
                                  },
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _resetAllFilters();
                              Navigator.pop(modalCtx);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _currentPage = 1;
                              });
                              Navigator.pop(modalCtx);
                              _fetchProviders();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
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
          },
        );
      },
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
    // Prioritize the active category if viewing a specific category
    final targetCat = _activeCategoryFilter.trim().toLowerCase();
    if (targetCat.isNotEmpty && targetCat != 'all') {
      catList.sort((a, b) {
        final aLower = a.toLowerCase();
        final bLower = b.toLowerCase();
        final aMatch = aLower == targetCat || aLower.contains(targetCat) || targetCat.contains(aLower);
        final bMatch = bLower == targetCat || bLower.contains(targetCat) || targetCat.contains(bLower);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
        return 0;
      });
    }
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (id.isNotEmpty) {
              context.push('/provider-profile/$id');
            }
          },
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
    ),
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
