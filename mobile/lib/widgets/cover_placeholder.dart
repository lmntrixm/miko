import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';

/// Striped placeholder until licensed cover art exists. Never use real cover art in samples.
class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({
    super.key,
    this.width,
    this.height,
    this.radius = 14,
  });
  final double? width, height, radius;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? 0),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        child: CustomPaint(
          painter: _Stripes(c.textPrimary.withValues(alpha: 0.06), c.surface3),
        ),
      ),
    );
  }
}

class _Stripes extends CustomPainter {
  _Stripes(this.a, this.b);
  final Color a, b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = b);
    final p = Paint()
      ..color = a
      ..strokeWidth = 6;
    for (double x = -size.height; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_Stripes o) => o.a != a || o.b != b;
}
