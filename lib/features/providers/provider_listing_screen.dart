import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProviderListingScreen extends StatelessWidget {
  final String category;
  const ProviderListingScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: (){})
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // dummy count
        itemBuilder: (context, index) {
          return Card(
            child: InkWell(
              onTap: () => context.push('/provider-profile/$index'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.business, size: 30, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Provider ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('10 years exp • $category', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 16),
                              const Text(' 4.8 (120 reviews)', style: TextStyle(fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Starts at', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('\$5k', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
