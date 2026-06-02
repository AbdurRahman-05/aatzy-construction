import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

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
      final response = await http.get(Uri.parse('$apiBaseUrl/providers/${auth.id}/stats'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final businessName = auth.businessName ?? 'Your Business';

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.notifications), onPressed: (){})
      ]),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, $businessName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Active Leads', '${_stats?['activeLeads'] ?? 0}', Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Projects', '${_stats?['projects'] ?? 0}', Colors.green)),
                    ],
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
                        subtitle: Text('By ${lead['userName']}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => context.push('/provider-lead/${lead['id']}'),
                      ),
                    )).toList(),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
