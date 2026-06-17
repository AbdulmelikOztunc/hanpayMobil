import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hanpay_mobil/core/theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 40, this.compact = false});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hexSize = height * 0.95;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(hexSize, hexSize),
          painter: _HexLogoPainter(),
        ),
        if (!compact) ...[
          SizedBox(width: height * 0.18),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: height * 0.52,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
              ),
              children: const [
                TextSpan(text: 'Han', style: TextStyle(color: AppColors.hanBlue)),
                TextSpan(text: 'Pay', style: TextStyle(color: AppColors.payBlue)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HexLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outer = _hexPath(center, radius);
    final inner = _hexPath(center, radius * 0.82);

    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.hexOuter, Color(0xFF1E5AD9)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawPath(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.hexInner, AppColors.hanBlue],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'H',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 - radius * 0.05),
    );
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
