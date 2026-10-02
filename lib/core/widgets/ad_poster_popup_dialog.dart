import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../constants.dart';

class AdPosterPopupDialog extends StatefulWidget {
  final List<Map<String, dynamic>> ads;

  const AdPosterPopupDialog({super.key, required this.ads});

  static Future<void> show(BuildContext context, Map<String, dynamic> ad) {
    return showList(context, [ad]);
  }

  static Future<void> showList(BuildContext context, List<Map<String, dynamic>> ads) {
    if (ads.isEmpty) return Future.value();
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AdPosterPopupDialog(ads: ads),
      ),
    );
  }

  @override
  State<AdPosterPopupDialog> createState() => _AdPosterPopupDialogState();
}

class _AdPosterPopupDialogState extends State<AdPosterPopupDialog> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleAction(BuildContext context, Map<String, dynamic> currentAd) async {
    Navigator.of(context).pop();

    final actionUrl = currentAd['actionUrl'] as String?;
    if (actionUrl == null || actionUrl.trim().isEmpty) return;

    final trimmed = actionUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Error launching ad url: $e');
      }
    } else {
      try {
        // App internal route
        if (context.mounted) {
          context.push(trimmed);
        }
      } catch (e) {
        debugPrint('Error pushing ad route: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAds = widget.ads.length;
    final safeIndex = _currentIndex.clamp(0, totalAds - 1);
    final currentAd = widget.ads[safeIndex];

    final title = (currentAd['title'] ?? '').toString();
    final desc = (currentAd['desc'] ?? '').toString();
    final badge = (currentAd['badge'] ?? 'SPECIAL OFFER').toString();
    final actionText = (currentAd['actionText'] ?? 'Explore Now').toString();

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Media Section (Images / Videos PageView)
                Stack(
                  children: [
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: totalAds,
                        onPageChanged: (idx) {
                          setState(() {
                            _currentIndex = idx;
                          });
                        },
                        itemBuilder: (context, idx) {
                          final adItem = widget.ads[idx];
                          final isVideo = adItem['mediaType'] == 'video' ||
                              (adItem['videoUrl'] != null &&
                                  adItem['videoUrl'].toString().trim().isNotEmpty);

                          if (isVideo) {
                            return _VideoAdView(
                              videoUrl: (adItem['videoUrl'] ?? '').toString(),
                              posterUrl: (adItem['imageUrl'] ?? '').toString(),
                              adId: (adItem['id'] ?? 'ad_$idx').toString(),
                              isCurrentPage: _currentIndex == idx,
                            );
                          } else {
                            return _ImageAdView(
                              imageUrl: (adItem['imageUrl'] ?? '').toString(),
                            );
                          }
                        },
                      ),
                    ),

                    // Ambient gradient overlay for controls visibility
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 52,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Left: Multi-Ad Count Indicator (if > 1 ad)
                    if (totalAds > 1)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.campaign_rounded, size: 14, color: Colors.amberAccent),
                              const SizedBox(width: 5),
                              Text(
                                '${_currentIndex + 1} / $totalAds',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Top Right: Circular Close Button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Left Chevron Nav Button (if multiple ads and not first)
                    if (totalAds > 1 && _currentIndex > 0)
                      Positioned(
                        left: 8,
                        top: 95,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Right Chevron Nav Button (if multiple ads and not last)
                    if (totalAds > 1 && _currentIndex < totalAds - 1)
                      Positioned(
                        right: 8,
                        top: 95,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Multi-ad pagination indicator dots (if totalAds > 1)
                if (totalAds > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalAds, (idx) {
                        final isSelected = idx == _currentIndex;
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3.5),
                            height: 6,
                            width: isSelected ? 22 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F766E)
                                  : (isDark ? Colors.white24 : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                // Details & Action Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badge.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.35,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Action CTA Button
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _handleAction(context, currentAd),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                actionText,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Image Ad View Supporting Base64 Data URL and Network Images
class _ImageAdView extends StatelessWidget {
  final String imageUrl;

  const _ImageAdView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();

    if (trimmed.isEmpty) {
      return Container(
        color: const Color(0xFF064354),
        child: const Center(
          child: Icon(Icons.campaign_rounded, size: 64, color: Colors.white70),
        ),
      );
    }

    if (trimmed.startsWith('data:image') || !trimmed.startsWith('http')) {
      final bytes = Base64ImageCache.decode(trimmed);
      if (bytes.isNotEmpty) {
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 240,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        );
      }
    }

    return Image.network(
      trimmed,
      width: double.infinity,
      height: 240,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildFallback(),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 240,
          color: Colors.grey.shade100,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
          ),
        );
      },
    );
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF064354),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white60),
      ),
    );
  }
}

/// Video Ad View Supporting Network URLs and Base64 Video Data with Playback Controls
class _VideoAdView extends StatefulWidget {
  final String videoUrl;
  final String posterUrl;
  final String adId;
  final bool isCurrentPage;

  const _VideoAdView({
    required this.videoUrl,
    required this.posterUrl,
    required this.adId,
    required this.isCurrentPage,
  });

  @override
  State<_VideoAdView> createState() => _VideoAdViewState();
}

class _VideoAdViewState extends State<_VideoAdView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant _VideoAdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage != oldWidget.isCurrentPage && _controller != null && _isInitialized) {
      if (widget.isCurrentPage) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }
  }

  Future<void> _initializePlayer() async {
    final rawUrl = widget.videoUrl.trim();
    if (rawUrl.isEmpty) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      VideoPlayerController controller;

      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(rawUrl));
      } else {
        // Base64 data URL or raw Base64 string
        final cleanBase64 = rawUrl.split(',').last.trim();
        final bytes = base64Decode(cleanBase64);
        final tempDir = await getTemporaryDirectory();
        final safeAdId = widget.adId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final file = File(
          '${tempDir.path}/ad_video_${safeAdId.isEmpty ? DateTime.now().millisecondsSinceEpoch : safeAdId}.mp4',
        );
        await file.writeAsBytes(bytes, flush: true);
        controller = VideoPlayerController.file(file);
      }

      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(_isMuted ? 0.0 : 1.0);

      if (widget.isCurrentPage) {
        await controller.play();
      }

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[AdPosterPopupDialog] Video player init error: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
      } else {
        _controller!.play();
        _showControls = false;
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Fallback to poster image if provided, or clean placeholder
      if (widget.posterUrl.trim().isNotEmpty) {
        return _ImageAdView(imageUrl: widget.posterUrl);
      }
      return Container(
        height: 240,
        color: const Color(0xFF1E1B4B),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_camera_back_rounded, size: 48, color: Colors.purpleAccent),
              SizedBox(height: 8),
              Text(
                'Video Advertisement',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 240,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              SizedBox(height: 10),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final isPlaying = _controller!.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        height: 240,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio > 0 ? _controller!.value.aspectRatio : 16 / 9,
                child: VideoPlayer(_controller!),
              ),
            ),

            // Tap Overlay Play/Pause Indicator (when paused or briefly shown)
            if (!isPlaying || _showControls)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Video Ad Badge (Bottom Left)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, size: 12, color: Colors.purpleAccent),
                    SizedBox(width: 4),
                    Text(
                      'VIDEO AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mute / Unmute Toggle Button (Bottom Right)
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleMute,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Video Progress Scrubber Bar at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF0F766E),
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
