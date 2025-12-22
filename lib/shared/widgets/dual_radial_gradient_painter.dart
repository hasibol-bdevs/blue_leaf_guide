import 'package:flutter/material.dart';

class DualRadialGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // First gradient - bottom-left
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1, 1),
        radius: 2,
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFF7692EF),
        ],
        stops: const [0.0, 0.15, 0.85],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint1);

    // Second gradient - bottom-right (overlay)
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1, 1),
        radius: 2,
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
          const Color(0xFF7692EF).withOpacity(0),
        ],
        stops: const [0.0, 0.10, 0.85],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
