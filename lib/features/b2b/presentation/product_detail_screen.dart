import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../services/b2b_api_service.dart';
import 'product_list_screen.dart' show formatRupees;
import 'widgets/custom_image.dart';
import '../../../core/widgets/shimmer_loading.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  List<dynamic> _relatedProducts = [];
  String? _errorMessage;
  int _imageIndex = 0;

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
      final res = await B2BApiService().get('/buyer/products/${widget.productId}');
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _product = res.data['product'];
          _relatedProducts = res.data['relatedProducts'] ?? [];
        });
      } else {
        setState(() => _errorMessage = res.data['error'] ?? 'Failed to load details');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to load product details.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openInquiry(Map<String, dynamic> p, double price, String unit) {
    final params = <String, String>{
      'productId': p['id'].toString(),
      'productName': p['name']?.toString() ?? '',
      'supplierId': p['supplier_id'].toString(),
      'supplierName': p['company_name']?.toString() ?? '',
      'unit': unit,
      'price': price.toStringAsFixed(2),
    };
    context.push(Uri(path: '/b2b-inquiry-form', queryParameters: params).toString());
  }

  void _openChat(Map<String, dynamic> p) {
    final supplierId = p['supplier_id']?.toString() ?? '';
    if (supplierId.isEmpty) return;
    final name = Uri.encodeQueryComponent(p['company_name']?.toString() ?? 'Supplier');
    context.push('/chat/$supplierId?name=$name');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ShimmerProductDetail();
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = _product;
    if (p == null) {
      return Scaffold(
        appBar: BentoAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Product'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BentoEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Product unavailable',
            subtitle: _errorMessage ?? 'This product may have been removed by the supplier.',
            actionLabel: 'Retry',
            onAction: _fetchProductDetails,
          ),
        ),
      );
    }

    final auth = ref.watch(authProvider);
    final isProvider = auth.role == 'PROVIDER';

    // Only show specifications the supplier actually entered
    final rawSpecs = p['specifications'];
    final specs = <String, String>{};
    if (rawSpecs is Map) {
      rawSpecs.forEach((key, value) {
        final v = value?.toString().trim() ?? '';
        if (v.isNotEmpty) specs[key.toString()] = v;
      });
    }

    final imagesList = p['images'] as List?;
    final images = (imagesList != null && imagesList.isNotEmpty)
        ? imagesList
        : const ['https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=600'];

    final double price = double.tryParse(p['price_per_unit']?.toString() ?? '') ?? 0.0;
    final String unit = p['unit_type'] ?? 'Bag';
    final bool verified = p['is_verified'] == true;
    final double rating = double.tryParse(p['avg_rating']?.toString() ?? '') ?? 0.0;
    final int reviews = int.tryParse(p['total_reviews']?.toString() ?? '') ?? 0;
    final String category = p['category']?.toString() ?? '';

    return Scaffold(
      appBar: BentoAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Product'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          // Image gallery
          BentoCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Bento.radius),
              child: SizedBox(
                height: 260,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (context, index) => Container(
                        color: Bento.surfaceAlt(dark),
                        padding: const EdgeInsets.all(12),
                        child: BuildMartImage(
                          imageUrl: images[index].toString(),
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) {
                            final active = i == _imageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active ? Bento.accent : Bento.muted(dark).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Bento.gap),

          // Title + price
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (category.isNotEmpty)
                      BentoPill(label: category, color: Bento.accentText(dark), icon: Icons.category_rounded),
                    if (verified)
                      const BentoPill(label: 'Verified supplier', color: Bento.green, icon: Icons.verified_rounded),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  p['name'] ?? '',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Bento.text(dark),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: Bento.accentGradient,
                    borderRadius: BorderRadius.circular(Bento.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Listed price',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: formatRupees(price),
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                TextSpan(
                                  text: '  / $unit',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Final price\nin quote',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 10.5, height: 1.2, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Bento.gap),

          // Description
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('About this product', Icons.notes_rounded, dark),
                const SizedBox(height: 8),
                Text(
                  (p['description']?.toString().trim().isNotEmpty ?? false)
                      ? p['description']
                      : 'No description provided.',
                  style: TextStyle(fontSize: 13.5, height: 1.5, color: Bento.muted(dark)),
                ),
              ],
            ),
          ),

          if (specs.isNotEmpty) ...[
            const SizedBox(height: Bento.gap),
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Specifications', Icons.straighten_rounded, dark),
                  const SizedBox(height: 10),
                  ...specs.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Bento.surfaceAlt(dark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(e.key,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Bento.muted(dark))),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(e.value,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Bento.text(dark))),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: Bento.gap),

          // Supplier
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Supplier', Icons.storefront_rounded, dark),
                const SizedBox(height: 12),
                Row(
                  children: [
                    BentoAvatar(
                      name: p['company_name']?.toString() ?? 'Supplier',
                      image: (p['logo_url']?.toString().isNotEmpty ?? false) ? p['logo_url'] : null,
                      size: 50,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p['company_name'] ?? 'Supplier',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                                ),
                              ),
                              if (verified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified_rounded, size: 16, color: Bento.accent),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 15, color: Bento.warning),
                              const SizedBox(width: 3),
                              Text(
                                reviews > 0 ? '${rating.toStringAsFixed(1)} · $reviews ratings' : 'No ratings yet',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Bento.text(dark)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 13, color: Bento.muted(dark)),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  p['supplier_location'] ?? 'All India',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Bento.muted(dark)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((p['supplier_description']?.toString().trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 10),
                  Text(
                    p['supplier_description'],
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: Bento.muted(dark)),
                  ),
                ],
              ],
            ),
          ),

          if (_relatedProducts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const BentoSectionHeader(title: 'Similar products'),
            const SizedBox(height: 10),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _relatedProducts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final rel = _relatedProducts[idx];
                  final relImages = rel['images'] as List?;
                  final relImage = (relImages != null && relImages.isNotEmpty) ? relImages[0] as String : '';
                  final relPrice = double.tryParse(rel['price_per_unit']?.toString() ?? '') ?? 0;
                  return BentoPressable(
                    onTap: () => context.pushReplacement('/b2b-product-detail/${rel['id']}'),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: Bento.surface(dark),
                        borderRadius: BorderRadius.circular(Bento.radiusSm + 2),
                        border: Border.all(color: Bento.border(dark)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 100,
                            width: double.infinity,
                            color: Bento.surfaceAlt(dark),
                            padding: const EdgeInsets.all(6),
                            child: BuildMartImage(imageUrl: relImage, fit: BoxFit.contain),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rel['name'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Bento.text(dark)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${formatRupees(relPrice)} / ${rel['unit_type'] ?? ''}',
                                  style: TextStyle(color: Bento.accentText(dark), fontWeight: FontWeight.w800, fontSize: 11.5),
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: Bento.surface(dark),
            border: Border(top: BorderSide(color: Bento.border(dark))),
          ),
          child: isProvider
              ? Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: Bento.muted(dark)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ordering materials is available on customer accounts.',
                        style: TextStyle(fontSize: 12.5, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    BentoPressable(
                      onTap: () => _openChat(p),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Bento.surfaceAlt(dark),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Bento.border(dark)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Bento.text(dark)),
                            const SizedBox(width: 6),
                            Text('Chat', style: TextStyle(fontWeight: FontWeight.w800, color: Bento.text(dark))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: BentoButton(
                          label: 'Get a quote',
                          icon: Icons.request_quote_rounded,
                          expand: true,
                          onTap: () => _openInquiry(p, price, unit),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, bool dark) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Bento.accentText(dark)),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Bento.text(dark))),
      ],
    );
  }
}
