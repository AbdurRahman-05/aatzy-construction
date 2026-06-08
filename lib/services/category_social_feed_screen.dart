import 'package:flutter/material.dart';
import 'dart:convert';
import '../features/providers/provider_profile_screen.dart';

class CategorySocialFeedScreen extends StatefulWidget {
  final String categoryName;
  final List<dynamic> posts;

  const CategorySocialFeedScreen({
    super.key,
    required this.categoryName,
    required this.posts,
  });

  @override
  State<CategorySocialFeedScreen> createState() => _CategorySocialFeedScreenState();
}

class _CategorySocialFeedScreenState extends State<CategorySocialFeedScreen> {
  final Set<String> _likedPostIds = {};
  final Map<String, int> _likeCounts = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.posts.length} posts',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: widget.posts.isEmpty
          ? const Center(
              child: Text(
                'No portfolio posts in this category.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.posts.length,
              itemBuilder: (context, index) {
                final post = widget.posts[index];
                final postId = post['id'] ?? 'post_$index';
                final provider = post['provider'] ?? {};
                final providerId = provider['id'] ?? '';
                final businessName = provider['businessName'] ?? provider['ownerName'] ?? 'Provider';
                final title = post['title'] ?? 'Portfolio Work';
                final description = post['description'] ?? '';
                final imageData = post['imageData'] as String?;

                final isLiked = _likedPostIds.contains(postId);
                final likes = _likeCounts[postId] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Provider Profile
                      InkWell(
                        onTap: () {
                          if (providerId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProviderProfileScreen(providerId: providerId),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                radius: 18,
                                child: Text(
                                  businessName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      businessName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      widget.categoryName,
                                      style: TextStyle(fontSize: 11, color: Colors.blue.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                      // Image
                      if (imageData != null)
                        GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              if (_likedPostIds.contains(postId)) {
                                _likedPostIds.remove(postId);
                                _likeCounts[postId] = likes - 1;
                              } else {
                                _likedPostIds.add(postId);
                                _likeCounts[postId] = likes + 1;
                              }
                            });
                          },
                          child: AspectRatio(
                            aspectRatio: 1.1,
                            child: Image.memory(
                              base64Decode(imageData.split(',').last),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),

                      // Action Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_likedPostIds.contains(postId)) {
                                    _likedPostIds.remove(postId);
                                    _likeCounts[postId] = likes - 1;
                                  } else {
                                    _likedPostIds.add(postId);
                                    _likeCounts[postId] = likes + 1;
                                  }
                                });
                              },
                              child: AnimatedScale(
                                scale: isLiked ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.black87,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.mode_comment_outlined, size: 24, color: Colors.black87),
                            const SizedBox(width: 16),
                            const Icon(Icons.send_outlined, size: 24, color: Colors.black87),
                            const Spacer(),
                            const Icon(Icons.bookmark_border, size: 24, color: Colors.black87),
                          ],
                        ),
                      ),

                      // Likes count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$likes likes',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),

                      // Title & Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 13.5),
                            children: [
                              TextSpan(
                                text: '$businessName ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                          child: Text(
                            description,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
