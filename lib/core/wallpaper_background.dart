import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ConstructionDoodlePainter extends CustomPainter {
  final bool isDark;
  const ConstructionDoodlePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Skip drawing background doodles on mobile screens/platforms to maximize scroll and transition performance
    if (size.width <= 600 || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return;
    }

    final paint = Paint()
      ..color = isDark 
          ? Colors.white.withValues(alpha: 0.03) 
          : Colors.black.withValues(alpha: 0.025) // Subtle outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw doodles in a grid with random slight rotations/offsets
    const double gridSize = 90.0;
    final int cols = (size.width / gridSize).ceil();
    final int rows = (size.height / gridSize).ceil();

    final math.Random random = math.Random(100); // Fixed seed for stable doodles

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Add random jitter to offset from rigid grid lines
        final double jitterX = (random.nextDouble() - 0.5) * 20;
        final double jitterY = (random.nextDouble() - 0.5) * 20;
        final double cx = (c + 0.5) * gridSize + jitterX;
        final double cy = (r + 0.5) * gridSize + jitterY;

        canvas.save();
        canvas.translate(cx, cy);
        
        // Random rotation of up to 25 degrees
        final double rotation = (random.nextDouble() - 0.5) * 0.45;
        canvas.rotate(rotation);

        // Pick one of the construction doodles
        final int type = random.nextInt(6);
        switch (type) {
          case 0:
            // House outline
            final path = Path();
            path.moveTo(-8, 8);
            path.lineTo(-8, -2);
            path.lineTo(0, -9);
            path.lineTo(8, -2);
            path.lineTo(8, 8);
            path.close();
            // Door
            path.moveTo(-2.5, 8);
            path.lineTo(-2.5, 3.5);
            path.lineTo(2.5, 3.5);
            path.lineTo(2.5, 8);
            canvas.drawPath(path, paint);
            break;
          case 1:
            // Hammer
            final path = Path();
            // Handle
            path.moveTo(0, 8);
            path.lineTo(0, -5);
            // Head
            path.moveTo(-7, -5);
            path.lineTo(5, -5);
            path.lineTo(5, -9);
            path.lineTo(-7, -9);
            path.close();
            canvas.drawPath(path, paint);
            break;
          case 2:
            // Set square triangle ruler
            final path = Path();
            path.moveTo(-7, 7);
            path.lineTo(7, 7);
            path.lineTo(-7, -7);
            path.close();
            // Inner cut-out
            path.moveTo(-4, 4);
            path.lineTo(2, 4);
            path.lineTo(-4, -2);
            path.close();
            canvas.drawPath(path, paint);
            break;
          case 3:
            // Hard hat / Safety helmet
            final path = Path();
            path.addArc(Rect.fromCircle(center: const Offset(0, 1), radius: 7), math.pi, math.pi);
            // Brim
            path.moveTo(-10, 1);
            path.lineTo(10, 1);
            canvas.drawPath(path, paint);
            break;
          case 4:
            // Gear
            canvas.drawCircle(const Offset(0, 0), 3.5, paint);
            for (int i = 0; i < 8; i++) {
              final double angle = i * math.pi / 4;
              final double x1 = 3.5 * math.cos(angle);
              final double y1 = 3.5 * math.sin(angle);
              final double x2 = 6.5 * math.cos(angle);
              final double y2 = 6.5 * math.sin(angle);
              canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
            }
            break;
          case 5:
            // Bricks / Wall block
            canvas.drawRect(Rect.fromCenter(center: const Offset(0, 0), width: 13, height: 7), paint);
            canvas.drawLine(const Offset(0, -3.5), const Offset(0, 3.5), paint);
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
    
    // Select background color matching theme
    final Color bgColor = backgroundColor ?? 
        (isDark ? const Color(0xFF121B22) : Colors.white);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ConstructionDoodlePainter(isDark: isDark),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
