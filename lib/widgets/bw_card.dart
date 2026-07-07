import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A paper panel with a 1px black edge. No radius, no shadow.
/// [dashed] gives the informal frame used for community notes / testimonies.
class BwCard extends StatelessWidget {
  const BwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.paperDeep,
    this.dashed = false,
    this.borderColor = AppColors.ink,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final bool dashed;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      color: color,
      width: double.infinity,
      child: child,
    );

    final framed = dashed
        ? CustomPaint(
            painter: _DashedBorderPainter(borderColor),
            child: body,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
            ),
            child: body,
          );

    if (onTap == null) return framed;
    return GestureDetector(onTap: onTap, child: framed);
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;

    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      var d = 0.0;
      while (d < total) {
        final start = a + dir * d;
        final end = a + dir * (d + dash).clamp(0, total);
        canvas.drawLine(start, end, paint);
        d += dash + gap;
      }
    }

    final tl = Offset.zero;
    final tr = Offset(size.width, 0);
    final br = Offset(size.width, size.height);
    final bl = Offset(0, size.height);
    line(tl, tr);
    line(tr, br);
    line(br, bl);
    line(bl, tl);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}
