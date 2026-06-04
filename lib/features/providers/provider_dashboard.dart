import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      backgroundColor: Colors.transparent,
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
