import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';

class CatalogItem {
  final String id;
  final String name;
  final String description;
  final String status;
  final String categoryName;
  final int categoryId;
  final double pricePerUnit;
  final String unitType;
  final Map<String, dynamic> specifications;
  final List<String> images;

  CatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.categoryName,
    required this.categoryId,
    required this.pricePerUnit,
    required this.unitType,
    required this.specifications,
    required this.images,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> specs = {};
    if (json['specifications'] != null && json['specifications'] is Map) {
      specs = Map<String, dynamic>.from(json['specifications']);
    }

    List<String> imgs = [];
    if (json['images'] != null && json['images'] is List) {
      imgs = List<String>.from(json['images']);
    }

    return CatalogItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Approved',
      categoryName: json['category_name'] ?? 'General',
      categoryId: json['category_id'] != null ? int.parse(json['category_id'].toString()) : 1,
      pricePerUnit: json['price_per_unit'] != null ? double.parse(json['price_per_unit'].toString()) : 450.0,
      unitType: json['unit_type'] ?? 'Bag',
      specifications: specs,
      images: imgs,
    );
  }
}

class SupplierCatalogScreen extends ConsumerStatefulWidget {
  const SupplierCatalogScreen({super.key});

  @override
  ConsumerState<SupplierCatalogScreen> createState() => _SupplierCatalogScreenState();
}

class _SupplierCatalogScreenState extends ConsumerState<SupplierCatalogScreen> {
  bool _isLoading = false;
  List<CatalogItem> _productsList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCatalogData();
  }

  Future<void> _fetchCatalogData() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      setState(() {
        _errorMessage = 'Please log in to view catalog';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = B2BApiService();
      final res = await api.get('/supplier/products', queryParameters: {'supplierId': auth.id!});
      if (res.success && res.data != null) {
        final List list = res.data['products'] ?? [];
        setState(() {
          _productsList = list.map((item) => CatalogItem.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _errorMessage = res.data['error'] ?? 'Failed to load products';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load catalog products.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCatalogItem(CatalogItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${item.name}" listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final api = B2BApiService();
        final res = await api.delete('/supplier/products/${item.id}');
        
        if (res.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${item.name}" removed successfully.')),
            );
          }
          _fetchCatalogData();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res.data['error'] ?? 'Failed to delete listing.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete listing.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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
        title: const Text('My Product Catalog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCatalogData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/supplier-add-product').then((_) => _fetchCatalogData()),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    color: Colors.amber.shade100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.black87), textAlign: TextAlign.center),
                  ),
                Expanded(
                  child: _productsList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No listings found in your catalog.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/supplier-add-product').then((_) => _fetchCatalogData()),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Listing'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _productsList.length,
                          itemBuilder: (context, index) {
                            final item = _productsList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.categoryName,
                                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Price: ₹${item.pricePerUnit.toStringAsFixed(0)} / ${item.unitType}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.status,
                                                  style: const TextStyle(
                                                    fontSize: 9.5, 
                                                    fontWeight: FontWeight.w800, 
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                          onPressed: () {
                                            context.push('/supplier-add-product', extra: {
                                              'id': item.id,
                                              'name': item.name,
                                              'description': item.description,
                                              'status': item.status,
                                              'categoryId': item.categoryId,
                                              'categoryName': item.categoryName,
                                              'price_per_unit': item.pricePerUnit,
                                              'unit_type': item.unitType,
                                              'specifications': item.specifications,
                                              'images': item.images,
                                            }).then((_) => _fetchCatalogData());
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => _deleteCatalogItem(item),
                                        ),
                                      ],
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
}
