import 'package:flutter/material.dart';
import '../../models/project.dart';

class CompareQuotesScreen extends StatelessWidget {
  final String projectId;
  CompareQuotesScreen({super.key, required this.projectId});

  final List<Quote> dummyQuotes = [
    Quote(
      id: '1',
      providerId: 'p1',
      providerName: 'Stellar Architects',
      estimatedCost: 45000,
      timeline: '6 weeks',
      notes: 'Includes initial 3D modeling and structural validation.',
    ),
    Quote(
      id: '2',
      providerId: 'p2',
      providerName: 'BuildMax Corp',
      estimatedCost: 42000,
      timeline: '8 weeks',
      notes: 'Standard architectural design, excludes structural validation.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Quotes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        children: dummyQuotes.map((q) => _buildQuoteCard(context, q)).toList(),
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Quote quote) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.business)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quote.providerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFeatureRow(Icons.attach_money, 'Estimated Cost', '\$${quote.estimatedCost}', Colors.green),
              const Divider(),
              _buildFeatureRow(Icons.timer, 'Timeline', quote.timeline, Colors.blue),
              const Divider(),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Text(quote.notes, style: const TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accepted quote from ${quote.providerName}')));
                    Navigator.pop(context);
                  },
                  child: const Text('Accept Quote'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
