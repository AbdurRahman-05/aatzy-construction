import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import 'widgets/custom_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isSaved = false;
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  List<dynamic> _relatedProducts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = B2BApiService();
      final res = await api.get('/buyer/products/${widget.productId}');
      if (res.success && res.data != null) {
        setState(() {
          _product = res.data['product'];
          _relatedProducts = res.data['relatedProducts'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = res.data['error'] ?? 'Failed to load details';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load live product details.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = _product;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Product details not found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProductDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final rawSpecs = p['specifications'];
    final Map<String, String> specs = {};
    if (rawSpecs is Map) {
      rawSpecs.forEach((key, value) {
        specs[key.toString()] = value.toString();
      });
    } else {
      specs['Packaging'] = 'Standard B2B Packing';
      specs['Min Order Quantity'] = '100 units';
    }

    final imagesList = p['images'] as List?;
    final images = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList
        : ['https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=600'];

    final double price = p['price_per_unit'] != null ? double.parse(p['price_per_unit'].toString()) : 0.0;
    final String unit = p['unit_type'] ?? 'Bag';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isSaved ? Colors.red : Colors.black87,
            ),
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isSaved ? 'Saved to favorites' : 'Removed from favorites')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return BuildMartImage(imageUrl: images[index], fit: BoxFit.cover, width: double.infinity);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          p['business_type'] ?? 'Verified Supplier',
                          style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${p['avg_rating'] ?? "0.0"} (${p['total_reviews'] ?? 0} reviews)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p['name'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estimated Rate: ₹${price.toStringAsFixed(0)} / $unit',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),

                  const SizedBox(height: 12),
                  const Text('Product Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(p['description'] ?? 'No description provided.', style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),

                  const SizedBox(height: 12),
                  const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300, width: 1, borderRadius: BorderRadius.circular(8)),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                    },
                    children: specs.entries.map((entry) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(entry.key, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(entry.value, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),

                  const SizedBox(height: 12),
                  const Text('Supplier Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BuildMartImage(imageUrl: p['logo_url'] ?? '', width: 52, height: 52, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p['company_name'] ?? 'BuildMart Supplier', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p['avg_rating'] ?? "0.0"} (${p['total_reviews'] ?? 0} Reviews)',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(p['supplier_location'] ?? 'All India', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_relatedProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Related Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _relatedProducts.length,
                        itemBuilder: (context, idx) {
                          final rel = _relatedProducts[idx];
                          final relImages = rel['images'] as List?;
                          final relImage = (relImages != null && relImages.isNotEmpty) ? relImages[0] as String : '';
                          return GestureDetector(
                            onTap: () {
                              context.pushReplacement('/b2b-product-detail/${rel['id']}');
                            },
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: BuildMartImage(imageUrl: relImage, width: 130, height: 90, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rel['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    '₹${rel['price_per_unit']} / ${rel['unit_type']}',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contacting ${p['company_name'] ?? "supplier"} via phone...')),
                  );
                },
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: const Text('Call Supplier'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/b2b-inquiry-form?productId=${p['id']}&productName=${Uri.encodeComponent(p['name'] ?? "")}&supplierId=${p['supplier_id']}&productImage=${Uri.encodeComponent(images[0])}',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send B2B Inquiry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
