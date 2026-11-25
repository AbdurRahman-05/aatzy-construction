import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import 'widgets/custom_image.dart';
import '../../../core/services/push_notification_service.dart';

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
  final List<String> images;
  final String finishedDate;

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
    required this.images,
    required this.finishedDate,
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
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      finishedDate: json['updated_at'] != null 
          ? json['updated_at'].toString().split('T')[0] 
          : (json['updatedAt'] != null 
              ? json['updatedAt'].toString().split('T')[0] 
              : ''),
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

        // Trigger native push notification on device
        final notifStage = deliveryStatus ?? newStatus;
        PushNotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: notifStage == 'Delivered'
              ? '✅ Material Delivered: ${lead.requirementTitle}'
              : (notifStage == 'Dispatched'
                  ? '🚚 Material Dispatched: ${lead.requirementTitle}'
                  : (notifStage == 'Packed'
                      ? '📦 Material Packed: ${lead.requirementTitle}'
                      : (newStatus == 'Quote Sent'
                          ? '💰 Quote Sent: ₹${quotedPrice?.toStringAsFixed(0) ?? ''}/${lead.unit}'
                          : '📦 Order Updated: $notifStage'))),
          body: 'Order for "${lead.requirementTitle}" (${lead.quantity}) updated to $notifStage.',
          payload: '/b2b-materials',
          channelId: 'buildzy_orders_v2',
          channelName: 'Material Inquiries & Orders',
        );

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

  void _confirmRejectLead(LeadItem lead, {String reason = 'Lead rejected by supplier during negotiation.'}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Reject Lead Inquiry?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject the requirement for "${lead.requirementTitle.isNotEmpty ? lead.requirementTitle : 'this material'}" from ${lead.buyerName}?',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF181B22)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                'Once rejected, this lead will be marked as Lead Rejected and negotiation will terminate.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF991B1B), height: 1.35),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateLeadStatus(lead, 'Lead Rejected', reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Reject', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showQuoteDialog(LeadItem lead, {bool isNewQuote = false}) {
    double selectedGstPercent = lead.gstPercent > 0 ? lead.gstPercent : 18.0;
    final notesController = TextEditingController(
      text: isNewQuote ? 'Generated a revised quote for the buyer.' : 'Quote proposed to the buyer.',
    );
    final quotedPriceController = TextEditingController(
      text: (lead.quotedPrice != null && lead.quotedPrice! > 0) ? lead.quotedPrice!.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final rate = double.tryParse(quotedPriceController.text.trim()) ?? 0.0;
            final qty = lead.quantityVal > 0 ? lead.quantityVal : 1.0;
            final subtotal = rate * qty;
            final gstAmount = subtotal * (selectedGstPercent / 100.0);
            final totalAmount = subtotal + gstAmount;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Header Banner
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F5F2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isNewQuote ? 'Revise Price Quotation' : 'Propose Price Quotation',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111318),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'For ${lead.buyerName} • ${lead.location}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 20),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),

                      // 2. Dialog Scrollable Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Requirement Summary Card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'TARGET REQUIREMENT',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1D4ED8),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            lead.requirementTitle,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF181B22),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF93C5FD)),
                                      ),
                                      child: Text(
                                        lead.quantity,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Rate Field
                              const Text(
                                'Quoted Rate per Unit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E333D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: quotedPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setDialogState(() {}),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111318)),
                                decoration: InputDecoration(
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      '₹',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  suffixText: '/ ${lead.unit}',
                                  suffixStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                                  hintText: 'e.g. 350.00',
                                  hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  filled: true,
                                  fillColor: const Color(0xFFF6F5F2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFECEAE6)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD6D3CE)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // GST Selection as Segmented Chips
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Applicable GST Tax',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E333D),
                                    ),
                                  ),
                                  Text(
                                    '${selectedGstPercent.toStringAsFixed(0)}% Tax Selected',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [5.0, 12.0, 18.0, 28.0].map((gst) {
                                  final isSelected = selectedGstPercent == gst;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          setDialogState(() {
                                            selectedGstPercent = gst;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF0EEEA),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFECEAE6),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${gst.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 18),

                              // Live Pricing & Billing Breakdown
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6F5F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFECEAE6)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Material Subtotal (${lead.quantity})', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                        Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF181B22))),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('GST (${selectedGstPercent.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                        Text('+ ₹${gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Divider(height: 1, color: Color(0xFFECEAE6)),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Estimated Billing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111318))),
                                        Text(
                                          '₹${totalAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Timeline / Notes Field
                              const Text(
                                'Timeline / Negotiation Notes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E333D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: notesController,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF181B22)),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Ready for dispatch within 2 days. Valid for 7 days...',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: const Color(0xFFF6F5F2),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFECEAE6)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD6D3CE)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Action Buttons
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          border: Border(top: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFD6D3CE)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: const Color(0xFF6B7280),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final qPrice = double.tryParse(quotedPriceController.text.trim()) ?? 0.0;
                                  if (qPrice <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid quoted rate per unit.')),
                                    );
                                    return;
                                  }
                                  Navigator.pop(context);
                                  _updateLeadStatus(
                                    lead,
                                    'Quote Sent',
                                    notesController.text.trim(),
                                    quotedPrice: qPrice,
                                    gstPercent: selectedGstPercent,
                                  );
                                },
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Send Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCloseDealDialog(LeadItem lead) {
    String selectedDeliveryStatus = lead.deliveryStatus;
    final initialNotes = lead.deliveryStatus == 'Delivered'
        ? 'Deal finalized and closed successfully!'
        : 'Status updated to ${lead.deliveryStatus}';
    final notesController = TextEditingController(text: initialNotes);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDelivered = selectedDeliveryStatus == 'Delivered';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F5F2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isDelivered ? Colors.green : const Color(0xFF2563EB)).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDelivered ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                                color: isDelivered ? Colors.green : const Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDelivered ? 'Finalize & Close Deal' : 'Update Delivery Status',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111318),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'For ${lead.buyerName} • ${lead.requirementTitle}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 20),
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Select Shipment / Delivery Stage',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E333D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: ['Pending', 'Packed', 'Dispatched', 'Delivered'].map((stage) {
                                  final isSelected = selectedDeliveryStatus == stage;
                                  Color activeColor = const Color(0xFF2563EB);
                                  if (stage == 'Delivered') activeColor = Colors.green;
                                  if (stage == 'Dispatched') activeColor = Colors.orange;

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          setDialogState(() {
                                            selectedDeliveryStatus = stage;
                                            if (notesController.text.startsWith('Status updated to') ||
                                                notesController.text == 'Deal finalized and closed successfully!' ||
                                                notesController.text.isEmpty) {
                                              if (stage == 'Delivered') {
                                                notesController.text = 'Deal finalized and closed successfully!';
                                              } else {
                                                notesController.text = 'Status updated to $stage';
                                              }
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          padding: const EdgeInsets.symmetric(vertical: 9),
                                          decoration: BoxDecoration(
                                            color: isSelected ? activeColor : const Color(0xFFF0EEEA),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected ? activeColor : const Color(0xFFECEAE6),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              stage,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected ? Colors.white : const Color(0xFF4B5563),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Timeline / Tracking Notes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E333D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: notesController,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF181B22)),
                                decoration: InputDecoration(
                                  hintText: 'Enter dispatch, vehicle number, or receipt info...',
                                  hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: const Color(0xFFF6F5F2),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFECEAE6)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFD6D3CE)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Actions
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          border: Border(top: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFD6D3CE)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: const Color(0xFF6B7280),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _updateLeadStatus(
                                    lead,
                                    isDelivered ? 'Completed' : 'Closed',
                                    notesController.text.trim(),
                                    deliveryStatus: selectedDeliveryStatus,
                                  );
                                },
                                icon: Icon(isDelivered ? Icons.check_circle_rounded : Icons.save_rounded, size: 16),
                                label: Text(
                                  isDelivered ? 'Finalize & Close Deal' : 'Update & Save',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDelivered ? Colors.green : const Color(0xFF0F766E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                                            lead.status == 'Closed'
                                                ? (lead.deliveryStatus == 'Delivered' ? 'Deal Closed' : 'In Transit (${lead.deliveryStatus})')
                                                : lead.status,
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
                                           if (lead.status == 'Closed' || lead.status == 'Accepted') ...[
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
    if (lead.status == 'Completed' || (lead.status == 'Closed' && lead.deliveryStatus == 'Delivered')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Order Completed & Closed',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          if (lead.images.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Material Delivery Proof (Uploaded by Consumer):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BuildMartImage(
                imageUrl: lead.images.last,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calling Buyer ${lead.buyerName}: ${lead.buyerPhone}...')),
                );
              },
              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
              label: const Text('Call Buyer'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }

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
            onPressed: () => _confirmRejectLead(lead),
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

    if (lead.status == 'Accepted' || (lead.status == 'Closed' && lead.deliveryStatus != 'Delivered')) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCloseDealDialog(lead),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('Update Status'),
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
              onPressed: () => _confirmRejectLead(lead, reason: 'Supplier rejected lead after buyer rejected the quote.'),
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
      return SizedBox(
        width: double.infinity,
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
