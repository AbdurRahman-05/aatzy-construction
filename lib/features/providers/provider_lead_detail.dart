import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import '../../core/wallpaper_background.dart';

class ProviderLeadDetail extends ConsumerStatefulWidget {
  final String leadId;
  const ProviderLeadDetail({super.key, required this.leadId});

  @override
  ConsumerState<ProviderLeadDetail> createState() => _ProviderLeadDetailState();
}

class _ProviderLeadDetailState extends ConsumerState<ProviderLeadDetail> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showAllServices = false;
  Map<String, dynamic>? _existingQuote;

  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _timelineController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _quickTimelines = const [
    '2-4 Weeks',
    '1-2 Months',
    '3-4 Months',
    '6 Months',
    '9-12 Months',
  ];

  @override
  void initState() {
    super.initState();
    _costController.addListener(_onCostChanged);
    _fetchProjectDetails();
  }

  void _onCostChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _costController.removeListener(_onCostChanged);
    _costController.dispose();
    _timelineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/projects/${widget.leadId}'));
      if (response.statusCode == 200) {
        if (mounted) {
          final decoded = jsonDecode(response.body);
          setState(() {
            _project = decoded;
            _isLoading = false;
          });

          // Check if provider has already quoted
          final auth = ref.read(authProvider);
          if (auth.id != null && _project?['quotes'] is List) {
            final quotes = _project!['quotes'] as List;
            final match = quotes.firstWhere(
              (q) => q['providerId'] == auth.id || q['provider']?['id'] == auth.id,
              orElse: () => null,
            );
            if (match != null) {
              setState(() => _existingQuote = match);
              if (_costController.text.isEmpty && match['estimatedCost'] != null) {
                _costController.text = (match['estimatedCost'] as num).toInt().toString();
              }
              if (_timelineController.text.isEmpty && match['timeline'] != null) {
                _timelineController.text = match['timeline'];
              }
              if (_notesController.text.isEmpty && match['notes'] != null) {
                _notesController.text = match['notes'];
              }
            }
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching project details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please login again.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/quotes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'projectId': widget.leadId,
          'providerId': auth.id,
          'estimatedCost': double.tryParse(_costController.text.trim()) ?? 0.0,
          'timeline': _timelineController.text.trim(),
          'notes': _notesController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Quote submitted successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to submit quote'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting quote: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Failed to reach server.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatCurrency(dynamic val) {
    if (val == null) return 'Not Specified';
    final numVal = val is num ? val : double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    if (numVal == null || numVal == 0) return 'Not Specified';
    try {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(numVal);
    } catch (_) {
      return '₹$numVal';
    }
  }

  String _formatCompactBudget(dynamic val) {
    if (val == null) return '';
    final numVal = val is num ? val : double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    if (numVal == null || numVal == 0) return '';
    if (numVal >= 10000000) {
      return '≈ ₹${(numVal / 10000000).toStringAsFixed(2)} Cr';
    } else if (numVal >= 100000) {
      return '≈ ₹${(numVal / 100000).toStringAsFixed(1)} Lakhs';
    }
    return '';
  }

  IconData _getServiceIcon(String serviceName) {
    final s = serviceName.toLowerCase();
    if (s.contains('design') || s.contains('plan') || s.contains('architect')) {
      return Icons.architecture_rounded;
    }
    if (s.contains('construct') || s.contains('build') || s.contains('cement') || s.contains('concrete')) {
      return Icons.construction_rounded;
    }
    if (s.contains('electric') || s.contains('power') || s.contains('solar')) {
      return Icons.electrical_services_rounded;
    }
    if (s.contains('plumb') || s.contains('water') || s.contains('drain') || s.contains('borewell')) {
      return Icons.plumbing_rounded;
    }
    if (s.contains('interior') || s.contains('floor') || s.contains('tile') || s.contains('paint')) {
      return Icons.chair_rounded;
    }
    if (s.contains('roof') || s.contains('demolition') || s.contains('ground')) {
      return Icons.roofing_rounded;
    }
    if (s.contains('legal') || s.contains('approv') || s.contains('finance') || s.contains('survey')) {
      return Icons.gavel_rounded;
    }
    if (s.contains('smart') || s.contains('security') || s.contains('pest')) {
      return Icons.shield_rounded;
    }
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return WallpaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            title: const Text('Lead Details', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
          ),
        ),
      );
    }

    if (_project == null) {
      return WallpaperBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Lead Details'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 54, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Lead details not found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Leads'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final title = _project!['title'] ?? 'Construction Project';
    final rawType = (_project!['type'] ?? '').toString().trim();
    final location = _project!['location'] ?? 'Tamil Nadu';
    final plotSize = _project!['plotSize']?.toString() ?? 'N/A';
    final budgetNum = _project!['budget'];
    final timeline = _project!['timeline'] ?? 'Flexible';
    final currentStage = _project!['currentStage'] ?? 'Planning & Approvals';
    final user = _project!['user'] ?? {};
    final userName = user['name'] ?? 'Client';

    // Parse Property Type and Services from raw type string
    String propertyType = 'Residential Villa';
    List<String> servicesList = [];

    if (rawType.contains(' - ')) {
      final parts = rawType.split(' - ');
      propertyType = parts[0].trim();
      final afterDash = parts.sublist(1).join(' - ');
      servicesList = afterDash.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (rawType.contains(',')) {
      servicesList = rawType.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      propertyType = 'Custom Project';
    } else if (rawType.isNotEmpty) {
      propertyType = rawType;
    }

    final displayedServices = _showAllServices ? servicesList : servicesList.take(6).toList();

    // Theme tokens
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primaryTeal = Color(0xFF0D9488);
    const deepTeal = Color(0xFF0F766E);

    // Live quotation cost calculation helper
    final enteredCost = double.tryParse(_costController.text.trim()) ?? 0.0;
    final clientBudgetVal = budgetNum is num ? budgetNum.toDouble() : double.tryParse(budgetNum?.toString() ?? '0') ?? 0.0;

    return WallpaperBackground(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/provider-home');
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF121B22) : Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/provider-home');
                }
              },
            ),
            centerTitle: true,
            title: const Text(
              'Lead Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryTeal.withValues(alpha: 0.28)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: primaryTeal),
                        SizedBox(width: 4),
                        Text(
                          'ACTIVE LEAD',
                          style: TextStyle(
                            color: primaryTeal,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 1. HERO PROJECT OVERVIEW CARD
                  // ==========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Property Type Pill & Status
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.domain_rounded, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    propertyType,
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: subTextColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Lead',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Project Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: subTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // 2. 2x2 KEY SPECIFICATIONS GRID
                  // ==========================================
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: [
                      // Budget Metric
                      _buildSpecTile(
                        icon: Icons.currency_rupee_rounded,
                        iconColor: const Color(0xFF10B981),
                        iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                        label: 'CLIENT BUDGET',
                        value: _formatCurrency(budgetNum),
                        subtitle: _formatCompactBudget(budgetNum),
                        valueColor: const Color(0xFF10B981),
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                      ),
                      // Plot Area Metric
                      _buildSpecTile(
                        icon: Icons.square_foot_rounded,
                        iconColor: const Color(0xFF0D9488),
                        iconBg: isDark ? const Color(0xFF134E4A) : const Color(0xFFF0FDFA),
                        label: 'PLOT AREA',
                        value: plotSize == 'N/A' ? 'N/A' : '$plotSize sq ft',
                        subtitle: 'Site Footprint',
                        valueColor: textColor,
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                      ),
                      // Timeline Metric
                      _buildSpecTile(
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        iconBg: isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
                        label: 'TARGET TIMELINE',
                        value: timeline,
                        subtitle: 'Requested Schedule',
                        valueColor: textColor,
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                      ),
                      // Stage Metric
                      _buildSpecTile(
                        icon: Icons.engineering_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        iconBg: isDark ? const Color(0xFF3B0764) : const Color(0xFFF5F3FF),
                        label: 'CURRENT STAGE',
                        value: currentStage,
                        subtitle: 'Awaiting Quotes',
                        valueColor: textColor,
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // 3. REQUIRED SERVICES (CLEAN TAGS & EXPANDABLE)
                  // ==========================================
                  if (servicesList.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.handyman_rounded, size: 16, color: primaryTeal),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Required Services',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: textColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${servicesList.length} Disciplines',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: displayedServices.map((service) {
                              final icon = _getServiceIcon(service);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 14, color: primaryTeal),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        service,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          if (servicesList.length > 6) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => setState(() => _showAllServices = !_showAllServices),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showAllServices
                                          ? 'Show Less'
                                          : 'Show all ${servicesList.length} services (${servicesList.length - 6} more)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: primaryTeal,
                                      ),
                                    ),
                                    Icon(
                                      _showAllServices ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: primaryTeal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // ==========================================
                  // 4. CLIENT PROFILE CARD
                  // ==========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryTeal.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Row(
                                children: [
                                  Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Aatzy Client',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryTeal.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 13, color: primaryTeal),
                              SizedBox(width: 4),
                              Text(
                                'Direct',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryTeal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // 5. SUBMIT QUOTATION FORM CARD
                  // ==========================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _existingQuote != null
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : cardBorder,
                        width: _existingQuote != null ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quotation Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.request_quote_rounded, size: 20, color: Color(0xFF0F766E)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _existingQuote != null ? 'Your Submitted Quote' : 'Submit Your Quotation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.5,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    _existingQuote != null
                                        ? 'You can revise your bid anytime'
                                        : 'Send a competitive proposal to win this project',
                                    style: TextStyle(fontSize: 11.5, color: subTextColor),
                                  ),
                                ],
                              ),
                            ),
                            if (_existingQuote != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text(
                                      'SUBMITTED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Field 1: Estimated Cost
                        Text(
                          'ESTIMATED TOTAL COST (₹)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: subTextColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 4200000',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18, color: Color(0xFF10B981)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryTeal, width: 1.8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Estimated cost is required';
                            if (double.tryParse(v.trim()) == null) return 'Enter a valid numeric amount';
                            return null;
                          },
                        ),

                        // Live Budget Feedback & Helper
                        if (enteredCost > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Quoted: ${_formatCurrency(enteredCost)} ${_formatCompactBudget(enteredCost)}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const Spacer(),
                              if (clientBudgetVal > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: enteredCost <= clientBudgetVal
                                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    enteredCost <= clientBudgetVal ? '✓ Within client budget' : '▲ Above client budget',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: enteredCost <= clientBudgetVal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Field 2: Timeline
                        Text(
                          'YOUR PROPOSED TIMELINE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: subTextColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _timelineController,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 6 Months, 16 Weeks',
                            prefixIcon: const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFFF59E0B)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryTeal, width: 1.8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Timeline is required' : null,
                        ),
                        const SizedBox(height: 8),

                        // Quick Timeline Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _quickTimelines.map((preset) {
                              final isSel = _timelineController.text == preset;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  label: Text(preset),
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                    color: isSel ? const Color(0xFFD97706) : subTextColor,
                                  ),
                                  backgroundColor: isSel
                                      ? const Color(0xFFFEF3C7)
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSel ? const Color(0xFFF59E0B) : cardBorder,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() => _timelineController.text = preset);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Field 3: Notes / Remarks
                        Text(
                          'PROPOSAL NOTES & WORK SCOPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: subTextColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 13.5, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Describe your expertise, milestone payments, materials quality guarantee...',
                            hintStyle: TextStyle(fontSize: 12.5, color: subTextColor.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryTeal, width: 1.8),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons: Decline & Submit Quote
                        _isSubmitting
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(color: primaryTeal),
                                ),
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: cardBorder),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        foregroundColor: subTextColor,
                                      ),
                                      child: const Text('Back / Decline', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: ElevatedButton.icon(
                                      onPressed: _submitQuote,
                                      icon: const Icon(Icons.send_rounded, size: 16),
                                      label: Text(
                                        _existingQuote != null ? 'Update Quote' : 'Submit Quote',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: deepTeal,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shadowColor: deepTeal.withValues(alpha: 0.35),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGET FOR SPECIFICATION CARDS
  // ==========================================
  Widget _buildSpecTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String subtitle,
    required Color valueColor,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
