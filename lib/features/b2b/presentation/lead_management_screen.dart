import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';

class LeadItem {
  final String id;
  final String date;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String requirementTitle;
  final String requirementDesc;
  final String quantity;
  final double quantityVal;
  final String unit;
  final String location;
  String status; 
  double? quotedPrice;
  String deliveryStatus; 
  double gstPercent;

  LeadItem({
    required this.id,
    required this.date,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.requirementTitle,
    required this.requirementDesc,
    required this.quantity,
    required this.quantityVal,
    required this.unit,
    required this.location,
    required this.status,
    this.quotedPrice,
    required this.deliveryStatus,
    required this.gstPercent,
  });

  factory LeadItem.fromJson(Map<String, dynamic> json) {
    final qtyVal = json['quantity'] != null ? double.parse(json['quantity'].toString()) : 100.0;
    final unitStr = json['unit'] ?? 'Units';
    return LeadItem(
      id: json['id'] ?? '',
      date: json['created_at'] != null 
          ? json['created_at'].toString().split('T')[0] 
          : '2026-06-05',
      buyerName: json['buyer_name'] ?? 'Buyer Client',
      buyerPhone: json['buyer_phone'] ?? '',
      buyerEmail: json['buyer_email'] ?? '',
      requirementTitle: json['title'] ?? json['product_name'] ?? 'Material Requirement',
      requirementDesc: json['description'] ?? 'Bulk order request details.',
      quantity: '$qtyVal $unitStr',
      quantityVal: qtyVal,
      unit: unitStr,
      location: json['location'] ?? 'All India',
      status: json['status'] ?? 'New',
      quotedPrice: json['quoted_price'] != null ? double.parse(json['quoted_price'].toString()) : null,
      deliveryStatus: json['delivery_status'] ?? 'Pending',
      gstPercent: json['gst_percent'] != null ? double.parse(json['gst_percent'].toString()) : 18.0,
    );
  }
}

class LeadManagementScreen extends ConsumerStatefulWidget {
  const LeadManagementScreen({super.key});

  @override
  ConsumerState<LeadManagementScreen> createState() => _LeadManagementScreenState();
}

class _LeadManagementScreenState extends ConsumerState<LeadManagementScreen> {
  bool _isLoading = false;
  List<LeadItem> _leads = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      setState(() {
        _errorMessage = 'Please log in to view leads';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = B2BApiService();
      final res = await api.get('/supplier/leads', queryParameters: {'supplierId': auth.id!});
      if (res.success && res.data != null) {
        final List list = res.data['leads'] ?? [];
        setState(() {
          _leads = list.map((item) => LeadItem.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _errorMessage = res.data['error'] ?? 'Failed to load leads';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch leads.';
        _leads = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLeadStatus(
    LeadItem lead,
    String newStatus,
    String notes, {
    double? quotedPrice,
    String? deliveryStatus,
    double? gstPercent,
  }) async {
    setState(() => _isLoading = true);
    final auth = ref.read(authProvider);

    try {
      final api = B2BApiService();
      final res = await api.post('/supplier/leads/${lead.id}/status', data: {
        'status': newStatus,
        'notes': notes,
        'supplierId': auth.id,
        'quotedPrice': quotedPrice,
        'deliveryStatus': deliveryStatus,
        'gstPercent': gstPercent,
      });

      if (res.success) {
        setState(() {
          lead.status = newStatus;
          if (quotedPrice != null) lead.quotedPrice = quotedPrice;
          if (deliveryStatus != null) lead.deliveryStatus = deliveryStatus;
          if (gstPercent != null) lead.gstPercent = gstPercent;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lead status updated to $newStatus successfully!')),
          );
        }
        _fetchLeads();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['error'] ?? 'Failed to update lead')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.blue;
      case 'Viewed':
        return Colors.orange;
      case 'Contacted':
        return Colors.teal;
      case 'Quote Sent':
        return Colors.purple;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Closed':
        return Colors.green.shade800;
      default:
        return Colors.grey;
    }
  }

  void _showQuoteDialog(LeadItem lead, {bool isNewQuote = false}) {
    double selectedGstPercent = lead.gstPercent;
    final notesController = TextEditingController(text: isNewQuote ? 'Generated a revised quote for the buyer.' : 'Quote proposed to the buyer.');
    final quotedPriceController = TextEditingController(text: lead.quotedPrice?.toString() ?? '410.00');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isNewQuote ? 'Generate Revised Quote' : 'Propose Price Quotation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: quotedPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quoted Rate per Unit (₹)',
                        hintText: 'e.g. 410.00',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<double>(
                      initialValue: selectedGstPercent,
                      decoration: const InputDecoration(labelText: 'GST Percent (%)'),
                      items: [5.0, 12.0, 18.0, 28.0].map((gst) {
                        return DropdownMenuItem(value: gst, child: Text('${gst.toStringAsFixed(0)}%'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedGstPercent = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Timeline/Negotiation Notes',
                        hintText: 'Enter specifications or timeline details...',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final qPrice = double.tryParse(quotedPriceController.text) ?? 0.0;
                    _updateLeadStatus(
                      lead,
                      'Quote Sent',
                      notesController.text.trim(),
                      quotedPrice: qPrice,
                      gstPercent: selectedGstPercent,
                    );
                  },
                  child: const Text('Send Quote'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCloseDealDialog(LeadItem lead) {
    String selectedDeliveryStatus = lead.deliveryStatus;
    final notesController = TextEditingController(text: lead.status == 'Closed' ? 'Updated delivery details.' : 'Deal finalized and closed successfully!');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(lead.status == 'Closed' ? 'Update Delivery Tracking' : 'Finalize & Close Deal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedDeliveryStatus,
                      decoration: const InputDecoration(labelText: 'Delivery Stage'),
                      items: ['Pending', 'Packed', 'Dispatched', 'Delivered'].map((stage) {
                        return DropdownMenuItem(value: stage, child: Text(stage));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedDeliveryStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Timeline Notes',
                        hintText: 'Enter dispatch or receipt info...',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateLeadStatus(
                      lead,
                      'Closed',
                      notesController.text.trim(),
                      deliveryStatus: selectedDeliveryStatus,
                    );
                  },
                  child: Text(lead.status == 'Closed' ? 'Save Status' : 'Close Deal'),
                ),
              ],
            );
          },
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
        title: const Text('Lead Management Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeads,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    color: Colors.amber.shade100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.black87), textAlign: TextAlign.center),
                  ),
                Expanded(
                  child: _leads.isEmpty
                      ? const Center(child: Text('No buyer inquiries received yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _leads.length,
                          itemBuilder: (context, index) {
                            final lead = _leads[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'DATE: ${lead.date}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(lead.status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(50),
                                            border: Border.all(color: _getStatusColor(lead.status).withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            lead.status == 'Closed' ? 'Deal Closed' : lead.status,
                                            style: TextStyle(color: _getStatusColor(lead.status), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    Text(
                                      lead.requirementTitle,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lead.requirementDesc,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                    ),
                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        _buildBadge(Icons.shopping_bag_outlined, 'Qty: ${lead.quantity}'),
                                        const SizedBox(width: 8),
                                        _buildBadge(Icons.location_on_rounded, lead.location),
                                      ],
                                    ),
                                    
                                     if (lead.quotedPrice != null) ...[
                                       const SizedBox(height: 10),
                                       Row(
                                         children: [
                                           _buildBadge(Icons.monetization_on_outlined, 'Quoted: ₹${lead.quotedPrice!.toStringAsFixed(2)}'),
                                           if (lead.status == 'Closed') ...[
                                             const SizedBox(width: 8),
                                             _buildBadge(Icons.local_shipping_outlined, 'Shipment: ${lead.deliveryStatus}'),
                                           ],
                                         ],
                                       ),
                                     ],
                                    
                                    const Divider(height: 24, color: Colors.grey),

                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.grey.shade200,
                                          child: const Icon(Icons.person, color: Colors.blue, size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lead.buyerName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              Text(
                                                'Email: ${lead.buyerEmail} | Ph: ${lead.buyerPhone}',
                                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    _buildActionButtons(lead),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons(LeadItem lead) {
    if (lead.status == 'Lead Rejected') {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'This lead has been rejected/terminated.',
          style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (lead.status == 'Quote Sent') {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.purple),
                  SizedBox(width: 6),
                  Text('Awaiting Buyer\'s Quote Decision', style: TextStyle(color: Colors.purple, fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _updateLeadStatus(lead, 'Lead Rejected', 'Lead rejected by supplier during negotiation.'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            child: const Text('Reject Lead'),
          ),
        ],
      );
    }

    if (lead.status == 'Accepted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCloseDealDialog(lead),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Finalize & Close Deal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling Buyer ${lead.buyerName}: ${lead.buyerPhone}...')),
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
              label: const Text('Call Buyer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }

    if (lead.status == 'Rejected') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showQuoteDialog(lead, isNewQuote: true),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Generate New Quote'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateLeadStatus(lead, 'Lead Rejected', 'Supplier rejected lead after buyer rejected the quote.'),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Reject Lead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }

    if (lead.status == 'Closed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showCloseDealDialog(lead),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('Update Delivery Stage'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling Buyer ${lead.buyerName}: ${lead.buyerPhone}...')),
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
              label: const Text('Call Buyer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showQuoteDialog(lead),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send Quote'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling Buyer ${lead.buyerName}: ${lead.buyerPhone}...')),
              );
            },
            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
            label: const Text('Call Buyer'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.blue),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
