import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import 'widgets/custom_image.dart';

class SupplierProfileScreen extends ConsumerStatefulWidget {
  const SupplierProfileScreen({super.key});

  @override
  ConsumerState<SupplierProfileScreen> createState() => _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends ConsumerState<SupplierProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _companyNameController;
  late final TextEditingController _businessTypeController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _gstController;
  late final TextEditingController _websiteController;

  bool _isLoading = true;
  bool _submitting = false;
  bool _isEditing = false;
  
  List<dynamic> _productsList = [];
  int _leadsCount = 0;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _businessTypeController = TextEditingController();
    _descController = TextEditingController();
    _locationController = TextEditingController();
    _gstController = TextEditingController();
    _websiteController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSupplierProfileData();
    });
  }

  Future<void> _loadSupplierProfileData() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) return;

    setState(() => _isLoading = true);

    try {
      final api = B2BApiService();
      
      // Fetch profile
      final profileRes = await api.get('/supplier/profile');
      if (profileRes.success && profileRes.data != null && profileRes.data['profile'] != null) {
        final p = profileRes.data['profile'];
        _companyNameController.text = p['company_name'] ?? auth.businessName ?? '';
        _businessTypeController.text = p['business_type'] ?? 'Manufacturer';
        _descController.text = p['description'] ?? 'Leading supplier of premium materials and building construction aggregates.';
        _locationController.text = p['location'] ?? 'All India';
        _gstController.text = p['gst_number'] ?? '';
        _websiteController.text = p['website'] ?? '';
        _logoUrl = p['logo_url'];
      } else {
        // Fallbacks
        _companyNameController.text = auth.businessName ?? 'UltraTech Build Solutions';
        _businessTypeController.text = 'Manufacturer';
        _descController.text = 'Leading manufacturer of structural cement, concrete aggregates, and premium building plaster solutions in India.';
        _locationController.text = 'Mumbai, Maharashtra';
        _gstController.text = '27AAAAA1111A1Z1';
        _websiteController.text = 'https://www.ultratechcement.com';
      }

      // Fetch products count
      final productsRes = await api.get('/supplier/products', queryParameters: {'supplierId': auth.id!});
      if (productsRes.success && productsRes.data != null) {
        _productsList = productsRes.data['products'] ?? [];
      }

      // Fetch leads count
      final leadsRes = await api.get('/supplier/leads', queryParameters: {'supplierId': auth.id!});
      if (leadsRes.success && leadsRes.data != null) {
        final leads = leadsRes.data['leads'] as List?;
        _leadsCount = leads?.length ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading supplier profile resources: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) return;

    setState(() => _submitting = true);
    try {
      final api = B2BApiService();
      final res = await api.put('/supplier/profile', data: {
        'supplierId': auth.id,
        'companyName': _companyNameController.text.trim(),
        'businessType': _businessTypeController.text.trim(),
        'description': _descController.text.trim(),
        'location': _locationController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'website': _websiteController.text.trim(),
      });

      if (mounted && res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
        _loadSupplierProfileData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['error'] ?? 'Failed to update profile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _gstController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Business Info' : 'B2B Supplier Profile'),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? _buildEditForm(isDark)
              : _buildInstagramProfile(primaryColor, isDark),
    );
  }

  Widget _buildInstagramProfile(Color primaryColor, bool isDark) {
    final name = _companyNameController.text;
    final businessType = _businessTypeController.text;
    final bio = _descController.text;
    final location = _locationController.text;
    final website = _websiteController.text;

    // Get HQ city (first word before comma)
    final hqCity = location.split(',').first.trim();

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Profile photo and metrics
                    Row(
                      children: [
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.orange, Colors.amber],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF121B22) : Colors.white,
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.blue.shade50,
                              backgroundImage: _logoUrl != null && _logoUrl!.isNotEmpty
                                  ? NetworkImage(_logoUrl!)
                                  : null,
                              child: _logoUrl == null || _logoUrl!.isEmpty
                                  ? Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Metrics
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetricItem('Products', '${_productsList.length}'),
                              _buildMetricItem('B2B Leads', '$_leadsCount'),
                              _buildMetricItem('HQ', hqCity),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Company Name & Verified Badge
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.2),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ),
                    // Business Type Tag
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        businessType,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Company Bio Description
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    if (website.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      // Website Link
                      GestureDetector(
                        onTap: () {
                          // Simple alert
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening website: $website')),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.link, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              website,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Row of Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push('/b2b-materials'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Leads Manager',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  indicatorColor: primaryColor,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: primaryColor,
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                    Tab(icon: Icon(Icons.info_outline_rounded, size: 22)),
                  ],
                ),
                isDark,
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            _buildProductsGrid(isDark),
            _buildInfoTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProductsGrid(bool isDark) {
    if (_productsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No Catalog Products Yet',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => context.push('/supplier-add-product').then((_) => _loadSupplierProfileData()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add B2B Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: _productsList.length,
      itemBuilder: (context, index) {
        final prod = _productsList[index];
        final imgs = prod['images'] as List?;
        final imgUrl = (imgs != null && imgs.isNotEmpty)
            ? imgs[0] as String
            : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=300';
            
        return InkWell(
          onTap: () => _showProductDetailsDialog(context, prod),
          child: BuildMartImage(
            imageUrl: imgUrl,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(bool isDark) {
    final gst = _gstController.text;
    final website = _websiteController.text;
    final location = _locationController.text;
    final businessType = _businessTypeController.text;
    final description = _descController.text;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Card(
          elevation: 0.5,
          color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Corporate Credentials',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.business_center_rounded, 'Business Category Type', businessType),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on_rounded, 'Headquarters Location', location),
                if (gst.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.verified_user_rounded, 'GST Identification Number', gst),
                ],
                if (website.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.language_rounded, 'Official Business Website', website),
                ],
                const SizedBox(height: 16),
                _buildInfoRow(Icons.info_rounded, 'Company Registered Description', description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProductDetailsDialog(BuildContext context, dynamic prod) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imgs = prod['images'] as List?;
    final imgUrl = (imgs != null && imgs.isNotEmpty)
        ? imgs[0] as String
        : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=600';
    
    final price = prod['price_per_unit'] ?? 0;
    final unit = prod['unit_type'] ?? 'Unit';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prod['name'] ?? 'Product Info',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 1.2,
                child: BuildMartImage(imageUrl: imgUrl, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate: ₹$price / $unit',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prod['description'] ?? 'No description provided.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 12.5,
                        height: 1.4,
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
  }

  Widget _buildEditForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Business Profile Registration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Registered Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessTypeController,
              decoration: const InputDecoration(
                labelText: 'Business Type',
                hintText: 'e.g. Manufacturer, Wholesaler, Exporter',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Company Overview Description',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Headquarters Location',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST Number (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Company Website (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _SliverAppBarDelegate(this.tabBar, this.isDark);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF121B22) : Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
