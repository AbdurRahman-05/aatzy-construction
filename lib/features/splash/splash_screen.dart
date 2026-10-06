import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_provider.dart';
import '../../core/providers/app_prefetch.dart';
import '../../core/services/location_service.dart';
import '../../core/services/push_notification_service.dart';

/// Next-Generation Animated Splash Screen for Connectzy
///
/// Features:
/// 1. Big, prominent, unconstrained logo without background box.
/// 2. Concentric expanding acoustic pulse rings ("radar connect" aura).
/// 3. Spring-physics entrance animation (easeOutBack).
/// 4. Shimmer light-reflection sweep across the logo silhouette.
/// 5. Inspiring quote reveal: "Connecting Your Dreams".
/// 6. Continuous subtle breathing cycle keeping the UI organic and alive.
/// 7. Sleek multi-color gradient loading runner.
/// 8. Seamless exit transition with parallel asynchronous startup prefetching.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Master entrance animation controller (1900ms)
  late AnimationController _entranceController;

  // Staggered entrance animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _shimmerSweep;
  late Animation<Offset> _quoteSlide;
  late Animation<double> _quoteOpacity;
  late Animation<double> _waveProgress1;
  late Animation<double> _waveProgress2;
  late Animation<double> _indicatorOpacity;

  // Continuous breathing / pulse animation controller (2000ms loop)
  late AnimationController _pulseController;
  late Animation<double> _breathingScale;
  late Animation<double> _ambientGlowPulse;

  // Exit transition controller (350ms)
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  // Completion trackers
  final Completer<void> _entranceCompleter = Completer<void>();
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runStartupSequence();
  }

  void _setupAnimations() {
    // 1. Entrance Controller (1900ms total sequence)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    // Wave ring 1: Expands from 12% to 68% of the timeline
    _waveProgress1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.12, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // Wave ring 2: Slightly delayed (28% to 84%)
    _waveProgress2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.28, 0.84, curve: Curves.easeOutCubic),
      ),
    );

    // Logo scale: Spring entrance with easeOutBack (0% -> 50%)
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );

    // Logo opacity: 0% -> 40%
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // Shimmer sweep across the logo (42% -> 76%)
    _shimmerSweep = Tween<double>(begin: -1.4, end: 2.2).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.76, curve: Curves.easeInOut),
      ),
    );

    // Quote "Connecting Your Dreams" slide & fade (50% -> 82%)
    _quoteSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _quoteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.50, 0.78, curve: Curves.easeOut),
      ),
    );

    // Indicator fade in (68% -> 95%)
    _indicatorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.68, 0.95, curve: Curves.easeIn),
      ),
    );

    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_entranceCompleter.isCompleted) {
          _entranceCompleter.complete();
        }
        if (mounted && !_navigationTriggered) {
          _pulseController.repeat(reverse: true);
        }
      }
    });

    // 2. Subtle continuous breathing cycle (2000ms loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _breathingScale = Tween<double>(begin: 1.0, end: 1.028).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _ambientGlowPulse = Tween<double>(begin: 0.70, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Smooth Exit transition (350ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInQuad,
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _runStartupSequence() async {
    // Start entrance animation immediately
    _entranceController.forward();

    // Minimum display timer so users always enjoy the visual experience (2.4s)
    final minDisplayFuture = Future.delayed(const Duration(milliseconds: 2400));

    // Run real application initialization in parallel
    final initFuture = _performInitialization();

    // Wait for entrance completion, data initialization, and the minimum timer
    await Future.wait([
      _entranceCompleter.future,
      minDisplayFuture,
      initFuture,
    ]);

    if (!mounted || _navigationTriggered) return;

    // Smooth exit transition
    await _exitController.forward();

    if (!mounted || _navigationTriggered) return;

    _navigateToDestination();
  }

  /// Real initialization tasks:
  /// - Pre-fetch feeds and cached state into Riverpod providers
  /// - Check persisted auth state
  /// - Initialize background services (Location, FCM) if signed in
  Future<void> _performInitialization() async {
    try {
      prefetchAppData(ref);

      if (!ref.read(authProvider).isInitialized) {
        final authCompleter = Completer<void>();
        final subscription = ref.listenManual<AuthState>(authProvider, (_, next) {
          if (next.isInitialized && !authCompleter.isCompleted) {
            authCompleter.complete();
          }
        });

        try {
          await authCompleter.future.timeout(const Duration(seconds: 4));
        } catch (_) {
          debugPrint('[Splash] Auth initialization wait timed out.');
        } finally {
          subscription.close();
        }
      }

      final auth = ref.read(authProvider);
      if (auth.id != null) {
        LocationService().detectAndSaveLocation();
        if (auth.role != null) {
          PushNotificationService().syncFCMToken(userId: auth.id, role: auth.role);
        }
      }
    } catch (e) {
      debugPrint('[Splash] Error during initialization: $e');
    }
  }

  void _navigateToDestination() {
    if (_navigationTriggered || !mounted) return;
    _navigationTriggered = true;

    final auth = ref.read(authProvider);
    if (auth.id != null) {
      if (auth.role == 'PROVIDER') {
        context.go('/provider-home');
      } else {
        context.go('/');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    // Responsive large logo width (without bounding box)
    final logoWidth = size.width > 500
        ? 300.0
        : (size.width * 0.72).clamp(210.0, 290.0);

    // Dark-first atmospheric palette
    final bgGradientColors = isDark
        ? const [
            Color(0xFF0F1E29),
            Color(0xFF09121A),
            Color(0xFF050A0F),
          ]
        : const [
            Color(0xFFFFFFFF),
            Color(0xFFF6F8FB),
            Color(0xFFECEFF4),
          ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bgGradientColors,
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _pulseController,
            _exitController,
          ]),
          builder: (context, child) {
            final entranceScale = _logoScale.value;
            final pulseScale = _entranceController.isCompleted ? _breathingScale.value : 1.0;
            final exitScale = _exitScale.value;
            final combinedScale = entranceScale * pulseScale * exitScale;

            final totalOpacity = (_logoOpacity.value * _exitOpacity.value).clamp(0.0, 1.0);

            return Stack(
              children: [
                // 1. Ambient Glow & Radial Wave Aura centered in background
                Center(
                  child: Opacity(
                    opacity: totalOpacity,
                    child: _AuraWaves(
                      wave1: _waveProgress1.value,
                      wave2: _waveProgress2.value,
                      glowPulse: _ambientGlowPulse.value,
                      isDark: isDark,
                    ),
                  ),
                ),

                // 2. Primary Foreground Content
                Center(
                  child: Opacity(
                    opacity: totalOpacity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // Prominent Big Logo without Background Box (Spring scale + Shimmer + Subtle Glow)
                        Transform.scale(
                          scale: combinedScale,
                          child: _CleanAnimatedLogo(
                            logoWidth: logoWidth,
                            shimmerProgress: _shimmerSweep.value,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Quote & Tagline: "Connecting Your Dreams"
                        SlideTransition(
                          position: _quoteSlide,
                          child: Opacity(
                            opacity: (_quoteOpacity.value * _exitOpacity.value).clamp(0.0, 1.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF0F766E).withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    '“ Connecting Your Dreams ”',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? const Color(0xFFE2E8F0)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF0F766E).withValues(alpha: 0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Modern Gradient Loading Indicator
                        Opacity(
                          opacity: (_indicatorOpacity.value * _exitOpacity.value).clamp(0.0, 1.0),
                          child: _GradientLoadingBar(isDark: isDark),
                        ),

                        const SizedBox(height: 20),

                        // Bottom Branding / Version Info
                        Opacity(
                          opacity: (_indicatorOpacity.value * _exitOpacity.value * 0.75).clamp(0.0, 1.0),
                          child: Text(
                            'v1.0.0 · Verified Infrastructure Hub',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dynamic Concentric Aura Wave Rings and Ambient Radial Glow
class _AuraWaves extends StatelessWidget {
  final double wave1;
  final double wave2;
  final double glowPulse;
  final bool isDark;

  const _AuraWaves({
    required this.wave1,
    required this.wave2,
    required this.glowPulse,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 440,
      height: 440,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient radial glow
          Container(
            width: 280 * glowPulse,
            height: 280 * glowPulse,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0F766E).withValues(alpha: 0.38 * glowPulse),
                        const Color(0xFF0F766E).withValues(alpha: 0.09 * glowPulse),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFF0F766E).withValues(alpha: 0.18 * glowPulse),
                        const Color(0xFF0F766E).withValues(alpha: 0.04 * glowPulse),
                        Colors.transparent,
                      ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Expanding wave ring 1
          if (wave1 > 0.0 && wave1 < 1.0)
            Container(
              width: 140 + (wave1 * 220),
              height: 140 + (wave1 * 220),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0F766E).withValues(
                    alpha: (1.0 - wave1) * (isDark ? 0.42 : 0.28),
                  ),
                  width: 1.5 * (1.0 - wave1 * 0.4),
                ),
              ),
            ),

          // Expanding wave ring 2
          if (wave2 > 0.0 && wave2 < 1.0)
            Container(
              width: 160 + (wave2 * 250),
              height: 160 + (wave2 * 250),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(
                    alpha: (1.0 - wave2) * (isDark ? 0.32 : 0.20),
                  ),
                  width: 1.5 * (1.0 - wave2 * 0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Clean Big Logo without Background Box + Shimmer Light Sweep
class _CleanAnimatedLogo extends StatelessWidget {
  final double logoWidth;
  final double shimmerProgress;
  final bool isDark;

  const _CleanAnimatedLogo({
    required this.logoWidth,
    required this.shimmerProgress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft atmospheric halo directly behind the logo silhouette
        Container(
          width: logoWidth * 0.75,
          height: logoWidth * 0.35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(logoWidth * 0.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: isDark ? 0.35 : 0.16),
                blurRadius: 45,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 35,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Pure Logo Image with Diagonal Shimmer Sweep
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(shimmerProgress - 1.2, -0.6),
              end: Alignment(shimmerProgress, 0.6),
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: isDark ? 0.55 : 0.70),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: Image.asset(
            'assets/logo.png',
            width: logoWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    );
  }
}

/// Sleek Multi-Color Gradient Loading Runner
class _GradientLoadingBar extends StatefulWidget {
  final bool isDark;

  const _GradientLoadingBar({required this.isDark});

  @override
  State<_GradientLoadingBar> createState() => _GradientLoadingBarState();
}

class _GradientLoadingBarState extends State<_GradientLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _runnerController;

  @override
  void initState() {
    super.initState();
    _runnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _runnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SizedBox(
      width: 140,
      height: 3.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Background track
            Positioned.fill(
              child: Container(color: trackColor),
            ),

            // Smooth sliding multi-gradient runner
            AnimatedBuilder(
              animation: _runnerController,
              builder: (context, child) {
                final value = _runnerController.value;
                final leftFraction = (value * 1.7) - 0.7;
                const widthFraction = 0.42;

                return Align(
                  alignment: Alignment(leftFraction * 2 - 1, 0),
                  child: FractionallySizedBox(
                    widthFactor: widthFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F766E),
                            Color(0xFF06B6D4),
                            Color(0xFFF59E0B),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
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
