import 'dart:async';

import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import 'widgets/custom_image.dart';
import '../../../core/widgets/shimmer_loading.dart';

class ProductItem {
  final String id;
  final String name;
  final String supplierName;
  final String location;
  final String imageUrl;
  final String description;
  final double pricePerUnit;
  final String unitType;
  final String category;
  final bool isVerified;

  ProductItem({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.pricePerUnit,
    required this.unitType,
    this.category = '',
    this.isVerified = false,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final imagesList = json['images'] as List?;
    final imgUrl = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList[0] as String
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400';

    return ProductItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      supplierName: json['company_name'] ?? json['supplierName'] ?? 'Supplier',
      location: json['location'] ?? 'All India',
      imageUrl: imgUrl,
      description: json['description'] ?? '',
      pricePerUnit: double.tryParse(json['price_per_unit']?.toString() ?? '') ?? 0.0,
      unitType: json['unit_type'] ?? 'Bag',
      category: json['category']?.toString() ?? '',
      isVerified: json['is_verified'] == true,
    );
  }
}

/// Same list the partner picks from when adding a product (ids 1-8 on the server).
const List<Map<String, dynamic>> kMaterialCategories = [
  {'name': 'All', 'icon': Icons.apps_rounded},
  {'name': 'Materials & Supply', 'icon': Icons.foundation_rounded},
  {'name': 'Paints', 'icon': Icons.color_lens_rounded},
  {'name': 'Electrical', 'icon': Icons.bolt_rounded},
  {'name': 'Plumbing', 'icon': Icons.water_drop_rounded},
  {'name': 'Hardware', 'icon': Icons.hardware_rounded},
  {'name': 'Interior Design', 'icon': Icons.format_paint_rounded},
  {'name': 'Furniture', 'icon': Icons.chair_rounded},
  {'name': 'LED Walls & Digital Displays', 'icon': Icons.smart_display_rounded},
];

String formatRupees(double value) {
  final whole = value.round().toString();
  if (whole.length <= 3) return '₹$whole';
  final last3 = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '₹${groups.join(',')},$last3';
}

class ProductListScreen extends StatefulWidget {
  final String? category;
  const ProductListScreen({super.key, this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  String _selectedLocation = 'All India';
  String _selectedCategory = 'All';

  bool _isLoading = true;
  List<ProductItem> _products = [];
  // Places that suppliers with products are actually in (from the server)
  List<String> _locations = const ['All India'];
  String? _errorMessage;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || value.trim() == _searchQuery) return;
      setState(() => _searchQuery = value.trim());
      _fetchProducts();
    });
  }

  Future<void> _fetchProducts() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, String>{
        if (_selectedCategory != 'All') 'category': _selectedCategory,
        if (_searchQuery.isNotEmpty) 'query': _searchQuery,
        if (_selectedLocation != 'All India') 'location': _selectedLocation,
      };

      final res = await B2BApiService().get('/buyer/products', queryParameters: queryParams);
      // A newer search/filter started while this one was loading - ignore this result
      if (!mounted || requestId != _requestId) return;

      if (res.success && res.data != null) {
        final List list = res.data['products'] ?? [];
        setState(() {
          _products = list.map((item) => ProductItem.fromJson(item)).toList();
          final serverLocations = (res.data['locations'] as List? ?? []).map((e) => e.toString()).toList();
          if (serverLocations.isNotEmpty) {
            _locations = ['All India', ...serverLocations];
          }
        });
      } else {
        setState(() {
          _errorMessage = res.data['error'] ?? 'Failed to fetch products';
          _products = [];
        });
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = 'Connection error: unable to fetch products.';
        _products = [];
      });
    } finally {
      if (mounted && requestId == _requestId) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: BoxDecoration(
            color: Bento.surface(dark),
            borderRadius: BorderRadius.circular(Bento.radius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier location',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Bento.text(dark))),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _locations.map((loc) {
                    final selected = loc == _selectedLocation;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        loc == 'All India' ? Icons.public_rounded : Icons.location_on_rounded,
                        color: selected ? Bento.accent : Bento.muted(dark),
                      ),
                      title: Text(loc,
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: Bento.text(dark),
                          )),
                      trailing: selected ? const Icon(Icons.check_circle_rounded, color: Bento.accent) : null,
                      onTap: () => Navigator.pop(ctx, loc),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != _selectedLocation) {
      setState(() => _selectedLocation = picked);
      _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: BentoAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Buy Materials'),
        actions: [
          IconButton(
            tooltip: 'My orders',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => context.push('/b2b-my-inquiries'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + location
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: BentoSearchField(
                    hint: 'Search cement, steel, paint…',
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                BentoPressable(
                  onTap: _pickLocation,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedLocation == 'All India' ? Bento.surface(dark) : Bento.accent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedLocation == 'All India' ? Bento.border(dark) : Bento.accent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 17,
                          color: _selectedLocation == 'All India' ? Bento.accentText(dark) : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            _selectedLocation == 'All India' ? 'All India' : _selectedLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: _selectedLocation == 'All India' ? Bento.text(dark) : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kMaterialCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = kMaterialCategories[i];
                final name = cat['name'] as String;
                final selected = name == _selectedCategory;
                return BentoPressable(
                  onTap: () {
                    if (selected) return;
                    setState(() => _selectedCategory = name);
                    _fetchProducts();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: selected ? Bento.ink : Bento.surface(dark),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Bento.ink : Bento.border(dark)),
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData,
                            size: 15, color: selected ? Bento.accentLight : Bento.muted(dark)),
                        const SizedBox(width: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Bento.text(dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: BentoCard(
                color: Bento.warning.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Bento.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(fontSize: 12, color: Bento.text(dark)))),
                  ],
                ),
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchProducts,
              color: Bento.accent,
              child: _isLoading
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: ShimmerProductGrid(itemCount: 6),
                    )
                  : _products.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            BentoEmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No products found',
                              subtitle: _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedLocation != 'All India'
                                  ? 'Try another search, category or location.'
                                  : 'Suppliers haven\'t listed products yet. Pull down to refresh.',
                              actionLabel: _searchQuery.isNotEmpty || _selectedCategory != 'All' || _selectedLocation != 'All India'
                                  ? 'Clear filters'
                                  : null,
                              onAction: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = 'All';
                                  _selectedLocation = 'All India';
                                });
                                _fetchProducts();
                              },
                            ),
                          ],
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: Bento.gap,
                            mainAxisSpacing: Bento.gap,
                            childAspectRatio: 0.62,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) => _ProductTile(item: _products[index], dark: dark),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductItem item;
  final bool dark;
  const _ProductTile({required this.item, required this.dark});

  @override
  Widget build(BuildContext context) {
    return BentoPressable(
      onTap: () => context.push('/b2b-product-detail/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Bento.surface(dark),
          borderRadius: BorderRadius.circular(Bento.radius - 4),
          border: Border.all(color: Bento.border(dark)),
          boxShadow: Bento.shadow(dark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Bento.surfaceAlt(dark),
                    padding: const EdgeInsets.all(8),
                    child: BuildMartImage(imageUrl: item.imageUrl, fit: BoxFit.contain),
                  ),
                  if (item.isVerified)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: BentoPill(
                        label: 'Verified',
                        icon: Icons.verified_rounded,
                        color: Colors.white,
                        background: Bento.accent,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Bento.text(dark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatRupees(item.pricePerUnit),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Bento.accentText(dark),
                          ),
                        ),
                        TextSpan(
                          text: ' / ${item.unitType}',
                          style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 13, color: Bento.muted(dark)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Bento.muted(dark)),
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
}
