import 'package:flutter/material.dart';

/// Pixel-perfect vector implementation of the official Google 4-color "G" emblem
class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
        size: Size(size, size),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Red Top Arc (#EA4335)
    paint.color = const Color(0xFFEA4335);
    final pathRed = Path();
    pathRed.moveTo(24, 9.5);
    pathRed.cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1);
    pathRed.lineTo(40.06, 6.25);
    pathRed.cubicTo(35.9, 2.38, 30.47, 0, 24, 0);
    pathRed.cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22);
    pathRed.lineTo(10.54, 19.41);
    pathRed.cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5);
    pathRed.close();
    canvas.drawPath(pathRed, paint);

    // 2. Yellow Left Arc (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    final pathYellow = Path();
    pathYellow.moveTo(10.53, 28.59);
    pathYellow.cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0);
    pathYellow.cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41);
    pathYellow.lineTo(2.55, 13.22);
    pathYellow.cubicTo(0.92, 16.46, 0, 20.12, 0, 24.0);
    pathYellow.cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78);
    pathYellow.lineTo(10.53, 28.59);
    pathYellow.close();
    canvas.drawPath(pathYellow, paint);

    // 3. Green Bottom Arc (#34A853)
    paint.color = const Color(0xFF34A853);
    final pathGreen = Path();
    pathGreen.moveTo(24, 48);
    pathGreen.cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19);
    pathGreen.lineTo(32.16, 36.19);
    pathGreen.cubicTo(30.01, 37.64, 27.24, 38.5, 24, 38.5);
    pathGreen.cubicTo(17.74, 38.5, 12.43, 34.28, 10.53, 28.59);
    pathGreen.lineTo(2.56, 34.78);
    pathGreen.cubicTo(6.51, 42.62, 14.62, 48, 24, 48);
    pathGreen.close();
    canvas.drawPath(pathGreen, paint);

    // 4. Blue Right Arc & Horizontal Bar (#4285F4)
    paint.color = const Color(0xFF4285F4);
    final pathBlue = Path();
    pathBlue.moveTo(46.98, 24.55);
    pathBlue.cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20.0);
    pathBlue.lineTo(24, 20.0);
    pathBlue.lineTo(24, 29.02);
    pathBlue.lineTo(36.94, 29.02);
    pathBlue.cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2);
    pathBlue.lineTo(39.89, 42.2);
    pathBlue.cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55);
    pathBlue.close();
    canvas.drawPath(pathBlue, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
