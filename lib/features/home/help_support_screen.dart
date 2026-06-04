import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    // Simulate API call to support endpoint
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ticket submitted! We will contact you soon.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  ExpansionTile(
                    leading: Icon(Icons.help_outline, color: Colors.blue),
                    title: Text('How do I request a quote?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 56, right: 16, bottom: 16),
                        child: Text(
                          'Navigate to the provider\'s profile, tap on the "Request Quote" button at the bottom, enter your project details or description, and submit. The provider will view this quote request in their leads panel.',
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),
                      )
                    ],
                  ),
                  Divider(height: 1),
                  ExpansionTile(
                    leading: Icon(Icons.help_outline, color: Colors.blue),
                    title: Text('Are service providers verified?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 56, right: 16, bottom: 16),
                        child: Text(
                          'Yes! All registration details, including PAN card, Aadhar card, and business verification documents, are manually reviewed by our admin panel team before a provider receives their verification badge.',
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),
                      )
                    ],
                  ),
                  Divider(height: 1),
                  ExpansionTile(
                    leading: Icon(Icons.help_outline, color: Colors.blue),
                    title: Text('What is the cost estimation tool?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 56, right: 16, bottom: 16),
                        child: Text(
                          'Our smart cost estimation calculator helps you project total material, labor, and compliance costs based on your plot size, building type, location, and structural configuration. Use it in the "Tools" panel.',
                          style: TextStyle(color: Colors.black54, height: 1.4),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Contact Support Team',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Describe your issue',
                        prefixIcon: Icon(Icons.message),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Please describe your request' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SUBMIT TICKET', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'Phone: +1 (800) 555-0199',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'Support Hours: Mon-Fri, 9AM-6PM',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
