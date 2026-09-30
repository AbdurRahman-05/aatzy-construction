import 'dart:convert';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? base64Image;
  final String? imageUrl;
  final String title;

  const FullScreenImageViewer({
    super.key,
    this.base64Image,
    this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final candidate = (imageUrl ?? base64Image ?? '').trim();

    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      imageWidget = Image.network(
        candidate,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Text(
              'Failed to load image from network',
              style: TextStyle(color: Colors.white70),
            ),
          );
        },
      );
    } else if (candidate.isNotEmpty) {
      try {
        final rawBase64 = candidate.contains(',') ? candidate.split(',').last : candidate;
        final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Failed to load image format',
                style: TextStyle(color: Colors.white70),
              ),
            );
          },
        );
      } catch (e) {
        imageWidget = const Center(
          child: Text(
            'Invalid image data',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
    } else {
      imageWidget = const Center(
        child: Text(
          'No image provided',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}
