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

  @override
  Widget build(BuildContext context) {
    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Create Project')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Project Title',
                        hintText: 'e.g. Villa Construction, Home Renovation',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Project Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1F2C34)
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Services Needed',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF0F9B8E)
                                      : Theme.of(context).primaryColor,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((service) {
                              final isSelected = _selectedServices.contains(service);
                              final isDark = Theme.of(context).brightness == Brightness.dark;
                              return FilterChip(
                                label: Text(service),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedServices.add(service);
                                    } else {
                                      _selectedServices.remove(service);
                                    }
                                  });
                                },
                                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                checkmarkColor: isDark ? const Color(0xFFF4EFE6) : Theme.of(context).primaryColor,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFFF4EFE6) : Theme.of(context).primaryColor)
                                      : (isDark ? const Color(0xFFF4EFE6) : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: isDark ? const Color(0xFF121B22) : Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g. Mumbai, Downtown, etc.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _plotSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Plot Size (sq ft)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Plot size is required';
                        if (double.tryParse(v.trim()) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Budget Range (USD/INR)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Budget is required';
                        if (double.tryParse(v.trim()) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _timelineController,
                      decoration: InputDecoration(
                        labelText: 'Timeline (e.g. 6 months)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Timeline is required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitProject,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
    ),
    );
  }
}
