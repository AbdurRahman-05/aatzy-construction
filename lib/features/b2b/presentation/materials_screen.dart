import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/b2b_api_service.dart';
import '../../auth/auth_provider.dart';
import 'my_inquiries_screen.dart';
import 'lead_management_screen.dart';
import 'widgets/custom_image.dart';

class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;

  // Consumer Side Data
  List<InquiryModel> _inquiries = [];
  
  // Provider Side Data
  List<LeadItem> _leads = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      setState(() {
        _errorMessage = 'Please log in to access materials';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = B2BApiService();
      if (auth.role == 'PROVIDER') {
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
      } else {
        // CONSUMER
        final res = await api.get('/buyer/inquiries', queryParameters: {'buyerId': auth.id!});
        if (res.success && res.data != null) {
          final List list = res.data['inquiries'] ?? [];
          setState(() {
            _inquiries = list.map((item) => InquiryModel.fromJson(item)).toList();
          });
        } else {
          setState(() {
            _errorMessage = res.data['error'] ?? 'Failed to load inquiries';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching materials: $e');
      setState(() {
        _errorMessage = 'Failed to load materials data.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filters for Consumer
  List<InquiryModel> get _consumerNotStarted => _inquiries.where((i) {
    return ['New', 'Viewed', 'Contacted', 'Quote Sent', 'Rejected'].contains(i.status);
  }).toList();

  List<InquiryModel> get _consumerOnProcesses => _inquiries.where((i) {
    return i.status == 'Accepted' || (i.status == 'Closed' && i.deliveryStatus != 'Delivered');
  }).toList();

  List<InquiryModel> get _consumerClosedDeals => _inquiries.where((i) {
    return i.status == 'Completed' || (i.status == 'Closed' && i.deliveryStatus == 'Delivered');
  }).toList();

  // Filters for Provider
  List<LeadItem> get _providerNotStarted => _leads.where((l) {
    return ['New', 'Viewed', 'Contacted', 'Quote Sent', 'Rejected', 'Lead Rejected'].contains(l.status);
  }).toList();

  List<LeadItem> get _providerOnProcesses => _leads.where((l) {
    return l.status == 'Accepted' || (l.status == 'Closed' && l.deliveryStatus != 'Delivered');
  }).toList();

  List<LeadItem> get _providerClosedDeals => _leads.where((l) {
    return l.status == 'Completed' || (l.status == 'Closed' && l.deliveryStatus == 'Delivered');
  }).toList();

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

  // Provider Action Handlers (reused from LeadManagementScreen)
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
        _fetchData();
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
      if (mounted) setState(() => _isLoading = false);
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
    final initialNotes = lead.deliveryStatus == 'Delivered'
        ? 'Deal finalized and closed successfully!'
        : 'Status updated to ${lead.deliveryStatus}';
    final notesController = TextEditingController(text: initialNotes);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(selectedDeliveryStatus == 'Delivered' ? 'Finalize & Close Deal' : 'Update Status'),
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
                            if (notesController.text.startsWith('Status updated to') ||
                                notesController.text == 'Deal finalized and closed successfully!' ||
                                notesController.text.isEmpty) {
                              if (val == 'Delivered') {
                                notesController.text = 'Deal finalized and closed successfully!';
                              } else {
                                notesController.text = 'Status updated to $val';
                              }
                            }
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
                  child: Text(selectedDeliveryStatus == 'Delivered' ? 'Close Deal' : 'Update & Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Consumer Action Handlers (Opens the timeline bottom sheet)
  void _showTimeline(InquiryModel inq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: _MaterialsTimelineView(
                inquiryId: inq.id,
                inq: inq,
                onStatusUpdated: _fetchData,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isProvider = auth.role == 'PROVIDER';

    // Determine counts for tabs
    int notStartedCount = isProvider ? _providerNotStarted.length : _consumerNotStarted.length;
    int onProcessesCount = isProvider ? _providerOnProcesses.length : _consumerOnProcesses.length;
    int closedDealsCount = isProvider ? _providerClosedDeals.length : _consumerClosedDeals.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(isProvider ? 'Supplier Materials Console' : 'Materials Procurement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Not Started'),
                  if (notStartedCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$notStartedCount',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('On Processes'),
                  if (onProcessesCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$onProcessesCount',
                        style: const TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Closed Deals'),
                  if (closedDealsCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$closedDealsCount',
                        style: const TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabList(isProvider, 0),
                      _buildTabList(isProvider, 1),
                      _buildTabList(isProvider, 2),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabList(bool isProvider, int tabIndex) {
    if (isProvider) {
      final List<LeadItem> list;
      if (tabIndex == 0) {
        list = _providerNotStarted;
      } else if (tabIndex == 1) {
        list = _providerOnProcesses;
      } else {
        list = _providerClosedDeals;
      }

      if (list.isEmpty) {
        return _buildEmptyState(isProvider, tabIndex);
      }

      return RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final lead = list[index];
            return _buildProviderLeadCard(lead);
          },
        ),
      );
    } else {
      final List<InquiryModel> list;
      if (tabIndex == 0) {
        list = _consumerNotStarted;
      } else if (tabIndex == 1) {
        list = _consumerOnProcesses;
      } else {
        list = _consumerClosedDeals;
      }

      if (list.isEmpty) {
        return _buildEmptyState(isProvider, tabIndex);
      }

      return RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final inq = list[index];
            return _buildConsumerInquiryCard(inq);
          },
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isProvider, int tabIndex) {
    final String title;
    final String subtitle;
    final IconData icon;

    if (tabIndex == 0) {
      title = 'No New Negotiations';
      subtitle = isProvider ? 'No pending leads awaiting quotation.' : 'No active inquiries waiting for quotes.';
      icon = Icons.hourglass_empty_rounded;
    } else if (tabIndex == 1) {
      title = 'No Ongoing Deliveries';
      subtitle = isProvider ? 'No orders currently in packed or dispatched stages.' : 'No active shipments currently on transit.';
      icon = Icons.local_shipping_outlined;
    } else {
      title = 'No Closed Deals';
      subtitle = isProvider ? 'You haven\'t closed or completed any bulk deals yet.' : 'No finalized or delivered orders in history.';
      icon = Icons.archive_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumerInquiryCard(InquiryModel inq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTimeline(inq),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${inq.id.length > 8 ? inq.id.substring(0, 8).toUpperCase() : inq.id}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(inq.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _getStatusColor(inq.status).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      inq.status == 'Closed'
                          ? 'Deal Finalized'
                          : (inq.status == 'Quote Sent' ? 'Quote Received' : inq.status),
                      style: TextStyle(color: _getStatusColor(inq.status), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                inq.productName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Supplier: ${inq.supplierName}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Quantity: ${inq.quantity}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              if (inq.quotedPrice != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quoted Price:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${inq.quotedPrice!.toStringAsFixed(2)} / Unit',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24, color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (inq.status == 'Completed' || inq.status == 'Closed') && inq.finishedDate.isNotEmpty
                        ? 'Closed on: ${inq.finishedDate}'
                        : 'Sent on: ${inq.date}',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  Row(
                    children: [
                      Text(
                        inq.status == 'Closed' ? 'Track Shipping' : 'Track Status',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderLeadCard(LeadItem lead) {
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
                  (lead.status == 'Completed' || lead.status == 'Closed') && lead.finishedDate.isNotEmpty
                      ? 'CLOSED ON: ${lead.finishedDate}'
                      : 'DATE: ${lead.date}',
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
            _buildProviderActionButtons(lead),
          ],
        ),
      ),
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

  Widget _buildProviderActionButtons(LeadItem lead) {
    if (lead.status == 'Completed') {
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
                  Text('Awaiting Buyer\'s Decision', style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
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
            child: const Text('Reject'),
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
              label: const Text('New Quote'),
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
              label: const Text('Update Status'),
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
}

// Reusable custom consumer timeline view specifically for materials screen
class _MaterialsTimelineView extends ConsumerStatefulWidget {
  final String inquiryId;
  final InquiryModel inq;
  final VoidCallback onStatusUpdated;

  const _MaterialsTimelineView({required this.inquiryId, required this.inq, required this.onStatusUpdated});

  @override
  ConsumerState<_MaterialsTimelineView> createState() => _MaterialsTimelineViewState();
}

class _MaterialsTimelineViewState extends ConsumerState<_MaterialsTimelineView> {
  bool _loading = true;
  bool _isUpdating = false;
  InquiryModel? _liveInq;
  List<dynamic> _timelineLogs = [];

  int _ratingInput = 5;
  final _reviewController = TextEditingController();
  bool _isSubmittingReview = false;
  String? _materialPhotoBase64;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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

  Future<void> _pickMaterialPhoto() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64Image';
        setState(() {
          _materialPhotoBase64 = dataUrl;
        });
      }
    } catch (e) {
      debugPrint('Error picking material photo: $e');
    }
  }

  Future<void> _completeAndCloseOrder() async {
    if (_materialPhotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a photo of the received material to close the order.')),
      );
      return;
    }
    setState(() => _isUpdating = true);
    final auth = ref.read(authProvider);
    try {
      final api = B2BApiService();
      final res = await api.post('/buyer/inquiries/${widget.inquiryId}/status', data: {
        'status': 'Completed',
        'buyerId': auth.id,
        'notes': 'Delivery confirmed by consumer. Material photo uploaded.',
        'images': [_materialPhotoBase64!]
      });
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order closed successfully! Delivery photo sent to provider.')),
          );
          widget.onStatusUpdated();
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res.data['error'] ?? 'Failed to close order')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error closing order: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final auth = ref.read(authProvider);
    try {
      final api = B2BApiService();
      final isAccept = newStatus == 'Closed' || newStatus == 'Accepted';
      final res = await api.post('/buyer/inquiries/${widget.inquiryId}/status', data: {
        'status': newStatus,
        'buyerId': auth.id,
        'notes': isAccept ? 'Quote accepted by buyer. Deal closed.' : 'Quote rejected by buyer.',
      });
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quote ${isAccept ? "Accepted & Deal Closed" : "Rejected"} successfully!')),
          );
          widget.onStatusUpdated();
          context.pop();
        }
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;
    setState(() => _isSubmittingReview = true);
    final auth = ref.read(authProvider);
    try {
      final api = B2BApiService();
      final res = await api.post('/buyer/inquiries/${widget.inquiryId}/status', data: {
        'buyerId': auth.id,
        'rating': _ratingInput,
        'reviewText': _reviewController.text.trim(),
      });
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        _fetchTimeline();
        widget.onStatusUpdated();
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  Future<void> _fetchTimeline() async {
    try {
      final api = B2BApiService();
      final res = await api.get('/buyer/inquiries/${widget.inquiryId}');
      if (res.success && res.data != null) {
        setState(() {
          if (res.data['inquiry'] != null) {
            _liveInq = InquiryModel.fromJson(res.data['inquiry']);
          }
          _timelineLogs = res.data['timeline'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching timeline: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isCompleted ? Colors.blue : Colors.grey.shade300,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCompleted ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isCompleted ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingStage(String stageName, String stageDesc, bool isActive, bool isPast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : (isPast ? Colors.blue : Colors.grey.shade300),
              ),
              child: Icon(
                isActive ? Icons.check : (isPast ? Icons.done : Icons.circle_outlined),
                size: 14,
                color: Colors.white,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: isPast ? Colors.blue : Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stageName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isActive ? Colors.green : (isPast ? Colors.black87 : Colors.grey),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stageDesc,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final inq = _liveInq ?? widget.inq;
    final ds = inq.deliveryStatus;
    final isPacked = ds == 'Packed' || ds == 'Dispatched' || ds == 'Delivered';
    final isDispatched = ds == 'Dispatched' || ds == 'Delivered';
    final isDelivered = ds == 'Delivered';

    final double baseAmount = (inq.quotedPrice ?? 0) * inq.quantityVal;
    final double gstAmount = baseAmount * (inq.gstPercent / 100);
    final double totalInvoice = baseAmount + gstAmount;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inq.status == 'Closed' ? 'Deal Finalized & Shipping' : 'Inquiry Tracker',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'ID: ${widget.inquiryId.toUpperCase()}',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          if (inq.status == 'Closed') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Delivery Tracker Stages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildShippingStage(
                    'Order Confirmed & Deal Closed',
                    'Supplier has locked quotes and finalized specifications.',
                    ds == 'Pending',
                    isPacked,
                  ),
                  _buildShippingStage(
                    'Material Packaging Processed',
                    'Goods are packed and verified for quality control checks.',
                    ds == 'Packed',
                    isDispatched,
                  ),
                  _buildShippingStage(
                    'Dispatched & In-Transit',
                    'Consignment left supplier warehouse hub.',
                    ds == 'Dispatched',
                    isDelivered,
                  ),
                  _buildShippingStage(
                    'Delivered Successfully',
                    'Goods received and verified at the building project site.',
                    ds == 'Delivered',
                    false,
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTimelineStep(
              'Inquiry Submitted',
              'Dispatched requirement specifications to supplier on ${inq.date}',
              true,
            ),
            _buildTimelineStep(
              'Supplier Reviewed Lead',
              inq.status != 'New' ? 'Supplier opened and viewed lead details' : 'Waiting for supplier review...',
              inq.status != 'New',
            ),
            _buildTimelineStep(
              'Quote Proposed',
              inq.quotedPrice != null 
                  ? 'Supplier submitted a quote of ₹${inq.quotedPrice!.toStringAsFixed(2)} / Unit' 
                  : 'Awaiting supplier price quotation proposal...',
              inq.quotedPrice != null,
            ),
            if (inq.status == 'Accepted')
              _buildTimelineStep(
                'Quote Accepted',
                'You accepted the quote proposal. Awaiting delivery scheduling.',
                true,
              )
            else if (inq.status == 'Rejected')
              _buildTimelineStep(
                'Quote Rejected',
                'You rejected this quote proposal.',
                true,
              )
            else
              _buildTimelineStep(
                'Deal Finalized',
                inq.status == 'Closed' ? 'Deal finalized' : 'Awaiting completion...',
                inq.status == 'Closed',
              ),
          ],

          if (inq.quotedPrice != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Tax GST Billing Invoice Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Base Item Amount (${inq.quantity})', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                      Text('₹${baseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GST (${inq.gstPercent.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      Text('₹${gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Billing Amount (incl. GST)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('₹${totalInvoice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (inq.status == 'Quote Sent') ...[
            const SizedBox(height: 24),
            if (_isUpdating)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('Rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Reject Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('Closed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
          ],
          
          if (inq.status == 'Closed') ...[
            const SizedBox(height: 24),
            if (inq.deliveryStatus == 'Delivered') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Confirm Received Material',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Supplier marked the package as delivered. Take a photo of the received material to confirm delivery and close the order.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    if (_materialPhotoBase64 != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BuildMartImage(
                          imageUrl: _materialPhotoBase64!,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: _pickMaterialPhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_materialPhotoBase64 != null ? 'Retake Photo' : 'Take Material Photo'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (_materialPhotoBase64 != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _completeAndCloseOrder,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Confirm Delivery & Close Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Supplier is processing your order. You can upload delivery photo once marked as Delivered.',
                        style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          if (inq.status == 'Completed') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
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
            if (inq.images.isNotEmpty) ...[
              const Text(
                'Material Delivery Photo (Uploaded by You):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BuildMartImage(
                  imageUrl: inq.images.last,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (inq.rating != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Review:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (idx) {
                        return Icon(
                          idx < inq.rating! ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    if (inq.reviewText != null && inq.reviewText!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('"${inq.reviewText}"', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              ),
            ] else ...[
              const Text('Rate Supplier Service & Materials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (idx) {
                  return IconButton(
                    icon: Icon(
                      idx < _ratingInput ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() => _ratingInput = idx + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Leave feedback notes...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSubmittingReview ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmittingReview
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Submit Rating & Review'),
              ),
            ],
          ],
          
          if (_timelineLogs.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Timeline Update History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timelineLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 16, color: Colors.grey),
                itemBuilder: (context, index) {
                  final log = _timelineLogs[index];
                  final dateStr = log['created_at'] != null 
                      ? log['created_at'].toString().split('T')[0] 
                      : '';
                  final rawNotes = log['notes'] ?? '';
                  String displayNotes = rawNotes;
                  if (rawNotes == 'Quote proposed to the buyer.') {
                    displayNotes = 'Quote proposed by seller.';
                  } else if (rawNotes == 'Generated a revised quote for the buyer.') {
                    displayNotes = 'Revised quote proposed by seller.';
                  } else {
                    displayNotes = rawNotes
                        .replaceAll('buyer', 'seller')
                        .replaceAll('Buyer', 'Seller');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(log['status'] ?? '').withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log['status'] == 'Quote Sent' ? 'Quote Received' : (log['status'] ?? 'Updated'),
                              style: TextStyle(
                                color: _getStatusColor(log['status'] ?? ''),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayNotes,
                        style: const TextStyle(fontSize: 12.5, height: 1.3),
                      ),
                      if (log['changed_by_name'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'By: ${log['changed_by_name']}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Dismiss Tracker'),
          ),
        ],
      ),
    );
  }
}
