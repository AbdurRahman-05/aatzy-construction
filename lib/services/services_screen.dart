import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Land & Legal', 'icon': Icons.landscape},
    {'name': 'Finance & Approvals', 'icon': Icons.account_balance},
    {'name': 'Survey & Analysis', 'icon': Icons.map},
    {'name': 'Design & Planning', 'icon': Icons.architecture},
    {'name': 'Construction', 'icon': Icons.construction},
    {'name': 'Engineering (MEP)', 'icon': Icons.engineering},
    {'name': 'Materials & Supply', 'icon': Icons.inventory},
    {'name': 'Utilities', 'icon': Icons.power},
    {'name': 'Interiors & Finishing', 'icon': Icons.format_paint},
    {'name': 'Project Management', 'icon': Icons.assignment},
    {'name': 'Inspection & Compliance', 'icon': Icons.fact_check},
    {'name': 'Smart & Security', 'icon': Icons.security},
    {'name': 'Logistics & Equipment', 'icon': Icons.local_shipping},
    {'name': 'Insurance', 'icon': Icons.shield},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () => context.push('/providers/${cat['name']}'),
            child: Card(
              elevation: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, size: 40, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(cat['name'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
