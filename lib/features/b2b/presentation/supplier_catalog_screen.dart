import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import 'widgets/custom_image.dart';
import '../../../core/full_screen_image_viewer.dart';

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

  /// Why the admin hid this product (only when status is Rejected).
  final String? rejectedReason;

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
    this.rejectedReason,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> specs = {};
    if (json['specifications'] != null && json['specifications'] is Map) {
      specs = Map<String, dynamic>.from(json['specifications']);
    }

    List<String> imgs = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imgs = (json['images'] as List).map((e) => e.toString()).toList();
      } else if (json['images'] is String && (json['images'] as String).isNotEmpty) {
        final raw = (json['images'] as String).trim();
        if (raw.startsWith('[') && raw.endsWith(']')) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              imgs = decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {
            imgs = [raw];
          }
        } else {
          imgs = [raw];
        }
      }
    }
    if (imgs.isEmpty && json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      imgs = [json['imageUrl'].toString()];
    }

    return CatalogItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Approved',
      categoryName: json['category_name'] ?? 'General',
      categoryId: json['category_id'] != null ? int.parse(json['category_id'].toString()) : 1,
      pricePerUnit: double.tryParse(json['price_per_unit']?.toString() ?? '') ?? 0.0,
      unitType: json['unit_type'] ?? 'Bag',
      specifications: specs,
      images: imgs,
      rejectedReason: json['rejected_reason']?.toString(),
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


  // ===========================================================================
  // UI (bento)
  // ===========================================================================

  String _price(double v) => '₹${NumberFormat.decimalPattern('en_IN').format(v.round())}';

  bool _hasText(String s) {
    final t = s.trim().toLowerCase();
    return t.isNotEmpty && t != 'none' && t != 'null';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Approved':
        return 'Live';
      case 'Pending':
        return 'In review';
      case 'Rejected':
        return 'Hidden';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('approved') || s.contains('active')) return Bento.green;
    if (s.contains('reject')) return Bento.red;
    return const Color(0xFFD97706);
  }

  void _openAddProduct() => context.push('/supplier-add-product').then((_) => _fetchCatalogData());

  void _editProduct(CatalogItem item) {
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
  }

  void _viewImage(CatalogItem item) {
    if (item.images.isEmpty || item.images.first.isEmpty) return;
    final img = item.images.first;
    final isNet = img.startsWith('http://') || img.startsWith('https://');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          base64Image: isNet ? null : img,
          imageUrl: isNet ? img : null,
          title: item.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final approved = _productsList.where((p) => _statusColor(p.status) == Bento.green).length;
    final pending = _productsList.length - approved;

    return Scaffold(
      appBar: BentoAppBar(
        title: const Text('My products'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh', onPressed: _fetchCatalogData),
        ],
      ),
      floatingActionButton: _productsList.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: Bento.accent,
              onRefresh: _fetchCatalogData,
              child: LayoutBuilder(
                builder: (context, c) {
                  final columns = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 600 ? 3 : 2);
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (_errorMessage != null) ...[
                                BentoCard(
                                  color: Color.alphaBlend(Bento.warning.withValues(alpha: 0.12), Bento.surface(dark)),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_errorMessage!, style: TextStyle(fontSize: 12.5, color: Bento.text(dark))),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: Bento.gap),
                              ],
                              if (_productsList.isNotEmpty)
                                Row(
                                  children: [
                                    Expanded(child: _statChip(dark, '${_productsList.length}', 'Listed', Icons.inventory_2_rounded, Bento.accent)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _statChip(dark, '$approved', 'Approved', Icons.verified_rounded, Bento.green)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _statChip(dark, '$pending', 'In review', Icons.hourglass_top_rounded, const Color(0xFFD97706))),
                                  ],
                                ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                      if (_productsList.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: BentoEmptyState(
                              icon: Icons.storefront_rounded,
                              title: 'Your catalog is empty',
                              subtitle: 'List cement, steel, tiles and more so buyers can send you inquiries.',
                              actionLabel: 'Add your first product',
                              onAction: _openAddProduct,
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: 286,
                              crossAxisSpacing: Bento.gap,
                              mainAxisSpacing: Bento.gap,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _productCard(dark, _productsList[i]),
                              childCount: _productsList.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _statChip(bool dark, String value, String label, IconData icon, Color color) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          BentoIconBubble(icon: icon, color: color, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, height: 1, fontWeight: FontWeight.w900, color: Bento.text(dark))),
                const SizedBox(height: 2),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, color: Bento.muted(dark), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(bool dark, CatalogItem item) {
    final hasImage = item.images.isNotEmpty && item.images.first.isNotEmpty;
    final statusColor = _statusColor(item.status);

    Widget placeholder() => Container(
          color: Bento.surfaceAlt(dark),
          alignment: Alignment.center,
          child: Icon(Icons.inventory_2_rounded, color: Bento.muted(dark), size: 34),
        );

    return BentoCard(
      padding: EdgeInsets.zero,
      onTap: () => _editProduct(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _viewImage(item),
                  child: hasImage
                      ? BuildMartImage(imageUrl: item.images.first, fit: BoxFit.cover, placeholder: placeholder())
                      : placeholder(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: BentoPill(
                    label: _statusLabel(item.status),
                    color: Colors.white,
                    background: statusColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: Bento.text(dark)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Bento.accentText(dark)),
                  ),
                  if (item.status == 'Rejected' && _hasText(item.rejectedReason ?? '')) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hidden: ${item.rejectedReason}. Edit to send for review.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Bento.red, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                  ] else if (_hasText(item.description)) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), height: 1.3),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _price(item.pricePerUnit),
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Bento.text(dark)),
                                ),
                                TextSpan(
                                  text: ' / ${item.unitType}',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Bento.muted(dark)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: BentoPressable(
                          onTap: () => _editProduct(item),
                          child: Container(
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Bento.accent.withValues(alpha: dark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, size: 15, color: Bento.accentText(dark)),
                                const SizedBox(width: 5),
                                Text('Edit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Bento.accentText(dark))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      BentoPressable(
                        onTap: () => _deleteCatalogItem(item),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Bento.red.withValues(alpha: dark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, size: 17, color: Bento.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
