import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/wallpaper_background.dart';

class CostEstimationScreen extends StatefulWidget {
  const CostEstimationScreen({super.key});

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  // Input States
  String _buildingType = 'House'; // House, Apartment, Villa, Office, Commercial, Warehouse
  String _selectedBhk = '2 BHK'; // 1 BHK, 2 BHK, 3 BHK, 4 BHK, Custom (for residential)
  String _selectedLayout = 'Standard Corporate'; // for Office
  String _selectedWarehouseLayout = 'Standard Storage'; // for Warehouse
  String _selectedCommercialLayout = 'Retail Showroom'; // for Commercial
  double _area = 1000;
  String _quality = 'Standard'; // Basic, Standard, Premium, Ultra Premium
  
  // Add-ons
  bool _includeInterior = false;
  bool _includeLandscaping = false;
  bool _includeSmartHome = false;
  bool _includeSolar = false;

  final TextEditingController _areaController = TextEditingController(text: '1000');
  final _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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

  // Base rate mapping (Basic Quality base rates in INR per sq ft)
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
    final primaryColor = isDark ? const Color(0xFF0F9B8E) : AppTheme.primaryTeal;
    final totalCost = _calculateTotalCost();
    final ratePerSqFt = _area > 0 ? totalCost / _area : 0.0;

    final roomAllocations = getRoomAllocation(_buildingType, _getActiveConfig(), _area);
    final costCategories = getCostCategories();

    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Cost Estimator'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: _showInfoDialog,
            )
          ],
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderCard(primaryColor, isDark),
              
              // Step 1: Building Type
              _buildSectionTitle('1. Select Building Type'),
              _buildBuildingTypeGrid(primaryColor, isDark),
              const SizedBox(height: 8),

              // Step 2: Configuration / BHK
              _buildSectionTitle('2. Configuration Layout'),
              _buildConfigurationSelector(primaryColor, isDark),
              const SizedBox(height: 8),

              // Step 3: Area Input & Presets
              _buildSectionTitle('3. Total Built-Up Area'),
              _buildAreaInputCard(primaryColor, isDark),
              const SizedBox(height: 8),

              // Step 4: Quality Standard
              _buildSectionTitle('4. Construction Material Quality'),
              _buildQualitySelector(primaryColor, isDark),
              const SizedBox(height: 8),

              // Step 5: Premium Add-ons
              _buildSectionTitle('5. Finishes & System Add-ons'),
              _buildAddonsCard(primaryColor, isDark),
              const SizedBox(height: 16),

              // Step 6: Detailed Output & Estimation Reports
              if (totalCost > 0) ...[
                _buildSectionTitle('Estimation Summary Report'),
                _buildSummaryReportCard(totalCost, ratePerSqFt, primaryColor, isDark),
                const SizedBox(height: 16),

                _buildSectionTitle('Detailed Area Allocation Breakdown'),
                _buildAreaAllocationCard(roomAllocations, totalCost, isDark),
                const SizedBox(height: 16),

                _buildSectionTitle('Cost Categories Breakdown'),
                _buildCostCategoriesCard(costCategories, totalCost, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color primaryColor, bool isDark) {
    return Card(
      elevation: 0,
      color: primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precision Cost Calculator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estimate construction expenses, material choices, and room dimensions in real-time.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingTypeGrid(Color primaryColor, bool isDark) {
    final types = [
      {'name': 'House', 'icon': Icons.home_rounded, 'desc': 'Single/Multi family residential'},
      {'name': 'Apartment', 'icon': Icons.apartment_rounded, 'desc': 'High-rise residential units'},
      {'name': 'Villa', 'icon': Icons.villa_rounded, 'desc': 'Premium luxury individual home'},
      {'name': 'Office', 'icon': Icons.business_rounded, 'desc': 'Corporate workspaces & cabins'},
      {'name': 'Commercial', 'icon': Icons.storefront_rounded, 'desc': 'Retail stores, showrooms, malls'},
      {'name': 'Warehouse', 'icon': Icons.warehouse_rounded, 'desc': 'Storage & industrial sheds'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final name = type['name'] as String;
        final icon = type['icon'] as IconData;
        final desc = type['desc'] as String;
        final isSelected = _buildingType == name;

        return Card(
          elevation: isSelected ? 4 : 0.5,
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _buildingType = name;
                // Reset configurations appropriately
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? primaryColor : Colors.grey,
                        size: 24,
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: primaryColor,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isSelected ? primaryColor.withValues(alpha: 0.8) : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigurationSelector(Color primaryColor, bool isDark) {
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
      options = ['Standard Storage', 'Cold Storage Facility', 'Fulfillment Hub', 'Industrial Factory'];
      selected = _selectedWarehouseLayout;
      onSelected = (val) => setState(() => _selectedWarehouseLayout = val);
    } else {
      options = ['Retail Showroom', 'Mixed Use Center', 'Strip Mall', 'Departmental Store'];
      selected = _selectedCommercialLayout;
      onSelected = (val) => setState(() => _selectedCommercialLayout = val);
    }

    return Card(
      elevation: 0.5,
      color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Row(
            children: options.map((opt) {
              final isSelected = selected == opt;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onSelected(opt);
                  },
                  selectedColor: primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: isDark ? const Color(0xFF121B22) : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaInputCard(Color primaryColor, bool isDark) {
    final areaPresets = [500, 1000, 1500, 2000, 3000, 5000];
    
    return Card(
      elevation: 0.5,
      color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Built-up Area (sq ft)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.square_foot_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primaryColor,
                inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
                thumbColor: primaryColor,
                overlayColor: primaryColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: _area.clamp(100, 10000),
                min: 100,
                max: 10000,
                divisions: 99,
                label: '${_area.round()} sq ft',
                onChanged: (v) {
                  setState(() {
                    _area = v.roundToDouble();
                    _areaController.text = _area.toStringAsFixed(0);
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('100 sq ft', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('Selected: ${_area.toStringAsFixed(0)} sq ft', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                const Text('10,000 sq ft', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Presets',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Row(
                children: areaPresets.map((preset) {
                  final isMatch = _area.round() == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _area = preset.toDouble();
                          _areaController.text = preset.toString();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide(
                          color: isMatch ? primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          width: isMatch ? 1.5 : 1,
                        ),
                        backgroundColor: isMatch ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        '${preset.toString()} sq ft',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMatch ? primaryColor : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySelector(Color primaryColor, bool isDark) {
    final grades = [
      {
        'grade': 'Basic',
        'cost': 'Standard Economy',
        'details': 'Local brickwork, standard cement, basic flooring, economic fixtures.',
        'color': Colors.grey,
        'rateMultiplier': 1.0
      },
      {
        'grade': 'Standard',
        'cost': 'Value Premium',
        'details': 'Branded tiles, premium vitrified flooring, OBD wall painting, modular kitchen setups.',
        'color': Colors.blue,
        'rateMultiplier': 1.35
      },
      {
        'grade': 'Premium',
        'cost': 'Elite Construction',
        'details': 'Italian marble, teakwood doors, plastic emulsion paints, high-end modular fittings.',
        'color': Colors.purple,
        'rateMultiplier': 1.75
      },
      {
        'grade': 'Ultra Premium',
        'cost': 'Signature Luxury',
        'details': 'Imported stone/wood, customized architectural glass structures, designer fittings.',
        'color': Colors.amber.shade700,
        'rateMultiplier': 2.25
      },
    ];

    double baseRate = _getBaseRate();

    return Column(
      children: grades.map((g) {
        final gradeName = g['grade'] as String;
        final costName = g['cost'] as String;
        final details = g['details'] as String;
        final color = g['color'] as Color;
        final multiplier = g['rateMultiplier'] as double;
        final isSelected = _quality == gradeName;
        final estimatedRate = baseRate * multiplier;

        return Card(
          elevation: isSelected ? 4 : 0.5,
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _quality = gradeName),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade400,
                        width: isSelected ? 6 : 2,
                      ),
                    ),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? primaryColor : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '₹${estimatedRate.toStringAsFixed(0)}/sqft',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          costName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey.shade600,
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

  Widget _buildAddonsCard(Color primaryColor, bool isDark) {
    return Card(
      elevation: 0.5,
      color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildAddonSwitchTile(
            title: 'Interior Design & Furniture',
            subtitle: 'Wardrobes, modular cabinets, designer false ceiling (+20% cost)',
            value: _includeInterior,
            icon: Icons.chair_rounded,
            onChanged: (v) => setState(() => _includeInterior = v),
          ),
          const Divider(height: 1, indent: 56),
          _buildAddonSwitchTile(
            title: 'Smart Home Automation',
            subtitle: 'Security cameras, smart locks, automated light controllers (+8% cost)',
            value: _includeSmartHome,
            icon: Icons.sensors_rounded,
            onChanged: (v) => setState(() => _includeSmartHome = v),
          ),
          const Divider(height: 1, indent: 56),
          _buildAddonSwitchTile(
            title: 'Landscaping & Gardening',
            subtitle: 'External green lawn, perimeter planting, pathway tiles (+5% cost)',
            value: _includeLandscaping,
            icon: Icons.yard_rounded,
            onChanged: (v) => setState(() => _includeLandscaping = v),
          ),
          const Divider(height: 1, indent: 56),
          _buildAddonSwitchTile(
            title: 'Off-grid Solar Energy Setup',
            subtitle: 'Roof rooftop panel modules, inverter unit & backup battery (+7% cost)',
            value: _includeSolar,
            icon: Icons.solar_power_rounded,
            onChanged: (v) => setState(() => _includeSolar = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: value ? Theme.of(context).primaryColor : Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  Widget _buildSummaryReportCard(
    double totalCost,
    double ratePerSqFt,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F9B8E), const Color(0xFF064354)]
              : [AppTheme.primaryTeal, AppTheme.secondaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'ESTIMATED PROJECT BUDGET',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currencyFormatter.format(totalCost),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Average: ₹${ratePerSqFt.toStringAsFixed(0)} / sq ft',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryStat('Building Type', _buildingType, Icons.construction),
                _buildSummaryStat('Layout Plan', _getActiveConfig(), Icons.grid_view_rounded),
                _buildSummaryStat('Quality Class', _quality, Icons.workspace_premium_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaAllocationCard(
    List<RoomDetail> allocations,
    double totalCost,
    bool isDark,
  ) {
    // Generate distinct colors for visual bar
    final barColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
    ];

    return Card(
      elevation: 0.5,
      color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Space Allocation & Room Sizes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Calculated floor space distribution based on your chosen layout configuration.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Visual Segmented Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(
                  children: List.generate(allocations.length, (idx) {
                    final alloc = allocations[idx];
                    final color = barColors[idx % barColors.length];
                    if (alloc.percentage <= 0) return const SizedBox();
                    return Expanded(
                      flex: (alloc.percentage * 100).round(),
                      child: Container(
                        color: color,
                        child: Tooltip(
                          message: '${alloc.name}: ${(alloc.percentage * 100).toStringAsFixed(0)}%',
                          child: const SizedBox.expand(),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rooms Details List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allocations.length,
              itemBuilder: (context, index) {
                final alloc = allocations[index];
                final color = barColors[index % barColors.length];
                final roomCost = totalCost * alloc.percentage;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      // Badge color block
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(alloc.icon, size: 18, color: isDark ? Colors.white60 : Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alloc.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${(alloc.percentage * 100).toStringAsFixed(0)}% of total layout',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${alloc.areaSqFt.toStringAsFixed(0)} sq ft',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currencyFormatter.format(roomCost),
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.greenAccent : Colors.green.shade700, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCategoriesCard(
    List<CostCategory> categories,
    double totalCost,
    bool isDark,
  ) {
    return Card(
      elevation: 0.5,
      color: isDark ? const Color(0xFF1F2C34) : Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Category Distribution',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'A standard construction cost partition from materials to professional fees.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final catCost = totalCost * cat.percentage;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 18, color: cat.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cat.categoryName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            _currencyFormatter.format(catCost),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: cat.percentage,
                                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(cat.percentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Estimation Logic'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('• Rates are based on standard local construction market indicators.'),
                SizedBox(height: 6),
                Text('• Quality grades dictate the level of luxury, fittings, structural modifications, and materials brand grades.'),
                SizedBox(height: 6),
                Text('• Room space distributions are generated through structural ratios mapped to selected building configurations.'),
                SizedBox(height: 6),
                Text('• Furnishing and add-on services are computed as structural increments of the base civil cost.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Okay'),
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
        case 'Cold Storage Facility':
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
        color: Colors.blue,
      ),
      CostCategory(
        categoryName: 'Flooring & Tiling',
        percentage: 0.12,
        icon: Icons.grid_on_rounded,
        color: Colors.orange,
      ),
      CostCategory(
        categoryName: 'Finishes & Decor (Paint, Putty)',
        percentage: 0.10,
        icon: Icons.format_paint_rounded,
        color: Colors.purple,
      ),
      CostCategory(
        categoryName: 'Plumbing & Sanitation',
        percentage: 0.08,
        icon: Icons.plumbing_rounded,
        color: Colors.teal,
      ),
      CostCategory(
        categoryName: 'Electrical & HVAC Fittings',
        percentage: 0.08,
        icon: Icons.electrical_services_rounded,
        color: Colors.amber,
      ),
      CostCategory(
        categoryName: 'Doors & Windows',
        percentage: 0.07,
        icon: Icons.sensor_door_rounded,
        color: Colors.red,
      ),
      CostCategory(
        categoryName: 'Professional & Labor Fees',
        percentage: 0.10,
        icon: Icons.engineering_rounded,
        color: Colors.green,
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
