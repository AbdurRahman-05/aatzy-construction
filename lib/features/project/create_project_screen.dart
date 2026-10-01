import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../../core/wallpaper_background.dart';
import '../../core/services/location_service.dart';
import '../../core/providers/projects_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  // Current step: 0 = Services, 1 = Location & Specs, 2 = Review & Confirm
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _plotSizeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _timelineController = TextEditingController();

  // Step 1: Selected Services
  final List<String> _selectedServices = [];

  // Step 2: Selected Residential / Property Type
  String _selectedPropertyType = 'Residential Villa';

  final List<Map<String, dynamic>> _propertyTypes = const [
    {
      'name': 'Residential Villa',
      'icon': Icons.villa_rounded,
      'desc': 'Independent house, duplex or luxury villa',
      'color': Color(0xFF0D9488),
      'bg': Color(0xFFF0FDFA),
    },
    {
      'name': 'Apartment / Flat',
      'icon': Icons.apartment_rounded,
      'desc': 'Multi-story apartment unit or penthouse',
      'color': Color(0xFF2563EB),
      'bg': Color(0xFFEFF6FF),
    },
    {
      'name': 'Commercial Complex',
      'icon': Icons.business_rounded,
      'desc': 'Office space, retail store or commercial building',
      'color': Color(0xFF7C3AED),
      'bg': Color(0xFFF5F3FF),
    },
    {
      'name': 'Industrial / Warehouse',
      'icon': Icons.warehouse_rounded,
      'desc': 'Factory, industrial shed or godown',
      'color': Color(0xFFEA580C),
      'bg': Color(0xFFFFF7ED),
    },
    {
      'name': 'Renovation & Remodel',
      'icon': Icons.home_repair_service_rounded,
      'desc': 'Restoration, room addition or floor extension',
      'color': Color(0xFF059669),
      'bg': Color(0xFFECFDF5),
    },
    {
      'name': 'Plot / Farmhouse',
      'icon': Icons.landscape_rounded,
      'desc': 'Boundary wall, farmhouse or land development',
      'color': Color(0xFFCA8A04),
      'bg': Color(0xFFFEFCE8),
    },
  ];

  // Search & Filter for Services
  final _serviceSearchController = TextEditingController();
  String _serviceSearchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Core Construction',
    'Design & Planning',
    'Interiors & Finishing',
    'MEP & Utilities',
    'Materials & Logistics',
    'Specialist Services',
  ];

  final List<Map<String, dynamic>> _allServices = const [
    // --- 1. Core Construction (12 services) ---
    {'name': 'Construction', 'category': 'Core Construction', 'icon': Icons.construction_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFF0F9FF)},
    {'name': 'Builder/General Contractor', 'category': 'Core Construction', 'icon': Icons.apartment_rounded, 'color': Color(0xFF1D4ED8), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Commercial Builder', 'category': 'Core Construction', 'icon': Icons.domain_rounded, 'color': Color(0xFF0F766E), 'bg': Color(0xFFF0FDFA)},
    {'name': 'Construction (Other)', 'category': 'Core Construction', 'icon': Icons.build_circle_rounded, 'color': Color(0xFF334155), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Construction Project Management', 'category': 'Core Construction', 'icon': Icons.assignment_turned_in_rounded, 'color': Color(0xFF4338CA), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Cement / Concrete', 'category': 'Core Construction', 'icon': Icons.foundation_rounded, 'color': Color(0xFF64748B), 'bg': Color(0xFFF8FAFC)},
    {'name': 'Bricklayer/Stonemason', 'category': 'Core Construction', 'icon': Icons.view_module_rounded, 'color': Color(0xFFB45309), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Ground Work', 'category': 'Core Construction', 'icon': Icons.terrain_rounded, 'color': Color(0xFF9A3412), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Demolition Contractor', 'category': 'Core Construction', 'icon': Icons.delete_sweep_rounded, 'color': Color(0xFFB91C1C), 'bg': Color(0xFFFEF2F2)},
    {'name': 'Roofing & Gutters', 'category': 'Core Construction', 'icon': Icons.roofing_rounded, 'color': Color(0xFFB45309), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Renovations/Remodeling', 'category': 'Core Construction', 'icon': Icons.home_repair_service_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Restoration', 'category': 'Core Construction', 'icon': Icons.restore_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},

    // --- 2. Design & Planning (7 services) ---
    {'name': 'Design & Planning', 'category': 'Design & Planning', 'icon': Icons.architecture_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFFAF5FF)},
    {'name': 'Survey & Analysis', 'category': 'Design & Planning', 'icon': Icons.explore_rounded, 'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Land & Legal', 'category': 'Design & Planning', 'icon': Icons.gavel_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Finance & Approvals', 'category': 'Design & Planning', 'icon': Icons.account_balance_rounded, 'color': Color(0xFF059669), 'bg': Color(0xFFECFDF5)},
    {'name': 'Project Management', 'category': 'Design & Planning', 'icon': Icons.assignment_rounded, 'color': Color(0xFF4F46E5), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Inspection & Compliance', 'category': 'Design & Planning', 'icon': Icons.verified_user_rounded, 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEF2F2)},
    {'name': 'Environmental Services', 'category': 'Design & Planning', 'icon': Icons.eco_rounded, 'color': Color(0xFF059669), 'bg': Color(0xFFD1FAE5)},

    // --- 3. Interiors & Finishing (17 services) ---
    {'name': 'Interiors & Finishing', 'category': 'Interiors & Finishing', 'icon': Icons.chair_rounded, 'color': Color(0xFF8B5CF6), 'bg': Color(0xFFF5F3FF)},
    {'name': 'Interior Design - Residential', 'category': 'Interiors & Finishing', 'icon': Icons.chair_rounded, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFEDE9FE)},
    {'name': 'Interior Design - Commercial', 'category': 'Interiors & Finishing', 'icon': Icons.business_center_rounded, 'color': Color(0xFF6D28D9), 'bg': Color(0xFFF5F3FF)},
    {'name': 'Flooring', 'category': 'Interiors & Finishing', 'icon': Icons.layers_rounded, 'color': Color(0xFF7C3AED), 'bg': Color(0xFFEDE9FE)},
    {'name': 'Tile Worker', 'category': 'Interiors & Finishing', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF4F46E5), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Painter', 'category': 'Interiors & Finishing', 'icon': Icons.format_paint_rounded, 'color': Color(0xFFDB2777), 'bg': Color(0xFFFCE7F3)},
    {'name': 'Plasterer', 'category': 'Interiors & Finishing', 'icon': Icons.imagesearch_roller_rounded, 'color': Color(0xFF64748B), 'bg': Color(0xFFF8FAFC)},
    {'name': 'Carpenter', 'category': 'Interiors & Finishing', 'icon': Icons.carpenter_rounded, 'color': Color(0xFF92400E), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Cabinet Maker', 'category': 'Interiors & Finishing', 'icon': Icons.kitchen_rounded, 'color': Color(0xFF78350F), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Kitchen Construction', 'category': 'Interiors & Finishing', 'icon': Icons.soup_kitchen_rounded, 'color': Color(0xFFC2410C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Counter Top', 'category': 'Interiors & Finishing', 'icon': Icons.countertops_rounded, 'color': Color(0xFF0D9488), 'bg': Color(0xFFCCFBF1)},
    {'name': 'Drywall', 'category': 'Interiors & Finishing', 'icon': Icons.grid_on_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Windows & Doors', 'category': 'Interiors & Finishing', 'icon': Icons.door_sliding_rounded, 'color': Color(0xFF64748B), 'bg': Color(0xFFF8FAFC)},
    {'name': 'Glass', 'category': 'Interiors & Finishing', 'icon': Icons.window_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Garage Doors', 'category': 'Interiors & Finishing', 'icon': Icons.garage_rounded, 'color': Color(0xFF1E293B), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Shutters & Awnings', 'category': 'Interiors & Finishing', 'icon': Icons.blinds_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Window Treatments', 'category': 'Interiors & Finishing', 'icon': Icons.curtains_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFFAF5FF)},

    // --- 4. MEP & Utilities (12 services) ---
    {'name': 'Engineering (MEP)', 'category': 'MEP & Utilities', 'icon': Icons.settings_rounded, 'color': Color(0xFF10B981), 'bg': Color(0xFFECFDF5)},
    {'name': 'Electrical Contractor', 'category': 'MEP & Utilities', 'icon': Icons.electrical_services_rounded, 'color': Color(0xFFD97706), 'bg': Color(0xFFFFFBEB)},
    {'name': 'Electrician - Commercial', 'category': 'MEP & Utilities', 'icon': Icons.bolt_rounded, 'color': Color(0xFFEAB308), 'bg': Color(0xFFFEF9C3)},
    {'name': 'Plumbing', 'category': 'MEP & Utilities', 'icon': Icons.plumbing_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Utilities', 'category': 'MEP & Utilities', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF59E0B), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Borewell', 'category': 'MEP & Utilities', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF06B6D4), 'bg': Color(0xFFECFEFF)},
    {'name': 'Drainage', 'category': 'MEP & Utilities', 'icon': Icons.water_damage_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Septic Systems', 'category': 'MEP & Utilities', 'icon': Icons.water_rounded, 'color': Color(0xFF0284C7), 'bg': Color(0xFFE0F2FE)},
    {'name': 'HVAC - Heating & Air', 'category': 'MEP & Utilities', 'icon': Icons.hvac_rounded, 'color': Color(0xFF0369A1), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Heating Engineer', 'category': 'MEP & Utilities', 'icon': Icons.thermostat_rounded, 'color': Color(0xFFBE123C), 'bg': Color(0xFFFFE4E6)},
    {'name': 'Solar', 'category': 'MEP & Utilities', 'icon': Icons.solar_power_rounded, 'color': Color(0xFFEAB308), 'bg': Color(0xFFFEF9C3)},
    {'name': 'Power Generator', 'category': 'MEP & Utilities', 'icon': Icons.power_rounded, 'color': Color(0xFFCA8A04), 'bg': Color(0xFFFEF08A)},

    // --- 5. Materials & Logistics (3 services) ---
    {'name': 'Materials & Supply', 'category': 'Materials & Logistics', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFFE11D48), 'bg': Color(0xFFFFF1F2)},
    {'name': 'Logistics & Equipment', 'category': 'Materials & Logistics', 'icon': Icons.local_shipping_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Insurance', 'category': 'Materials & Logistics', 'icon': Icons.umbrella_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFF0FDF4)},

    // --- 6. Specialist Services (13 services) ---
    {'name': 'Waterproofing-Weatherproofing', 'category': 'Specialist Services', 'icon': Icons.umbrella_rounded, 'color': Color(0xFF0369A1), 'bg': Color(0xFFE0F2FE)},
    {'name': 'Smart & Security', 'category': 'Specialist Services', 'icon': Icons.shield_rounded, 'color': Color(0xFF3B82F6), 'bg': Color(0xFFEFF6FF)},
    {'name': 'Pest Control', 'category': 'Specialist Services', 'icon': Icons.pest_control_rounded, 'color': Color(0xFF15803D), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Elevator', 'category': 'Specialist Services', 'icon': Icons.elevator_rounded, 'color': Color(0xFF6366F1), 'bg': Color(0xFFEEF2FF)},
    {'name': 'Pools, Spas & Saunas', 'category': 'Specialist Services', 'icon': Icons.pool_rounded, 'color': Color(0xFF0891B2), 'bg': Color(0xFFCFFAFE)},
    {'name': 'Fences', 'category': 'Specialist Services', 'icon': Icons.fence_rounded, 'color': Color(0xFF854D0E), 'bg': Color(0xFFFEF3C7)},
    {'name': 'Fireplace & Oven Builder', 'category': 'Specialist Services', 'icon': Icons.fireplace_rounded, 'color': Color(0xFFC2410C), 'bg': Color(0xFFFFEDD5)},
    {'name': 'Blacksmith', 'category': 'Specialist Services', 'icon': Icons.hardware_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Metal Work', 'category': 'Specialist Services', 'icon': Icons.precision_manufacturing_rounded, 'color': Color(0xFF475569), 'bg': Color(0xFFF1F5F9)},
    {'name': 'Energy Services', 'category': 'Specialist Services', 'icon': Icons.energy_savings_leaf_rounded, 'color': Color(0xFF16A34A), 'bg': Color(0xFFDCFCE7)},
    {'name': 'Handyman', 'category': 'Specialist Services', 'icon': Icons.handyman_rounded, 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFF7ED)},
    {'name': 'Power Washing', 'category': 'Specialist Services', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF2563EB), 'bg': Color(0xFFDBEAFE)},
    {'name': 'Protective Coatings/Sealants', 'category': 'Specialist Services', 'icon': Icons.format_color_fill_rounded, 'color': Color(0xFF9333EA), 'bg': Color(0xFFF3E8FF)},
  ];

  @override
  void initState() {
    super.initState();
    LocationService().getSavedLocation().then((loc) {
      if (mounted && loc.isNotEmpty) {
        setState(() {
          _locationController.text = loc;
        });
      }
    });
  }

  @override
  void dispose() {
    _serviceSearchController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _plotSizeController.dispose();
    _budgetController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  String _formatBudget(String val) {
    if (val.trim().isEmpty) return 'Not specified';
    final numVal = double.tryParse(val) ?? 0;
    if (numVal <= 0) return 'Not specified';
    if (numVal >= 10000000) {
      return '₹ ${(numVal / 10000000).toStringAsFixed(2)} Cr';
    } else if (numVal >= 100000) {
      return '₹ ${(numVal / 100000).toStringAsFixed(1)} Lakhs';
    } else {
      return '₹ ${numVal.toStringAsFixed(0)}';
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one service needed for your project'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_locationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a site location or city'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submitProject() async {
    if (_selectedServices.isEmpty) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service')),
      );
      return;
    }

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please login again.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final projectTitle = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : '$_selectedPropertyType Project';

      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': auth.id,
          'title': projectTitle,
          'type': '$_selectedPropertyType - ${_selectedServices.join(', ')}',
          'location': LocationService.resolveToCityState(
            _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : 'Tamil Nadu',
          ),
          'plotSize': double.tryParse(_plotSizeController.text.trim()) ?? 0.0,
          'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
          'timeline': _timelineController.text.trim().isNotEmpty ? _timelineController.text.trim() : 'Flexible',
          'currentStage': 'Planning & Approvals',
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        // Invalidate Riverpod cache so home/dashboard/profile counts refresh immediately
        ref.invalidate(userProjectsProvider(auth.id!));

        _showSuccessDialog();
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to initialize project'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error creating project: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to reach server.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFA7F3D0), width: 2.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.rocket_launch_rounded, color: Color(0xFF059669), size: 38),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Project Launched! 🚀',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your construction project has been published successfully. Verified contractors and specialists in ${_locationController.text.trim()} have been alerted to submit competitive quotes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (context.canPop()) {
                        context.pop(true);
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View in Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Inline Edit Modals for Step 3 ---

  void _showPlotSizeDialog() {
    final controller = TextEditingController(text: _plotSizeController.text);
    final quickSizes = ['600', '1200', '1500', '2400', '3000', '4500'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Plot Size (sq ft)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Plot Area in sq ft',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.square_foot_rounded, color: Color(0xFF0D9488)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Select:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickSizes.map((s) {
                      return ActionChip(
                        label: Text('$s sq ft'),
                        onPressed: () => setModalState(() => controller.text = s),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() => _plotSizeController.text = controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Plot Size', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(text: _budgetController.text);
    final quickBudgets = [
      {'label': '₹25 Lakhs', 'val': '2500000'},
      {'label': '₹45 Lakhs', 'val': '4500000'},
      {'label': '₹75 Lakhs', 'val': '7500000'},
      {'label': '₹1.2 Crore', 'val': '12000000'},
      {'label': '₹2.5 Crore', 'val': '25000000'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Budget Limit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estimated Budget',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Select:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickBudgets.map((b) {
                      return ActionChip(
                        label: Text(b['label']!),
                        onPressed: () => setModalState(() => controller.text = b['val']!),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() => _budgetController.text = controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Budget', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTimelineDialog() {
    final controller = TextEditingController(text: _timelineController.text);
    final quickTimelines = ['3-6 Months', '6-9 Months', '9-12 Months', '12-18 Months', '18-24 Months'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Target Timeline', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Expected Duration',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFF59E0B)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Quick Select:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickTimelines.map((t) {
                      return ActionChip(
                        label: Text(t),
                        onPressed: () => setModalState(() => controller.text = t),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() => _timelineController.text = controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProjectIdentityDialog() {
    final titleCtrl = TextEditingController(text: _titleController.text);
    String tempType = _selectedPropertyType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomInset + 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Edit Title & Property Type', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Project Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF0D9488)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Property Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _propertyTypes.map((type) {
                        final isSel = type['name'] == tempType;
                        return ChoiceChip(
                          label: Text(type['name']),
                          selected: isSel,
                          selectedColor: const Color(0xFFCCFBF1),
                          onSelected: (_) => setModalState(() => tempType = type['name']),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _titleController.text = titleCtrl.text.trim();
                            _selectedPropertyType = tempType;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditLocationDialog() {
    final locCtrl = TextEditingController(text: _locationController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomInset + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Edit Project City Location', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locCtrl,
                    decoration: InputDecoration(
                      labelText: 'Project City Location',
                      hintText: 'e.g. Madurai, Tamil Nadu',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFF0D9488)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF0D9488)),
                        tooltip: 'Detect live City GPS',
                        onPressed: () async {
                          final loc = await LocationService().detectAndSaveLocation(forceRefresh: true);
                          if (loc != null && loc.isNotEmpty) {
                            setModalState(() => locCtrl.text = loc);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select City:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Madurai', 'Dindigul', 'Chennai', 'Coimbatore', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Theni'
                      ].map((cityName) {
                        final isSel = locCtrl.text.toLowerCase().contains(cityName.toLowerCase());
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(cityName),
                            selected: isSel,
                            selectedColor: const Color(0xFF0D9488),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                              color: isSel ? Colors.white : const Color(0xFF334155),
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (selected) {
                              setModalState(() {
                                locCtrl.text = '$cityName, Tamil Nadu';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (locCtrl.text.trim().isNotEmpty) {
                          final resolved = LocationService.resolveToCityState(locCtrl.text.trim());
                          setState(() => _locationController.text = resolved);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save City Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: WallpaperBackground(
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1E293B), size: 28),
              onPressed: _prevStep,
            ),
            centerTitle: true,
            title: Text(
              _currentStep == 0
                  ? 'Step 1: Select Services'
                  : (_currentStep == 1 ? 'Step 2: Project Details' : 'Step 3: Review & Launch'),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text(
                      '${_currentStep + 1} of 3',
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF0D9488)),
                      SizedBox(height: 16),
                      Text('Initializing your project...', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      children: [
                        // Stepper Progress Indicator at top
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                          child: _buildStepperIndicator(isSmallScreen),
                        ),

                        // Body per step
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            child: _buildStepContent(isSmallScreen),
                          ),
                        ),

                        // Sticky Bottom Action Bar
                        _buildBottomActionBar(isSmallScreen),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // --- Stepper Indicator ---

  Widget _buildStepperIndicator(bool isSmallScreen) {
    final steps = [
      {'num': '1', 'title': 'Services', 'icon': Icons.layers_rounded},
      {'num': '2', 'title': 'Details', 'icon': Icons.edit_note_rounded},
      {'num': '3', 'title': 'Review', 'icon': Icons.rocket_launch_rounded},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final linePassed = (index ~/ 2) < _currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: linePassed ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final step = steps[stepIdx];
        final isActive = stepIdx == _currentStep;
        final isPassed = stepIdx < _currentStep;

        return GestureDetector(
          onTap: () {
            // Allow jumping to completed steps or current
            if (isPassed || stepIdx <= _currentStep) {
              setState(() => _currentStep = stepIdx);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: isSmallScreen ? 28 : 32,
                height: isSmallScreen ? 28 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF0D9488)
                      : (isPassed ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9)),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF0D9488)
                        : (isPassed ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text(
                          step['num'] as String,
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF64748B),
                            fontSize: isSmallScreen ? 11 : 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                step['title'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12.5,
                  fontWeight: isActive ? FontWeight.w900 : (isPassed ? FontWeight.w700 : FontWeight.w500),
                  color: isActive ? const Color(0xFF0F766E) : (isPassed ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // --- Step Content Switcher ---

  Widget _buildStepContent(bool isSmallScreen) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Services(isSmallScreen);
      case 1:
        return _buildStep2Specifications(isSmallScreen);
      case 2:
      default:
        return _buildStep3ReviewAndLaunch(isSmallScreen);
    }
  }

  // ==========================================
  // STEP 1: SELECT SERVICES WANTED
  // ==========================================

  Widget _buildStep1Services(bool isSmallScreen) {
    final filteredServices = _allServices.where((s) {
      final matchesSearch = _serviceSearchQuery.trim().isEmpty ||
          (s['name'] as String).toLowerCase().contains(_serviceSearchQuery.trim().toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || s['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Header Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'STEP 1 OF 3',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select Services Needed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 17 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose all construction disciplines & specialists required for your site blueprint.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: isSmallScreen ? 11 : 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search Bar
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _serviceSearchController,
            onChanged: (val) => setState(() => _serviceSearchQuery = val),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Search 40+ services (e.g. Plumbing, Solar, Design)...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF0D9488)),
              suffixIcon: _serviceSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _serviceSearchController.clear();
                        setState(() => _serviceSearchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _categories.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  selectedColor: const Color(0xFF0D9488),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? Colors.white : const Color(0xFF64748B),
                  ),
                  side: BorderSide(
                    color: isSel ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Selection Counter & Quick Select Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF0D9488)),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedServices.length} Services Selected',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var s in filteredServices) {
                        final name = s['name'] as String;
                        if (!_selectedServices.contains(name)) {
                          _selectedServices.add(name);
                        }
                      }
                    });
                  },
                  child: const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedServices.clear()),
                  child: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Service Grid
        filteredServices.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No services found for "$_serviceSearchQuery"', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredServices.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isSmallScreen ? 2 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isSmallScreen ? 2.0 : 2.2,
                ),
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  final name = service['name'] as String;
                  final icon = service['icon'] as IconData;
                  final color = service['color'] as Color;
                  final bg = service['bg'] as Color;
                  final isSelected = _selectedServices.contains(name);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedServices.remove(name);
                        } else {
                          _selectedServices.add(name);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0D9488) : bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 16,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0D9488)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // ==========================================
  // STEP 2: LOCATION, PROPERTY TYPE, PLOT, BUDGET & TIMELINE
  // ==========================================

  Widget _buildStep2Specifications(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'STEP 2 OF 3',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Location & Project Specs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 17 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provide your residential type, site location, plot area, budget limit and target timeline.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: isSmallScreen ? 11 : 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Project Title
        const Text(
          'PROJECT TITLE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. My Modern Villa, Greenfield Residence',
              prefixIcon: Icon(Icons.home_work_rounded, color: Color(0xFF0D9488), size: 20),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Residential / Property Type
        const Text(
          'RESIDENTIAL / PROPERTY TYPE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final crossAxisCount = availableWidth >= 640 ? 3 : 2;
            const spacing = 10.0;
            final totalSpacing = (crossAxisCount - 1) * spacing;
            final itemWidth = (availableWidth - totalSpacing) / crossAxisCount;
            // Target item height of ~102px gives ample space for icon, title, and description
            const double targetHeight = 104.0;
            final dynamicAspectRatio = (itemWidth / targetHeight).clamp(1.15, 1.8);

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _propertyTypes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: dynamicAspectRatio,
              ),
              itemBuilder: (context, index) {
                final prop = _propertyTypes[index];
                final name = prop['name'] as String;
                final icon = prop['icon'] as IconData;
                final desc = prop['desc'] as String;
                final isSelected = _selectedPropertyType == name;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPropertyType = name;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.14),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 20, color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B)),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF0D9488)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF1E293B),
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9.0 : 9.5,
                                  color: Colors.grey.shade600,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),

        // 3. Site Location / City
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROJECT CITY LOCATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            InkWell(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 10),
                        Text('Detecting your city GPS...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                final loc = await LocationService().detectAndSaveLocation(forceRefresh: true);
                if (mounted && loc != null && loc.isNotEmpty) {
                  setState(() => _locationController.text = loc);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('City resolved: $loc'), backgroundColor: const Color(0xFF0D9488)),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF0D9488)),
                    SizedBox(width: 4),
                    Text(
                      'Live GPS City',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'e.g. Madurai, Tamil Nadu',
                    prefixIcon: Icon(Icons.location_city_rounded, color: Color(0xFF0D9488), size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.gps_fixed_rounded, color: Color(0xFF0D9488), size: 20),
                tooltip: 'Detect live City GPS',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 10),
                          Text('Detecting your city GPS...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  final loc = await LocationService().detectAndSaveLocation(forceRefresh: true);
                  if (mounted && loc != null && loc.isNotEmpty) {
                    setState(() => _locationController.text = loc);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('City resolved: $loc'), backgroundColor: const Color(0xFF0D9488)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Select City: ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              ...[
                'Madurai',
                'Dindigul',
                'Chennai',
                'Coimbatore',
                'Tiruchirappalli',
                'Salem',
                'Tirunelveli',
                'Theni',
                'Virudhunagar',
                'Erode',
              ].map((cityName) {
                final isSelected = _locationController.text.toLowerCase().contains(cityName.toLowerCase());
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cityName),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D9488),
                    backgroundColor: const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    showCheckmark: isSelected,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _locationController.text = '$cityName, Tamil Nadu';
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. Plot Size, Budget & Timeline Specifications Card
        const Text(
          'PLOT SIZE, BUDGET & TIMELINE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Plot Size Field + quick presets
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.square_foot_rounded, color: Color(0xFF0D9488), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Plot Area (sq ft)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: isSmallScreen ? 88 : 100,
                    height: 38,
                    child: TextField(
                      controller: _plotSizeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F766E), fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. 1200',
                        hintStyle: TextStyle(fontWeight: FontWeight.w400, color: Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ['600', '1200', '1500', '2400', '3000', '4000'].map((s) {
                  final isSel = _plotSizeController.text == s;
                  return ActionChip(
                    label: Text('$s sq ft', style: TextStyle(fontSize: 11, color: isSel ? const Color(0xFF0D9488) : Colors.black87)),
                    backgroundColor: isSel ? const Color(0xFFCCFBF1) : const Color(0xFFF1F5F9),
                    onPressed: () => setState(() => _plotSizeController.text = s),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
              const Divider(height: 24),

              // Budget Field + quick presets
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget Limit',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(_formatBudget(_budgetController.text), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: isSmallScreen ? 100 : 115,
                    height: 38,
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 13),
                      decoration: InputDecoration(
                        prefixText: _budgetController.text.isNotEmpty ? '₹ ' : null,
                        hintText: 'e.g. 4500000',
                        hintStyle: TextStyle(fontWeight: FontWeight.w400, color: Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  {'l': '₹25L', 'v': '2500000'},
                  {'l': '₹45L', 'v': '4500000'},
                  {'l': '₹75L', 'v': '7500000'},
                  {'l': '₹1.2Cr', 'v': '12000000'},
                  {'l': '₹2.5Cr', 'v': '25000000'},
                ].map((b) {
                  final isSel = _budgetController.text == b['v'];
                  return ActionChip(
                    label: Text(b['l']!, style: TextStyle(fontSize: 11, color: isSel ? const Color(0xFF059669) : Colors.black87)),
                    backgroundColor: isSel ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9),
                    onPressed: () => setState(() => _budgetController.text = b['v']!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
              const Divider(height: 24),

              // Target Timeline Field + quick presets
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFF59E0B), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Target Timeline',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: isSmallScreen ? 95 : 110,
                    height: 38,
                    child: TextField(
                      controller: _timelineController,
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD97706), fontSize: 12.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. 9 Months',
                        hintStyle: TextStyle(fontWeight: FontWeight.w400, color: Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ['3-6 Months', '6-9 Months', '9-12 Months', '12-18 Months', '18-24 Months'].map((t) {
                  final isSel = _timelineController.text == t;
                  return ActionChip(
                    label: Text(t, style: TextStyle(fontSize: 11, color: isSel ? const Color(0xFFD97706) : Colors.black87)),
                    backgroundColor: isSel ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                    onPressed: () => setState(() => _timelineController.text = t),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: CONFIRM ALL CHANGES & EDITABLE REVIEW & LAUNCH
  // ==========================================

  Widget _buildStep3ReviewAndLaunch(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Header Banner
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'STEP 3 OF 3: FINAL REVIEW',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to Launch!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify your project blueprint below. You can tap [Edit] on any section to modify it before launching.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: isSmallScreen ? 11 : 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section Title
        const Text(
          'CONFIRM PROJECT BLUEPRINT (ALL EDITABLE)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),

        // 1. Identity & Property Type Card (Editable)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.title_rounded, color: Color(0xFF0D9488), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Project Identity',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _showEditProjectIdentityDialog,
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0D9488)),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : '$_selectedPropertyType Project',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.villa_rounded, size: 14, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 5),
                    Text(
                      _selectedPropertyType,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Site Location Card (Editable)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Site Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : 'Location not set',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showEditLocationDialog,
                icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0D9488)),
                label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Specifications Card (Plot Area, Budget, Timeline) - Each tile clickable!
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Core Specifications', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  Text('(Tap tile to edit)', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Plot Size
                  Expanded(
                    child: InkWell(
                      onTap: _showPlotSizeDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.square_foot_rounded, size: 14, color: Color(0xFF0D9488)),
                                SizedBox(width: 3),
                                Text('Plot Size', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_plotSizeController.text} sq ft',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            const Text('✏️ Edit', style: TextStyle(fontSize: 9.5, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Budget Limit
                  Expanded(
                    child: InkWell(
                      onTap: _showBudgetDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.currency_rupee_rounded, size: 14, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Text('Budget', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatBudget(_budgetController.text),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('✏️ Edit', style: TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Target Timeline
                  Expanded(
                    child: InkWell(
                      onTap: _showTimelineDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 3),
                                Text('Timeline', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _timelineController.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('✏️ Edit', style: TextStyle(fontSize: 9.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 4. Selected Services Card (Editable)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.handyman_rounded, color: Color(0xFF7C3AED), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Services Required (${_selectedServices.length})',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentStep = 0),
                    icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF0D9488)),
                    label: const Text('Edit Services', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedServices.map((serviceName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF0D9488)),
                        const SizedBox(width: 5),
                        Text(
                          serviceName,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Trust & Guarantee Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCCFBF1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0D9488), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Providers Guaranteed',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F766E)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Only KYC-verified and rated contractors in your city will view your requirements and offer quotes.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF134E4A), height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ==========================================
  // STICKY BOTTOM ACTION BAR (DYNAMIC PER STEP)
  // ==========================================

  Widget _buildBottomActionBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back Button (shown on Steps 2 and 3)
            if (_currentStep > 0) ...[
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF475569)),
                      Text('Back', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
            ],

            // Main Step Action Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _currentStep == 2 ? _submitProject : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _currentStep == 2
                            ? [const Color(0xFF0F766E), const Color(0xFF0D9488), const Color(0xFF10B981)]
                            : [const Color(0xFF0F766E), const Color(0xFF0D9488)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentStep == 2 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _currentStep == 0
                                    ? (isSmallScreen ? 'Next: Details →' : 'Next: Project Details →')
                                    : (_currentStep == 1
                                        ? (isSmallScreen ? 'Next: Review →' : 'Next: Review & Confirm →')
                                        : '🚀 Launch Project'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: isSmallScreen ? 13.5 : 14.5,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
