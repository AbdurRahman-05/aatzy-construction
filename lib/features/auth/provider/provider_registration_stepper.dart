import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants.dart';

class ProviderRegistrationStepper extends StatefulWidget {
  const ProviderRegistrationStepper({super.key});

  @override
  State<ProviderRegistrationStepper> createState() => _ProviderRegistrationStepperState();
}

class _ProviderRegistrationStepperState extends State<ProviderRegistrationStepper> {
  int _currentStep = 0;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  
  // Controllers
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  // Image Data (Base64)
  String? _aadharBase64;
  String? _panBase64;
  String? _portfolioBase64;

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Reduced size for Base64 efficiency
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64Image';

        setState(() {
          if (type == 'aadhar') _aadharBase64 = dataUrl;
          if (type == 'pan') _panBase64 = dataUrl;
          if (type == 'portfolio') _portfolioBase64 = dataUrl;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${type.toUpperCase()} document selected!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  final List<String> _categories = [
    'Land & Legal', 'Finance & Approvals', 'Survey & Analysis', 'Design & Planning',
    'Construction', 'Engineering (MEP)', 'Materials & Supply', 'Utilities',
    'Interiors & Finishing', 'Project Management', 'Inspection & Compliance',
    'Smart & Security', 'Logistics & Equipment', 'Insurance'
  ];
  final Set<String> _selectedCategories = {};

  Future<void> _submitRegistration() async {
    // Client-side validation
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final businessName = _businessNameController.text.trim();

    if (email.isEmpty || password.isEmpty || businessName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Email, Password, and Business Name before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final payload = {
        'ownerName': _ownerNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': email,
        'password': password,
        'businessName': businessName,
        'experience': _experienceController.text.trim(),
        'category': _selectedCategories.isNotEmpty ? _selectedCategories.join(', ') : 'General',
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'aadharCard': _aadharBase64,
        'panCard': _panBase64,
        'profileCompletion': ((_currentStep + 1) / 6 * 100).toInt(),
      };

      debugPrint('Submitting registration for: $email');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/providers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        context.go('/provider-verification-pending', extra: {
          'email': email,
          'password': password,
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Failed to reach server.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentStep + 1) / 6;
    int percentage = (progress * 100).toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Registration')),
      body: _isLoading 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Creating your profile...'),
            ],
          ))
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profile Completion', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        Text('$percentage%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.blue.shade50,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 5) {
                      setState(() => _currentStep += 1);
                    } else {
                      _submitRegistration();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    } else {
                      context.pop();
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(_currentStep == 5 ? 'FINISH' : 'CONTINUE'),
                          ),
                          const SizedBox(width: 12),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('BACK'),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Basic Details'),
                      content: Column(
                        children: [
                          TextFormField(controller: _ownerNameController, decoration: const InputDecoration(labelText: 'Full Name')),
                          const SizedBox(height: 8),
                          TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
                          const SizedBox(height: 8),
                          TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                          const SizedBox(height: 8),
                          TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                        ],
                      ),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: const Text('OTP Verification'),
                      content: Column(
                        children: [
                          const Text('Enter OTP sent to your phone number'),
                          const SizedBox(height: 8),
                          TextFormField(decoration: const InputDecoration(labelText: 'OTP', hintText: '123456')),
                        ],
                      ),
                      isActive: _currentStep >= 1,
                    ),
                    Step(
                      title: const Text('Service Category Selection'),
                      content: Wrap(
                        spacing: 8,
                        children: _categories.map((c) {
                          final isSelected = _selectedCategories.contains(c);
                          return FilterChip(
                            label: Text(c),
                            selected: isSelected,
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
                      isActive: _currentStep >= 2,
                    ),
                    Step(
                      title: const Text('Business Details'),
                      content: Column(
                        children: [
                          TextFormField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business Name')),
                          const SizedBox(height: 8),
                          TextFormField(controller: _experienceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Years of Experience')),
                          const SizedBox(height: 8),
                          TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: 'Office Address')),
                          const SizedBox(height: 8),
                          TextFormField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Business Bio / Description')),
                        ],
                      ),
                      isActive: _currentStep >= 3,
                    ),
                    Step(
                      title: const Text('Document Upload'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _pickImage('aadhar'), 
                            icon: Icon(_aadharBase64 != null ? Icons.check_circle : Icons.upload_file, color: _aadharBase64 != null ? Colors.green : null), 
                            label: Text(_aadharBase64 != null ? 'Aadhar Uploaded' : 'Upload Aadhar Card')
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage('pan'), 
                            icon: Icon(_panBase64 != null ? Icons.check_circle : Icons.upload_file, color: _panBase64 != null ? Colors.green : null), 
                            label: Text(_panBase64 != null ? 'PAN Card Uploaded' : 'Upload PAN Card')
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _pickImage('portfolio'), 
                            icon: Icon(_portfolioBase64 != null ? Icons.check_circle : Icons.image, color: _portfolioBase64 != null ? Colors.green : null), 
                            label: Text(_portfolioBase64 != null ? 'Portfolio Uploaded' : 'Upload Portfolio Images')
                          ),
                        ],
                      ),
                      isActive: _currentStep >= 4,
                    ),
                    Step(
                      title: const Text('Profile Completion'),
                      content: Column(
                        children: [
                          TextFormField(decoration: const InputDecoration(labelText: 'Add specific services (comma separated)')),
                          const SizedBox(height: 8),
                          TextFormField(decoration: const InputDecoration(labelText: 'Approximate Pricing / Hourly Rate')),
                        ],
                      ),
                      isActive: _currentStep >= 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
