import 'package:flutter/material.dart';
import 'package:construction_app/core/widgets/bento.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:construction_app/core/api_http.dart' as http;
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


    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final hPad = width >= 700 ? 24.0 : (width < 380 ? 14.0 : 18.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leads',
                              style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1, color: Bento.text(dark)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _isLoading
                                  ? 'Finding work near you…'
                                  : '${_allLeads.length} project · ${_allMaterialLeads.length} material',
                              style: TextStyle(fontSize: 13, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      BentoCircleButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh leads',
                        onPressed: () => _fetchLeads(),
                      ),
                    ],
                  ),
                ),

                // Project / material switch
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: BentoSegmented(
                    labels: ['Projects (${_allLeads.length})', 'Materials (${_allMaterialLeads.length})'],
                    icons: const [Icons.home_work_rounded, Icons.inventory_2_rounded],
                    index: _selectedSegment,
                    onChanged: (i) => setState(() {
                      _userSwitchedSegment = true;
                      _selectedSegment = i;
                      _applyFilter();
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Search
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: BentoSearchField(
                    controller: _searchController,
                    hint: _selectedSegment == 0 ? 'Search projects, clients, places' : 'Search material requests',
                    onChanged: (_) {},
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                          child: const ShimmerLeadsList(itemCount: 4),
                        )
                      : RefreshIndicator(
                          color: Bento.accent,
                          onRefresh: _fetchLeads,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(
                              key: ValueKey(_selectedSegment),
                              child: _selectedSegment == 0 ? _buildProjectLeadsView(hPad, width) : _buildMaterialLeadsView(hPad),
                            ),
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

  // ===========================================================================
  // Project leads
  // ===========================================================================

  Widget _buildProjectLeadsView(double hPad, double width) {
    if (_filteredLeads.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 110),
        children: [
          BentoEmptyState(
            icon: Icons.radar_rounded,
            title: _searchController.text.isNotEmpty ? 'No matching leads' : 'No project leads right now',
            subtitle: _searchController.text.isNotEmpty
                ? 'Try another name, client or place.'
                : 'New projects in your category and city will appear here. Pull down to refresh.',
          ),
          if (_allMaterialLeads.isNotEmpty) ...[
            const SizedBox(height: Bento.gap),
            BentoCard(
              gradient: Bento.accentGradient,
              padding: const EdgeInsets.all(18),
              onTap: () => setState(() {
                _userSwitchedSegment = true;
                _selectedSegment = 1;
                _applyFilter();
              }),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_allMaterialLeads.length} material request${_allMaterialLeads.length == 1 ? '' : 's'} waiting',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Buyers want quotes for building materials.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
            ),
          ],
        ],
      );
    }

    final columns = width >= 700 ? 2 : 1;
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 110),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 172,
        crossAxisSpacing: Bento.gap,
        mainAxisSpacing: Bento.gap,
      ),
      itemCount: _filteredLeads.length,
      itemBuilder: (context, i) => _buildLeadCard(_filteredLeads[i]),
    );
  }

  Widget _buildLeadCard(dynamic lead) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = (lead['title'] ?? 'New project').toString();
    final client = (lead['userName'] ?? 'Client').toString();
    final type = (lead['type'] ?? '').toString();
    final location = (lead['location'] ?? '').toString();
    final budget = lead['budget'] is num ? lead['budget'] as num : null;
    final created = DateTime.tryParse((lead['createdAt'] ?? '').toString());
    final isNew = created != null && DateTime.now().difference(created).inHours < 48;

    return BentoCard(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        await context.push('/provider-lead/${lead['id']}');
        _fetchLeads(silent: true);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BentoIconBubble(icon: Icons.home_work_rounded, color: Bento.accent, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Bento.text(dark)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.isEmpty ? client : '$client · $type',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Bento.muted(dark)),
                    ),
                  ],
                ),
              ),
              if (isNew) const BentoPill(label: 'NEW', color: Bento.accent, icon: Icons.bolt_rounded),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              if (location.isNotEmpty)
                Flexible(
                  child: BentoPill(label: location, color: Bento.muted(dark), background: Bento.surfaceAlt(dark), icon: Icons.place_rounded),
                ),
              const SizedBox(width: 6),
              if (budget != null)
                BentoPill(
                  label: '₹${NumberFormat.decimalPattern('en_IN').format(budget.round())}',
                  color: const Color(0xFF059669),
                  icon: Icons.account_balance_wallet_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'View & send quote',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Bento.accentText(dark)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 16, color: Bento.accentText(dark)),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Material inquiries
  // ===========================================================================

  Widget _buildMaterialLeadsView(double hPad) {
    if (_filteredMaterialLeads.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 110),
        children: [
          BentoEmptyState(
            icon: Icons.inventory_2_rounded,
            title: _searchController.text.isNotEmpty ? 'No matching requests' : 'No material requests yet',
            subtitle: 'Buyer requests for your products will show up here.',
            actionLabel: 'Open materials console',
            onAction: () => context.push('/b2b-materials'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 110),
      children: [
        BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => context.push('/b2b-materials'),
          child: Row(
            children: [
              const BentoIconBubble(icon: Icons.hub_rounded, color: Bento.violet, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Orders & delivery tracking',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Bento.text(Theme.of(context).brightness == Brightness.dark)),
                ),
              ),
              const Icon(Icons.north_east_rounded, size: 18),
            ],
          ),
        ),
        const SizedBox(height: Bento.gap),
        for (final lead in _filteredMaterialLeads) ...[
          _buildMaterialLeadCard(lead),
          const SizedBox(height: Bento.gap),
        ],
      ],
    );
  }

  Widget _buildMaterialLeadCard(dynamic lead) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final status = (lead['status'] ?? 'New').toString();
    final title = (lead['title'] ?? 'Material requirement').toString();
    final desc = (lead['description'] ?? '').toString();
    final quantity = lead['quantity']?.toString() ?? '0';
    final unit = (lead['unit'] ?? 'units').toString();
    final location = (lead['location'] ?? '').toString();
    final date = lead['created_at'] != null ? lead['created_at'].toString().split('T').first : '';
    final buyerName = (lead['buyer_name'] ?? 'Customer').toString();
    final buyerId = (lead['buyer_id'] ?? '').toString();

    Color statusColor = Bento.blue;
    if (status == 'Quote Sent') statusColor = Bento.violet;
    if (status == 'Accepted' || status == 'Closed') statusColor = Bento.green;
    if (status == 'Rejected' || status == 'Lead Rejected') statusColor = Bento.red;

    return BentoCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/b2b-materials'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BentoPill(label: status, color: statusColor),
              const Spacer(),
              if (date.isNotEmpty) Text(date, style: TextStyle(fontSize: 11.5, color: Bento.muted(dark), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: Bento.text(dark)),
          ),
          if (desc.isNotEmpty && desc != 'none') ...[
            const SizedBox(height: 4),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: Bento.muted(dark), height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              BentoPill(label: '$quantity $unit', color: Bento.accentText(dark), icon: Icons.shopping_bag_rounded),
              if (location.isNotEmpty && location != 'none')
                BentoPill(label: location, color: Bento.muted(dark), background: Bento.surfaceAlt(dark), icon: Icons.place_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Bento.surfaceAlt(dark), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                BentoAvatar(name: buyerName, size: 34, ring: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(buyerName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Bento.text(dark))),
                      if (date.isNotEmpty)
                        Text(
                          'Requested $date',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Bento.muted(dark)),
                        ),
                    ],
                  ),
                ),
                if (buyerId.isNotEmpty)
                  BentoCircleButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: Bento.accentText(dark),
                    tooltip: 'Chat with customer',
                    onPressed: () => context.push('/provider-chat/$buyerId?name=${Uri.encodeQueryComponent(buyerName)}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BentoButton(label: 'Send quote', icon: Icons.send_rounded, expand: true, onTap: () => context.push('/b2b-materials')),
        ],
      ),
    );
  }
}
