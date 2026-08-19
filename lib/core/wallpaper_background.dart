import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConstructionDoodlePainter extends CustomPainter {
  final bool isDark;
  const ConstructionDoodlePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = isDark
          ? const Color(0xFF0F9B8E).withValues(alpha: 0.10)
          : const Color(0xFF064354).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFF064354).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle architectural blueprint dot grid
    const double dotStep = 45.0;
    for (double x = 20; x < size.width; x += dotStep) {
      for (double y = 20; y < size.height; y += dotStep) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    // Draw elegant construction & blueprint doodles scattered cleanly
    const double gridSize = 110.0;
    final int cols = (size.width / gridSize).ceil();
    final int rows = (size.height / gridSize).ceil();
    final math.Random random = math.Random(42);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Reduced skip so icons are easily visible across background
        if (random.nextDouble() > 0.8) continue;

        final double jitterX = (random.nextDouble() - 0.5) * 30;
        final double jitterY = (random.nextDouble() - 0.5) * 30;
        final double cx = (c + 0.5) * gridSize + jitterX;
        final double cy = (r + 0.5) * gridSize + jitterY;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate((random.nextDouble() - 0.5) * 0.35);

        final int type = random.nextInt(6);
        switch (type) {
          case 0:
            // Architectural house structure
            final path = Path();
            path.moveTo(-10, 10);
            path.lineTo(-10, -3);
            path.lineTo(0, -11);
            path.lineTo(10, -3);
            path.lineTo(10, 10);
            path.close();
            path.moveTo(-3, 10);
            path.lineTo(-3, 4);
            path.lineTo(3, 4);
            path.lineTo(3, 10);
            canvas.drawPath(path, strokePaint);
            break;
          case 1:
            // Builder Safety Helmet
            final path = Path();
            path.addArc(Rect.fromCircle(center: const Offset(0, 1), radius: 8), math.pi, math.pi);
            path.moveTo(-11, 1);
            path.lineTo(11, 1);
            canvas.drawPath(path, strokePaint);
            break;
          case 2:
            // Set square triangle ruler
            final path = Path();
            path.moveTo(-8, 8);
            path.lineTo(8, 8);
            path.lineTo(-8, -8);
            path.close();
            path.moveTo(-5, 5);
            path.lineTo(2, 5);
            path.lineTo(-5, -2);
            path.close();
            canvas.drawPath(path, strokePaint);
            break;
          case 3:
            // Structural Beam Truss Cross
            canvas.drawRect(Rect.fromCenter(center: const Offset(0, 0), width: 16, height: 16), strokePaint);
            canvas.drawLine(const Offset(-8, -8), const Offset(8, 8), strokePaint);
            canvas.drawLine(const Offset(-8, 8), const Offset(8, -8), strokePaint);
            break;
          case 4:
            // Hammer
            final path = Path();
            path.moveTo(0, 9);
            path.lineTo(0, -4);
            path.moveTo(-7, -4);
            path.lineTo(6, -4);
            path.lineTo(6, -9);
            path.lineTo(-7, -9);
            path.close();
            canvas.drawPath(path, strokePaint);
            break;
          case 5:
            // Blueprint Compass Circles
            canvas.drawCircle(const Offset(0, 0), 9, strokePaint);
            canvas.drawCircle(const Offset(0, 0), 4, strokePaint);
            canvas.drawLine(const Offset(-12, 0), const Offset(12, 0), strokePaint);
            canvas.drawLine(const Offset(0, -12), const Offset(0, 12), strokePaint);
            break;
        }

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WallpaperBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const WallpaperBackground({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgColor = backgroundColor ?? 
        (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Top Ambient Teal Header Glow (Subtle & Dimmed)
          Positioned(
            top: -140,
            left: -100,
            right: -100,
            height: 380,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [
                      isDark
                          ? const Color(0xFF0F9B8E).withValues(alpha: 0.06)
                          : const Color(0xFF064354).withValues(alpha: 0.03),
                      isDark
                          ? const Color(0xFF0B6780).withValues(alpha: 0.02)
                          : const Color(0xFF0B6780).withValues(alpha: 0.01),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Bottom-Right Warm Accent Glow (Subtle & Dimmed)
          Positioned(
            bottom: -120,
            right: -100,
            width: 400,
            height: 400,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isDark
                          ? const Color(0xFF1E88E5).withValues(alpha: 0.04)
                          : const Color(0xFFFFB74D).withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Architectural blueprint pattern watermark
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: ConstructionDoodlePainter(isDark: isDark),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
