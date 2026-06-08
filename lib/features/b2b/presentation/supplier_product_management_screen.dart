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
  final _priceController = TextEditingController(text: '450');
  final _unitTypeController = TextEditingController(text: 'Bag');
  
  final _specKeyController = TextEditingController(text: 'Min Order Qty');
  final _specValueController = TextEditingController(text: '100 units');

  int _selectedCategory = 1;
  bool _submitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Materials & Supply'},
    {'id': 2, 'name': 'Electrical'},
    {'id': 3, 'name': 'Plumbing'},
    {'id': 4, 'name': 'Interior Design'},
    {'id': 5, 'name': 'Furniture'},
    {'id': 6, 'name': 'Paints'},
    {'id': 7, 'name': 'Hardware'},
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

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.editItem!;
      _nameController.text = item['name'] ?? '';
      _descController.text = item['description'] ?? '';
      _selectedCategory = item['categoryId'] ?? 1;
      _priceController.text = (item['price_per_unit'] ?? '450').toString();
      _unitTypeController.text = item['unit_type'] ?? 'Bag';
      
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

  @override
  void dispose() {
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
        'price_per_unit': double.tryParse(_priceController.text) ?? 450.0,
        'unit_type': _unitTypeController.text.trim(),
        'specifications': {
          _specKeyController.text.trim(): _specValueController.text.trim()
        },
        'images': [_imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=400']
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit B2B Listing' : 'Add B2B Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  hintText: 'e.g. OPC 53 Grade Cement',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _selectedCategory,
                items: _categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'],
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Marketplace Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per Unit (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || double.tryParse(value) == null ? 'Required numeric price' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Type (e.g. Bag, Ton)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Listing Description',
                  hintText: 'Provide detailed features, benefits, shipping packaging details...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Key Specification / Detail',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _specKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Spec Key (e.g. Grade)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _specValueController,
                      decoration: const InputDecoration(
                        labelText: 'Spec Value (e.g. 53 Grade)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Product Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'Enter custom image URL or select a preset below',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.blue),
                    tooltip: 'Pick image from gallery',
                    onPressed: _pickLocalImage,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 12),
              
              const Text(
                'Or choose a preset preview:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final isSelected = _imageUrlController.text == preset['url'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageUrlController.text = preset['url']!;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(preset['url']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              preset['label']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              if (_imageUrlController.text.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: BuildMartImage(
                            imageUrl: _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                              onPressed: () {
                                setState(() {
                                  _imageUrlController.clear();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitting ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditing ? 'Save Changes' : 'Publish Material', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
