import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';
import 'provider_layout.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  Map<String, dynamic>? _stats;
  List<dynamic> _projects = [];
  bool _isLoading = true;
  int _dashboardTab = 0; // 0: General, 1: Finance
  int _selectedYear = 2026;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final statsResponse = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats'));
      final projectsResponse = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/projects'));

      if (statsResponse.statusCode == 200 && projectsResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = jsonDecode(statsResponse.body);
            _projects = jsonDecode(projectsResponse.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final businessName = auth.businessName ?? 'Your Business';

    // Calculate financials
    double totalRevenue = 0.0;
    double totalMaterialExpenses = 0.0;
    double totalLaborExpenses = 0.0;

    for (final project in _projects) {
      final tasks = project['tasks'] as List? ?? [];
      double projRevenue = 0.0;
      double projMaterials = 0.0;
      for (final t in tasks) {
        projRevenue += (t['quotedCost'] as num? ?? 0.0).toDouble();
        projMaterials += (t['taskCost'] as num? ?? 0.0).toDouble();
      }
      final projLabor = projRevenue * 0.12; // 12% labor cost estimate

      totalRevenue += projRevenue;
      totalMaterialExpenses += projMaterials;
      totalLaborExpenses += projLabor;
    }

    final totalExpenses = totalMaterialExpenses + totalLaborExpenses;
    final totalProfit = totalRevenue - totalExpenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $businessName',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sliding Tab Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _dashboardTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _dashboardTab == 0 ? Theme.of(context).primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'General Info',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _dashboardTab == 0 ? Colors.white : Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _dashboardTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _dashboardTab == 1 ? Theme.of(context).primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Finance Dashboard',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _dashboardTab == 1 ? Colors.white : Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TAB 0: Overview / General
                    if (_dashboardTab == 0) ...[
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('Active Leads', '${_stats?['activeLeads'] ?? 0}', Colors.blue)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Projects', '${_stats?['projects'] ?? 0}', Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Active Jobs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final activeJobs = (_stats?['activeJobs'] as List? ?? [])
                              .where((job) => ![
                                    'completed',
                                    'finished',
                                    'finished pending approval',
                                    'cancelled'
                                  ].contains((job['currentStage'] as String? ?? '').toLowerCase()))
                              .toList();

                          if (activeJobs.isEmpty) {
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 1.5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.celebration,
                                        size: 36,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'All Jobs Completed!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Congratulations! You have no active jobs in execution right now. Time to take on new projects!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          ref.read(providerTabProvider.notifier).setTab(2); // Leads tab is index 2
                                        },
                                        icon: const Icon(Icons.search, size: 18),
                                        label: const Text('See More Leads'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: activeJobs.map((job) => Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.handyman, color: Colors.white),
                                ),
                                title: Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Client: ${job['userName']}'),
                                    const SizedBox(height: 4),
                                    Text('Stage: ${job['currentStage']}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () async {
                                  await context.push('/provider-job/${job['id']}');
                                  _fetchStats();
                                },
                              ),
                            )).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Recent Leads', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if ((_stats?['recentLeads'] as List?)?.isEmpty ?? true)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No leads found in your category yet.'),
                        ))
                      else
                        ...(_stats?['recentLeads'] as List).map((lead) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(lead['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('By ${lead['userName']}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(lead['location'] ?? 'N/A', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => context.push('/provider-lead/${lead['id']}'),
                          ),
                        )).toList(),
                    ],

                    // TAB 1: Finance Dashboard
                    if (_dashboardTab == 1) ...[
                      _buildFinanceStats(totalRevenue, totalExpenses, totalProfit),
                      const SizedBox(height: 16),
                      _buildFinanceChart(),
                      const SizedBox(height: 20),
                      Text(
                        'Project-wise Profitability',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_projects.isEmpty)
                        const Center(child: Text('No project financials recorded yet.'))
                      else
                        ..._projects.map((proj) {
                          final title = proj['title'] ?? 'N/A';
                          final stage = proj['currentStage'] ?? 'N/A';
                          final tasks = proj['tasks'] as List? ?? [];
                          double revenue = 0.0;
                          double materials = 0.0;
                          for (final t in tasks) {
                            revenue += (t['quotedCost'] as num? ?? 0.0).toDouble();
                            materials += (t['taskCost'] as num? ?? 0.0).toDouble();
                          }
                          final labor = revenue * 0.12;
                          final expenses = materials + labor;
                          final profit = revenue - expenses;
                          final isProfit = profit >= 0;
                          final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await context.push('/provider-job/${proj['id']}');
                                _fetchStats();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            stage,
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Quoted Cost', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Total Cost', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text('₹${expenses.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(isProfit ? 'Profit' : 'Loss', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                '${isProfit ? "+" : ""}₹${profit.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isProfit ? Colors.green : Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Materials: ₹${materials.toStringAsFixed(0)} • Labor: ₹${labor.toStringAsFixed(0)}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                        ),
                                        Text(
                                          'Margin: ${margin.toStringAsFixed(1)}%',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: isProfit ? Colors.green : Colors.red, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildFinanceStats(double revenue, double expenses, double profit) {
    final double profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Total Revenue',
                '₹${revenue.toStringAsFixed(0)}',
                Colors.blue,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Est. Expenses',
                '₹${expenses.toStringAsFixed(0)}',
                Colors.orange,
                Icons.trending_down,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                'Net Profit',
                '₹${profit.toStringAsFixed(0)}',
                Colors.green,
                Icons.currency_rupee,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                'Profit Margin',
                '${profitMargin.toStringAsFixed(1)}%',
                Colors.purple,
                Icons.percent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinanceCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceChart() {
    final monthlyProfits = List<double>.filled(12, 0.0);
    final monthlyRevenues = List<double>.filled(12, 0.0);

    for (final project in _projects) {
      final createdAtStr = project['createdAt'] as String?;
      if (createdAtStr == null) continue;
      final dt = DateTime.tryParse(createdAtStr);
      if (dt == null || dt.year != _selectedYear) continue;

      final tasks = project['tasks'] as List? ?? [];
      double revenue = 0.0;
      double materialCost = 0.0;
      for (final t in tasks) {
        revenue += (t['quotedCost'] as num? ?? 0.0).toDouble();
        materialCost += (t['taskCost'] as num? ?? 0.0).toDouble();
      }
      final laborCost = revenue * 0.12;
      final profit = revenue - (materialCost + laborCost);

      monthlyProfits[dt.month - 1] += profit;
      monthlyRevenues[dt.month - 1] += revenue;
    }

    double maxVal = 1000.0;
    for (int i = 0; i < 12; i++) {
      if (monthlyProfits[i] > maxVal) maxVal = monthlyProfits[i];
      if (monthlyRevenues[i] > maxVal) maxVal = monthlyRevenues[i];
    }
    maxVal = (maxVal * 1.15).clamp(100.0, double.infinity);

    final List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Profit & Revenue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isDense: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                      items: [2025, 2026, 2027].map((y) {
                        return DropdownMenuItem<int>(
                          value: y,
                          child: Text('$y'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.shade800,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = monthNames[group.x.toInt()];
                        final String type = rodIndex == 0 ? 'Revenue' : 'Profit';
                        return BarTooltipItem(
                          '$month\n$type: ₹${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 12) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthNames[idx],
                              style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthlyRevenues[index],
                          color: Colors.blue.shade400,
                          width: 5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: monthlyProfits[index],
                          color: Colors.green.shade400,
                          width: 5,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegendIndicator(Colors.blue.shade400, 'Quoted Revenue'),
                const SizedBox(width: 24),
                _buildChartLegendIndicator(Colors.green.shade400, 'Est. Net Profit'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegendIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
