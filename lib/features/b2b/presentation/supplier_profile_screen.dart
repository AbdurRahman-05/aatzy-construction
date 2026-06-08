import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';

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

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _companyNameController = TextEditingController(text: auth.businessName ?? 'UltraTech Build Solutions');
    _businessTypeController = TextEditingController(text: 'Manufacturer');
    _descController = TextEditingController(text: 'Leading manufacturer of structural cement, concrete aggregates, and premium building plaster solutions in India.');
    _locationController = TextEditingController(text: 'Mumbai, Maharashtra');
    _gstController = TextEditingController(text: '27AAAAA1111A1Z1');
    _websiteController = TextEditingController(text: 'https://www.ultratechcement.com');
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update profile')),
      );
      return;
    }

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
        context.pop();
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Company Business Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Business Credentials',
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
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _submitting ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
