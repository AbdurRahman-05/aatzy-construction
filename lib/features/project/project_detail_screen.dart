import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final currentStage = "Design & Planning"; // Dummy

    return Scaffold(
      appBar: AppBar(title: const Text('Villa Construction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Budget', style: TextStyle(color: Colors.grey)),
                        Text('\$150,000', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Location', style: TextStyle(color: Colors.grey)),
                        Text('Downtown Ave', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Project Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: 0.3, minHeight: 10, borderRadius: BorderRadius.all(Radius.circular(5))),
            const SizedBox(height: 8),
            Text('Current Stage: $currentStage', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
            
            const SizedBox(height: 24),
            Text('Recommended Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Logic based on workflow
            if (currentStage == "Design & Planning") ...[
              _buildServiceRecommendation(context, 'Architects', 'Design & Planning'),
              _buildServiceRecommendation(context, 'Structural Engineers', 'Engineering (MEP)'),
            ],
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quotes Received', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () => context.push('/compare-quotes/$projectId'),
                  child: const Text('Compare'),
                )
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.request_quote, color: Colors.orange),
                title: const Text('2 New Quotes Available'),
                subtitle: const Text('Review and accept to proceed'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.push('/compare-quotes/$projectId'),
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Cost Tracking', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              color: Colors.green,
                              value: 10000,
                              title: 'Spent',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: Colors.orange,
                              value: 35000,
                              title: 'Quoted',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            PieChartSectionData(
                              color: Colors.grey.shade300,
                              value: 105000,
                              title: 'Remaining',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCostRow('Estimated Total', '\$150,000', Colors.black),
                    const Divider(),
                    _buildCostRow('Quoted so far', '\$45,000', Colors.orange),
                    const Divider(),
                    _buildCostRow('Spent', '\$10,000', Colors.green),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRecommendation(BuildContext context, String title, String category) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.architecture, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Find professionals for this stage'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => context.push('/providers/$category'),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      ],
    );
  }
}
