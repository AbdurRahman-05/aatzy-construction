import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/projects_provider.dart';
import '../auth/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    List<dynamic> projects = [];
    List<dynamic> orders = [];
    
    if (auth.id != null) {
      final projectsAsync = ref.watch(userProjectsProvider(auth.id!));
      final projData = projectsAsync.asData?.value;
      if (projData != null) {
        projects = projData.projects;
        orders = projData.materialOrders;
      }
    }

    int activeProjects = projects.where((p) {
      final stage = (p['currentStage'] as String? ?? '').toLowerCase();
      return stage != 'completed' && stage != 'finished' && stage != 'cancelled';
    }).length;

    double totalBudget = 0;
    for (var p in projects) {
      totalBudget += double.tryParse((p['budget'] ?? '0').toString()) ?? 0;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text('My Dashboard', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            _buildStatCard('Total Budget', '₹${totalBudget.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green, isDark),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSmallStatCard('Active Projects', activeProjects.toString(), Icons.business, Colors.blue, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildSmallStatCard('Total Estimates', projects.length.toString(), Icons.calculate, Colors.orange, isDark)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSmallStatCard('Material Orders', orders.length.toString(), Icons.inventory_2, Colors.purple, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildSmallStatCard('Saved Providers', '0', Icons.people, Colors.teal, isDark)),
              ],
            ),
            const SizedBox(height: 32),
            Text('Recent Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Not enough data to display charts.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
