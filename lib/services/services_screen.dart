import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/social_feed_provider.dart';
import '../core/providers/notifications_provider.dart';
import '../features/providers/provider_profile_screen.dart';
import '../core/widgets/shimmer_loading.dart';
import '../core/widgets/bento.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  int _selectedTab = 0; // 0 for Services, 1 for Portfolio
  String _selectedPortfolioFilter = 'All Projects';
  final Set<String> _bookmarkedProjects = {};
  String _serviceSearchQuery = '';

  final List<Map<String, dynamic>> categories = const [
    // --- Original Main Categories ---
    {'name': 'Land & Legal', 'icon': Icons.gavel_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Finance & Approvals', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF059669), 'bg': Color(0xFFECFDF5)},
    {'name': 'Survey & Analysis', 'icon': Icons.explore_rounded, 'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Design & Planning', 'icon': Icons.architecture_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFFAF5FF)},
    {'name': 'Construction', 'icon': Icons.construction_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFF0F9FF)},
    {'name': 'Engineering (MEP)', 'icon': Icons.settings_rounded, 'color': Color(0xFF10B981), 'bg': Color(0xFFECFDF5)},
    {'name': 'Materials & Supply', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFFE11D48), 'bg': Color(0xFFFFF1F2)},
    {'name': 'LED Walls & Digital Displays', 'icon': Icons.smart_display_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Utilities', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF59E0B), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Borewell', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF06B6D4), 'bg': Color(0xFFECFEFF)},
    {'name': 'Interiors & Finishing', 'icon': Icons.chair_rounded, 'color': Color(0xFF8B5CF6), 'bg': Color(0xFFF5F3FF)},
    {'name': 'Project Management', 'icon': Icons.assignment_rounded, 'color': Color(0xFF4F46E5), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Inspection & Compliance', 'icon': Icons.verified_user_rounded, 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEF2F2)},
    {'name': 'Smart & Security', 'icon': Icons.shield_rounded, 'color': Color(0xFF3B82F6), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Logistics & Equipment', 'icon': Icons.local_shipping_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Insurance', 'icon': Icons.umbrella_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFF0FDF4)},

    // --- Detailed Construction Services ---
    {'name': 'Blacksmith', 'icon': Icons.hardware_rounded, 'color': Color(0xFF4B5563), 'bg': Color(0xFFF0EEEA)},
    {'name': 'Bricklayer/Stonemason', 'icon': Icons.view_module_rounded, 'color': Color(0xFFB45309), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Builder/General Contractor', 'icon': Icons.apartment_rounded, 'color': Color(0xFF0F766E), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Cabinet Maker', 'icon': Icons.kitchen_rounded, 'color': Color(0xFF78350F), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Carpenter', 'icon': Icons.carpenter_rounded, 'color': Color(0xFF92400E), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Cement / Concrete', 'icon': Icons.foundation_rounded, 'color': Color(0xFF6B7280), 'bg': Color(0xFFF6F5F2)},
    {'name': 'Commercial Builder', 'icon': Icons.domain_rounded, 'color': Color(0xFF0F766E), 'bg': Color(0xFFF0FDFA)},
    {'name': 'Construction (Other)', 'icon': Icons.build_circle_rounded, 'color': Color(0xFF2E333D), 'bg': Color(0xFFF0EEEA)},
    {'name': 'Construction Project Management', 'icon': Icons.assignment_turned_in_rounded, 'color': Color(0xFF4338CA), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Counter Top', 'icon': Icons.countertops_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},
    {'name': 'Demolition Contractor', 'icon': Icons.delete_sweep_rounded, 'color': Color(0xFFB91C1C), 'bg': Color(0xFFFEF2F2)},
    {'name': 'Drainage', 'icon': Icons.water_damage_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Drywall', 'icon': Icons.grid_on_rounded, 'color': Color(0xFF4B5563), 'bg': Color(0xFFF0EEEA)},
    {'name': 'Electrical Contractor', 'icon': Icons.electrical_services_rounded, 'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Electrician - Commercial', 'icon': Icons.bolt_rounded, 'color': Color(0xFFEAB308), 'bg': Color(0xFFFEF9C3)},
    {'name': 'Elevator', 'icon': Icons.elevator_rounded, 'color': Color(0xFF6366F1), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Energy Services', 'icon': Icons.energy_savings_leaf_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Environmental Services', 'icon': Icons.eco_rounded, 'color': Color(0xFF059669), 'bg': Color(0xFFD1FAE5)},
    {'name': 'Fences', 'icon': Icons.fence_rounded, 'color': Color(0xFF854D0E), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Fireplace & Oven Builder', 'icon': Icons.fireplace_rounded, 'color': Color(0xFFC2410C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Flooring', 'icon': Icons.layers_rounded, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFEDE9FE)},
    {'name': 'Garage Doors', 'icon': Icons.garage_rounded, 'color': Color(0xFF181B22), 'bg': Color(0xFFF0EEEA)},
    {'name': 'Glass', 'icon': Icons.window_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Ground Work', 'icon': Icons.terrain_rounded, 'color': Color(0xFF9A3412), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Handyman', 'icon': Icons.handyman_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Heating Engineer', 'icon': Icons.thermostat_rounded, 'color': Color(0xFFBE123C), 'bg': Color(0xFFFFE4E6)},
    {'name': 'HVAC - Heating & Air', 'icon': Icons.hvac_rounded, 'color': Color(0xFF0369A1), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Interior Design - Commercial', 'icon': Icons.business_center_rounded, 'color': Color(0xFF6D28D9), 'bg': Color(0xFFF5F3FF)},
    {'name': 'Interior Design - Residential', 'icon': Icons.chair_rounded, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFEDE9FE)},
    {'name': 'Kitchen Construction', 'icon': Icons.soup_kitchen_rounded, 'color': Color(0xFFC2410C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Metal Work', 'icon': Icons.precision_manufacturing_rounded, 'color': Color(0xFF4B5563), 'bg': Color(0xFFF0EEEA)},
    {'name': 'Painter', 'icon': Icons.format_paint_rounded, 'color': Color(0xFFDB2777), 'bg': Color(0xFFFCE7F3)},
    {'name': 'Pest Control', 'icon': Icons.pest_control_rounded, 'color': Color(0xFF15803D), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Plasterer', 'icon': Icons.imagesearch_roller_rounded, 'color': Color(0xFF6B7280), 'bg': Color(0xFFF6F5F2)},
    {'name': 'Plumbing', 'icon': Icons.plumbing_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Pools, Spas & Saunas', 'icon': Icons.pool_rounded, 'color': Color(0xFF0891B2), 'bg': Color(0xFFCFFAFE)},
    {'name': 'Power Generator', 'icon': Icons.power_rounded, 'color': Color(0xFFCA8A04), 'bg': Color(0xFFFEF08A)},
    {'name': 'Power Washing', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFDBEAFE)},
    {'name': 'Protective Coatings/Sealants', 'icon': Icons.format_color_fill_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFF3E8FF)},
    {'name': 'Renovations/Remodeling', 'icon': Icons.home_repair_service_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Restoration', 'icon': Icons.restore_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},
    {'name': 'Roofing & Gutters', 'icon': Icons.roofing_rounded, 'color': Color(0xFFB45309), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Septic Systems', 'icon': Icons.water_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Shutters & Awnings', 'icon': Icons.blinds_rounded, 'color': Color(0xFF4B5563), 'bg': Color(0xFFF0EEEA)},
    {'name': 'Solar', 'icon': Icons.solar_power_rounded, 'color': Color(0xFFEAB308), 'bg': Color(0xFFFEF9C3)},
    {'name': 'Tile Worker', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF4F46E5), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Waterproofing-Weatherproofing', 'icon': Icons.umbrella_rounded, 'color': Color(0xFF0369A1), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Window Treatments', 'icon': Icons.curtains_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFFAF5FF)},
    {'name': 'Windows & Doors', 'icon': Icons.door_sliding_rounded, 'color': Color(0xFF6B7280), 'bg': Color(0xFFF6F5F2)},
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSocialFeed();
    });
  }

  Future<void> _fetchSocialFeed() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      ref.invalidate(socialFeedProvider);
      await ref.read(socialFeedProvider.future);
    } catch (e) {
      debugPrint('Services fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    try {
      ref.invalidate(socialFeedProvider);
      ref.invalidate(notificationsProvider);
      await ref.read(socialFeedProvider.future);
    } catch (e) {
      debugPrint('Services onRefresh error: $e');
    }
  }

  final _serviceSearchController = TextEditingController();

  @override
  void dispose() {
    _serviceSearchController.dispose();
    super.dispose();
  }

  void _setServiceQuery(String value) {
    _serviceSearchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _serviceSearchQuery = value);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(notificationsProvider).where((n) => n.isUnread).length;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final hPad = screenWidth >= 700 ? 24.0 : (isSmallScreen ? 14.0 : 18.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Market',
                              style: TextStyle(fontSize: 28, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -1, color: Bento.text(dark)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _selectedTab == 0
                                  ? '${categories.length} services from verified partners'
                                  : 'Recent work by Connectzy partners',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Bento.muted(dark), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      BentoBadgeButton(
                        icon: Icons.notifications_none_rounded,
                        count: unreadCount,
                        onTap: () => context.push('/notifications'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: BentoSegmented(
                    labels: const ['Services', 'Portfolio'],
                    icons: const [Icons.grid_view_rounded, Icons.photo_library_rounded],
                    index: _selectedTab,
                    onChanged: (i) => setState(() => _selectedTab = i),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Bento.accent,
                    child: _selectedTab == 0
                        ? _buildServicesView(isSmallScreen, screenWidth, hPad)
                        : _buildPortfolioView(isSmallScreen, screenWidth, hPad),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SERVICES TAB VIEW (bento)
  // ==========================================
  Widget _buildServicesView(bool isSmallScreen, double screenWidth, double hPad) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final query = _serviceSearchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? categories
        : categories.where((c) => (c['name'] as String).toLowerCase().contains(query)).toList();

    const quickFilters = [
      ('All', ''),
      ('LED Walls', 'LED'),
      ('Interiors', 'Interior'),
      ('Contractors', 'Contractor'),
      ('Electrical', 'Electrical'),
      ('Materials', 'Material'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 900 ? 5 : (w >= 650 ? 4 : 3);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 110),
          children: [
            // Bento hero row
            SizedBox(
              height: 172,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: BentoCard(
                      gradient: Bento.inkGradient,
                      padding: EdgeInsets.zero,
                      onTap: () => context.push('/create-project'),
                      child: Stack(
                        children: [
                          const Positioned(right: -50, top: -60, child: BentoGlow(size: 170)),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BentoPill(
                                  label: 'ONE-STOP',
                                  color: Bento.accentLight,
                                  background: Bento.accentLight.withValues(alpha: 0.14),
                                  icon: Icons.bolt_rounded,
                                ),
                                const Spacer(),
                                const Text(
                                  'Post a project,\nget quotes',
                                  style: TextStyle(color: Colors.white, fontSize: 19, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                ),
                                const SizedBox(height: 6),
                                const Row(
                                  children: [
                                    Text('Start now', style: TextStyle(color: Bento.accentLight, fontSize: 12.5, fontWeight: FontWeight.w800)),
                                    SizedBox(width: 3),
                                    Icon(Icons.arrow_forward_rounded, color: Bento.accentLight, size: 15),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Bento.gap),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: _sideTile(dark, Icons.verified_rounded, 'All partners', 'Verified pros', Bento.accent,
                              () => context.push('/providers/All')),
                        ),
                        const SizedBox(height: Bento.gap),
                        Expanded(
                          child: _sideTile(dark, Icons.shopping_cart_rounded, 'Materials', 'Wholesale prices', Bento.violet,
                              () => context.push('/b2b-products')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            BentoSearchField(
              controller: _serviceSearchController,
              hint: 'Search ${categories.length}+ services',
              onChanged: (val) => setState(() => _serviceSearchQuery = val.trim()),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (label, value) = quickFilters[i];
                  final selected = value.isEmpty ? query.isEmpty : query == value.toLowerCase();
                  return BentoPressable(
                    onTap: () => _setServiceQuery(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? (dark ? Colors.white : Bento.ink) : Bento.surface(dark),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: selected ? Colors.transparent : Bento.border(dark)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: selected ? (dark ? Bento.ink : Colors.white) : Bento.text(dark),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),

            BentoSectionHeader(
              title: query.isEmpty ? 'All services' : 'Results (${filtered.length})',
              actionLabel: query.isEmpty ? 'All partners' : 'Clear',
              onAction: () => query.isEmpty ? context.push('/providers/All') : _setServiceQuery(''),
            ),

            if (filtered.isEmpty)
              BentoEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No services matching "$_serviceSearchQuery"',
                subtitle: 'Try "LED", "Interior" or "Builder".',
                actionLabel: 'Reset search',
                onAction: () => _setServiceQuery(''),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisExtent: isSmallScreen ? 112 : 118,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final cat = filtered[i];
                  final color = cat['color'] as Color? ?? Bento.accent;
                  return BentoCard(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
                    radius: 20,
                    color: dark
                        ? Color.alphaBlend(color.withValues(alpha: 0.12), Bento.surface(true))
                        : Color.alphaBlend(color.withValues(alpha: 0.06), Colors.white),
                    onTap: () => context.push('/providers/${Uri.encodeComponent(cat['name'])}'),
                    child: Column(
                      children: [
                        BentoIconBubble(icon: cat['icon'] as IconData, color: color, size: 40),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
                            child: Text(
                              cat['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10.5 : 11.5,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Bento.text(dark),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 22),

            // Custom requirement CTA
            BentoCard(
              gradient: Bento.accentGradient,
              padding: const EdgeInsets.all(18),
              onTap: () => context.push('/create-project'),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Have a custom requirement?',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Describe it once and get quotes from matching partners.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sideTile(bool dark, IconData icon, String title, String caption, Color color, VoidCallback onTap) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          BentoIconBubble(icon: icon, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Bento.text(dark)),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Bento.muted(dark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================
  // PORTFOLIO TAB VIEW (Live Builder Showcases Only)
  // ==========================================
  Widget _buildPortfolioView(bool isSmallScreen, double screenWidth, double horizontalPadding) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterOptions = ['All Projects', 'Residential', 'Commercial', 'Interior', 'Infrastructure'];
    final socialAsync = ref.watch(socialFeedProvider);
    final socialPosts = socialAsync.value ?? [];

    // Transform dynamic social feed posts into portfolio builder inspirations
    final List<Map<String, dynamic>> combinedPortfolio = [];

    for (int i = 0; i < socialPosts.length; i++) {
      final post = socialPosts[i];
      final provider = post['provider'] ?? {};
      final builderName = provider['businessName'] ?? provider['ownerName'] ?? 'Verified Builder';
      final location = provider['city'] ?? post['location'] ?? 'Chennai, Tamil Nadu';
      final title = post['title'] ?? post['caption'] ?? 'Modern Architectural Inspiration';
      final rawCategory = (provider['category'] ?? post['category'] ?? 'Residential').toString();
      final category = rawCategory.contains(',') ? rawCategory.split(',').first.trim() : rawCategory;
      final imageData = post['imageData'] as String?;
      final imageUrl = post['imageUrl'] as String?;
      final providerId = provider['id']?.toString() ?? '';

      Color tagColor = const Color(0xFF10B981);
      Color tagBg = const Color(0xFFECFDF5);
      final lowerCat = rawCategory.toLowerCase();
      if (lowerCat.contains('interior')) {
        tagColor = const Color(0xFFF59E0B);
        tagBg = const Color(0xFFFFFBEB);
      } else if (lowerCat.contains('commercial')) {
        tagColor = const Color(0xFF3B82F6);
        tagBg = const Color(0xFFEFF6FF);
      } else if (lowerCat.contains('infrastructure')) {
        tagColor = const Color(0xFF8B5CF6);
        tagBg = const Color(0xFFFAF5FF);
      }

      combinedPortfolio.add({
        'id': post['id']?.toString() ?? 'social_$i',
        'title': title,
        'builder': builderName,
        'providerId': providerId,
        'category': category,
        'rawCategory': rawCategory,
        'location': location,
        'area': post['area'] ?? '2,400 sq.ft',
        'year': post['year'] ?? '2025',
        'imageData': imageData,
        'image': imageUrl ?? '',
        'fallbackAsset': 'assets/images/build_plan_achieve.jpg',
        'tagColor': tagColor,
        'tagBg': tagBg,
        'isBuilderInspiration': true,
      });
    }

    final int totalCount = combinedPortfolio.length;
    final int residentialCount = combinedPortfolio.where((p) => (p['category'] as String).toLowerCase().contains('residential')).length;
    final int commercialCount = combinedPortfolio.where((p) => (p['category'] as String).toLowerCase().contains('commercial')).length;
    final int interiorCount = combinedPortfolio.where((p) => (p['category'] as String).toLowerCase().contains('interior')).length;
    final int infraCount = combinedPortfolio.where((p) => (p['category'] as String).toLowerCase().contains('infrastructure')).length;

    final filteredProjects = combinedPortfolio.where((p) {
      if (_selectedPortfolioFilter == 'All Projects') return true;
      final String cat = (p['rawCategory'] as String? ?? p['category'] as String).toLowerCase();
      final String filter = _selectedPortfolioFilter.toLowerCase();
      return cat.contains(filter) || filter.contains((p['category'] as String).toLowerCase());
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = _selectedPortfolioFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPortfolioFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F766E) : (isDark ? const Color(0xFF181B22) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F766E) : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFECEAE6)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? const Color(0xFF9AA1AD) : const Color(0xFF4B5563)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Completed Projects Hero Stat Card (Live Data)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181B22) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFECEAE6)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF111318).withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Project Showcases',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF9AA1AD) : const Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalCount > 0 ? totalCount.toString().padLeft(2, '0') : '00',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981), height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Verified contractor inspirations and live project showcases',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF9AA1AD) : const Color(0xFF6B7280), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Image.asset(
                        'assets/images/banner_building.jpg',
                        height: 90,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.domain_rounded, size: 70, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // 4 Category Stats Row
                Row(
                  children: [
                    _buildMiniStat(residentialCount.toString().padLeft(2, '0'), 'Residential', Icons.home_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
                    const SizedBox(width: 6),
                    _buildMiniStat(commercialCount.toString().padLeft(2, '0'), 'Commercial', Icons.domain_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
                    const SizedBox(width: 6),
                    _buildMiniStat(interiorCount.toString().padLeft(2, '0'), 'Interior', Icons.chair_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
                    const SizedBox(width: 6),
                    _buildMiniStat(infraCount.toString().padLeft(2, '0'), 'Infrastructure', Icons.add_road_rounded, const Color(0xFF8B5CF6), const Color(0xFFFAF5FF)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // "Builder Inspirations" Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Builder Inspirations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF111318)),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedPortfolioFilter = 'All Projects'),
                child: Row(
                  children: [
                    Text('View All ($totalCount)', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade600),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Builder Inspirations List
          if (_isLoading || (socialAsync.isLoading && combinedPortfolio.isEmpty))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: ShimmerSocialFeed(itemCount: 4),
            )
          else if (filteredProjects.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181B22) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0EEEA)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111318) : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 36),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No Showcases Found',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF111318)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPortfolioFilter == 'All Projects'
                        ? 'Contractor inspirations and live showcases will appear here.'
                        : 'No live showcases found under "$_selectedPortfolioFilter".',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProjects.length,
              itemBuilder: (context, index) {
                final project = filteredProjects[index];
                final isBookmarked = _bookmarkedProjects.contains(project['id']);
                final imageData = project['imageData'] as String?;
                final hasBase64 = imageData != null && imageData.isNotEmpty;
                final builder = project['builder'] as String? ?? 'Verified Builder';
                final providerId = project['providerId'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181B22) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0EEEA), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF111318).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: isSmallScreen ? 90 : 105,
                          height: isSmallScreen ? 90 : 105,
                          color: isDark ? const Color(0xFF111318) : const Color(0xFFF0EEEA),
                          child: hasBase64
                              ? Image.memory(
                                  base64Decode(imageData.contains(',') ? imageData.split(',').last : imageData),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image, size: 40, color: isDark ? const Color(0xFF4B5563) : Colors.grey),
                                )
                              : (project['image'] != null && (project['image'] as String).startsWith('http')
                                  ? Image.network(
                                      project['image'] as String,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Image.asset(
                                        project['fallbackAsset'] as String? ?? 'assets/images/build_plan_achieve.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      project['fallbackAsset'] as String? ?? 'assets/images/build_plan_achieve.jpg',
                                      fit: BoxFit.cover,
                                    )),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Project Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? (project['tagColor'] as Color? ?? const Color(0xFF10B981)).withValues(alpha: 0.2) : (project['tagBg'] as Color? ?? const Color(0xFFECFDF5)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        project['category'] as String? ?? 'Residential',
                                        style: TextStyle(
                                          color: project['tagColor'] as Color? ?? const Color(0xFF10B981),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isBookmarked) {
                                        _bookmarkedProjects.remove(project['id']);
                                      } else {
                                        _bookmarkedProjects.add(project['id'] as String);
                                      }
                                    });
                                  },
                                  child: Icon(
                                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                    size: 18,
                                    color: isBookmarked ? const Color(0xFF0F766E) : (isDark ? const Color(0xFF6B7280) : Colors.grey.shade400),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              project['title'] as String? ?? 'Architectural Project',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13.5 : 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF111318),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    builder,
                                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFD6D3CE) : Colors.grey.shade700, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 12),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 11, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade400),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    project['location'] as String? ?? 'Chennai',
                                    style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade500, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (providerId.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProviderProfileScreen(providerId: providerId),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF111318) : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_rounded, size: 11, color: Color(0xFF2563EB)),
                                          SizedBox(width: 3),
                                          Text(
                                            'Builder Profile',
                                            style: TextStyle(fontSize: 9.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    '${project['area']} • ${project['year']}',
                                    style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade600, fontWeight: FontWeight.w600),
                                  ),
                                GestureDetector(
                                  onTap: () => _showProjectDetailDialog(project),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF111318) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (project['tagColor'] as Color? ?? const Color(0xFF0F766E)).withValues(alpha: isDark ? 0.35 : 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      'View Project',
                                      style: TextStyle(
                                        color: project['tagColor'] as Color? ?? const Color(0xFF0F766E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),

          // Bottom "Have a project in mind?" Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF181B22),
                        const Color(0xFF111318),
                      ]
                    : [
                        const Color(0xFFF0FDF4),
                        const Color(0xFFEFF6FF),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111318) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Have a project in mind?',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF111318)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Let\'s build something amazing together',
                        style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/create-project'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Start a Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5)),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String count, String label, IconData icon, Color color, Color bg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111318) : bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetailDialog(Map<String, dynamic> project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageData = project['imageData'] as String?;
    final hasBase64 = imageData != null && imageData.isNotEmpty;
    final providerId = project['providerId'] as String? ?? '';
    final builder = project['builder'] as String? ?? 'Verified Builder';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF181B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? const Color(0xFF4B5563) : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: hasBase64
                    ? Image.memory(
                        base64Decode(imageData.contains(',') ? imageData.split(',').last : imageData),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image, size: 60, color: isDark ? const Color(0xFF4B5563) : Colors.grey),
                      )
                    : (project['image'] != null && (project['image'] as String).startsWith('http')
                        ? Image.network(
                            project['image'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              project['fallbackAsset'] as String? ?? 'assets/images/build_plan_achieve.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            project['fallbackAsset'] as String? ?? 'assets/images/build_plan_achieve.jpg',
                            fit: BoxFit.cover,
                          )),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project['title'] as String? ?? 'Architectural Project',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF111318)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? (project['tagColor'] as Color? ?? const Color(0xFF10B981)).withValues(alpha: 0.2) : (project['tagBg'] as Color? ?? const Color(0xFFECFDF5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      project['category'] as String? ?? 'Residential',
                      style: TextStyle(
                        color: project['tagColor'] as Color? ?? const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 4),
                Text(builder, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF181B22), fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 13),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(project['location'] as String? ?? 'Chennai', style: TextStyle(color: isDark ? const Color(0xFF9AA1AD) : Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF111318) : const Color(0xFFF0EEEA), borderRadius: BorderRadius.circular(8)),
                  child: Text('📐 Area: ${project['area']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFD6D3CE) : Colors.black87)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF111318) : const Color(0xFFF0EEEA), borderRadius: BorderRadius.circular(8)),
                  child: Text('📅 Year: ${project['year']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFD6D3CE) : Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (providerId.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderProfileScreen(providerId: providerId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_outline_rounded, size: 16),
                      label: const Text('Builder Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/create-project');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Start Similar Project', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
