import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/b2b_api_service.dart';

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String category;
  final String date;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'General',
      date: json['publishedAt'] != null 
          ? json['publishedAt'].toString().split('T')[0] 
          : '2026-06-05',
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isLoading = false;
  List<NewsArticle> _newsList = [];
  String? _errorMessage;
  String _selectedMaterialTab = 'Cement';

  final Map<String, List<double>> _trendData = {
    'Cement': [440, 435, 430, 422, 420],
    'Steel': [56000, 56500, 57200, 57800, 58000],
    'Bricks': [8.2, 8.1, 8.3, 8.5, 8.6],
  };

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = B2BApiService();
      final res = await api.get('/news');
      if (res.success && res.data != null) {
        final List list = res.data['news'] ?? [];
        setState(() {
          _newsList = list.map((item) => NewsArticle.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _errorMessage = res.data['error'] ?? 'Failed to load news';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch market news.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('B2B Construction News'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Live Price Trend Index',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text('Visual price movement tracker of key construction commodities.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _trendData.keys.map((mat) {
                            final isSelected = _selectedMaterialTab == mat;
                            return ChoiceChip(
                              label: Text(mat),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedMaterialTab = mat);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _trendData[_selectedMaterialTab]!.asMap().entries.map((entry) {
                            final val = entry.value;
                            final list = _trendData[_selectedMaterialTab]!;
                            final maxVal = list.reduce((a, b) => a > b ? a : b);
                            final heightPercent = (val / maxVal) * 100;

                            return Column(
                              children: [
                                Text(
                                  _selectedMaterialTab == 'Steel' 
                                      ? '₹${(val / 1000).toStringAsFixed(1)}k' 
                                      : '₹${val.toStringAsFixed(1)}',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 32,
                                  height: heightPercent.clamp(20, 100).toDouble(),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.blue, Colors.teal],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('M-${5 - entry.key}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending Industry Reports',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _fetchNews,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.black87), textAlign: TextAlign.center),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _newsList.length,
                    itemBuilder: (context, index) {
                      final art = _newsList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    art.category.toUpperCase(),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                                Text(art.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              art.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              art.content,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.45),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
