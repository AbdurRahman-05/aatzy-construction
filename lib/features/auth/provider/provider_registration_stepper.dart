import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';

class ProviderRegistrationStepper extends ConsumerStatefulWidget {
  final bool isGoogleSignUp;
  final String? email;
  final String? ownerName;

  const ProviderRegistrationStepper({
    super.key,
    this.isGoogleSignUp = false,
    this.email,
    this.ownerName,
  });

  @override
  ConsumerState<ProviderRegistrationStepper> createState() => _ProviderRegistrationStepperState();
}

class _ProviderRegistrationStepperState extends ConsumerState<ProviderRegistrationStepper> {
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
  final _gstController = TextEditingController();
  final _servicesController = TextEditingController();
  final _pricingController = TextEditingController();
  final _otpController = TextEditingController();

  String _verificationId = '';

  // Image Data (Base64)
  String? _aadharBase64;
  String? _panBase64;
  String? _portfolioBase64;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogleSignUp) {
      _emailController.text = widget.email ?? '';
      _ownerNameController.text = widget.ownerName ?? '';
      _passwordController.text = 'google_oauth_placeholder_${DateTime.now().millisecondsSinceEpoch}';
      _currentStep = 2;
    }
  }

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
            SnackBar(
              content: Text('${type.toUpperCase()} document selected!'), 
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'), 
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
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

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
        setState(() {
          _verificationId = data['verificationId'] ?? '';
          _currentStep = 1;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully to your phone!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to send OTP')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to trigger OTP.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpStep() async {
    final phone = _phoneController.text.trim();
    final otpCode = _otpController.text.trim();

    if (otpCode.isEmpty || _verificationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'verificationId': _verificationId,
          'code': otpCode,
        }),
      );

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 2; // Proceed to step 2
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified successfully!'), backgroundColor: Colors.green),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Invalid OTP code')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification service error.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRegistration() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final businessName = _businessNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || businessName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Email, Password, Phone, and Business Name before submitting.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final payload = {
        'ownerName': _ownerNameController.text.trim(),
        'phone': phone,
        'email': email,
        'password': password,
        'businessName': businessName,
        'experience': _experienceController.text.trim(),
        'category': _selectedCategories.isNotEmpty ? _selectedCategories.join(', ') : 'General',
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'aadharCard': _aadharBase64,
        'panCard': _panBase64,
        'profileCompletion': ((_currentStep + 1) / 6 * 100).toInt(),
        'verificationId': _verificationId,
        'otpCode': _otpController.text.trim(),
        'isGoogleSignUp': widget.isGoogleSignUp,
      };

      debugPrint('Submitting registration for: $email');

      final response = await http.post(
        Uri.parse('$apiBaseUrl/providers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final data = _parseResponse(response);

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
            behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
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
    _gstController.dispose();
    _servicesController.dispose();
    _pricingController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF064354), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF064354), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final titles = [
      'Basic Details',
      'Phone Verification',
      'Service Categories',
      'Business Details',
      'Verify Documents',
      'Services & Pricing'
    ];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of 6',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                titles[_currentStep],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF064354),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF064354)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String? base64Data,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasFile = base64Data != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? Colors.green.shade400 : Colors.grey.shade300,
            width: hasFile ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasFile ? Colors.green.shade100 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? Icons.check_circle_rounded : icon,
                color: hasFile ? Colors.green.shade700 : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: hasFile ? Colors.green.shade900 : const Color(0xFF064354),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? 'Tap to replace file' : 'Tap to upload from gallery',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile ? Colors.green.shade700 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: hasFile ? Colors.green.shade400 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your provider profile credentials to get started.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _ownerNameController,
              decoration: _buildInputDecoration(label: 'Full Name', prefixIcon: Icons.person_outline_rounded),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _buildInputDecoration(label: 'Phone Number', prefixIcon: Icons.phone_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(label: 'Email Address', prefixIcon: Icons.email_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: _buildInputDecoration(label: 'Password', prefixIcon: Icons.lock_outline_rounded),
            ),
          ],
        );

      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
            ),
            const SizedBox(height: 6),
            Text(
              'Please enter the 4-digit OTP sent to ${_phoneController.text.isNotEmpty ? _phoneController.text : "your phone number"}.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phonelink_ring_rounded, size: 50, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '• • • •',
                hintStyle: TextStyle(fontSize: 20, letterSpacing: 8, color: Colors.grey.shade400),
                counterText: '',
                filled: true,
                fillColor: Colors.grey.shade50,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF064354), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _sendOtp,
                child: const Text('Resend Code', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064354))),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
            ),
            const SizedBox(height: 6),
            Text(
              'Select the service domains your business is specialized in.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _categories.map((c) {
                final isSelected = _selectedCategories.contains(c);
                return FilterChip(
                  label: Text(
                    c,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  selected: isSelected,
                  checkmarkColor: Colors.white,
                  selectedColor: const Color(0xFF064354),
                  backgroundColor: Colors.grey.shade100,
                  shadowColor: Colors.transparent,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF064354) : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
            ),
            const SizedBox(height: 6),
            Text(
              'Provide details about your business profile, experience, and bios.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            if (widget.isGoogleSignUp) ...[
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration(label: 'Phone Number', prefixIcon: Icons.phone_outlined),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _businessNameController,
              decoration: _buildInputDecoration(label: 'Business Name', prefixIcon: Icons.business_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration(label: 'Years of Experience', prefixIcon: Icons.history_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: _buildInputDecoration(label: 'Office Address', prefixIcon: Icons.location_on_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: _buildInputDecoration(label: 'Business Bio / Description', prefixIcon: Icons.info_outline_rounded),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstController,
              decoration: _buildInputDecoration(
                label: 'GST Number (Optional)',
                prefixIcon: Icons.verified_user_rounded,
                hintText: 'e.g. 27AAAAA1111A1Z1',
              ),
            ),
          ],
        );

      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Verification Files',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
            ),
            const SizedBox(height: 6),
            Text(
              'Please submit identification documents. Files are kept private.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _buildUploadCard(
              title: 'Aadhar Card',
              base64Data: _aadharBase64,
              icon: Icons.assignment_ind_outlined,
              onTap: () => _pickImage('aadhar'),
            ),
            _buildUploadCard(
              title: 'PAN Card',
              base64Data: _panBase64,
              icon: Icons.credit_card_outlined,
              onTap: () => _pickImage('pan'),
            ),
            _buildUploadCard(
              title: 'Portfolio/Gallery Images',
              base64Data: _portfolioBase64,
              icon: Icons.photo_library_outlined,
              onTap: () => _pickImage('portfolio'),
            ),
          ],
        );

      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pricing & Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
            ),
            const SizedBox(height: 6),
            Text(
              'Provide approximate pricing and specific services to finalize profile.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _servicesController,
              decoration: _buildInputDecoration(
                label: 'Specific Services offered',
                prefixIcon: Icons.handyman_outlined,
                hintText: 'e.g. Tile Installation, Plumbing Repairs (comma separated)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pricingController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration(
                label: 'Approximate Pricing / Hourly Rate',
                prefixIcon: Icons.currency_rupee_rounded,
                hintText: 'e.g. ₹500/hr or ₹20000/milestone',
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > (widget.isGoogleSignUp ? 2 : 0)) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentStep -= 1);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF064354),
                  side: const BorderSide(color: Color(0xFF064354), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'BACK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  _sendOtp();
                } else if (_currentStep == 1) {
                  _verifyOtpStep();
                } else if (_currentStep < 5) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitRegistration();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF064354),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 5 ? 'SUBMIT' : 'CONTINUE',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Provider Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF064354),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep > (widget.isGoogleSignUp ? 2 : 0)) {
              setState(() => _currentStep -= 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF064354))),
                SizedBox(height: 20),
                Text(
                  'Creating your profile...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF064354)),
                ),
              ],
            ),
          )
        : Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: _buildStepContent(),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
    );
  }

  dynamic _parseResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw Exception("Server returned empty response (Status: ${response.statusCode}). Please make sure your Next.js backend server is running.");
    }
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Invalid server response format (Status: ${response.statusCode}).");
    }
  }
}
