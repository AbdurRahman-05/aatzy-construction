import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../../core/wallpaper_background.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _timelineController = TextEditingController();
  
  final List<String> _selectedServices = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Land & Legal', 'Finance & Approvals', 'Survey & Analysis', 'Design & Planning',
    'Construction', 'Engineering (MEP)', 'Materials & Supply', 'Utilities',
    'Interiors & Finishing', 'Project Management', 'Inspection & Compliance',
    'Smart & Security', 'Logistics & Equipment', 'Insurance'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _plotSizeController.dispose();
    _budgetController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service needed')),
      );
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please login again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': auth.id,
          'title': _titleController.text.trim(),
          'type': _selectedServices.join(', '),
          'location': _locationController.text.trim(),
          'plotSize': double.tryParse(_plotSizeController.text.trim()) ?? 0.0,
          'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
          'timeline': _timelineController.text.trim(),
          'currentStage': 'Design & Planning',
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!'), backgroundColor: Colors.green),
        );
        context.pop(true);
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to create project'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error creating project: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to reach server.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Land & Legal': return Icons.gavel_rounded;
      case 'Finance & Approvals': return Icons.assignment_turned_in_rounded;
      case 'Survey & Analysis': return Icons.analytics_rounded;
      case 'Design & Planning': return Icons.architecture_rounded;
      case 'Construction': return Icons.construction_rounded;
      case 'Engineering (MEP)': return Icons.engineering_rounded;
      case 'Materials & Supply': return Icons.precision_manufacturing_rounded;
      case 'Utilities': return Icons.plumbing_rounded;
      case 'Interiors & Finishing': return Icons.format_paint_rounded;
      case 'Project Management': return Icons.business_center_rounded;
      case 'Inspection & Compliance': return Icons.verified_rounded;
      case 'Smart & Security': return Icons.security_rounded;
      case 'Logistics & Equipment': return Icons.local_shipping_rounded;
      case 'Insurance': return Icons.shield_rounded;
      default: return Icons.category_rounded;
    }
  }

  Widget _buildCategoryCard(String service, bool isDark, Color primaryColor) {
    final isSelected = _selectedServices.contains(service);
    final icon = _getCategoryIcon(service);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedServices.remove(service);
          } else {
            _selectedServices.add(service);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 105,
        height: 105,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected 
              ? primaryColor.withValues(alpha: 0.1) 
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? primaryColor 
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  icon, 
                  color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.grey.shade600),
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  service,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected 
                        ? (isDark ? Colors.white : primaryColor)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: primaryColor,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
        ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.room_service_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Services Needed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF064354),
                  ),
                ),
                const Spacer(),
                if (_selectedServices.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedServices.length} Selected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _categories.map((service) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCategoryCard(service, isDark, primaryColor),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    required String? Function(String?) validator,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(prefixIcon, color: primaryColor.withValues(alpha: 0.7)),
          suffixText: suffixText,
          suffixStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          filled: true,
          fillColor: Colors.transparent,
          labelStyle: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1.5,
            ),
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354);

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'New Site Blueprint',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Premium Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [const Color(0xFF0F9B8E), const Color(0xFF0E5E6F)]
                                : [const Color(0xFF064354), const Color(0xFF0B7C8E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.architecture_rounded, 
                                    color: Colors.white, 
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Initiate Construction',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w900, 
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Define your construction or renovation details to start soliciting quotes from verified builders.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85), 
                                fontSize: 12, 
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 1: General Information
                      Text(
                        'BASIC INFORMATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Project Title',
                        hint: 'e.g. 3BHK Villa Construction, Kitchen Renovation',
                        prefixIcon: Icons.edit_note_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Project Title is required' : null,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Site Location',
                        hint: 'e.g. Indiranagar, Bangalore',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 28),

                      // Section 2: Services
                      Text(
                        'REQUIRED EXPERTISE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildServicesSection(isDark, primaryColor),
                      const SizedBox(height: 28),

                      // Section 3: Specifications
                      Text(
                        'SPECIFICATIONS & LOGISTICS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _plotSizeController,
                        label: 'Plot Size',
                        hint: 'e.g. 1200',
                        prefixIcon: Icons.square_foot_rounded,
                        suffixText: 'sq ft',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Plot size is required';
                          if (double.tryParse(v.trim()) == null) return 'Please enter a valid number';
                          return null;
                        },
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _budgetController,
                        label: 'Budget Limit',
                        hint: 'e.g. 4500000',
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Budget is required';
                          if (double.tryParse(v.trim()) == null) return 'Please enter a valid number';
                          return null;
                        },
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _timelineController,
                        label: 'Target Timeline',
                        hint: 'e.g. 9 months',
                        prefixIcon: Icons.calendar_month_rounded,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Timeline is required' : null,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                      const SizedBox(height: 36),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _submitProject,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text(
                            'Save & Launch Blueprint',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
