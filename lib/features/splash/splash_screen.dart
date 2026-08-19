import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../../core/providers/app_prefetch.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _progressAnimation;

  String _loadingStatus = 'Initializing Buildzy Engine...';
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();

    // Start background pre-fetching while the splash animation plays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      prefetchAppData(ref);
    });

    // Main sequence controller (1.1 seconds for fast snappy loading)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Continuous subtle breathing / pulse for glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Continuous shimmer loop
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Logo entrance: Scale + Opacity (0ms - 400ms)
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Title entrance: Slide + Opacity (200ms - 600ms)
    _titleSlide = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeIn),
      ),
    );

    // Progress bar fill (150ms - 1000ms)
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _progressAnimation.addListener(() {
      final val = _progressAnimation.value;
      if (val < 0.35) {
        if (_loadingStatus != 'Initializing Buildzy Engine...') {
          setState(() => _loadingStatus = 'Initializing Buildzy Engine...');
        }
      } else if (val < 0.70) {
        if (_loadingStatus != 'Loading Architectural Modules...') {
          setState(() => _loadingStatus = 'Loading Architectural Modules...');
        }
      } else if (val < 0.92) {
        if (_loadingStatus != 'Connecting Construction Network...') {
          setState(() => _loadingStatus = 'Connecting Construction Network...');
        }
      } else {
        if (_loadingStatus != 'Ready!') {
          setState(() => _loadingStatus = 'Ready!');
        }
      }
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _attemptNavigation();
      }
    });

    _mainController.forward();
  }

  void _attemptNavigation() {
    if (_navigationTriggered || !mounted) return;

    final auth = ref.read(authProvider);
    if (!auth.isInitialized) {
      // If auth not yet loaded, wait briefly and retry
      Timer(const Duration(milliseconds: 200), _attemptNavigation);
      return;
    }

    _navigationTriggered = true;

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
    _mainController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes just in case
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (_mainController.isCompleted && next.isInitialized && !_navigationTriggered) {
        _attemptNavigation();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF090D14),
      body: Stack(
        children: [
          // Background Blueprint Grid & Ambient Glows
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintBackgroundPainter(
                pulseValue: _pulseController.value,
              ),
            ),
          ),

          // Central animated content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Logo with Pulse Glow & Halo
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _mainController,
                        _pulseController,
                        _shimmerController,
                      ]),
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        final shimmer = _shimmerController.value;

                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Ambient Pulse Glow
                                Container(
                                  width: 170 + (pulse * 20),
                                  height: 170 + (pulse * 20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF1F2937).withValues(alpha: 0.35 + (pulse * 0.15)),
                                        const Color(0xFF00D2FF).withValues(alpha: 0.12 + (pulse * 0.08)),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),

                                // Rotating Geometric Blueprint Ring
                                Transform.rotate(
                                  angle: shimmer * 2 * math.pi,
                                  child: Container(
                                    width: 154,
                                    height: 154,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF00D2FF).withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // Counter Rotating Dash Ring
                                Transform.rotate(
                                  angle: -shimmer * 2 * math.pi,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1F2937).withValues(alpha: 0.45),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),

                                // App Icon Card Container
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1E2638),
                                        Color(0xFF0F1522),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF641E).withValues(alpha: 0.3),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, -4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // App Title & Tagline
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _titleSlide.value),
                          child: Opacity(
                            opacity: _titleOpacity.value,
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFF9CA3AF),
                                      Color(0xFF1F2937),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: const Text(
                                    'BUILDZY',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SMART CONSTRUCTION & ARCHITECTURE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 3),

                    // Progress Bar & Dynamic Status
                    AnimatedBuilder(
                      animation: Listenable.merge([_mainController, _shimmerController]),
                      builder: (context, child) {
                        final progress = _progressAnimation.value;
                        final percent = (progress * 100).toInt();

                        return Opacity(
                          opacity: _titleOpacity.value,
                          child: Column(
                            children: [
                              // Progress Bar Track
                              Container(
                                width: double.infinity,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    // Filled bar with animated gradient
                                    FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00D2FF),
                                              Color(0xFF374151),
                                              Color(0xFF1F2937),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF1F2937).withValues(alpha: 0.6),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Status text + Percentage
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _loadingStatus,
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$percent%',
                                    style: const TextStyle(
                                      color: Color(0xFF00D2FF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Blueprint Ambient Background
class _BlueprintBackgroundPainter extends CustomPainter {
  final double pulseValue;

  _BlueprintBackgroundPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.15),
        radius: 0.9,
        colors: [
          Color(0xFF141D2B),
          Color(0xFF090D14),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF00D2FF).withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Ambient radial glow top right (cyan)
    final cyanGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00D2FF).withValues(alpha: 0.07 + (pulseValue * 0.04)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.2),
        radius: 180,
      ));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 180, cyanGlow);

    // Ambient radial glow bottom left (slate)
    final slateGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1F2937).withValues(alpha: 0.12 + (pulseValue * 0.04)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.15, size.height * 0.75),
        radius: 200,
      ));
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 200, slateGlow);
  }

  @override
  bool shouldRepaint(covariant _BlueprintBackgroundPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
