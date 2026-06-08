import 'package:flutter/material.dart';

class CostEstimationScreen extends StatefulWidget {
  const CostEstimationScreen({super.key});

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  double area = 1000;
  String quality = 'Standard';
  double estimatedTotal = 0;

  void calculate() {
    double baseRate = 100;
    if (quality == 'Premium') baseRate = 150;
    if (quality == 'Basic') baseRate = 70;
    
    setState(() {
      estimatedTotal = area * baseRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cost Estimator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: '1000',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Area (sq ft)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: (v) => area = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: quality,
              decoration: InputDecoration(labelText: 'Material Quality', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              items: ['Basic', 'Standard', 'Premium'].map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
              onChanged: (v) => setState(() => quality = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: calculate,
              child: const Text('Calculate Estimate'),
            ),
            const SizedBox(height: 32),
            if (estimatedTotal > 0) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Estimated Total Cost', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('₹${estimatedTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 24),
                      _buildBreakdown('Materials (60%)', estimatedTotal * 0.6),
                      _buildBreakdown('Labor (30%)', estimatedTotal * 0.3),
                      _buildBreakdown('Other (10%)', estimatedTotal * 0.1),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
