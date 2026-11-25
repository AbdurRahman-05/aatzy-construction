import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:construction_app/core/api_http.dart' as http;
import '../constants.dart';
import '../providers/ads_provider.dart' show parseAdGradient, parseAdIcon;
import 'ad_poster_popup_dialog.dart';
import 'bento.dart';

/// Active ads placed on the HOME page for one app side.
/// [side] is 'CLIENT' (customer app) or 'PROVIDER' (partner app).
/// Managed from Admin Panel -> Ads Manager ("Where to show the ad").
final homeAdsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, side) async {
  try {
    final res = await http
        .get(Uri.parse('$apiBaseUrl/ads?target=$side&activeOnly=true&placement=HOME'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    final raw = (jsonDecode(res.body)['ads'] as List?) ?? [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((ad) => ad['isActive'] != false)
        .toList();
  } catch (e) {
    debugPrint('[HomeAdSlot] fetch error: $e');
    return [];
  }
});

/// Auto-rotating sponsored banner for the home pages.
/// Renders nothing when there are no home ads, so the layout stays clean.
class HomeAdSlot extends ConsumerStatefulWidget {
  final String side;

  /// Spacing around the slot, applied only when ads are shown.
  final EdgeInsetsGeometry padding;
  final double height;

  const HomeAdSlot({
    super.key,
    required this.side,
    this.padding = EdgeInsets.zero,
    this.height = 172,
  });

  @override
  ConsumerState<HomeAdSlot> createState() => _HomeAdSlotState();
}

class _HomeAdSlotState extends ConsumerState<HomeAdSlot> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;
  int _count = 0;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _count < 2 || _userInteracting || !_controller.hasClients) return;
      final next = (_index + 1) % _count;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Map<String, dynamic> ad) async {
    final isVideo = ad['mediaType'] == 'video' || (ad['videoUrl']?.toString().trim().isNotEmpty ?? false);
    final action = (ad['actionUrl'] ?? '').toString().trim();

    // Videos and ads without a link open the full poster popup
    if (isVideo || action.isEmpty) {
      await AdPosterPopupDialog.show(context, ad);
      return;
    }

    if (action.startsWith('http://') || action.startsWith('https://')) {
      try {
        final uri = Uri.parse(action);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[HomeAdSlot] launch error: $e');
      }
    } else if (mounted) {
      try {
        context.push(action.startsWith('/') ? action : '/$action');
      } catch (e) {
        debugPrint('[HomeAdSlot] route error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(homeAdsProvider(widget.side)).asData?.value ?? const [];
    _count = ads.length;
    if (ads.isEmpty) return const SizedBox.shrink();
    if (_index >= ads.length) _index = 0;

    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollStartNotification && n.dragDetails != null) _userInteracting = true;
                if (n is ScrollEndNotification) _userInteracting = false;
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: ads.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _AdBanner(ad: ads[i], onTap: () => _open(ads[i])),
                ),
              ),
            ),
          ),
          if (ads.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(ads.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Bento.accent : Bento.border(dark),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  final Map<String, dynamic> ad;
  final VoidCallback onTap;

  const _AdBanner({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (ad['title'] ?? '').toString();
    final desc = (ad['desc'] ?? '').toString();
    final badge = (ad['badge'] ?? '').toString().trim();
    final image = (ad['imageUrl'] ?? '').toString().trim();
    final isVideo = ad['mediaType'] == 'video' || (ad['videoUrl']?.toString().trim().isNotEmpty ?? false);
    final hasAction = (ad['actionUrl'] ?? '').toString().trim().isNotEmpty;
    final actionText = (ad['actionText'] ?? '').toString().trim();
    final gradient = parseAdGradient((ad['gradient'] ?? '').toString());

    Widget background;
    if (image.isNotEmpty) {
      if (image.startsWith('http://') || image.startsWith('https://')) {
        background = Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => _gradientBg(gradient));
      } else {
        final bytes = Base64ImageCache.decode(image);
        background = bytes.isEmpty
            ? _gradientBg(gradient)
            : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => _gradientBg(gradient));
      }
    } else {
      background = _gradientBg(gradient);
    }

    return BentoCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          // Readability scrim (left side, where the text sits)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xD9000000), Color(0x66000000), Color(0x00000000)],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          if (image.isEmpty)
            Positioned(
              right: -12,
              bottom: -18,
              child: Icon(parseAdIcon((ad['icon'] ?? '').toString()), size: 120, color: Colors.white.withValues(alpha: 0.15)),
            ),
          if (isVideo)
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: BentoPill(
              label: badge.isEmpty ? 'SPONSORED' : badge.toUpperCase(),
              color: Colors.white,
              background: Colors.black.withValues(alpha: 0.45),
              icon: Icons.campaign_rounded,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  FractionallySizedBox(
                    widthFactor: 0.78,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: 0.72,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
                if (hasAction || isVideo) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isVideo && !hasAction ? 'Watch now' : (actionText.isEmpty ? 'Explore now' : actionText),
                          style: const TextStyle(color: Bento.accentDeep, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Bento.accentDeep),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg(List<Color> colors) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
      );
}
