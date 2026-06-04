import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../auth/auth_provider.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {
  Map<String, dynamic>? _provider;
  List<dynamic> _portfolio = [];
  int _completedProjectsCount = 0;
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
        http.get(Uri.parse('$apiBaseUrl/providers/${widget.providerId}/projects')),
      ]);

      if (mounted) {
        setState(() {
          if (responses[0].statusCode == 200) {
            _provider = jsonDecode(responses[0].body)['provider'];
          }
          if (responses[1].statusCode == 200) {
            _portfolio = jsonDecode(responses[1].body)['images'];
          }
          if (responses[2].statusCode == 200) {
            final projectsList = jsonDecode(responses[2].body) as List;
            _completedProjectsCount = projectsList.where((p) => p['currentStage'] == 'Completed').length;
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
                                radius: 45,
                                backgroundColor: Colors.blue.shade600,
                                backgroundImage: _provider!['profileImage'] != null && _provider!['profileImage'].toString().isNotEmpty
                                    ? MemoryImage(base64Decode(_provider!['profileImage'].split(',').last))
                                    : null,
                                child: _provider!['profileImage'] == null || _provider!['profileImage'].toString().isEmpty
                                    ? Text(
                                        (_provider!['businessName'] ?? 'P')[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                      )
                                    : null,
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  final starVal = index + 1;
                                  final avg = _provider!['avgRating'] ?? 0.0;
                                  return Icon(
                                    starVal <= avg
                                        ? Icons.star
                                        : (starVal - 0.5 <= avg ? Icons.star_half : Icons.star_border),
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${_provider!['avgRating'] ?? 0.0} (${(_provider!['reviews'] as List?)?.length ?? 0} reviews)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Owner: ${_provider!['ownerName'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 const Icon(Icons.work, color: Colors.blue, size: 18),
                                 const SizedBox(width: 6),
                                 Text(
                                   '${_provider!['experience'] ?? 0} years experience',
                                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 16),
                             const Text(
                               'Services Offered',
                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                             ),
                             const SizedBox(height: 8),
                             Wrap(
                               spacing: 8,
                               runSpacing: 8,
                               children: (_provider!['category'] as String? ?? 'General')
                                   .split(',')
                                   .map((c) {
                                     final cleanCat = c.trim();
                                     if (cleanCat.isEmpty) return const SizedBox.shrink();
                                     return Chip(
                                       label: Text(
                                         cleanCat,
                                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                                       ),
                                       backgroundColor: Colors.blue.shade50,
                                       side: BorderSide(color: Colors.blue.shade100),
                                       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                       visualDensity: VisualDensity.compact,
                                     );
                                   })
                                   .toList(),
                             ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.assignment_turned_in, color: Colors.green, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '$_completedProjectsCount projects completed successfully',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green),
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
                            const Divider(height: 48),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Reviews & Ratings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                TextButton.icon(
                                  onPressed: () => _showWriteReviewModal(context),
                                  icon: const Icon(Icons.rate_review, size: 18),
                                  label: const Text('Write Review'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if ((_provider!['reviews'] as List?)?.isEmpty ?? true)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No reviews yet. Be the first to review!',
                                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: (_provider!['reviews'] as List).length,
                                itemBuilder: (context, idx) {
                                  final r = _provider!['reviews'][idx];
                                  final rating = r['rating'] ?? 5;
                                  final comment = r['comment'] ?? '';
                                  final reviewer = r['user']?['name'] ?? 'Anonymous';
                                  final date = r['createdAt'] != null
                                      ? DateTime.tryParse(r['createdAt'])?.toLocal().toString().substring(0, 10) ?? ''
                                      : '';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                reviewer,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              Text(
                                                date,
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                           Row(
                                             children: List.generate(5, (index) => Icon(
                                               index < rating ? Icons.star : Icons.star_border,
                                               color: Colors.amber,
                                               size: 16,
                                             )),
                                           ),
                                           if (r['project'] != null) ...[
                                             const SizedBox(height: 6),
                                             Container(
                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                               decoration: BoxDecoration(
                                                 color: Colors.blue.shade50,
                                                 borderRadius: BorderRadius.circular(6),
                                               ),
                                               child: Text(
                                                 'Project: ${r['project']['title'] ?? ''} (${r['project']['type'] ?? ''})',
                                                 style: TextStyle(
                                                   color: Colors.blue.shade800,
                                                   fontSize: 11,
                                                   fontWeight: FontWeight.w600,
                                                 ),
                                               ),
                                             ),
                                           ],
                                           if (comment.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              comment,
                                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showQuoteModal(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Request Quote', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
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

  void _showWriteReviewModal(BuildContext context) {
    final commentController = TextEditingController();
    int selectedRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Write a Review',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap stars to select rating:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = index + 1;
                      return IconButton(
                        icon: Icon(
                          starVal <= selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your review comments',
                      hintText: 'Share your experience working with this provider...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please write a comment.')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _submitReview(selectedRating, commentController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit Review'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReview(int rating, String comment) async {
    final auth = ref.read(authProvider);
    if (auth.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/providers/${widget.providerId}/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': auth.id,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        _fetchProviderData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit review. Please try again.')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to backend.')),
      );
    }
  }
}
