import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
/// 5. Continuous subtle breathing cycle keeping the UI organic and alive.
/// 6. Seamless exit transition with parallel asynchronous startup prefetching.
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
  late Animation<double> _waveProgress1;
  late Animation<double> _waveProgress2;

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

                // 2. Primary Foreground Content (Centered Animated Logo)
                Center(
                  child: Opacity(
                    opacity: totalOpacity,
                    child: Transform.scale(
                      scale: combinedScale,
                      child: _CleanAnimatedLogo(
                        logoWidth: logoWidth,
                        shimmerProgress: _shimmerSweep.value,
                        isDark: isDark,
                      ),
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
    // Pure Logo Image with Diagonal Shimmer Sweep (Zero background box or halo)
    return ShaderMask(
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
    );
  }
}
