import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../../core/wallpaper_background.dart';
import '../providers/provider_profile_screen.dart';

class CompareQuotesScreen extends ConsumerStatefulWidget {
  final String projectId;
  const CompareQuotesScreen({super.key, required this.projectId});

  @override
  ConsumerState<CompareQuotesScreen> createState() => _CompareQuotesScreenState();
}

class _CompareQuotesScreenState extends ConsumerState<CompareQuotesScreen> {
  List<dynamic> _quotes = [];
  bool _isLoading = true;
  bool _isAccepting = false;

  Future<void> _acceptQuote(String quoteId, String providerName) async {
    setState(() => _isAccepting = true);
    try {
      final response = await http.patch(
        Uri.parse('$apiBaseUrl/quotes/$quoteId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isAccepted': true}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Accepted quote from $providerName!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept quote. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error accepting quote: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Failed to reach server.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProjectQuotes();
  }

  Future<void> _fetchProjectQuotes() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/projects/${widget.projectId}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _quotes = data['quotes'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching project quotes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WallpaperBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Compare Quotes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No quotes received yet for this project.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _quotes.length,
                  itemBuilder: (context, index) {
                    final q = _quotes[index];
                    return _buildQuoteCard(context, q);
                  },
                ),
      ),
    );
  }

  Widget _buildQuoteCard(BuildContext context, Map<String, dynamic> quote) {
    final provider = quote['provider'] ?? {};
    final providerName = provider['businessName'] ?? provider['ownerName'] ?? 'Unknown Provider';
    final cost = quote['estimatedCost']?.toString() ?? '0.0';
    final timeline = quote['timeline'] ?? 'N/A';
    final notes = quote['notes'] ?? 'No notes provided.';
    final quoteId = quote['id'] ?? '';

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.business, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      providerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFeatureRow(Icons.currency_rupee, 'Estimated Cost', '₹$cost', Colors.green),
              const Divider(),
              _buildFeatureRow(Icons.timer, 'Timeline', timeline, Colors.blue),
              const Divider(),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(notes, style: const TextStyle(color: Colors.grey, height: 1.4)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderProfileScreen(
                          providerId: quote['providerId'] ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('View Profile'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAccepting ? null : () => _acceptQuote(quoteId, providerName),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Accept Quote'),
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
