import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../../core/wallpaper_background.dart';

class ProviderLeadDetail extends ConsumerStatefulWidget {
  final String leadId;
  const ProviderLeadDetail({super.key, required this.leadId});

  @override
  ConsumerState<ProviderLeadDetail> createState() => _ProviderLeadDetailState();
}

class _ProviderLeadDetailState extends ConsumerState<ProviderLeadDetail> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _timelineController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();
  }

  @override
  void dispose() {
    _costController.dispose();
    _timelineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/projects/${widget.leadId}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _project = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching project details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please login again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/quotes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectId': widget.leadId,
          'providerId': auth.id,
          'estimatedCost': double.tryParse(_costController.text.trim()) ?? 0.0,
          'timeline': _timelineController.text.trim(),
          'notes': _notesController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote submitted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to submit quote'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error submitting quote: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to reach server.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: const Center(child: Text('Lead details not found.')),
      );
    }

    final title = _project!['title'] ?? 'N/A';
    final type = _project!['type'] ?? 'N/A';
    final location = _project!['location'] ?? 'N/A';
    final plotSize = _project!['plotSize']?.toString() ?? 'N/A';
    final budget = _project!['budget']?.toString() ?? 'N/A';
    final timeline = _project!['timeline'] ?? 'N/A';
    final user = _project!['user'] ?? {};
    final userName = user['name'] ?? 'Client';

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Lead Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('Location: $location', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(type, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Plot Size:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('$plotSize sq ft', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Client Budget:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('₹$budget', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Requested Timeline:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(timeline, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Client Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Verified BuildConnect Client'),
              ),
              const Divider(height: 32),
              Text('Submit Your Quote', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Estimated Cost (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Cost is required';
                  if (double.tryParse(v.trim()) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timelineController,
                decoration: InputDecoration(
                  labelText: 'Your Timeline (e.g. 4 weeks)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Timeline is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitQuote,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Submit Quote'),
                          ),
                        ),
                      ],
                    )
            ],
          ),
        ),
      ),
    ),
    );
  }
}
