import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../../core/providers/app_prefetch.dart';
import '../../core/services/location_service.dart';
import '../../core/services/push_notification_service.dart';

/// Professional animated splash / loading screen.
///
/// Features:
/// - Uses the exact existing logo (`assets/logo.png`) without redesign or alteration.
/// - Clean background matching the app's current theme (light/dark).
/// - Logo entrance animation: Opacity 0% -> 100%, Scale 85% -> 100% (750ms, ease-out).
/// - Subtle breathing pulse after logo settles.
/// - Minimal, lightweight loading indicator below the logo.
/// - Asynchronous startup: Waits for real initialization tasks (auth, services, data prefetch).
/// - Graceful transition: If initialization is fast, it finishes the animation naturally;
///   if slower, it continues breathing smoothly without freezing.
/// - Smooth exit fade transition to the destination screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Entrance animation controller (750ms)
  late AnimationController _entranceController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _indicatorOpacity;

  // Subtle breathing / pulse animation controller (1600ms)
  late AnimationController _pulseController;
  late Animation<double> _logoPulse;

  // Exit transition controller (280ms)
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;
  late Animation<double> _exitScale;

  // Track natural entrance completion
  final Completer<void> _entranceCompleter = Completer<void>();
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runStartupSequence();
  }

  void _setupAnimations() {
    // 1. Entrance animation (750ms ease-out)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      ),
    );

    // Indicator fades in gently in the latter half of the entrance
    _indicatorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
      ),
    );

    _entranceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_entranceCompleter.isCompleted) {
          _entranceCompleter.complete();
        }
        // Start subtle breathing pulse once entrance is fully completed
        if (mounted && !_navigationTriggered) {
          _pulseController.repeat(reverse: true);
        }
      }
    });

    // 2. Subtle continuous breathing pulse (1600ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoPulse = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Smooth exit transition (280ms)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOut,
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _runStartupSequence() async {
    // Start entrance animation immediately
    _entranceController.forward();

    // Run real application initialization in parallel
    final initFuture = _performInitialization();

    // Wait for BOTH:
    // 1. Natural completion of the logo entrance animation (~750ms)
    // 2. Completion of actual initialization tasks
    await Future.wait([
      _entranceCompleter.future,
      initFuture,
    ]);

    if (!mounted || _navigationTriggered) return;

    // Smooth exit transition
    await _exitController.forward();

    if (!mounted || _navigationTriggered) return;

    _navigateToDestination();
  }

  /// Real initialization tasks:
  /// - Pre-fetch data into cache
  /// - Wait for persisted authentication state
  /// - Initialize background services if authenticated
  Future<void> _performInitialization() async {
    try {
      // Warm up critical feeds & cached data in parallel
      prefetchAppData(ref);

      // Wait for auth provider to finish reading from local storage
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

      // If user is authenticated, sync location and notifications
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
    final backgroundColor = isDark ? const Color(0xFF121B22) : const Color(0xFFF5F5F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _pulseController,
            _exitController,
          ]),
          builder: (context, child) {
            // Combine entrance scale, pulse breathing, and exit scale smoothly
            final entranceScale = _logoScale.value;
            final pulseScale = _entranceController.isCompleted ? _logoPulse.value : 1.0;
            final exitScale = _exitScale.value;
            final finalScale = entranceScale * pulseScale * exitScale;

            // Combine entrance opacity and exit opacity
            final finalOpacity = (_logoOpacity.value * _exitOpacity.value).clamp(0.0, 1.0);

            return Opacity(
              opacity: finalOpacity,
              child: Transform.scale(
                scale: finalScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Existing Logo Asset (Clean, Unaltered)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 28,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 116,
                          height: 116,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Minimal, Lightweight Loading Indicator
                    Opacity(
                      opacity: _indicatorOpacity.value * _exitOpacity.value,
                      child: _MinimalLoadingIndicator(isDark: isDark),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A sleek, minimal, and lightweight indeterminate loading indicator bar.
///
/// Designed to be clean, distraction-free, and respectful of the brand palette.
class _MinimalLoadingIndicator extends StatefulWidget {
  final bool isDark;

  const _MinimalLoadingIndicator({required this.isDark});

  @override
  State<_MinimalLoadingIndicator> createState() => _MinimalLoadingIndicatorState();
}

class _MinimalLoadingIndicatorState extends State<_MinimalLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final runnerColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF1F2937);

    return SizedBox(
      width: 110,
      height: 2.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            // Background track
            Positioned.fill(
              child: Container(color: trackColor),
            ),

            // Smooth sliding runner
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final value = _controller.value;
                // Move from left to right with a smooth sweep
                final leftFraction = (value * 1.6) - 0.6;
                final widthFraction = 0.4;

                return Align(
                  alignment: Alignment(leftFraction * 2 - 1, 0),
                  child: FractionallySizedBox(
                    widthFactor: widthFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: runnerColor,
                        borderRadius: BorderRadius.circular(2),
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
