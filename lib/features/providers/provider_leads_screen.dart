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
// import '../../core/services/subscription_service.dart';
// import '../subscription/widgets/provider_subscription_modal.dart';
import '../../core/widgets/shimmer_loading.dart';

class ProviderLeadsScreen extends ConsumerStatefulWidget {
  const ProviderLeadsScreen({super.key});

  @override
  ConsumerState<ProviderLeadsScreen> createState() => _ProviderLeadsScreenState();
}

class _ProviderLeadsScreenState extends ConsumerState<ProviderLeadsScreen> with WidgetsBindingObserver {
  List<dynamic> _allLeads = [];
  List<dynamic> _filteredLeads = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);

    // If leads were already pre-populated into providerLeadsProvider (e.g. from ProviderDashboard), load them instantly
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

    if (!silent && _allLeads.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats'));
      if (response.statusCode == 404) {
        ref.read(authProvider.notifier).forceLogout(reason: 'Your account has been deleted by an administrator.');
        return;
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final leads = (data['allLeads'] as List? ?? []);
        ref.read(providerLeadsProvider.notifier).setLeads(leads);
        if (mounted) {
          setState(() {
            _allLeads = leads;
            _applyFilter();
            _isLoading = false;
          });
        }
      } else {
        if (mounted && _isLoading) setState(() => _isLoading = false);
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
    } else {
      _filteredLeads = _allLeads.where((lead) {
        final title = (lead['title'] ?? '').toString().toLowerCase();
        final location = (lead['location'] ?? '').toString().toLowerCase();
        final client = (lead['userName'] ?? '').toString().toLowerCase();
        return title.contains(query) || location.contains(query) || client.contains(query);
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
    // 1. Sync immediately whenever providerLeadsProvider updates (e.g. from Dashboard or other screens)
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
        _fetchLeads(silent: _allLeads.isNotEmpty);
      }
    });

    // 3. Listen to explicit refresh triggers (e.g. re-tapping Leads tab icon)
    ref.listen<int>(providerLeadsRefreshTriggerProvider, (prev, next) {
      if (next != prev) {
        _fetchLeads(silent: _allLeads.isNotEmpty);
      }
    });

    // 4. Auto-refresh when notifications update (e.g. new lead notification arrived via 20s poll)
    ref.listen(notificationsProvider, (prev, next) {
      if (next.length != prev?.length) {
        _fetchLeads(silent: true);
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 700;
    final horizontalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Project Leads'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search leads...',
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
              Expanded(
                child: _isLoading
                    ? const ShimmerLeadsList(itemCount: 4)
                    : RefreshIndicator(
                        onRefresh: _fetchLeads,
                        child: _filteredLeads.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: Center(
                                      child: Text(
                                        'No leads found matching your category and location.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : isTablet
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
                                  ),
                      ),
              ),
            ],
          ),
        ),
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
          // final subState = ref.read(subscriptionProvider);
          // if (!subState.isSubscribed) {
          //   showProviderSubscriptionModal(context);
          //   return;
          // }
          await context.push('/provider-lead/${lead['id']}');
          _fetchLeads(silent: true); // refresh silently on returning
        },
      ),
    );
  }
}
