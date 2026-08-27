import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/wallpaper_background.dart';

class CostEstimationScreen extends StatefulWidget {
  const CostEstimationScreen({super.key});

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  // Input States
  String _buildingType = 'House'; // House, Apartment, Villa, Office, Commercial, Warehouse
  String _selectedBhk = '2 BHK'; // 1 BHK, 2 BHK, 3 BHK, 4 BHK, Custom
  String _selectedLayout = 'Standard Corporate'; // for Office
  String _selectedWarehouseLayout = 'Standard Storage'; // for Warehouse
  String _selectedCommercialLayout = 'Retail Showroom'; // for Commercial
  double _area = 1000;
  String _quality = 'Standard'; // Basic, Standard, Premium, Ultra Premium

  // Add-ons
  bool _includeInterior = true;
  bool _includeSmartHome = false;
  bool _includeLandscaping = false;
  bool _includeSolar = false;

  final TextEditingController _areaController = TextEditingController(text: '1000');
  final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  // Purple / Indigo accent colors matching reference design
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color darkPurple = Color(0xFF4F46E5);

  @override
  void initState() {
    super.initState();
    _areaController.addListener(() {
      final parsed = double.tryParse(_areaController.text);
      if (parsed != null && parsed != _area) {
        setState(() {
          _area = parsed;
        });
      }
    });
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  // Base rate mapping (INR per sq ft)
  double _getBaseRate() {
    switch (_buildingType) {
      case 'Apartment':
        return 1800;
      case 'Villa':
        return 2200;
      case 'Office':
        return 2000;
      case 'Commercial':
        return 2500;
      case 'Warehouse':
        return 1100;
      case 'House':
      default:
        return 1500;
    }
  }

  // Quality multiplier mapping
  double _getQualityMultiplier() {
    switch (_quality) {
      case 'Standard':
        return 1.35;
      case 'Premium':
        return 1.75;
      case 'Ultra Premium':
        return 2.25;
      case 'Basic':
      default:
        return 1.0;
    }
  }

  // Active configuration based on building type
  String _getActiveConfig() {
    if (_isResidential()) {
      return _selectedBhk;
    } else if (_buildingType == 'Office') {
      return _selectedLayout;
    } else if (_buildingType == 'Warehouse') {
      return _selectedWarehouseLayout;
    } else {
      return _selectedCommercialLayout;
    }
  }

  bool _isResidential() {
    return _buildingType == 'House' || _buildingType == 'Apartment' || _buildingType == 'Villa';
  }

  // Total cost calculation
  double _calculateTotalCost() {
    if (_area <= 0) return 0;

    double baseRate = _getBaseRate();
    double qualityMultiplier = _getQualityMultiplier();
    double baseCost = _area * baseRate * qualityMultiplier;

    // Add-on percentages
    double addOnMultiplier = 1.0;
    if (_includeInterior) addOnMultiplier += 0.20; // +20%
    if (_includeLandscaping) addOnMultiplier += 0.05; // +5%
    if (_includeSmartHome) addOnMultiplier += 0.08; // +8%
    if (_includeSolar) addOnMultiplier += 0.07; // +7%

    return baseCost * addOnMultiplier;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCost = _calculateTotalCost();
    final ratePerSqFt = _area > 0 ? totalCost / _area : 0.0;

    final roomAllocations = getRoomAllocation(_buildingType, _getActiveConfig(), _area);
    final costCategories = getCostCategories();

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF1E293B), size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Cost Estimator',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.info_outline_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
              onPressed: _showInfoDialog,
            )
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  _buildHeaderCard(isDark),
                  const SizedBox(height: 16),

                  // Step 1: Building Type
                  _buildSectionHeader('1', 'Select Building Type', isDark),
                  const SizedBox(height: 10),
                  _buildBuildingTypeGrid(isDark),
                  const SizedBox(height: 20),

                  // Step 2: Configuration / BHK
                  _buildSectionHeader('2', 'Configuration Layout', isDark),
                  const SizedBox(height: 10),
                  _buildConfigurationSelector(isDark),
                  const SizedBox(height: 20),

                  // Step 3: Area Input & Presets
                  _buildSectionHeader('3', 'Total Built-Up Area', isDark),
                  const SizedBox(height: 10),
                  _buildAreaInputCard(isDark),
                  const SizedBox(height: 20),

                  // Step 4: Quality Standard
                  _buildSectionHeader('4', 'Construction Material Quality', isDark),
                  const SizedBox(height: 10),
                  _buildQualitySelector(isDark),
                  const SizedBox(height: 20),

                  // Architectural Hero Banner Illustration
                  _buildHeroBanner(isDark),
                  const SizedBox(height: 20),

                  // Step 5: Premium Add-ons
                  _buildSectionHeader('5', 'Finishes & System Add-ons', isDark),
                  const SizedBox(height: 10),
                  _buildAddonsCard(isDark),
                  const SizedBox(height: 24),

                  // Step 6: Detailed Output & Estimation Reports
                  if (totalCost > 0) ...[
                    _buildSummaryReportCard(totalCost, ratePerSqFt, isDark),
                    const SizedBox(height: 20),

                    _buildSectionHeader(null, 'Space Allocation & Room Sizes', isDark, subtitle: 'Calculated floor space distribution based on your chosen layout configuration.'),
                    const SizedBox(height: 10),
                    _buildAreaAllocationCard(roomAllocations, totalCost, isDark),
                    const SizedBox(height: 20),

                    _buildSectionHeader(null, 'Cost Categories Breakdown', isDark, subtitle: 'A standard construction cost partition from materials to professional fees.'),
                    const SizedBox(height: 10),
                    _buildCostCategoriesCard(costCategories, totalCost, isDark),
                  ],
                ],
              ),
            ),

            // Bottom Sticky Total Estimated Bar
            if (totalCost > 0)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildBottomStickyBar(totalCost, isDark),
              ),
          ],
        ),
      ),
    );
  }

  // Section header with purple numbered badge or icon
  Widget _buildSectionHeader(String? stepNumber, String title, bool isDark, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: primaryPurple,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: stepNumber != null
                    ? Text(
                        stepNumber,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    : const Icon(Icons.grid_view_rounded, color: Colors.white, size: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Top Header Card
  Widget _buildHeaderCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryPurple.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precision Cost Calculator',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimate construction expenses, material choices, and room dimensions in real-time.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section 1: 2-Column Building Type Grid with 3D Renders
  Widget _buildBuildingTypeGrid(bool isDark) {
    final types = [
      {
        'name': 'House',
        'desc': 'Single/Multi family residential',
        'image': 'assets/images/estimator_house.jpg',
      },
      {
        'name': 'Apartment',
        'desc': 'High-rise residential units',
        'image': 'assets/images/estimator_apartment.jpg',
      },
      {
        'name': 'Villa',
        'desc': 'Premium luxury individual home',
        'image': 'assets/images/estimator_villa.jpg',
      },
      {
        'name': 'Office',
        'desc': 'Corporate workspaces & cabins',
        'image': 'assets/images/estimator_office.jpg',
      },
      {
        'name': 'Commercial',
        'desc': 'Retail stores, showrooms, malls',
        'image': 'assets/images/estimator_commercial.jpg',
      },
      {
        'name': 'Warehouse',
        'desc': 'Storage & industrial sheds',
        'image': 'assets/images/estimator_warehouse.jpg',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final name = type['name'] as String;
        final desc = type['desc'] as String;
        final imagePath = type['image'] as String;
        final isSelected = _buildingType == name;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _buildingType = name;
              if (_isResidential()) {
                _selectedBhk = '2 BHK';
              } else if (_buildingType == 'Office') {
                _selectedLayout = 'Standard Corporate';
              } else if (_buildingType == 'Warehouse') {
                _selectedWarehouseLayout = 'Standard Storage';
              } else {
                _selectedCommercialLayout = 'Retail Showroom';
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryPurple.withValues(alpha: isDark ? 0.15 : 0.06)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryPurple : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: primaryPurple.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Architectural render image
                      Expanded(
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: primaryPurple.withValues(alpha: 0.1),
                                  child: const Icon(Icons.home_work_rounded, color: primaryPurple, size: 36),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? primaryPurple : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Section 2: Configuration Layout / BHK Horizontal Pills
  Widget _buildConfigurationSelector(bool isDark) {
    List<String> options = [];
    String selected = '';
    void Function(String) onSelected;

    if (_isResidential()) {
      options = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Custom'];
      selected = _selectedBhk;
      onSelected = (val) => setState(() => _selectedBhk = val);
    } else if (_buildingType == 'Office') {
      options = ['Basic Layout', 'Standard Corporate', 'Premium Co-working', 'Executive HQ'];
      selected = _selectedLayout;
      onSelected = (val) => setState(() => _selectedLayout = val);
    } else if (_buildingType == 'Warehouse') {
      options = ['Standard Storage', 'Cold Storage', 'Fulfillment Hub', 'Industrial Factory'];
      selected = _selectedWarehouseLayout;
      onSelected = (val) => setState(() => _selectedWarehouseLayout = val);
    } else {
      options = ['Retail Showroom', 'Mixed Use Center', 'Strip Mall', 'Departmental Store'];
      selected = _selectedCommercialLayout;
      onSelected = (val) => setState(() => _selectedCommercialLayout = val);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryPurple
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primaryPurple
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: primaryPurple.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                    ] else if (opt == 'Custom') ...[
                      Icon(Icons.tune_rounded, color: isDark ? Colors.white60 : const Color(0xFF64748B), size: 15),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Section 3: Built-Up Area Card with Slider and Quick Presets
  Widget _buildAreaInputCard(bool isDark) {
    final areaPresets = [500, 1000, 1500, 2000, 3000, 5000];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Built-up Area (sq ft)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          // Numeric Area Input Container with sq ft badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    'sq ft',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Purple Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryPurple,
              inactiveTrackColor: primaryPurple.withValues(alpha: 0.18),
              thumbColor: primaryPurple,
              overlayColor: primaryPurple.withValues(alpha: 0.15),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _area.clamp(100, 10000),
              min: 100,
              max: 10000,
              divisions: 99,
              onChanged: (v) {
                setState(() {
                  _area = v.roundToDouble();
                  _areaController.text = _area.toStringAsFixed(0);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '100 sq ft',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
                Text(
                  'Selected: ${_area.toStringAsFixed(0)} sq ft',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                Text(
                  '10,000 sq ft',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Quick Presets',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Presets Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: areaPresets.map((preset) {
                final isSelected = _area.round() == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _area = preset.toDouble();
                        _areaController.text = preset.toString();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryPurple
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? primaryPurple
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        '$preset sq ft',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Section 4: Construction Material Quality Radio Cards
  Widget _buildQualitySelector(bool isDark) {
    final grades = [
      {
        'grade': 'Basic',
        'cost': 'Standard Economy',
        'details': 'Local brickwork, standard cement, basic flooring, economic fixtures.',
        'badgeBg': const Color(0xFFE0F2FE),
        'badgeColor': const Color(0xFF0284C7),
        'rateMultiplier': 1.0,
      },
      {
        'grade': 'Standard',
        'cost': 'Value Premium',
        'details': 'Branded tiles, premium vitrified flooring, OBD wall painting, modular kitchen setups.',
        'badgeBg': const Color(0xFFEDE9FE),
        'badgeColor': const Color(0xFF7C3AED),
        'rateMultiplier': 1.35,
      },
      {
        'grade': 'Premium',
        'cost': 'Elite Construction',
        'details': 'Italian marble, teakwood doors, plastic emulsion paints, high-end modular fittings.',
        'badgeBg': const Color(0xFFFFEDD5),
        'badgeColor': const Color(0xFFEA580C),
        'rateMultiplier': 1.75,
      },
      {
        'grade': 'Ultra Premium',
        'cost': 'Signature Luxury',
        'details': 'Imported stone/wood, customized architectural glass structures, designer fittings.',
        'badgeBg': const Color(0xFFDCFCE7),
        'badgeColor': const Color(0xFF16A34A),
        'rateMultiplier': 2.25,
      },
    ];

    double baseRate = _getBaseRate();

    return Column(
      children: grades.map((g) {
        final gradeName = g['grade'] as String;
        final costName = g['cost'] as String;
        final details = g['details'] as String;
        final badgeBg = g['badgeBg'] as Color;
        final badgeColor = g['badgeColor'] as Color;
        final multiplier = g['rateMultiplier'] as double;
        final isSelected = _quality == gradeName;
        final estimatedRate = baseRate * multiplier;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _quality = gradeName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryPurple.withValues(alpha: isDark ? 0.15 : 0.05)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? primaryPurple
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Radio Indicator
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primaryPurple : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: primaryPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              gradeName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? primaryPurple : (isDark ? Colors.white : const Color(0xFF1E293B)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? badgeColor.withValues(alpha: 0.2) : badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹${estimatedRate.toStringAsFixed(0)}/sqft',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? badgeColor.withValues(alpha: 0.9) : badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          costName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            height: 1.25,
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
      }).toList(),
    );
  }

  // Architectural Hero Banner placed between Quality & Add-ons
  Widget _buildHeroBanner(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Image.asset(
          'assets/images/estimator_hero.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(),
        ),
      ),
    );
  }

  // Section 5: Premium Add-ons Switch Card
  Widget _buildAddonsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAddonTile(
            title: 'Interior Design & Furniture',
            subtitle: 'Wardrobes, modular cabinets, designer false ceiling',
            percentage: '+20%',
            value: _includeInterior,
            icon: Icons.chair_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            isDark: isDark,
            onChanged: (v) => setState(() => _includeInterior = v),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildAddonTile(
            title: 'Smart Home Automation',
            subtitle: 'Security cameras, smart locks, automated light controllers',
            percentage: '+8%',
            value: _includeSmartHome,
            icon: Icons.wifi_rounded,
            iconBg: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            isDark: isDark,
            onChanged: (v) => setState(() => _includeSmartHome = v),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildAddonTile(
            title: 'Landscaping & Gardening',
            subtitle: 'External green lawn, perimeter planting, pathway tiles',
            percentage: '+5%',
            value: _includeLandscaping,
            icon: Icons.eco_rounded,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            isDark: isDark,
            onChanged: (v) => setState(() => _includeLandscaping = v),
          ),
          Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildAddonTile(
            title: 'Off-grid Solar Energy Setup',
            subtitle: 'Roof rooftop panel modules, inverter unit & backup battery',
            percentage: '+7%',
            value: _includeSolar,
            icon: Icons.solar_power_rounded,
            iconBg: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFEA580C),
            isDark: isDark,
            onChanged: (v) => setState(() => _includeSolar = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonTile({
    required String title,
    required String subtitle,
    required String percentage,
    required bool value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDark ? Colors.white70 : iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: value,
                  activeThumbColor: primaryPurple,
                  activeTrackColor: primaryPurple.withValues(alpha: 0.3),
                  onChanged: onChanged,
                ),
              ),
              Text(
                '$percentage of total cost',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section 6: Estimation Summary Report Card (Gradient Cyan/Blue with 3D Coins)
  Widget _buildSummaryReportCard(double totalCost, double ratePerSqFt, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF0369A1),
            Color(0xFF0D9488),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Estimation Summary Report',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ESTIMATED PROJECT BUDGET',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormatter.format(totalCost),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Average: ₹${ratePerSqFt.toStringAsFixed(0)} / sq ft',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // 3D Gold Coins Graphic
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/images/estimator_coins.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Glassmorphic Bottom Tiles
          Row(
            children: [
              _buildSummaryParameterTile(Icons.home_rounded, 'Building Type', _buildingType),
              const SizedBox(width: 8),
              _buildSummaryParameterTile(Icons.grid_view_rounded, 'Layout Plan', _getActiveConfig()),
              const SizedBox(width: 8),
              _buildSummaryParameterTile(Icons.workspace_premium_rounded, 'Quality Class', _quality),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryParameterTile(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
  }

  // Section 7: Space Allocation & Room Sizes Card
  Widget _buildAreaAllocationCard(List<RoomDetail> allocations, double totalCost, bool isDark) {
    final barColors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFFEC4899), // Pink
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Segmented Multi-Color Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: List.generate(allocations.length, (idx) {
                  final alloc = allocations[idx];
                  final color = barColors[idx % barColors.length];
                  if (alloc.percentage <= 0) return const SizedBox();
                  return Expanded(
                    flex: (alloc.percentage * 100).round(),
                    child: Container(color: color),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // List of Room Allocation Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allocations.length,
            separatorBuilder: (context, index) => Divider(
              height: 14,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final alloc = allocations[index];
              final color = barColors[index % barColors.length];
              final roomCost = totalCost * alloc.percentage;

              return Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(alloc.icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alloc.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${(alloc.percentage * 100).toStringAsFixed(0)}% of total layout',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${alloc.areaSqFt.toStringAsFixed(0)} sq ft',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(roomCost),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Section 8: Cost Categories Breakdown Card
  Widget _buildCostCategoriesCard(List<CostCategory> categories, double totalCost, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (context, index) => Divider(
          height: 18,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final catCost = totalCost * cat.percentage;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(cat.icon, size: 14, color: cat.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat.categoryName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    _currencyFormatter.format(catCost),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 36),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: cat.percentage,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(cat.percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Floating Bottom Total Bar
  Widget _buildBottomStickyBar(double totalCost, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFC7D2FE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Estimated Budget',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : darkPurple,
            ),
          ),
          Text(
            _currencyFormatter.format(totalCost),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Estimation Logic', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('• Rates are based on standard local construction market indicators.'),
                SizedBox(height: 6),
                Text('• Quality grades dictate the level of luxury, fittings, structural modifications, and brand grades.'),
                SizedBox(height: 6),
                Text('• Room space distributions are generated through structural ratios mapped to selected building configurations.'),
                SizedBox(height: 6),
                Text('• Finishes and add-ons are calculated as increments on top of civil base costs.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple)),
            ),
          ],
        );
      },
    );
  }

  // Room allocation helper data mappings
  List<RoomDetail> getRoomAllocation(String buildingType, String config, double totalArea) {
    Map<String, double> allocation = {};

    if (buildingType == 'House' || buildingType == 'Apartment' || buildingType == 'Villa') {
      switch (config) {
        case '1 BHK':
          allocation = {
            'Living Room / Hall': 0.35,
            'Master Bedroom': 0.22,
            'Kitchen': 0.15,
            'Bathroom': 0.10,
            'Passage & Utility': 0.10,
            'Balcony': 0.08,
          };
          break;
        case '2 BHK':
          allocation = {
            'Living Room / Hall': 0.30,
            'Master Bedroom': 0.18,
            'Bedroom 2': 0.15,
            'Kitchen': 0.12,
            'Bathrooms (2)': 0.10,
            'Passage & Utility': 0.08,
            'Balcony': 0.07,
          };
          break;
        case '3 BHK':
          allocation = {
            'Living Room / Hall': 0.25,
            'Master Bedroom': 0.16,
            'Bedroom 2': 0.13,
            'Bedroom 3': 0.12,
            'Kitchen': 0.11,
            'Bathrooms (3)': 0.10,
            'Passage & Utility': 0.07,
            'Balcony': 0.06,
          };
          break;
        case '4 BHK':
          allocation = {
            'Living Room / Hall': 0.22,
            'Master Bedroom': 0.15,
            'Bedroom 2': 0.12,
            'Bedroom 3': 0.11,
            'Bedroom 4': 0.10,
            'Kitchen': 0.10,
            'Bathrooms (4)': 0.10,
            'Passage & Utility': 0.05,
            'Balcony': 0.05,
          };
          break;
        default: // Custom
          allocation = {
            'Living Area / Hall': 0.30,
            'Bedrooms': 0.30,
            'Kitchen': 0.15,
            'Bathrooms': 0.10,
            'Passage & Balcony': 0.15,
          };
      }
    } else if (buildingType == 'Office') {
      switch (config) {
        case 'Basic Layout':
          allocation = {
            'Open Workstation Area': 0.50,
            'Reception & Waiting': 0.15,
            'Executive Cabin': 0.12,
            'Restrooms & Utility': 0.13,
            'Pantry': 0.10,
          };
          break;
        case 'Standard Corporate':
          allocation = {
            'Open Workstations': 0.40,
            'Executive Cabins': 0.18,
            'Conference Room': 0.15,
            'Reception & Lounge': 0.12,
            'Restrooms & Utility': 0.08,
            'Pantry & Cafeteria': 0.07,
          };
          break;
        case 'Premium Co-working':
          allocation = {
            'Hot Desks & Open Area': 0.35,
            'Private Offices': 0.20,
            'Meeting Rooms': 0.15,
            'Cafeteria & Lounge': 0.15,
            'Restrooms & Server Room': 0.08,
            'Reception & Phone Booths': 0.07,
          };
          break;
        default: // Executive HQ
          allocation = {
            'Executive Cabins & Suites': 0.30,
            'Open Workstations': 0.25,
            'Boardrooms & Meeting': 0.15,
            'Grand Lobby & Reception': 0.15,
            'Lounge & Dining Area': 0.10,
            'Server & Utility Rooms': 0.05,
          };
      }
    } else if (buildingType == 'Warehouse') {
      switch (config) {
        case 'Standard Storage':
          allocation = {
            'Racking & Inventory Area': 0.80,
            'Admin Office': 0.08,
            'Loading / Unloading Bay': 0.07,
            'Utility & Restrooms': 0.05,
          };
          break;
        case 'Cold Storage':
          allocation = {
            'Cold Vaults & Chillers': 0.70,
            'Sorting & Processing Hall': 0.15,
            'Office & Control Room': 0.06,
            'Refrigerated Loading Bay': 0.05,
            'Machine Room & Utility': 0.04,
          };
          break;
        case 'Fulfillment Hub':
          allocation = {
            'Sorting & Staging Area': 0.40,
            'Storage & Racking': 0.35,
            'Loading & Docking Bays': 0.15,
            'Office & Security Room': 0.06,
            'Restrooms & Staff Room': 0.04,
          };
          break;
        default: // Industrial Factory
          allocation = {
            'Production & Assembly Line': 0.50,
            'Inventory & Warehouse Area': 0.30,
            'Quality Lab & Offices': 0.10,
            'Utility & Power Room': 0.06,
            'Restrooms & Locker Rooms': 0.04,
          };
      }
    } else { // Commercial Building
      switch (config) {
        case 'Retail Showroom':
          allocation = {
            'Display & Sales Floor': 0.65,
            'Stockroom & Inventory': 0.15,
            'Billing Counter & Reception': 0.10,
            'Restrooms & Office': 0.10,
          };
          break;
        case 'Mixed Use Center':
          allocation = {
            'Retail Storefronts': 0.50,
            'Office Spaces': 0.25,
            'Lobby & Corridors': 0.13,
            'Service Areas & Restrooms': 0.08,
            'Admin & Security': 0.04,
          };
          break;
        case 'Strip Mall':
          allocation = {
            'Commercial Shop Units': 0.60,
            'Walkways & Parking Zone': 0.20,
            'Restrooms & Electrical Room': 0.12,
            'Management Office': 0.08,
          };
          break;
        default: // Departmental Store
          allocation = {
            'Shopping Aisles': 0.55,
            'Checkout Counters & Lobby': 0.15,
            'Backstage Stock Area': 0.15,
            'Fitting Rooms & Restrooms': 0.08,
            'Admin & Server Room': 0.07,
          };
      }
    }

    IconData getIconForRoom(String room) {
      final lower = room.toLowerCase();
      if (lower.contains('living') || lower.contains('hall') || lower.contains('lobby') || lower.contains('reception')) {
        return Icons.chair_rounded;
      } else if (lower.contains('master') || lower.contains('bedroom') || lower.contains('guest') || lower.contains('kids') || lower.contains('suite')) {
        return Icons.bed_rounded;
      } else if (lower.contains('kitchen') || lower.contains('pantry') || lower.contains('cafeteria')) {
        return Icons.soup_kitchen_rounded;
      } else if (lower.contains('bathroom') || lower.contains('restroom') || lower.contains('fitting')) {
        return Icons.wc_rounded;
      } else if (lower.contains('balcony') || lower.contains('deck') || lower.contains('walkway')) {
        return Icons.balcony_rounded;
      } else if (lower.contains('passage') || lower.contains('utility') || lower.contains('corridor') || lower.contains('common')) {
        return Icons.door_sliding_rounded;
      } else if (lower.contains('workstation') || lower.contains('desk') || lower.contains('office') || lower.contains('cabin') || lower.contains('admin')) {
        return Icons.desktop_mac_rounded;
      } else if (lower.contains('meeting') || lower.contains('boardroom') || lower.contains('conference') || lower.contains('huddle')) {
        return Icons.groups_rounded;
      } else if (lower.contains('storage') || lower.contains('racking') || lower.contains('vault') || lower.contains('inventory') || lower.contains('stock')) {
        return Icons.inventory_2_rounded;
      } else if (lower.contains('loading') || lower.contains('dock') || lower.contains('bay')) {
        return Icons.local_shipping_rounded;
      } else if (lower.contains('machine') || lower.contains('server') || lower.contains('power') || lower.contains('utility') || lower.contains('control')) {
        return Icons.developer_board_rounded;
      } else if (lower.contains('production') || lower.contains('assembly') || lower.contains('lab')) {
        return Icons.precision_manufacturing_rounded;
      } else if (lower.contains('shop') || lower.contains('retail') || lower.contains('showroom') || lower.contains('display')) {
        return Icons.storefront_rounded;
      }
      return Icons.space_dashboard_rounded;
    }

    return allocation.entries.map((e) {
      return RoomDetail(
        name: e.key,
        percentage: e.value,
        areaSqFt: totalArea * e.value,
        icon: getIconForRoom(e.key),
      );
    }).toList();
  }

  List<CostCategory> getCostCategories() {
    return [
      CostCategory(
        categoryName: 'Civil & Structural Work',
        percentage: 0.45,
        icon: Icons.foundation_rounded,
        color: const Color(0xFF3B82F6),
      ),
      CostCategory(
        categoryName: 'Flooring & Tiling',
        percentage: 0.12,
        icon: Icons.grid_on_rounded,
        color: const Color(0xFFF97316),
      ),
      CostCategory(
        categoryName: 'Finishes & Decor (Paint, Putty)',
        percentage: 0.10,
        icon: Icons.format_paint_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      CostCategory(
        categoryName: 'Plumbing & Sanitation',
        percentage: 0.08,
        icon: Icons.plumbing_rounded,
        color: const Color(0xFF06B6D4),
      ),
      CostCategory(
        categoryName: 'Electrical & HVAC Fittings',
        percentage: 0.08,
        icon: Icons.electrical_services_rounded,
        color: const Color(0xFFF59E0B),
      ),
      CostCategory(
        categoryName: 'Doors & Windows',
        percentage: 0.07,
        icon: Icons.sensor_door_rounded,
        color: const Color(0xFFEF4444),
      ),
      CostCategory(
        categoryName: 'Professional & Labor Fees',
        percentage: 0.10,
        icon: Icons.engineering_rounded,
        color: const Color(0xFF10B981),
      ),
    ];
  }
}

class RoomDetail {
  final String name;
  final double areaSqFt;
  final double percentage;
  final IconData icon;

  RoomDetail({
    required this.name,
    required this.areaSqFt,
    required this.percentage,
    required this.icon,
  });
}

class CostCategory {
  final String categoryName;
  final double percentage;
  final IconData icon;
  final Color color;

  CostCategory({
    required this.categoryName,
    required this.percentage,
    required this.icon,
    required this.color,
  });
}
