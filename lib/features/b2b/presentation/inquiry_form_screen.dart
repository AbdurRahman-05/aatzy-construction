import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import 'widgets/custom_image.dart';

class InquiryFormScreen extends ConsumerStatefulWidget {
  final String? supplierId;
  final String? productId;
  final String? productName;
  final String? productImage;

  const InquiryFormScreen({
    super.key,
    this.supplierId,
    this.productId,
    this.productName,
    this.productImage,
  });

  @override
  ConsumerState<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends ConsumerState<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  final _locController = TextEditingController();
  String _selectedUnit = 'Bags';
  bool _submitting = false;

  final List<String> _units = ['Pieces', 'Bags', 'Metric Tons', 'Meters', 'Liters', 'Cubic Meters'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.productName != null
          ? 'Requirement for ${widget.productName}'
          : '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _locController.dispose();
    super.dispose();
  }

  void _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit inquiries')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = B2BApiService();
      final res = await api.post('/buyer/inquiries', data: {
        'buyerId': auth.id,
        'supplierId': widget.supplierId,
        'productId': widget.productId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'quantity': double.parse(_qtyController.text),
        'unit': _selectedUnit,
        'location': _locController.text.trim(),
        'images': widget.productImage != null ? [widget.productImage] : []
      });

      if (res.success) {
        if (mounted) _showSuccessDialog();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['error'] ?? 'Failed to submit inquiry')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting inquiry: $e')),
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
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Inquiry Submitted!'),
            ],
          ),
          content: const Text(
            'Your requirement request has been dispatched. The supplier will review the details and get back to you shortly with a quote.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                context.pop(); // Close dialog
                context.go('/'); // Navigate back home
              },
              child: const Text('Return to Home'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BentoAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create B2B Inquiry', overflow: TextOverflow.ellipsis),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 20,
              vertical: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.productName != null && widget.productImage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: BuildMartImage(imageUrl: widget.productImage!, width: 50, height: 50, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('INQUIRY TARGET PRODUCT:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 2),
                                Text(
                                  widget.productName!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Text(
                    'Requirement Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Requirement Title',
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
                      labelText: 'Detailed Description',
                      hintText: 'Describe concrete strength grade, sizing, delivery location details, etc...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please describe your request details' : null,
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, fieldConstraints) {
                      final isCompact = fieldConstraints.maxWidth < 360;

                      final qtyField = TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity Needed',
                          hintText: 'e.g. 100',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        ),
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Enter valid amount' : null,
                      );

                      final unitField = DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedUnit,
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(unit),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        ),
                      );

                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            qtyField,
                            const SizedBox(height: 16),
                            unitField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: qtyField,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: unitField,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locController,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Delivery Location',
                      hintText: 'e.g. Madurai, Tamil Nadu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _submitting ? null : _submitInquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit B2B Inquiry', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
