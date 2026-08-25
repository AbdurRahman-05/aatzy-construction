import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/social_feed_provider.dart';
import '../core/providers/notifications_provider.dart';
import '../features/providers/provider_profile_screen.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  int _selectedTab = 0; // 0 for Services, 1 for Portfolio
  String _selectedPortfolioFilter = 'All Projects';
  final Set<String> _bookmarkedProjects = {};

  final List<Map<String, dynamic>> categories = const [
    // --- Original Main Categories ---
    {'name': 'Land & Legal', 'icon': Icons.gavel_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Finance & Approvals', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF059669), 'bg': Color(0xFFECFDF5)},
    {'name': 'Survey & Analysis', 'icon': Icons.explore_rounded, 'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Design & Planning', 'icon': Icons.architecture_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFFAF5FF)},
    {'name': 'Construction', 'icon': Icons.construction_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFF0F9FF)},
    {'name': 'Engineering (MEP)', 'icon': Icons.settings_rounded, 'color': Color(0xFF10B981), 'bg': Color(0xFFECFDF5)},
    {'name': 'Materials & Supply', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFFE11D48), 'bg': Color(0xFFFFF1F2)},
    {'name': 'Utilities', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF59E0B), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Borewell', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF06B6D4), 'bg': Color(0xFFECFEFF)},
    {'name': 'Interiors & Finishing', 'icon': Icons.chair_rounded, 'color': Color(0xFF8B5CF6), 'bg': Color(0xFFF5F3FF)},
    {'name': 'Project Management', 'icon': Icons.assignment_rounded, 'color': Color(0xFF4F46E5), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Inspection & Compliance', 'icon': Icons.verified_user_rounded, 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEF2F2)},
    {'name': 'Smart & Security', 'icon': Icons.shield_rounded, 'color': Color(0xFF3B82F6), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Logistics & Equipment', 'icon': Icons.local_shipping_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Insurance', 'icon': Icons.umbrella_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFF0FDF4)},

    // --- Detailed Construction Services ---
    {'name': 'Blacksmith', 'icon': Icons.hardware_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Bricklayer/Stonemason', 'icon': Icons.view_module_rounded, 'color': Color(0xFFB45309), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Builder/General Contractor', 'icon': Icons.apartment_rounded, 'color': Color(0xFF1D4ED8), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Cabinet Maker', 'icon': Icons.kitchen_rounded, 'color': Color(0xFF78350F), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Carpenter', 'icon': Icons.carpenter_rounded, 'color': Color(0xFF92400E), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Cement / Concrete', 'icon': Icons.foundation_rounded, 'color': Color(0xFF64748B), 'bg': Color(0xFFF8FAFC)},
    {'name': 'Commercial Builder', 'icon': Icons.domain_rounded, 'color': Color(0xFF0F766E), 'bg': Color(0xFFF0FDFA)},
    {'name': 'Construction (Other)', 'icon': Icons.build_circle_rounded, 'color': Color(0xFF334155), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Construction Project Management', 'icon': Icons.assignment_turned_in_rounded, 'color': Color(0xFF4338CA), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Counter Top', 'icon': Icons.countertops_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},
    {'name': 'Demolition Contractor', 'icon': Icons.delete_sweep_rounded, 'color': Color(0xFFB91C1C), 'bg': Color(0xFFFEF2F2)},
    {'name': 'Drainage', 'icon': Icons.water_damage_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Drywall', 'icon': Icons.grid_on_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Electrical Contractor', 'icon': Icons.electrical_services_rounded, 'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Electrician - Commercial', 'icon': Icons.bolt_rounded, 'color': Color(0xFFEAB308), 'bg': Color(0xFFFEF9C3)},
    {'name': 'Elevator', 'icon': Icons.elevator_rounded, 'color': Color(0xFF6366F1), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Energy Services', 'icon': Icons.energy_savings_leaf_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Environmental Services', 'icon': Icons.eco_rounded, 'color': Color(0xFF059669), 'bg': Color(0xFFD1FAE5)},
    {'name': 'Fences', 'icon': Icons.fence_rounded, 'color': Color(0xFF854D0E), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Fireplace & Oven Builder', 'icon': Icons.fireplace_rounded, 'color': Color(0xFFC2410C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Flooring', 'icon': Icons.layers_rounded, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFEDE9FE)},
    {'name': 'Garage Doors', 'icon': Icons.garage_rounded, 'color': Color(0xFF1E293B), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Glass', 'icon': Icons.window_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Ground Work', 'icon': Icons.terrain_rounded, 'color': Color(0xFF9A3412), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Handyman', 'icon': Icons.handyman_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Heating Engineer', 'icon': Icons.thermostat_rounded, 'color': Color(0xFFBE123C), 'bg': Color(0xFFFFE4E6)},
    {'name': 'HVAC - Heating & Air', 'icon': Icons.hvac_rounded, 'color': Color(0xFF0369A1), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Interior Design - Commercial', 'icon': Icons.business_center_rounded, 'color': Color(0xFF6D28D9), 'bg': Color(0xFFF5F3FF)},
    {'name': 'Interior Design - Residential', 'icon': Icons.chair_rounded, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFEDE9FE)},
    {'name': 'Kitchen Construction', 'icon': Icons.soup_kitchen_rounded, 'color': Color(0xFFC2410C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Metal Work', 'icon': Icons.precision_manufacturing_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Painter', 'icon': Icons.format_paint_rounded, 'color': Color(0xFFDB2777), 'bg': Color(0xFFFCE7F3)},
    {'name': 'Pest Control', 'icon': Icons.pest_control_rounded, 'color': Color(0xFF15803D), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Plasterer', 'icon': Icons.imagesearch_roller_rounded, 'color': Color(0xFF64748B), 'bg': Color(0xFFF8FAFC)},
    {'name': 'Plumbing', 'icon': Icons.plumbing_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Pools, Spas & Saunas', 'icon': Icons.pool_rounded, 'color': Color(0xFF0891B2), 'bg': Color(0xFFCFFAFE)},
    {'name': 'Power Generator', 'icon': Icons.power_rounded, 'color': Color(0xFFCA8A04), 'bg': Color(0xFFFEF08A)},
    {'name': 'Power Washing', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFDBEAFE)},
    {'name': 'Protective Coatings/Sealants', 'icon': Icons.format_color_fill_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFF3E8FF)},
    {'name': 'Renovations/Remodeling', 'icon': Icons.home_repair_service_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Restoration', 'icon': Icons.restore_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},
    {'name': 'Roofing & Gutters', 'icon': Icons.roofing_rounded, 'color': Color(0xFFB45309), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Septic Systems', 'icon': Icons.water_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Shutters & Awnings', 'icon': Icons.blinds_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Solar', 'icon': Icons.solar_power_rounded, 'color': Color(0xFFEAB308), 'bg': Color(0xFFFEF9C3)},
    {'name': 'Tile Worker', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF4F46E5), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Waterproofing-Weatherproofing', 'icon': Icons.umbrella_rounded, 'color': Color(0xFF0369A1), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Window Treatments', 'icon': Icons.curtains_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFFAF5FF)},
    {'name': 'Windows & Doors', 'icon': Icons.door_sliding_rounded, 'color': Color(0xFF64748B), 'bg': Color(0xFFF8FAFC)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSocialFeed();
    });
  }

  Future<void> _fetchSocialFeed() async {
    ref.invalidate(socialFeedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => n.isUnread).length;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;
    final isTabletOrLaptop = screenWidth >= 700;
    final horizontalPadding = isTabletOrLaptop ? 24.0 : (isSmallScreen ? 12.0 : 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Top Custom Header
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTab == 0 ? 'Services & Portfolio' : 'Our Portfolio',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 19,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTab == 0
                                  ? 'All solutions for your construction needs'
                                  : 'Explore our completed projects',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedTab == 0)
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.notifications_outlined, color: Color(0xFF1E293B), size: 19),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Pill Segmented Switcher (Services vs Portfolio)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0 ? const Color(0xFF1D4ED8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: _selectedTab == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 16,
                                    color: _selectedTab == 0 ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Services',
                                    style: TextStyle(
                                      color: _selectedTab == 0 ? Colors.white : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1 ? const Color(0xFF1D4ED8) : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: _selectedTab == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business_center_rounded,
                                    size: 16,
                                    color: _selectedTab == 1 ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Portfolio',
                                    style: TextStyle(
                                      color: _selectedTab == 1 ? Colors.white : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content Body
                Expanded(
                  child: _selectedTab == 0
                      ? _buildServicesView(isSmallScreen, screenWidth, horizontalPadding)
                      : _buildPortfolioView(isSmallScreen, screenWidth, horizontalPadding),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SERVICES TAB VIEW (Left Screen in Image)
  // ==========================================
  Widget _buildServicesView(bool isSmallScreen, double screenWidth, double horizontalPadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final gridCrossAxisCount = availableWidth >= 900 ? 5 : (availableWidth >= 650 ? 4 : 3);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // One Stop Solution Hero Banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEFF6FF),
                  const Color(0xFFF8FAFC),
                  const Color(0xFFEEF2FF),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDBEAFE)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'One Stop Solution',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 19,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'From planning to completion,\nwe build your dreams',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12.5,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => context.push('/create-project'),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D4ED8),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore Services',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isSmallScreen ? 11 : 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/banner_building.jpg',
                            height: isSmallScreen ? 85 : 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.apartment_rounded, size: isSmallScreen ? 60 : 80, color: Colors.blue.shade200),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // "All Services" Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Container(width: 24, height: 2.5, decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(2))),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/providers/All'),
                child: Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3-Column Services Grid (Preserving ALL 48+ services)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              childAspectRatio: isSmallScreen ? 0.85 : 0.88,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final Color iconColor = cat['color'] as Color? ?? const Color(0xFF1D4ED8);
              final Color bgColor = cat['bg'] as Color? ?? const Color(0xFFEFF6FF);

              return GestureDetector(
                onTap: () => context.push('/providers/${cat['name']}'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
                        child: Column(
                          children: [
                            Container(
                              width: isSmallScreen ? 40 : 44,
                              height: isSmallScreen ? 40 : 44,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  cat['icon'] as IconData,
                                  size: isSmallScreen ? 20 : 22,
                                  color: iconColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Center(
                                child: Text(
                                  cat['name'] as String,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isSmallScreen ? 10.5 : 11.5,
                                    color: const Color(0xFF1E293B),
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.grey.shade300),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Bottom CTA Banner ("Have a Custom Requirement?")
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFEFF6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Have a Custom Requirement?',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We\'ll create a tailored solution just for your project.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/create-project'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Request a Quote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Image.asset(
                    'assets/images/banner_building.jpg',
                    height: 80,
                    fit: BoxFit.contain,
                    color: const Color(0xFFF8FAFC),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.apartment, size: 60, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
      },
    );
  }

  // ==========================================
  // PORTFOLIO TAB VIEW (Live Builder Showcases Only)
  // ==========================================
  Widget _buildPortfolioView(bool isSmallScreen, double screenWidth, double horizontalPadding) {
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
      final category = provider['category'] ?? post['category'] ?? 'Residential';
      final imageData = post['imageData'] as String?;
      final imageUrl = post['imageUrl'] as String?;
      final providerId = provider['id']?.toString() ?? '';

      Color tagColor = const Color(0xFF10B981);
      Color tagBg = const Color(0xFFECFDF5);
      if (category.toString().toLowerCase().contains('interior')) {
        tagColor = const Color(0xFFF59E0B);
        tagBg = const Color(0xFFFFFBEB);
      } else if (category.toString().toLowerCase().contains('commercial')) {
        tagColor = const Color(0xFF3B82F6);
        tagBg = const Color(0xFFEFF6FF);
      } else if (category.toString().toLowerCase().contains('infrastructure')) {
        tagColor = const Color(0xFF8B5CF6);
        tagBg = const Color(0xFFFAF5FF);
      }

      combinedPortfolio.add({
        'id': post['id']?.toString() ?? 'social_$i',
        'title': title,
        'builder': builderName,
        'providerId': providerId,
        'category': category,
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
      return (p['category'] as String).toLowerCase().contains(_selectedPortfolioFilter.toLowerCase()) ||
          _selectedPortfolioFilter.toLowerCase().contains((p['category'] as String).toLowerCase());
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                      color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
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
                        color: isSelected ? Colors.white : const Color(0xFF475569),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                          const Text(
                            'Live Project Showcases',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalCount > 0 ? totalCount.toString().padLeft(2, '0') : '00',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF10B981), height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Verified contractor inspirations and live project showcases',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
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
              const Text(
                'Builder Inspirations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedPortfolioFilter = 'All Projects'),
                child: Row(
                  children: [
                    Text('View All ($totalCount)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Builder Inspirations List
          if (socialAsync.isLoading && combinedPortfolio.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredProjects.isEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No Showcases Found',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPortfolioFilter == 'All Projects'
                        ? 'Contractor inspirations and live showcases will appear here.'
                        : 'No live showcases found under "$_selectedPortfolioFilter".',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
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
                          color: const Color(0xFFF1F5F9),
                          child: hasBase64
                              ? Image.memory(
                                  base64Decode(imageData.contains(',') ? imageData.split(',').last : imageData),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, size: 40, color: Colors.grey),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: project['tagBg'] as Color? ?? const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    project['category'] as String? ?? 'Residential',
                                    style: TextStyle(
                                      color: project['tagColor'] as Color? ?? const Color(0xFF10B981),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                                    color: isBookmarked ? const Color(0xFF1D4ED8) : Colors.grey.shade400,
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
                                color: const Color(0xFF0F172A),
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
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
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
                                Icon(Icons.location_on_rounded, size: 11, color: Colors.grey.shade400),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    project['location'] as String? ?? 'Chennai',
                                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
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
                                        color: const Color(0xFFEFF6FF),
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
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                  ),
                                GestureDetector(
                                  onTap: () => _showProjectDetailDialog(project),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (project['tagColor'] as Color? ?? const Color(0xFF1D4ED8)).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      'View Project',
                                      style: TextStyle(
                                        color: project['tagColor'] as Color? ?? const Color(0xFF1D4ED8),
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
                colors: [
                  const Color(0xFFF0FDF4),
                  const Color(0xFFEFF6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Have a project in mind?',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Let\'s build something amazing together',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/create-project'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
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
              child: Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDetailDialog(Map<String, dynamic> project) {
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
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
                            const Icon(Icons.image, size: 60, color: Colors.grey),
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: project['tagBg'] as Color? ?? const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    project['category'] as String? ?? 'Residential',
                    style: TextStyle(
                      color: project['tagColor'] as Color? ?? const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
                Text(builder, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 13),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(project['location'] as String? ?? 'Chennai', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text('📐 Area: ${project['area']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text('📅 Year: ${project['year']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                        foregroundColor: const Color(0xFF1D4ED8),
                        side: const BorderSide(color: Color(0xFF1D4ED8)),
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
                      backgroundColor: const Color(0xFF1D4ED8),
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
