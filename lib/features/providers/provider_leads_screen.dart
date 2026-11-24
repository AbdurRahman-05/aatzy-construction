import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../core/constants.dart';
import '../../core/providers/notifications_provider.dart';
import '../../core/providers/provider_data_provider.dart';
import '../auth/auth_provider.dart';
import 'provider_layout.dart';
import '../../core/widgets/shimmer_loading.dart';

class ProviderLeadsScreen extends ConsumerStatefulWidget {
  const ProviderLeadsScreen({super.key});

  @override
  ConsumerState<ProviderLeadsScreen> createState() => _ProviderLeadsScreenState();
}

class _ProviderLeadsScreenState extends ConsumerState<ProviderLeadsScreen> with WidgetsBindingObserver {
  List<dynamic> _allLeads = [];
  List<dynamic> _filteredLeads = [];
  List<dynamic> _allMaterialLeads = [];
  List<dynamic> _filteredMaterialLeads = [];
  int _selectedSegment = 0; // 0: Project Leads, 1: Material Inquiries
  bool _userSwitchedSegment = false;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);

    // If leads were already pre-populated into providerLeadsProvider, load them instantly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cached = ref.read(providerLeadsProvider);
      if (cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allLeads = cached;
            _applyFilter();
            _isLoading = false;
          });
        }
      }
      _fetchLeads(silent: cached.isNotEmpty);
    });

    // Auto-poll silently every 20 seconds while user is active on the Leads tab
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && ref.read(providerTabProvider) == 2) {
        _fetchLeads(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && ref.read(providerTabProvider) == 2) {
      _fetchLeads(silent: true);
    }
  }

  Future<void> _fetchLeads({bool silent = false}) async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!silent && _allLeads.isEmpty && _allMaterialLeads.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats')),
        http.get(Uri.parse('$apiBaseUrl/supplier/leads?supplierId=${auth.id}')),
      ]);

      final resStats = responses[0];
      final resMaterials = responses[1];

      if (resStats.statusCode == 404) {
        ref.read(authProvider.notifier).forceLogout(reason: 'Your account has been deleted by an administrator.');
        return;
      }

      List<dynamic> leads = [];
      if (resStats.statusCode == 200) {
        final data = jsonDecode(resStats.body);
        leads = (data['allLeads'] as List? ?? []);
        ref.read(providerLeadsProvider.notifier).setLeads(leads);
      }

      List<dynamic> materialLeads = [];
      if (resMaterials.statusCode == 200) {
        final matData = jsonDecode(resMaterials.body);
        materialLeads = (matData['leads'] as List? ?? []);
      }

      if (mounted) {
        setState(() {
          _allLeads = leads;
          _allMaterialLeads = materialLeads;
          // If the user hasn't explicitly tapped a tab, and there are 0 project leads but >0 material leads,
          // automatically default to the Material Inquiries tab so vendors are not greeted with an empty screen.
          if (!_userSwitchedSegment && _allLeads.isEmpty && _allMaterialLeads.isNotEmpty) {
            _selectedSegment = 1;
          }
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredLeads = List.from(_allLeads);
      _filteredMaterialLeads = List.from(_allMaterialLeads);
    } else {
      _filteredLeads = _allLeads.where((lead) {
        final title = (lead['title'] ?? '').toString().toLowerCase();
        final location = (lead['location'] ?? '').toString().toLowerCase();
        final client = (lead['userName'] ?? '').toString().toLowerCase();
        return title.contains(query) || location.contains(query) || client.contains(query);
      }).toList();

      _filteredMaterialLeads = _allMaterialLeads.where((lead) {
        final title = (lead['title'] ?? '').toString().toLowerCase();
        final location = (lead['location'] ?? '').toString().toLowerCase();
        final client = (lead['buyer_name'] ?? '').toString().toLowerCase();
        final desc = (lead['description'] ?? '').toString().toLowerCase();
        return title.contains(query) || location.contains(query) || client.contains(query) || desc.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Sync immediately whenever providerLeadsProvider updates
    ref.listen<List<dynamic>>(providerLeadsProvider, (prev, next) {
      if (mounted && next != _allLeads) {
        setState(() {
          _allLeads = next;
          _applyFilter();
          _isLoading = false;
        });
      }
    });

    // 2. Auto-fetch fresh leads when user navigates to the Leads tab (tab 2)
    ref.listen<int>(providerTabProvider, (prev, next) {
      if (next == 2 && prev != 2) {
        _fetchLeads(silent: _allLeads.isNotEmpty || _allMaterialLeads.isNotEmpty);
      }
    });

    // 3. Listen to explicit refresh triggers (e.g. re-tapping Leads tab icon)
    ref.listen<int>(providerLeadsRefreshTriggerProvider, (prev, next) {
      if (next != prev) {
        _fetchLeads(silent: _allLeads.isNotEmpty || _allMaterialLeads.isNotEmpty);
      }
    });

    // 4. Auto-refresh when notifications update
    ref.listen(notificationsProvider, (prev, next) {
      if (next.length != prev?.length) {
        _fetchLeads(silent: true);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 700;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_selectedSegment == 0 ? 'Project Leads' : 'Material Inquiries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Leads',
            onPressed: () => _fetchLeads(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Segmented Switcher: Project Leads vs Material Inquiries
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _userSwitchedSegment = true;
                              _selectedSegment = 0;
                              _applyFilter();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedSegment == 0
                                  ? const Color(0xFF0F766E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedSegment == 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_center_outlined,
                                  size: 16,
                                  color: _selectedSegment == 0
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Projects (${_allLeads.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedSegment == 0
                                        ? Colors.white
                                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _userSwitchedSegment = true;
                              _selectedSegment = 1;
                              _applyFilter();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedSegment == 1
                                  ? const Color(0xFF0F766E)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedSegment == 1
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: _selectedSegment == 1
                                      ? Colors.white
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Materials (${_allMaterialLeads.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _selectedSegment == 1
                                        ? Colors.white
                                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  ),
                                ),
                                if (_allMaterialLeads.isNotEmpty && _selectedSegment != 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_allMaterialLeads.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: _selectedSegment == 0 ? 'Search project leads...' : 'Search material inquiries...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
              ),

              // Leads / Inquiries Content
              Expanded(
                child: _isLoading
                    ? const ShimmerLeadsList(itemCount: 4)
                    : RefreshIndicator(
                        onRefresh: _fetchLeads,
                        child: _selectedSegment == 0
                            ? _buildProjectLeadsView(horizontalPadding, isTablet, isDark)
                            : _buildMaterialLeadsView(horizontalPadding, isTablet, isDark),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectLeadsView(double horizontalPadding, bool isTablet, bool isDark) {
    if (_filteredLeads.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No leads found matching your category and location.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
          if (_allMaterialLeads.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              color: isDark ? const Color(0xFF0F766E).withValues(alpha: 0.15) : const Color(0xFFF0FDFA),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFF0F766E), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You have ${_allMaterialLeads.length} Material Inquiries waiting!',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buyers are requesting quotes for bulk building materials. Tap below to view your inquiries and submit quotations.',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _userSwitchedSegment = true;
                            _selectedSegment = 1;
                            _applyFilter();
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text('View ${_allMaterialLeads.length} Material Inquiries'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return isTablet
        ? GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredLeads.length,
            itemBuilder: (context, index) {
              return _buildLeadCard(_filteredLeads[index]);
            },
          )
        : ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: _filteredLeads.length,
            itemBuilder: (context, index) {
              return _buildLeadCard(_filteredLeads[index]);
            },
          );
  }

  Widget _buildMaterialLeadsView(double horizontalPadding, bool isTablet, bool isDark) {
    if (_filteredMaterialLeads.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
        children: [
          const Center(
            child: Text(
              'No material inquiries found matching your search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => context.push('/b2b-materials'),
              icon: const Icon(Icons.hub_outlined, size: 16),
              label: const Text('Open Materials Hub Console'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      children: [
        // Quick shortcut to full Materials Console
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hub_outlined, color: Color(0xFF0F766E), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Materials Order Console & Delivery Tracking',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/b2b-materials'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFF0F766E),
                ),
                child: const Text('Open Console ↗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        // List of Material Inquiry Cards
        ..._filteredMaterialLeads.map((lead) => _buildMaterialLeadCard(lead)),
      ],
    );
  }

  Widget _buildMaterialLeadCard(dynamic lead) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = (lead['status'] ?? 'New').toString();
    final title = (lead['title'] ?? 'Material Requirement').toString();
    final desc = (lead['description'] ?? '').toString();
    final quantity = lead['quantity']?.toString() ?? '0';
    final unit = (lead['unit'] ?? 'Units').toString();
    final location = (lead['location'] ?? 'Madurai').toString();
    final date = lead['created_at'] != null ? lead['created_at'].toString().split('T').first : '';
    final buyerName = (lead['buyer_name'] ?? 'Customer').toString();
    final buyerEmail = (lead['buyer_email'] ?? '').toString();
    final buyerPhone = (lead['buyer_phone'] ?? '').toString();

    Color statusColor = Colors.blue;
    if (status == 'Quote Sent') statusColor = Colors.purple;
    if (status == 'Accepted' || status == 'Closed') statusColor = Colors.green;
    if (status == 'Rejected' || status == 'Lead Rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/b2b-materials'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (date.isNotEmpty)
                    Text(
                      'DATE: $date',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (desc.isNotEmpty && desc != 'none') ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(Icons.shopping_bag_outlined, 'Qty: $quantity $unit'),
                  if (location.isNotEmpty && location != 'none')
                    _buildChip(Icons.location_on_outlined, location),
                ],
              ),
              const Divider(height: 20, color: Colors.grey),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 18, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        if (buyerEmail.isNotEmpty || buyerPhone.isNotEmpty)
                          Text(
                            [
                              if (buyerEmail.isNotEmpty) 'Email: $buyerEmail',
                              if (buyerPhone.isNotEmpty) 'Ph: $buyerPhone',
                            ].join(' | '),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/b2b-materials'),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send Quote'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        foregroundColor: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling Buyer $buyerName: ${buyerPhone.isNotEmpty ? buyerPhone : buyerEmail}...')),
                        );
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text('Call Buyer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0F766E)),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLeadCard(dynamic lead) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
          child: const Icon(Icons.business_center, color: Colors.blue),
        ),
        title: Text(
          lead['title'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: ${lead['userName'] ?? 'Unknown'}'),
            if (lead['type'] != null && lead['type'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Category: ${lead['type']}',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lead['location'] ?? 'N/A',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (lead['budget'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Text(
                      '₹${(lead['budget'] as num).toInt().toString()}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await context.push('/provider-lead/${lead['id']}');
          _fetchLeads(silent: true); // refresh silently on returning
        },
      ),
    );
  }
}
