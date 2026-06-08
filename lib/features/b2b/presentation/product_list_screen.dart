import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import 'widgets/custom_image.dart';

class ProductItem {
  final String id;
  final String name;
  final String supplierName;
  final String location;
  final String imageUrl;
  final String description;
  final double pricePerUnit;
  final String unitType;

  ProductItem({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.pricePerUnit,
    required this.unitType,
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
      pricePerUnit: (json['price_per_unit'] != null) ? double.parse(json['price_per_unit'].toString()) : 0.0,
      unitType: json['unit_type'] ?? 'Bag',
    );
  }
}

class ProductListScreen extends StatefulWidget {
  final String? category;

  const ProductListScreen({super.key, this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedLocation = 'All India';
  String _selectedCategory = 'All';
  
  bool _isLoading = false;
  List<ProductItem> _products = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = B2BApiService();
      
      final Map<String, String> queryParams = {};
      if (_selectedCategory != 'All') {
        queryParams['category'] = _selectedCategory;
      }
      if (_searchQuery.isNotEmpty) {
        queryParams['query'] = _searchQuery;
      }
      if (_selectedLocation != 'All India') {
        queryParams['location'] = _selectedLocation;
      }

      final res = await api.get('/buyer/products', queryParameters: queryParams);
      
      if (res.success && res.data != null) {
        final List list = res.data['products'] ?? [];
        setState(() {
          _products = list.map((item) => ProductItem.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _errorMessage = res.data['error'] ?? 'Failed to fetch products';
          _products = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection Error: Unable to fetch products.';
        _products = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('B2B Sourcing Products'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val);
                    _fetchProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Press enter to search...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterDropdown(
                        'Category: $_selectedCategory',
                        ['All', 'Materials & Supply', 'Electrical', 'Plumbing', 'Interior Design', 'Furniture', 'Paints', 'Hardware'],
                        (val) {
                          setState(() => _selectedCategory = val);
                          _fetchProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        'Location: $_selectedLocation',
                        ['All India', 'Mumbai', 'Delhi NCR', 'Bengaluru', 'Chennai', 'Kolkata'],
                        (val) {
                          setState(() => _selectedLocation = val);
                          _fetchProducts();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),

          if (_errorMessage != null)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No approved B2B products found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final item = _products[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: BuildMartImage(imageUrl: item.imageUrl, width: 95, height: 95, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.supplierName,
                                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item.pricePerUnit.toStringAsFixed(0)} / ${item.unitType}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, size: 12, color: Colors.red),
                                            const SizedBox(width: 4),
                                            Text(item.location, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () => context.push('/b2b-product-detail/${item.id}'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options, ValueChanged<String> onChanged) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) {
        return options.map((opt) {
          return PopupMenuItem(value: opt, child: Text(opt));
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(50),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
