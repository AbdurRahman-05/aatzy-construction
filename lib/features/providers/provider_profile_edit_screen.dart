import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../core/services/media_picker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';

class ProviderProfileEditScreen extends ConsumerStatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  ConsumerState<ProviderProfileEditScreen> createState() => _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends ConsumerState<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _businessTypeController;
  late TextEditingController _gstController;
  late TextEditingController _websiteController;
  final TextEditingController _categorySearchController = TextEditingController();

  String _categorySearchQuery = '';
  String? _aadharBase64;
  String? _panBase64;
  String? _profileImageBase64;
  List<dynamic> _portfolioImages = [];

  final List<String> _categories = const [
    'Land & Legal', 'Finance & Approvals', 'Survey & Analysis', 'Design & Planning',
    'Construction', 'Engineering (MEP)', 'Materials & Supply', 'Utilities',
    'Borewell', 'Interiors & Finishing', 'Project Management', 'Inspection & Compliance',
    'Smart & Security', 'Logistics & Equipment', 'Insurance',
    'Blacksmith', 'Bricklayer/Stonemason', 'Builder/General Contractor', 'Cabinet Maker',
    'Carpenter', 'Cement / Concrete', 'Commercial Builder', 'Construction (Other)',
    'Construction Project Management', 'Counter Top', 'Demolition Contractor', 'Drainage',
    'Drywall', 'Electrical Contractor', 'Electrician - Commercial', 'Elevator',
    'Energy Services', 'Environmental Services', 'Fences', 'Fireplace & Oven Builder',
    'Flooring', 'Garage Doors', 'Glass', 'Ground Work',
    'Handyman', 'Heating Engineer', 'HVAC - Heating & Air',
    'Interior Design - Commercial', 'Interior Design - Residential',
    'Kitchen Construction', 'LED Walls & Digital Displays', 'Metal Work', 'Painter', 'Pest Control',
    'Plasterer', 'Plumbing', 'Pools, Spas & Saunas', 'Power Generator',
    'Power Washing', 'Protective Coatings/Sealants', 'Renovations/Remodeling',
    'Restoration', 'Roofing & Gutters', 'Septic Systems', 'Shutters & Awnings',
    'Solar', 'Tile Worker', 'Waterproofing-Weatherproofing', 'Window Treatments',
    'Windows & Doors',
  ];
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _businessNameController = TextEditingController(text: auth.businessName);
    _ownerNameController = TextEditingController(text: auth.name);
    _phoneController = TextEditingController(text: '');
    _addressController = TextEditingController();
    _bioController = TextEditingController();
    _businessTypeController = TextEditingController();
    _gstController = TextEditingController();
    _websiteController = TextEditingController();

    _businessNameController.addListener(() => setState(() {}));
    _ownerNameController.addListener(() => setState(() {}));

    _fetchProfileData();
    _fetchPortfolio();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _businessTypeController.dispose();
    _gstController.dispose();
    _websiteController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  ImageProvider? _getProfileImage() {
    if (_profileImageBase64 == null || _profileImageBase64!.trim().isEmpty) {
      return null;
    }
    final str = _profileImageBase64!.trim();
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return NetworkImage(str);
    }
    try {
      final clean = str.contains(',') ? str.split(',').last : str;
      final bytes = base64Decode(clean);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Widget _buildPortfolioImage(dynamic imageData) {
    if (imageData == null) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
    final str = imageData.toString().trim();
    if (str.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return Image.network(
        str,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
        ),
      );
    }
    try {
      final bytes = Base64ImageCache.decode(str);
      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
          ),
        );
      }
    } catch (_) {}
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
    );
  }

  Future<void> _fetchProfileData() async {
    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = auth.id ?? prefs.getString('auth_id');
    if (effectiveId == null) return;
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/$effectiveId/profile'));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body)['provider'];
        final categoryStr = data['category'] as String? ?? '';
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _businessTypeController.text = data['businessType'] ?? '';
          _gstController.text = data['gstNumber'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _aadharBase64 = data['aadharCard'];
          _panBase64 = data['panCard'];
          _profileImageBase64 = data['profileImage'];
          _selectedCategories.clear();
          if (categoryStr.isNotEmpty) {
            _selectedCategories.addAll(categoryStr.split(',').map((c) => c.trim()));
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchPortfolio() async {
    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = auth.id ?? prefs.getString('auth_id');
    if (effectiveId == null) return;
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/$effectiveId/portfolio'));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _portfolioImages = jsonDecode(response.body)['images'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching portfolio: $e');
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await MediaPickerService.pickImage(
      source: ImageSource.gallery,
      context: context,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      if (mounted) {
        setState(() {
          _profileImageBase64 = 'data:image/jpeg;base64,$base64Image';
        });
      }
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await MediaPickerService.pickImage(
      source: ImageSource.gallery,
      context: context,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      if (!mounted) return;

      setState(() {
        if (type == 'aadhar') _aadharBase64 = dataUrl;
        if (type == 'pan') _panBase64 = dataUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.toUpperCase()} document selected!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addPortfolioImage() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? tempBase64;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Add Project Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tempBase64 != null)
                  Container(
                    height: 160,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(tempBase64!.split(',').last)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: () async {
                      final XFile? image = await MediaPickerService.pickImage(
                        source: ImageSource.gallery,
                        context: context,
                        maxWidth: 1000,
                        maxHeight: 1000,
                        imageQuality: 75,
                      );
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        final base64 = base64Encode(bytes);
                        setModalState(() {
                          tempBase64 = 'data:image/jpeg;base64,$base64';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF2563EB)),
                          SizedBox(height: 6),
                          Text('Select Project Photo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          SizedBox(height: 2),
                          Text('PNG, JPG up to 10MB', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Project Title *',
                    hintText: 'e.g. 500 Bags Cement Supply to Site A',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'e.g. Completed on schedule with test certificate',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (tempBase64 == null || titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an image and enter a title')),
                  );
                  return;
                }
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                final auth = ref.read(authProvider);
                final prefs = await SharedPreferences.getInstance();
                final effectiveId = auth.id ?? prefs.getString('auth_id');
                if (effectiveId == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Session expired. Please log in again.')),
                    );
                    setState(() => _isLoading = false);
                  }
                  return;
                }
                try {
                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/providers/$effectiveId/portfolio'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'imageData': tempBase64,
                    }),
                  );
                  if (response.statusCode == 201) {
                    try {
                      final newItem = jsonDecode(response.body);
                      setState(() {
                        _portfolioImages.insert(0, newItem);
                      });
                    } catch (_) {}
                    _fetchPortfolio();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo added to portfolio!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  } else {
                    debugPrint('Add portfolio failed: ${response.statusCode}');
                  }
                } catch (e) {
                  debugPrint('Add portfolio error: $e');
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add to Portfolio'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePortfolioImage(String imageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to remove this project photo from your public portfolio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final auth = ref.read(authProvider);
      final prefs = await SharedPreferences.getInstance();
      final effectiveId = auth.id ?? prefs.getString('auth_id');
      if (effectiveId == null) {
        setState(() => _isLoading = false);
        return;
      }
      try {
        final response = await http.delete(Uri.parse('$apiBaseUrl/providers/$effectiveId/portfolio?imageId=$imageId'));
        if (response.statusCode == 200) {
          setState(() {
            _portfolioImages.removeWhere((item) => item['id'] == imageId);
          });
          _fetchPortfolio();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo removed.'), behavior: SnackBarBehavior.floating),
            );
          }
        }
      } catch (e) {
        debugPrint('Delete portfolio error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted errors before saving'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final effectiveId = auth.id ?? prefs.getString('auth_id');
    if (effectiveId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/providers/$effectiveId/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessName': _businessNameController.text.trim(),
          'ownerName': _ownerNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'bio': _bioController.text.trim(),
          'category': _selectedCategories.isNotEmpty ? _selectedCategories.join(', ') : 'General',
          'aadharCard': _aadharBase64,
          'panCard': _panBase64,
          'profileImage': _profileImageBase64,
          'profileCompletion': 100,
          'businessType': _businessTypeController.text.trim(),
          'gstNumber': _gstController.text.trim(),
          'website': _websiteController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Update error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedCategories = _categories.where((c) {
      if (_categorySearchQuery.trim().isEmpty) return true;
      return c.toLowerCase().contains(_categorySearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF2563EB)),
              label: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Profile Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. HEADER PROFILE CARD
                      _buildHeaderCard(),
                      const SizedBox(height: 18),

                      // 2. BUSINESS INFORMATION
                      _buildCardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.storefront_rounded,
                              title: 'Business Information',
                              subtitle: 'Primary identity visible to buyers & clients',
                              color: const Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 18),
                            _buildTextField(
                              controller: _businessNameController,
                              label: 'Business Name',
                              hint: 'e.g. MPS Traders',
                              prefixIcon: Icons.business_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _ownerNameController,
                              label: 'Owner / Contact Person',
                              hint: 'e.g. Mohamed Ismail',
                              prefixIcon: Icons.person_rounded,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Owner name is required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'e.g. 9876543210',
                              prefixIcon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _addressController,
                              label: 'Office Address',
                              hint: 'e.g. 12/B Commercial Complex, Madurai, Tamil Nadu',
                              prefixIcon: Icons.location_on_rounded,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _bioController,
                              label: 'Business Bio / Description',
                              hint: 'Describe your expertise, supply capabilities, years in business, etc...',
                              prefixIcon: Icons.description_rounded,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. COMMERCIAL & TAX DETAILS
                      _buildCardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.receipt_long_rounded,
                              title: 'Commercial & Tax Details',
                              subtitle: 'Business classification and registrations',
                              color: const Color(0xFF7C3AED),
                            ),
                            const SizedBox(height: 18),
                            _buildTextField(
                              controller: _businessTypeController,
                              label: 'Business Type',
                              hint: 'e.g. Manufacturer, Wholesaler, Contractor, Trader',
                              prefixIcon: Icons.category_rounded,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _gstController,
                              label: 'GST Number (Optional)',
                              hint: 'e.g. 33AAAAA0000A1Z5',
                              prefixIcon: Icons.verified_user_rounded,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _websiteController,
                              label: 'Company Website (Optional)',
                              hint: 'e.g. https://www.mpstraders.com',
                              prefixIcon: Icons.language_rounded,
                              keyboardType: TextInputType.url,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. SERVICES & CATEGORIES
                      _buildCardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildSectionHeader(
                                    icon: Icons.grid_view_rounded,
                                    title: 'Services & Trades',
                                    subtitle: 'Select categories you specialize in',
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    '${_selectedCategories.length} Selected',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Search filter box
                            TextField(
                              controller: _categorySearchController,
                              onChanged: (val) => setState(() => _categorySearchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search trades & services...',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                                suffixIcon: _categorySearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _categorySearchController.clear();
                                          setState(() => _categorySearchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 240),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: displayedCategories.map((c) {
                                    final isSelected = _selectedCategories.contains(c);
                                    return FilterChip(
                                      label: Text(
                                        c,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                        ),
                                      ),
                                      selected: isSelected,
                                      selectedColor: const Color(0xFFEFF6FF),
                                      checkmarkColor: const Color(0xFF1D4ED8),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedCategories.add(c);
                                          } else {
                                            _selectedCategories.remove(c);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. PROJECT PORTFOLIO
                      _buildCardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildSectionHeader(
                                    icon: Icons.photo_library_rounded,
                                    title: 'Project Portfolio',
                                    subtitle: 'Showcase photos to attract clients',
                                    color: const Color(0xFFE11D48),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _addPortfolioImage,
                                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18, color: Color(0xFF2563EB)),
                                  label: const Text(
                                    'Add Photo',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (_portfolioImages.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No project photos added yet',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Upload pictures of supplies or work sites to build trust.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _portfolioImages.length,
                                itemBuilder: (context, index) {
                                  final img = _portfolioImages[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: _buildPortfolioImage(img['imageData']),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.black87, Colors.transparent],
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                              ),
                                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                                            ),
                                            child: Text(
                                              img['title'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: InkWell(
                                            onTap: () => _deletePortfolioImage(img['id']),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 6. KYC DOCUMENTS
                      _buildCardSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              icon: Icons.verified_user_rounded,
                              title: 'KYC Verification Documents',
                              subtitle: 'Attach documents to unlock verified badges',
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(height: 16),
                            _buildDocUploadTile(
                              title: 'Aadhar Card',
                              subtitle: 'Proof of government identity',
                              url: _aadharBase64,
                              onUpload: () => _pickImage('aadhar'),
                            ),
                            const SizedBox(height: 12),
                            _buildDocUploadTile(
                              title: 'PAN Card',
                              subtitle: 'Proof of tax & business entity',
                              url: _panBase64,
                              onUpload: () => _pickImage('pan'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ==========================================
  // COMPONENT BUILDERS
  // ==========================================

  Widget _buildHeaderCard() {
    final businessName = _businessNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF334155),
                    backgroundImage: _getProfileImage(),
                    child: _profileImageBase64 == null
                        ? Text(
                            businessName.isNotEmpty ? businessName[0].toUpperCase() : 'B',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: const Color(0xFF2563EB),
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: _pickProfileImage,
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            businessName.isNotEmpty ? businessName : 'Your Business Name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            ownerName.isNotEmpty ? 'Owner: $ownerName' : 'Supplier Profile',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickProfileImage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Change Profile Logo / Photo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            prefixIcon: Icon(prefixIcon, size: 19, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocUploadTile({
    required String title,
    required String subtitle,
    required String? url,
    required VoidCallback onUpload,
  }) {
    final hasDoc = url != null && url.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasDoc ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoc ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasDoc ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasDoc ? Icons.check_circle_rounded : Icons.file_upload_outlined,
              size: 20,
              color: hasDoc ? const Color(0xFF16A34A) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDoc ? 'Document Uploaded & Attached' : subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasDoc ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    fontWeight: hasDoc ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onUpload,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: BorderSide(
                color: hasDoc ? const Color(0xFF22C55E) : const Color(0xFF2563EB),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.white,
            ),
            child: Text(
              hasDoc ? 'Replace' : 'Upload',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasDoc ? const Color(0xFF15803D) : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
