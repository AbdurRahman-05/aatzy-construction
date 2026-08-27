import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../../core/wallpaper_background.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'My Dream Construction');
  final _locationController = TextEditingController(text: 'Bangalore, Karnataka');
  final _plotSizeController = TextEditingController(text: '1200');
  final _budgetController = TextEditingController(text: '4500000');
  final _timelineController = TextEditingController(text: '9 Months');
  
  final List<String> _selectedServices = [
    'Land & Legal',
    'Finance & Approvals',
    'Design & Planning',
    'Construction',
  ];

  bool _isLoading = false;
  int _currentStep = 0; // 0: Basic Info, 1: Services, 2: Specifications, 3: Review

  final _serviceSearchController = TextEditingController();
  String _serviceSearchQuery = '';

  final List<Map<String, dynamic>> _allServices = const [
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

    // --- Detailed Construction Services (60+ Services) ---
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
  void dispose() {
    _serviceSearchController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _plotSizeController.dispose();
    _budgetController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  Future<void> _submitProject() async {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service needed')),
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
      final response = await http.post(
        Uri.parse('$apiBaseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': auth.id,
          'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Site Construction Blueprint',
          'type': _selectedServices.join(', '),
          'location': _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : 'Bangalore',
          'plotSize': double.tryParse(_plotSizeController.text.trim()) ?? 1200.0,
          'budget': double.tryParse(_budgetController.text.trim()) ?? 4500000.0,
          'timeline': _timelineController.text.trim().isNotEmpty ? _timelineController.text.trim() : '9 Months',
          'currentStage': 'Design & Planning',
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Construction Blueprint initialized successfully!'), backgroundColor: Colors.green),
        );
        context.pop(true);
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

  void _showPlotSizeDialog() {
    final controller = TextEditingController(text: _plotSizeController.text);
    final focusNode = FocusNode();
    final quickSizes = ['600', '1200', '1500', '2400', '3000', '4000'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Enter Plot Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      autofocus: false,
                      onSubmitted: (_) {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() => _plotSizeController.text = controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      decoration: InputDecoration(
                        labelText: 'Plot Area',
                        suffixText: 'sq ft',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.square_foot_rounded, color: Color(0xFF6366F1)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Quick Select:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickSizes.map((size) {
                        return ActionChip(
                          label: Text('$size sq ft'),
                          onPressed: () {
                            setModalState(() {
                              controller.text = size;
                            });
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            setState(() {
                              _plotSizeController.text = controller.text.trim();
                            });
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Plot Size', style: TextStyle(fontWeight: FontWeight.bold)),
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

    Future.delayed(const Duration(milliseconds: 180), () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _showBudgetDialog() {
    final controller = TextEditingController(text: _budgetController.text);
    final focusNode = FocusNode();
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
      useSafeArea: true,
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
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Set Budget Limit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      autofocus: false,
                      onSubmitted: (_) {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() => _budgetController.text = controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      decoration: InputDecoration(
                        labelText: 'Estimated Budget',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF10B981)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Quick Select:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickBudgets.map((b) {
                        return ActionChip(
                          label: Text(b['label']!),
                          onPressed: () {
                            setModalState(() {
                              controller.text = b['val']!;
                            });
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            setState(() {
                              _budgetController.text = controller.text.trim();
                            });
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
              ),
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 180), () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _showTimelineDialog() {
    final controller = TextEditingController(text: _timelineController.text);
    final focusNode = FocusNode();
    final quickTimelines = ['3-6 Months', '6-9 Months', '9-12 Months', '12-18 Months', '18-24 Months'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Target Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: false,
                      onSubmitted: (_) {
                        if (controller.text.trim().isNotEmpty) {
                          setState(() => _timelineController.text = controller.text.trim());
                        }
                        Navigator.pop(context);
                      },
                      decoration: InputDecoration(
                        labelText: 'Expected Duration',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Quick Select:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickTimelines.map((t) {
                        return ActionChip(
                          label: Text(t),
                          onPressed: () {
                            setModalState(() {
                              controller.text = t;
                            });
                          },
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            setState(() {
                              _timelineController.text = controller.text.trim();
                            });
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
              ),
            );
          },
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 180), () {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _showProjectDetailsDialog() {
    final titleCtrl = TextEditingController(text: _titleController.text);
    final locCtrl = TextEditingController(text: _locationController.text);
    final titleFocusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Project Identity & Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      focusNode: titleFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Project Title',
                        hintText: 'e.g. 3BHK Villa Construction',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: locCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Site Location',
                        hintText: 'e.g. Indiranagar, Bangalore',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFE11D48)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (titleCtrl.text.trim().isNotEmpty) _titleController.text = titleCtrl.text.trim();
                            if (locCtrl.text.trim().isNotEmpty) _locationController.text = locCtrl.text.trim();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
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

    Future.delayed(const Duration(milliseconds: 180), () {
      if (titleFocusNode.canRequestFocus) {
        titleFocusNode.requestFocus();
      }
    });
  }

  String _formatBudget(String rawBudget) {
    final numVal = double.tryParse(rawBudget);
    if (numVal == null) return rawBudget;
    if (numVal >= 10000000) {
      return '₹ ${(numVal / 10000000).toStringAsFixed(1)} Cr';
    } else if (numVal >= 100000) {
      return '₹ ${(numVal / 100000).toStringAsFixed(1)} Lakhs';
    } else {
      return '₹ ${numVal.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1E293B), size: 28),
            onPressed: () => context.pop(),
          ),
          centerTitle: true,
          title: const Text(
            'New Site Blueprint',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blueprint draft saved securely!')),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline_rounded, color: Color(0xFF4F46E5), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Save Draft',
                        style: TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Hero Banner with Pure Vector CustomPainter (No image dependency)
                                _buildHeroBanner(isSmallScreen),
                                const SizedBox(height: 18),

                                // 2. Stepper Progress Bar
                                _buildStepperIndicator(isSmallScreen),
                                const SizedBox(height: 22),

                                // 3. Section Title
                                const Text(
                                  'REQUIRED EXPERTISE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 4. Services Needed Card Container
                                _buildServicesNeededCard(isSmallScreen),
                                const SizedBox(height: 22),

                                // 5. Specifications & Logistics Header
                                const Text(
                                  'SPECIFICATIONS & LOGISTICS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // 6. Project Title & Location Quick View Card
                                _buildProjectIdentityCard(isSmallScreen),
                                const SizedBox(height: 10),

                                // 7. Specifications Action Tiles (Plot Size, Budget, Timeline)
                                _buildSpecificationTiles(isSmallScreen),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 8. Sticky Bottom Action Bar
                      _buildBottomActionBar(isSmallScreen),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 152 : 166,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 3D Isometric Construction Building & Tower Crane (Pure Canvas Rendering - 0 Asset dependencies)
            Positioned(
              right: 6,
              top: 4,
              bottom: 4,
              width: isSmallScreen ? 140 : 160,
              child: CustomPaint(
                painter: _ConstructionBannerPainter(),
              ),
            ),
            // Left content overlay
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 13.0 : 16.0,
                vertical: isSmallScreen ? 11.0 : 13.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // White round compass icon badge
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.architecture_rounded,
                            color: Color(0xFF4F46E5),
                            size: 19,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Let's build something\ngreat together!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14.5 : 16.5,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Share your project details and get quotes from verified experts.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: isSmallScreen ? 9.5 : 10.5,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 90 : 110), // Reserved space for the 3D building
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperIndicator(bool isSmallScreen) {
    final steps = [
      {'num': '1', 'label': 'Basic Info'},
      {'num': '2', 'label': 'Services'},
      {'num': '3', 'label': 'Specifications'},
      {'num': '4', 'label': 'Review'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector dashed line
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4).copyWith(bottom: 18),
              height: 1.5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dotCount = (constraints.maxWidth / 6).floor().clamp(1, 10);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      dotCount,
                      (_) => Container(
                        width: 3,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final step = steps[stepIdx];
        final isActive = stepIdx == _currentStep;
        final isPassed = stepIdx < _currentStep;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _currentStep = stepIdx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSmallScreen ? 28 : 32,
                height: isSmallScreen ? 28 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : (isPassed ? const Color(0xFF10B981) : const Color(0xFFF1F5F9)),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF6366F1)
                        : (isPassed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Text(
                          step['num']!,
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF64748B),
                            fontSize: isSmallScreen ? 11 : 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              step['label']!,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildServicesNeededCard(bool isSmallScreen) {
    final allCount = _allServices.length;
    final selectedCount = _selectedServices.length;

    final filteredServices = _serviceSearchQuery.trim().isEmpty
        ? _allServices
        : _allServices.where((s) {
            final name = (s['name'] as String).toLowerCase();
            return name.contains(_serviceSearchQuery.trim().toLowerCase());
          }).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Counter Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: Color(0xFF7C3AED),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services Needed',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select all services that apply to your project',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Selection Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedCount > 0 ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedCount > 0 ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$selectedCount of $allCount',
                  style: TextStyle(
                    color: selectedCount > 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Bar & Quick Actions
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _serviceSearchController,
                    onChanged: (val) {
                      setState(() {
                        _serviceSearchQuery = val;
                      });
                    },
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    decoration: InputDecoration(
                      hintText: 'Search 60+ services (e.g. Plumbing, Solar)...',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      suffixIcon: _serviceSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _serviceSearchController.clear();
                                setState(() {
                                  _serviceSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Clear / Select All Button
              InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedServices.length == _allServices.length) {
                      _selectedServices.clear();
                    } else {
                      _selectedServices.clear();
                      _selectedServices.addAll(_allServices.map((s) => s['name'] as String));
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _selectedServices.length == _allServices.length ? 'Clear' : 'Select All',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Column Services Grid (Showing all 60+ services or filtered results)
          if (filteredServices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 32, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'No services found matching "$_serviceSearchQuery"',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredServices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final s = filteredServices[index];
                final name = s['name'] as String;
                final icon = s['icon'] as IconData;
                final color = s['color'] as Color;
                final bg = s['bg'] as Color;
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? bg : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        // Top Right Checkbox Box
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected ? color : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 11)
                                : null,
                          ),
                        ),
                        // Icon & Label
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: color, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                  height: 1.15,
                                ),
                                maxLines: 2,
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
            ),
        ],
      ),
    );
  }

  Widget _buildProjectIdentityCard(bool isSmallScreen) {
    return GestureDetector(
      onTap: _showProjectDetailsDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text.isNotEmpty ? _titleController.text : 'Project Title',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locationController.text.isNotEmpty ? _locationController.text : 'Site Location',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Edit',
              style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF6366F1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationTiles(bool isSmallScreen) {
    return Column(
      children: [
        // 1. Plot Size Tile
        _buildSpecTile(
          icon: Icons.square_foot_rounded,
          iconColor: const Color(0xFF6366F1),
          iconBg: const Color(0xFFEEF2FF),
          title: 'Plot Size',
          value: _plotSizeController.text.isNotEmpty ? '${_plotSizeController.text} sq ft' : 'Add size',
          hasValue: _plotSizeController.text.isNotEmpty,
          onTap: _showPlotSizeDialog,
        ),
        const SizedBox(height: 8),

        // 2. Budget Limit Tile
        _buildSpecTile(
          icon: Icons.currency_rupee_rounded,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFFECFDF5),
          title: 'Budget Limit',
          value: _budgetController.text.isNotEmpty ? _formatBudget(_budgetController.text) : 'Add budget',
          hasValue: _budgetController.text.isNotEmpty,
          onTap: _showBudgetDialog,
        ),
        const SizedBox(height: 8),

        // 3. Target Timeline Tile
        _buildSpecTile(
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBg: const Color(0xFFFFFBEB),
          title: 'Target Timeline',
          value: _timelineController.text.isNotEmpty ? _timelineController.text : 'Select duration',
          hasValue: _timelineController.text.isNotEmpty,
          onTap: _showTimelineDialog,
        ),
      ],
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasValue ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  fontSize: 12.5,
                  fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B4DFF), Color(0xFF3872FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4DFF).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_circle_right_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Save & Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom 3D Isometric Vector Painter for Construction Building & Tower Crane
class _ConstructionBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.58;
    final cy = size.height * 0.42;
    final w = size.width * 0.32;
    final h = size.height * 0.52;
    final dy = w * 0.45; // Isometric angle offset

    // ==========================================
    // 1. ISOMETRIC ROOFTOP DECK (Top Diamond)
    // ==========================================
    final roofPath = Path()
      ..moveTo(cx, cy - dy)
      ..lineTo(cx + w, cy)
      ..lineTo(cx, cy + dy)
      ..lineTo(cx - w, cy)
      ..close();

    final roofPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF475569), Color(0xFF334155)],
      ).createShader(Rect.fromLTWH(cx - w, cy - dy, w * 2, dy * 2));
    canvas.drawPath(roofPath, roofPaint);

    // ==========================================
    // 2. LEFT ISOMETRIC FACADE (Light Face)
    // ==========================================
    final leftFacadePath = Path()
      ..moveTo(cx - w, cy)
      ..lineTo(cx, cy + dy)
      ..lineTo(cx, cy + dy + h)
      ..lineTo(cx - w, cy + h)
      ..close();

    final leftFacadePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(cx - w, cy, w, dy + h));
    canvas.drawPath(leftFacadePath, leftFacadePaint);

    // Left Facade Windows Grid (Isometric Parallelograms)
    const floors = 4;
    final floorH = (h + dy * 0.2) / floors;
    for (int f = 0; f < floors; f++) {
      final fy = cy + 6 + f * floorH;
      // Floor concrete slab line
      final slabPath = Path()
        ..moveTo(cx - w + 2, cy + f * floorH)
        ..lineTo(cx - 2, cy + dy + f * floorH);
      canvas.drawPath(slabPath, Paint()..color = const Color(0xFF64748B)..strokeWidth = 1.5..style = PaintingStyle.stroke);

      // 2 Windows per floor on left face
      for (int win = 0; win < 2; win++) {
        final wx1 = cx - w + 6 + win * (w * 0.44);
        final wx2 = wx1 + (w * 0.38);
        final wy1 = fy + win * (dy * 0.42);
        final wy2 = wy1 + (dy * 0.38);

        final winPath = Path()
          ..moveTo(wx1, wy1)
          ..lineTo(wx2, wy2)
          ..lineTo(wx2, wy2 + floorH * 0.65)
          ..lineTo(wx1, wy1 + floorH * 0.65)
          ..close();

        final isLit = (f + win) % 2 == 0;
        final winShader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLit
              ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
              : [const Color(0xFF0284C7), const Color(0xFF0F172A)],
        ).createShader(Rect.fromLTWH(wx1, wy1, w * 0.38, floorH * 0.65));

        canvas.drawPath(winPath, Paint()..shader = winShader);
        canvas.drawPath(winPath, Paint()..color = Colors.white24..strokeWidth = 0.8..style = PaintingStyle.stroke);
      }
    }

    // ==========================================
    // 3. RIGHT ISOMETRIC FACADE (Shadow Face)
    // ==========================================
    final rightFacadePath = Path()
      ..moveTo(cx, cy + dy)
      ..lineTo(cx + w, cy)
      ..lineTo(cx + w, cy + h)
      ..lineTo(cx, cy + dy + h)
      ..close();

    final rightFacadePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF020617)],
      ).createShader(Rect.fromLTWH(cx, cy, w, dy + h));
    canvas.drawPath(rightFacadePath, rightFacadePaint);

    // Right Facade Windows Grid
    for (int f = 0; f < floors; f++) {
      final slabPath = Path()
        ..moveTo(cx + 2, cy + dy + f * floorH)
        ..lineTo(cx + w - 2, cy + f * floorH);
      canvas.drawPath(slabPath, Paint()..color = const Color(0xFF475569)..strokeWidth = 1.5..style = PaintingStyle.stroke);

      for (int win = 0; win < 2; win++) {
        final wx1 = cx + 6 + win * (w * 0.44);
        final wx2 = wx1 + (w * 0.38);
        final wy1 = cy + dy + 6 + f * floorH - win * (dy * 0.42);
        final wy2 = wy1 - (dy * 0.38);

        final winPath = Path()
          ..moveTo(wx1, wy1)
          ..lineTo(wx2, wy2)
          ..lineTo(wx2, wy2 + floorH * 0.65)
          ..lineTo(wx1, wy1 + floorH * 0.65)
          ..close();

        final winShader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF0F172A)],
        ).createShader(Rect.fromLTWH(wx1, wy2, w * 0.38, floorH * 0.65));

        canvas.drawPath(winPath, Paint()..shader = winShader);
        canvas.drawPath(winPath, Paint()..color = Colors.white12..strokeWidth = 0.8..style = PaintingStyle.stroke);
      }
    }

    // ==========================================
    // 4. ROOFTOP PENTHOUSE & REBAR COLUMNS
    // ==========================================
    final pentX = cx - 12;
    final pentY = cy - dy + 4;
    final pentPath = Path()
      ..moveTo(pentX, pentY)
      ..lineTo(pentX + 16, pentY + 6)
      ..lineTo(pentX + 16, pentY + 18)
      ..lineTo(pentX, pentY + 12)
      ..close();
    canvas.drawPath(pentPath, Paint()..color = const Color(0xFF334155));

    // Rebar vertical steel poles sticking out (under construction)
    final rebarPaint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx - w + 8, cy - 8), Offset(cx - w + 8, cy - 1), rebarPaint);
    canvas.drawLine(Offset(cx - w + 14, cy - 6), Offset(cx - w + 14, cy - 1), rebarPaint);
    canvas.drawLine(Offset(cx + w - 8, cy - 8), Offset(cx + w - 8, cy - 1), rebarPaint);
    canvas.drawLine(Offset(cx + w - 14, cy - 6), Offset(cx + w - 14, cy - 1), rebarPaint);

    // ==========================================
    // 5. 3D TOWER CRANE (Yellow & Steel)
    // ==========================================
    final mastX = cx + 8;
    final mastTop = size.height * 0.05;
    final mastBase = cy + 4;

    // Crane Tower Mast
    final cranePaint = Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(mastX - 3, mastTop), Offset(mastX - 3, mastBase), cranePaint);
    canvas.drawLine(Offset(mastX + 3, mastTop), Offset(mastX + 3, mastBase), cranePaint);

    // Mast cross-lattice
    for (double y = mastTop + 4; y < mastBase - 4; y += 8) {
      canvas.drawLine(Offset(mastX - 3, y), Offset(mastX + 3, y + 8), Paint()..color = const Color(0xFFF59E0B)..strokeWidth = 1.0);
    }

    // Crane Jib (Long boom arm extending forward/left)
    final jibTip = size.width * 0.08;
    final jibBack = size.width * 0.96;
    final boomY = mastTop + 8;

    // Main Jib Arm
    canvas.drawLine(Offset(jibTip, boomY), Offset(jibBack, boomY), cranePaint..strokeWidth = 2.2);
    // Crane Peak & Tie Rods
    canvas.drawLine(Offset(mastX, mastTop), Offset(jibTip + 20, boomY), Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 1.2);
    canvas.drawLine(Offset(mastX, mastTop), Offset(jibBack - 8, boomY), Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 1.2);

    // Crane Operator Cab
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(mastX - 4, boomY + 2, 7, 7), const Radius.circular(1.5)),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(mastX - 3, boomY + 3, 5, 4),
      Paint()..color = const Color(0xFF0284C7),
    );

    // Counterweight block on rear
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(jibBack - 8, boomY + 1, 9, 8), const Radius.circular(2)),
      Paint()..color = const Color(0xFFDC2626),
    );

    // Trolley, Hoist Cable & Suspended Concrete Beam
    final trolleyX = cx - 18;
    canvas.drawCircle(Offset(trolleyX, boomY + 1), 2.2, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawLine(Offset(trolleyX, boomY + 2), Offset(trolleyX, cy - 4), Paint()..color = Colors.white70..strokeWidth = 1.0);

    // Suspended Concrete Beam Block
    final loadRRect = RRect.fromRectAndRadius(Rect.fromLTWH(trolleyX - 8, cy - 4, 16, 6), const Radius.circular(1.5));
    canvas.drawRRect(loadRRect, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(loadRRect, Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 0.8..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
