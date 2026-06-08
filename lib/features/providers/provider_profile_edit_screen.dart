import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  late TextEditingController _businessTypeController;
  late TextEditingController _gstController;
  late TextEditingController _websiteController;
  
  String? _aadharBase64;
  String? _panBase64;
  String? _profileImageBase64;
  List<dynamic> _portfolioImages = [];

  final List<String> _categories = const [
    'Land & Legal', 'Finance & Approvals', 'Survey & Analysis', 'Design & Planning',
    'Construction', 'Engineering (MEP)', 'Materials & Supply', 'Utilities',
    'Interiors & Finishing', 'Project Management', 'Inspection & Compliance',
    'Smart & Security', 'Logistics & Equipment', 'Insurance'
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
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    final auth = ref.read(authProvider);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/profile'));
      if (response.statusCode == 200) {
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
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/portfolio'));
      if (response.statusCode == 200) {
        setState(() {
          _portfolioImages = jsonDecode(response.body)['images'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching portfolio: $e');
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${type.toUpperCase()} document selected!')));
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
          title: const Text('Add Project Photo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tempBase64 != null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(tempBase64!.split(',').last)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
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
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Select Photo'),
                  ),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Project Title')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description (Optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (tempBase64 == null || titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image and title')));
                  return;
                }
                Navigator.pop(ctx);
                
                setState(() => _isLoading = true);
                final auth = ref.read(authProvider);
                try {
                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/providers/${auth.id}/portfolio'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'imageData': tempBase64,
                    }),
                  );
                  if (response.statusCode == 201) {
                    _fetchPortfolio();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo added to portfolio!')));
                    }
                  }
                } catch (e) {
                  debugPrint('Add portfolio error: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('ADD PHOTO'),
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
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to remove this project photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final auth = ref.read(authProvider);
      try {
        final response = await http.delete(Uri.parse('$apiBaseUrl/providers/${auth.id}/portfolio?imageId=$imageId'));
        if (response.statusCode == 200) {
          _fetchPortfolio();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo removed.')));
          }
        }
      } catch (e) {
        debugPrint('Delete portfolio error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = ref.read(authProvider);

    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/providers/${auth.id}/profile'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Business Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _profileImageBase64 != null
                              ? MemoryImage(base64Decode(_profileImageBase64!.split(',').last))
                              : null,
                          child: _profileImageBase64 == null
                              ? const Icon(Icons.business, size: 50, color: Colors.blue)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () async {
                              final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 600,
                                maxHeight: 600,
                                imageQuality: 70,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                final base64Image = base64Encode(bytes);
                                setState(() {
                                  _profileImageBase64 = 'data:image/jpeg;base64,$base64Image';
                                });
                              }
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue.shade700,
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Office Address', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'Business Bio / Description', border: OutlineInputBorder()),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Business Type',
                      hintText: 'e.g. Manufacturer, Wholesaler, Exporter, Service Provider',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gstController,
                    decoration: const InputDecoration(
                      labelText: 'GST Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Company Website (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Services Offered', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((c) {
                        final isSelected = _selectedCategories.contains(c);
                        return FilterChip(
                          label: Text(c, style: TextStyle(fontSize: 12, color: isSelected ? Colors.blue.shade900 : Colors.black87)),
                          selected: isSelected,
                          selectedColor: Colors.blue.shade50,
                          checkmarkColor: Colors.blue.shade800,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300),
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
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Project Portfolio', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _addPortfolioImage,
                        icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                        tooltip: 'Add Project Photo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_portfolioImages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No project photos added yet.', style: TextStyle(color: Colors.grey))),
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
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: MemoryImage(base64Decode(img['imageData'].split(',').last)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                ),
                                child: Text(
                                  img['title'],
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  onPressed: () => _deletePortfolioImage(img['id']),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  Text('KYC Documents', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  _buildDocUploadTile(
                    title: 'Aadhar Card',
                    url: _aadharBase64,
                    onUpload: () => _pickImage('aadhar'),
                  ),
                  const SizedBox(height: 12),
                  _buildDocUploadTile(
                    title: 'PAN Card',
                    url: _panBase64,
                    onUpload: () => _pickImage('pan'),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDocUploadTile({required String title, String? url, required VoidCallback onUpload}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(url != null ? Icons.check_circle : Icons.description, color: url != null ? Colors.green : Colors.grey),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          TextButton.icon(
            onPressed: onUpload,
            icon: Icon(url != null ? Icons.edit : Icons.upload),
            label: Text(url != null ? 'Change' : 'Upload'),
          ),
        ],
      ),
    );
  }
}
