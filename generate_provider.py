import os

files = {
    "lib/features/providers/provider_dashboard.dart": """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard'), actions: [
        IconButton(icon: const Icon(Icons.notifications), onPressed: (){})
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, Stellar Architects', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('Active Leads', '12', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Projects', '5', Colors.green)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Leads', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: const Text('Villa Construction - Design Phase', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Requested 2 hours ago'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/provider-lead/1'),
              ),
            )
          ],
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
""",
    "lib/features/providers/provider_lead_detail.dart": """import 'package:flutter/material.dart';

class ProviderLeadDetail extends StatelessWidget {
  final String leadId;
  const ProviderLeadDetail({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lead Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Villa Construction', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Location: Downtown Ave • Plot: 2400 sq ft', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('User Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Looking for a complete architectural design and structural planning for a 3-story residential villa.'),
            const SizedBox(height: 32),
            const Text('Submit Quote', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Estimated Cost (\$)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(labelText: 'Timeline (e.g. 4 weeks)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Notes / Remarks', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote submitted successfully!')));
                    },
                    child: const Text('Submit Quote'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
""",
    "lib/features/providers/provider_layout.dart": """import 'package:flutter/material.dart';
import 'provider_dashboard.dart';
import '../chat/chat_list_screen.dart';
import '../home/profile_screen.dart';

class ProviderLayout extends StatefulWidget {
  const ProviderLayout({super.key});

  @override
  State<ProviderLayout> createState() => _ProviderLayoutState();
}

class _ProviderLayoutState extends State<ProviderLayout> {
  int _currentIndex = 0;

  final screens = [
    const ProviderDashboard(),
    const Center(child: Text('Leads / Requests')),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Leads'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
"""
}

for filepath, content in files.items():
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w') as f:
        f.write(content)
print("Provider files generated successfully.")
