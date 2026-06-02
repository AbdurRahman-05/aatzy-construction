import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  Map<String, dynamic>? _provider;
  List<dynamic> _portfolio = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviderData();
  }

  Future<void> _fetchProviderData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/profile')),
        http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/portfolio')),
      ]);

      if (mounted) {
        setState(() {
          if (responses[0].statusCode == 200) {
            _provider = jsonDecode(responses[0].body)['provider'];
          }
          if (responses[1].statusCode == 200) {
            _portfolio = jsonDecode(responses[1].body)['images'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching provider data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _provider == null
              ? const Center(child: Text('Provider not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 200,
                        color: Colors.blue.shade100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.blue.shade600,
                                child: Text(
                                  (_provider!['businessName'] ?? 'P')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _provider!['businessName'] ?? 'Unknown Business',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Owner: ${_provider!['ownerName'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.work, color: Colors.blue, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${_provider!['experience'] ?? 0} years experience',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.category, color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _provider!['category'] ?? 'General',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              _provider!['bio'] ?? 'No bio provided.',
                              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                            ),
                            const SizedBox(height: 24),

                            if (_portfolio.isNotEmpty) ...[
                              const Text('Project Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _portfolio.length,
                                  itemBuilder: (context, index) {
                                    final img = _portfolio[index];
                                    return Container(
                                      width: 250,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                              child: Image.memory(
                                                base64Decode(img['imageData'].split(',').last),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(img['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                if (img['description'] != null && img['description'].toString().isNotEmpty)
                                                  Text(img['description'], style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            if (_provider!['address'] != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on, color: Colors.red.shade400, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _provider!['address'],
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_provider!['email'] != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.email, color: Colors.blue.shade400, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _provider!['email'],
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_provider!['phone'] != null && _provider!['phone'].toString().isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.phone, color: Colors.green.shade400, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _provider!['phone'],
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                _showQuoteModal(context);
                              },
                              child: const Text('Request Quote'),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  void _showQuoteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Request Quote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Describe your requirements', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote request sent!')));
              },
              child: const Text('Submit Request'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
