import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserTutorialSlide {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final String imageAsset;
  final List<Color> gradientColors;
  final List<String> bulletPoints;

  const UserTutorialSlide({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.imageAsset,
    required this.gradientColors,
    required this.bulletPoints,
  });
}

class UserTutorialDialog extends StatefulWidget {
  final String? userId;

  const UserTutorialDialog({super.key, this.userId});

  static const String _prefKeyBase = 'has_seen_user_tutorial';

  static String _getPrefKey(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      return '${_prefKeyBase}_$userId';
    }
    return _prefKeyBase;
  }

  /// Show the tutorial dialog.
  /// If [force] is true, opens regardless of whether user has seen it before.
  static Future<void> show(BuildContext context, {String? userId, bool force = false}) async {
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrefKey(userId);
      final hasSeen = prefs.getBool(key) ?? false;
      if (hasSeen) return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UserTutorialDialog(userId: userId),
    );
  }

  /// Helper to reset tutorial state so user can re-watch or test
  static Future<void> resetSeenState({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getPrefKey(userId);
    await prefs.remove(key);
  }

  @override
  State<UserTutorialDialog> createState() => _UserTutorialDialogState();
}

class _UserTutorialDialogState extends State<UserTutorialDialog> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _animController;
  late Animation<double> _floatAnimation;

  final List<UserTutorialSlide> _slides = const [
    UserTutorialSlide(
      title: 'Post Projects & Get Verified Bids',
      category: 'PROJECT HUB',
      description: 'Easily publish your building, renovation, or interior design projects and get competitive quotes from top pros.',
      icon: Icons.apartment_rounded,
      imageAsset: 'assets/tutorial_1.png',
      gradientColors: [Color(0xFF0284C7), Color(0xFF0F172A)],
      bulletPoints: [
        'Post custom project details with budget & timeline',
        'Receive itemized proposals from verified contractors',
        'Select and hire the best match for your budget',
      ],
    ),
    UserTutorialSlide(
      title: 'Instant Cost & Material Estimator',
      category: 'SMART CALCULATOR',
      description: 'Calculate accurate cost estimates and material quantities before starting construction.',
      icon: Icons.calculate_rounded,
      imageAsset: 'assets/tutorial_2.png',
      gradientColors: [Color(0xFF059669), Color(0xFF064E3B)],
      bulletPoints: [
        'Estimate total costs for residential & commercial builds',
        'Calculate cement, steel, bricks, tiles & sand quantities',
        'Plan budgets smartly and prevent cost overruns',
      ],
    ),
    UserTutorialSlide(
      title: 'Browse Verified Professionals',
      category: 'TRUSTED EXPERTS',
      description: 'Discover certified contractors, architects, interior designers, and skilled construction specialists.',
      icon: Icons.verified_user_rounded,
      imageAsset: 'assets/tutorial_3.png',
      gradientColors: [Color(0xFFD97706), Color(0xFF78350F)],
      bulletPoints: [
        'Inspect portfolios, past work photos & credentials',
        'Read authentic client reviews and star ratings',
        'Connect directly via call or in-app messaging',
      ],
    ),
    UserTutorialSlide(
      title: 'Wholesale Material Store',
      category: 'B2B MARKETPLACE',
      description: 'Order high-quality building materials directly from verified manufacturers and suppliers.',
      icon: Icons.storefront_rounded,
      imageAsset: 'assets/tutorial_4.png',
      gradientColors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      bulletPoints: [
        'Browse steel, cement, electrical, plumbing & finishings',
        'Send bulk inquiry forms for custom wholesale quotes',
        'Track material orders & delivery status in real-time',
      ],
    ),
    UserTutorialSlide(
      title: 'Compare Quotes & Live Chat',
      category: 'FULL CONTROL',
      description: 'Compare bidder proposals side-by-side and coordinate smoothly throughout project execution.',
      icon: Icons.compare_arrows_rounded,
      imageAsset: 'assets/tutorial_5.png',
      gradientColors: [Color(0xFF0284C7), Color(0xFF1E3A8A)],
      bulletPoints: [
        'Side-by-side quote breakdown for maximum transparency',
        'Direct chat to clarify specs & negotiate pricing',
        'Stay updated on project milestones & delivery',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final key = UserTutorialDialog._getPrefKey(widget.userId);
    await prefs.setBool(key, true);
  }

  void _finishTutorial() {
    _markAsSeen();
    Navigator.of(context).pop();
  }

  void _skipTutorial() {
    _markAsSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSlide = _slides[_currentIndex];
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 20,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Gradient Progress Line
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 5,
              width: double.infinity,
              alignment: Alignment.centerLeft,
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              child: FractionallySizedBox(
                widthFactor: (_currentIndex + 1) / _slides.length,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: currentSlide.gradientColors,
                    ),
                  ),
                ),
              ),
            ),

            // Top Header: Category Badge + Counter + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 14, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          currentSlide.gradientColors[0].withValues(alpha: 0.15),
                          currentSlide.gradientColors[0].withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: currentSlide.gradientColors[0].withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(currentSlide.icon, size: 14, color: currentSlide.gradientColors[0]),
                        const SizedBox(width: 6),
                        Text(
                          currentSlide.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: currentSlide.gradientColors[0],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${_slides.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _skipTutorial,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Skip'),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            // PageView Main Body (Responsive desktop/mobile)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 560;

                      if (isWide) {
                        return _buildDesktopLayout(slide, isDark);
                      } else {
                        return _buildMobileLayout(slide, isDark);
                      }
                    },
                  );
                },
              ),
            ),

            // Bottom Navigation Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isSelected = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isSelected ? 26 : 7,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? currentSlide.gradientColors[0]
                              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: currentSlide.gradientColors[0].withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      if (_currentIndex > 0) ...[
                        OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: currentSlide.gradientColors,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentSlide.gradientColors[0].withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentIndex < _slides.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                );
                              } else {
                                _finishTutorial();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentIndex == _slides.length - 1
                                      ? 'Get Started Now'
                                      : 'Explore Next Benefit',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentIndex == _slides.length - 1
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wide Screen (Tablet / Desktop) Side-by-Side Layout
  Widget _buildDesktopLayout(UserTutorialSlide slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: Floating 3D AI Artwork Image Container
          Expanded(
            flex: 4,
            child: _buildArtworkHero(slide, isDark, height: 260),
          ),
          const SizedBox(width: 28),

          // Right Side: Content Details
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    slide.description,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildBulletPointsCard(slide, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile Screen Stacked Vertical Layout
  Widget _buildMobileLayout(UserTutorialSlide slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Floating 3D AI Artwork Image Container
            _buildArtworkHero(slide, isDark, height: 180),
            const SizedBox(height: 16),

            // Title
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Bullet Points Card
            _buildBulletPointsCard(slide, isDark),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Artwork Hero Widget with Float Animation & AI 3D Image
  Widget _buildArtworkHero(UserTutorialSlide slide, bool isDark, {required double height}) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              slide.gradientColors[0].withValues(alpha: isDark ? 0.25 : 0.15),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: slide.gradientColors[0].withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background subtle glow circle
            Container(
              width: height * 0.75,
              height: height * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.gradientColors[0].withValues(alpha: 0.15),
              ),
            ),

            // 3D AI Image Asset with Fallback to Icon
            Image.asset(
              slide.imageAsset,
              fit: BoxFit.contain,
              height: height * 0.9,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: slide.gradientColors),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, size: 48, color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bullet Points Card Component
  Widget _buildBulletPointsCard(UserTutorialSlide slide, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : slide.gradientColors[0].withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: slide.gradientColors[0].withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: slide.bulletPoints.map((bullet) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: slide.gradientColors[0].withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: slide.gradientColors[0],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
