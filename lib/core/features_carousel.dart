import 'dart:async';
import 'package:flutter/material.dart';

class AppFeaturesCarousel extends StatefulWidget {
  final bool isProvider;
  const AppFeaturesCarousel({super.key, required this.isProvider});

  @override
  State<AppFeaturesCarousel> createState() => _AppFeaturesCarouselState();
}

class _AppFeaturesCarouselState extends State<AppFeaturesCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-scroll every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= 4) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Define the features/benefits
    final List<Map<String, dynamic>> items = widget.isProvider
        ? [
            {
              'title': 'Verified Client Leads',
              'desc': 'Get instant access to high-intent customer project leads in your region.',
              'icon': Icons.flash_on_rounded,
              'gradient': [const Color(0xFF0F9B8E), const Color(0xFF0E5E6F)],
              'badge': 'LEAD GENERATION',
            },
            {
              'title': 'Smart Cost Estimator',
              'desc': 'Calculate precise foundation, structure, and labor costs in seconds.',
              'icon': Icons.calculate_rounded,
              'gradient': [const Color(0xFF064354), const Color(0xFF0B7C8E)],
              'badge': 'PRO TOOLS',
            },
            {
              'title': 'Showcase Portfolio',
              'desc': 'Promote your completed sites and stand out to premium clients.',
              'icon': Icons.photo_library_rounded,
              'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
              'badge': 'PORTFOLIO',
            },
            {
              'title': 'B2B Marketplace Sales',
              'desc': 'List materials on BuildMart and secure bulk wholesale orders directly.',
              'icon': Icons.storefront_rounded,
              'gradient': [const Color(0xFFF39C12), const Color(0xFFD35400)],
              'badge': 'B2B MERCHANT',
            },
          ]
        : [
            {
              'title': 'Premium Quote Comparison',
              'desc': 'Compare contractor quotes side-by-side with full transparency.',
              'icon': Icons.compare_arrows_rounded,
              'gradient': [const Color(0xFF064354), const Color(0xFF0B7C8E)],
              'badge': 'SMART CHOICE',
            },
            {
              'title': 'Milestone-Based Escrow',
              'desc': 'Your funds are secure. Payments are released only when milestones are met.',
              'icon': Icons.security_rounded,
              'gradient': [const Color(0xFF0F9B8E), const Color(0xFF0E5E6F)],
              'badge': 'SECURE PAY',
            },
            {
              'title': 'BuildMart B2B Marketplace',
              'desc': 'Purchase high-grade construction materials at bulk wholesale prices.',
              'icon': Icons.shopping_bag_rounded,
              'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
              'badge': 'WHOLESALE',
            },
            {
              'title': 'Vetted Local Builders',
              'desc': 'Connect directly with certified, licensed, and top-rated local contractors.',
              'icon': Icons.verified_user_rounded,
              'gradient': [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
              'badge': 'VERIFIED ONLY',
            },
          ];

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page! - index);
                    value = (1 - (value.abs() * 0.08)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 140,
                      width: Curves.easeOut.transform(value) * 380,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: item['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (item['gradient'][0] as Color).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background icon
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          item['icon'],
                          size: 110,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['badge'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['desc'],
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Icon(
                                item['icon'],
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? (isDark ? const Color(0xFF0F9B8E) : const Color(0xFF064354))
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
