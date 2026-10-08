import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import 'widgets/custom_image.dart';

class SupplierProductManagementScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? editItem;
  const SupplierProductManagementScreen({super.key, this.editItem});

  @override
  ConsumerState<SupplierProductManagementScreen> createState() => _SupplierProductManagementScreenState();
}

class _SupplierProductManagementScreenState extends ConsumerState<SupplierProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitTypeController = TextEditingController();

  final _specKeyController = TextEditingController();
  final _specValueController = TextEditingController();

  int _selectedCategory = 1;
  bool _submitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Materials & Supply', 'icon': Icons.foundation_rounded},
    {'id': 2, 'name': 'Electrical', 'icon': Icons.bolt_rounded},
    {'id': 3, 'name': 'Plumbing', 'icon': Icons.water_drop_rounded},
    {'id': 4, 'name': 'Interior Design', 'icon': Icons.format_paint_rounded},
    {'id': 5, 'name': 'Furniture', 'icon': Icons.chair_rounded},
    {'id': 6, 'name': 'Paints', 'icon': Icons.color_lens_rounded},
    {'id': 7, 'name': 'Hardware', 'icon': Icons.hardware_rounded},
  ];

  final List<Map<String, String>> _presets = [
    {
      'label': 'Cement Bag',
      'url': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Steel Rebar',
      'url': 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Bricks',
      'url': 'https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Pipes',
      'url': 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecc?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Wires',
      'url': 'https://images.unsplash.com/photo-1558346490-a72e53ae2d4f?auto=format&fit=crop&q=80&w=400'
    },
    {
      'label': 'Interior/Timber',
      'url': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&q=80&w=400'
    },
  ];

  final List<String> _quickUnits = [
    'Bag',
    'Ton',
    'Piece',
    'Sq.ft',
    'Kg',
    'Bundle',
    'Truckload',
    'Meter',
    'Box',
  ];

  final List<Map<String, String>> _quickSpecs = [
    {'key': 'Grade', 'value': '53 Grade'},
    {'key': 'Packaging', 'value': '50kg Bag'},
    {'key': 'Min Order', 'value': '50 Units'},
    {'key': 'Standard', 'value': 'IS 12269'},
    {'key': 'Delivery', 'value': '2-3 Days'},
  ];

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_rebuildPreview);
    _priceController.addListener(_rebuildPreview);
    _unitTypeController.addListener(_rebuildPreview);
    _specKeyController.addListener(_rebuildPreview);
    _specValueController.addListener(_rebuildPreview);
    _imageUrlController.addListener(_rebuildPreview);

    if (_isEditing) {
      final item = widget.editItem!;
      _nameController.text = item['name'] ?? '';
      _descController.text = item['description'] ?? '';
      _selectedCategory = item['categoryId'] ?? 1;
      _priceController.text = (item['price_per_unit'] ?? '').toString();
      _unitTypeController.text = item['unit_type'] ?? '';

      final listImgs = item['images'];
      if (listImgs is List && listImgs.isNotEmpty) {
        _imageUrlController.text = listImgs.first.toString();
      }

      final specs = item['specifications'];
      if (specs is Map && specs.isNotEmpty) {
        _specKeyController.text = specs.keys.first.toString();
        _specValueController.text = specs.values.first.toString();
      }
    }
  }

  void _rebuildPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_rebuildPreview);
    _priceController.removeListener(_rebuildPreview);
    _unitTypeController.removeListener(_rebuildPreview);
    _specKeyController.removeListener(_rebuildPreview);
    _specValueController.removeListener(_rebuildPreview);
    _imageUrlController.removeListener(_rebuildPreview);

    _nameController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _unitTypeController.dispose();
    _specKeyController.dispose();
    _specValueController.dispose();
    super.dispose();
  }

  Future<void> _pickLocalImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64String';
        setState(() {
          _imageUrlController.text = dataUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add products')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = B2BApiService();

      final String path;
      if (_isEditing) {
        path = '/supplier/products/${widget.editItem!['id']}';
      } else {
        path = '/supplier/products';
      }

      final payload = {
        'supplierId': auth.id,
        'categoryId': _selectedCategory,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price_per_unit': double.tryParse(_priceController.text) ?? 0.0,
        'unit_type': _unitTypeController.text.trim().isNotEmpty ? _unitTypeController.text.trim() : 'Unit',
        'specifications': _specKeyController.text.trim().isNotEmpty
            ? {_specKeyController.text.trim(): _specValueController.text.trim()}
            : {},
        'images': [
          _imageUrlController.text.trim().isNotEmpty
              ? _imageUrlController.text.trim()
              : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400'
        ]
      };

      final B2BApiResponse res;
      if (_isEditing) {
        res = await api.put(path, data: payload);
      } else {
        res = await api.post(path, data: payload);
      }

      if (res.success) {
        if (mounted) _showSuccessDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['error'] ?? 'Failed to submit listing')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(_isEditing ? Icons.check_circle_outline_rounded : Icons.check_circle_rounded,
                  color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(_isEditing ? 'Listing Updated' : 'Listing Created'),
            ],
          ),
          content: Text(
            _isEditing
                ? 'Your B2B material listing has been updated successfully.'
                : 'Your B2B material listing has been published to the buyer catalog successfully.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.pop(); // Return to dashboard
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryName(int id) {
    final cat = _categories.firstWhere((c) => c['id'] == id, orElse: () => {'name': 'General Materials'});
    return cat['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Material Listing' : 'Add Material Listing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
            ),
            Text(
              'B2B Supplier Marketplace',
              style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEditing ? Icons.edit_note_rounded : Icons.storefront_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEditing ? 'Editing' : 'Catalog Studio',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTabletOrWide = constraints.maxWidth >= 768;
          final contentPadding = isTabletOrWide ? 24.0 : 16.0;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tablet Welcome & Workflow Banner
                      if (isTabletOrWide)
                        _buildTabletHeaderBanner(context, isDark, primaryColor),

                      if (isTabletOrWide)
                        // Tablet 2-Column Split View
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN: Forms, Pricing, Specs (Flex 3)
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildBasicInfoCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                                  const SizedBox(height: 20),
                                  _buildPricingCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                                  const SizedBox(height: 20),
                                  _buildSpecsCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // RIGHT COLUMN: Media & Live Buyer Preview & Sticky CTA (Flex 2)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildMediaCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                                  const SizedBox(height: 20),
                                  _buildLivePreviewCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                                  const SizedBox(height: 20),
                                  _buildActionCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        // MOBILE: Single Column Flow
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBasicInfoCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                            const SizedBox(height: 16),
                            _buildPricingCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                            const SizedBox(height: 16),
                            _buildSpecsCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                            const SizedBox(height: 16),
                            _buildMediaCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                            const SizedBox(height: 16),
                            _buildLivePreviewCard(context, cardBg, cardBorder, textDark, textMuted, primaryColor),
                            const SizedBox(height: 24),
                            _buildSubmitButton(primaryColor),
                            const SizedBox(height: 16),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TABLET HEADER BANNER
  // ==========================================
  Widget _buildTabletHeaderBanner(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.dashboard_customize_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isEditing ? 'Editing Material Listing' : 'Supplier Product Studio',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Tablet Optimized',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage product details, pricing, and specifications on the left while previewing how buyers see your listing in real-time on the right.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. BASIC INFORMATION CARD
  // ==========================================
  Widget _buildBasicInfoCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textDark,
    Color textMuted,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Basic Product Details',
            subtitle: 'Name, marketplace category, and summary',
            color: primaryColor,
          ),
          const SizedBox(height: 18),

          // Product Title
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Product Title',
              hintText: 'e.g. UltraTech Super Cement 53 Grade',
              prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Product title is required' : null,
          ),
          const SizedBox(height: 16),

          // Marketplace Category
          DropdownButtonFormField<int>(
            initialValue: _selectedCategory,
            items: _categories.map((cat) {
              return DropdownMenuItem<int>(
                value: cat['id'] as int,
                child: Row(
                  children: [
                    Icon(cat['icon'] as IconData, size: 18, color: primaryColor),
                    const SizedBox(width: 10),
                    Text(cat['name'] as String),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
            decoration: InputDecoration(
              labelText: 'Marketplace Category',
              prefixIcon: const Icon(Icons.category_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),

          // Listing Description
          TextFormField(
            controller: _descController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Product Description',
              hintText: 'Describe composition, technical features, warranty, and delivery package details...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Icon(Icons.description_outlined, size: 20),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Please provide a description' : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. PRICING & MEASUREMENT CARD
  // ==========================================
  Widget _buildPricingCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textDark,
    Color textMuted,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.currency_rupee_rounded,
            title: 'Pricing & Unit of Measure',
            subtitle: 'Base wholesale or retail rates per unit',
            color: Colors.teal,
          ),
          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price per Unit
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price per Unit (₹)',
                    hintText: '420',
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: textDark),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter price';
                    if (double.tryParse(value.trim()) == null) return 'Must be numeric';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Unit Type
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _unitTypeController,
                  decoration: InputDecoration(
                    labelText: 'Unit Type',
                    hintText: 'e.g. Bag',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Unit Selection Chips
          Text(
            'Quick Unit Suggestions:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _quickUnits.map((u) {
              final isSelected = _unitTypeController.text.trim().toLowerCase() == u.toLowerCase();
              return ActionChip(
                label: Text(u),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : textDark,
                ),
                backgroundColor: isSelected ? primaryColor : Theme.of(context).cardColor,
                side: BorderSide(
                  color: isSelected ? primaryColor : cardBorder,
                ),
                onPressed: () {
                  setState(() {
                    _unitTypeController.text = u;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. SPECIFICATIONS CARD
  // ==========================================
  Widget _buildSpecsCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textDark,
    Color textMuted,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.tune_rounded,
            title: 'Technical Specifications',
            subtitle: 'Key technical attributes buyers compare (e.g. Grade, MOQ, Standard)',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _specKeyController,
                  decoration: InputDecoration(
                    labelText: 'Spec Property / Key',
                    hintText: 'e.g. Grade or Packaging',
                    prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _specValueController,
                  decoration: InputDecoration(
                    labelText: 'Spec Value',
                    hintText: 'e.g. 53 Grade OPC',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick Preset Specs
          Text(
            'Common Spec Presets:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _quickSpecs.map((spec) {
              return ActionChip(
                label: Text('${spec['key']}: ${spec['value']}'),
                labelStyle: TextStyle(fontSize: 11, color: textDark),
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(color: cardBorder),
                onPressed: () {
                  setState(() {
                    _specKeyController.text = spec['key']!;
                    _specValueController.text = spec['value']!;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. MEDIA & PRESETS CARD
  // ==========================================
  Widget _buildMediaCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textDark,
    Color textMuted,
    Color primaryColor,
  ) {
    final currentImage = _imageUrlController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.image_outlined,
            title: 'Product Imagery',
            subtitle: 'Upload photo or choose a standard material preset',
            color: Colors.indigo,
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'Image URL or Uploaded Path',
              hintText: 'https://... or select below',
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
              suffixIcon: IconButton(
                icon: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                tooltip: 'Pick from device gallery',
                onPressed: _pickLocalImage,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Upload button bar
          OutlinedButton.icon(
            onPressed: _pickLocalImage,
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: const Text('Pick Photo from Device Gallery'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Quick Material Photo Presets:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted),
          ),
          const SizedBox(height: 8),

          // Presets Grid / Scroll
          SizedBox(
            height: 74,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = currentImage == preset['url'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _imageUrlController.text = preset['url']!;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? primaryColor : cardBorder,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 6)]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            preset['url']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 16)),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: Colors.black.withValues(alpha: 0.65),
                              padding: const EdgeInsets.symmetric(vertical: 2.5),
                              child: Text(
                                preset['label']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 3,
                              right: 3,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 10, color: Colors.white),
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
        ],
      ),
    );
  }

  // ==========================================
  // 5. LIVE BUYER CATALOG PREVIEW CARD
  // ==========================================
  Widget _buildLivePreviewCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textDark,
    Color textMuted,
    Color primaryColor,
  ) {
    final title = _nameController.text.trim().isEmpty ? 'Product Title Here' : _nameController.text.trim();
    final priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final unit = _unitTypeController.text.trim().isEmpty ? 'Unit' : _unitTypeController.text.trim();
    final categoryName = _getCategoryName(_selectedCategory);
    final imageUrl = _imageUrlController.text.trim().isNotEmpty
        ? _imageUrlController.text.trim()
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.visibility_rounded, color: Colors.purple, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Buyer Catalog Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'REALTIME',
                  style: TextStyle(color: Colors.green, fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // The Preview Item Widget (Simulates Buyer View)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image with Category Pill
                Stack(
                  children: [
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: BuildMartImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 3),
                            Text(
                              'Verified Partner',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Content Details
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price & Unit
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹${priceVal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            ' / $unit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),

                      if (_specKeyController.text.trim().isNotEmpty &&
                          _specValueController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_specKeyController.text.trim()}: ${_specValueController.text.trim()}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. ACTION & PUBLICATION CARD (TABLET)
  // ==========================================
  Widget _buildActionCard(
    BuildContext context,
    Color cardBg,
    Color cardBorder,
    Color textDark,
    Color textMuted,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubmitButton(primaryColor),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel & Return'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Material listings are immediately visible across Connectzy B2B builder catalog.',
                  style: TextStyle(fontSize: 10.5, color: textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SUBMIT BUTTON WIDGET
  // ==========================================
  Widget _buildSubmitButton(Color primaryColor) {
    return ElevatedButton(
      onPressed: _submitting ? null : _submitListing,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: _submitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isEditing ? Icons.save_rounded : Icons.publish_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Save Changes' : 'Publish Listing',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // SECTION HEADER HELPER
  // ==========================================
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
