import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A subtle paper-grain overlay — the digital equivalent of paper texture.
///
/// Performance: the grain is rendered into a single small tile image *once*
/// (cached statically), then painted with a repeating [ui.ImageShader] in one
/// cheap `drawRect`. No per-frame loops, no multiply blend — so it composites
/// fast even with several screens alive in an IndexedStack.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color ?? AppColors.paper,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          // Grain sits on top but never intercepts touches.
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(child: CustomPaint(painter: _GrainPainter())),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();

  static const int _tileSize = 160;
  static ui.Image? _tile;

  static ui.Image _grainTile() {
    final cached = _tile;
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rng = Random(0xB4EAD);
    final paint = Paint();
    for (var i = 0; i < 650; i++) {
      final dx = rng.nextDouble() * _tileSize;
      final dy = rng.nextDouble() * _tileSize;
      final a = 0.02 + rng.nextDouble() * 0.05;
      paint.color = AppColors.ink.withValues(alpha: a);
      canvas.drawCircle(Offset(dx, dy), 0.6, paint);
    }
    final image =
        recorder.endRecording().toImageSync(_tileSize, _tileSize);
    _tile = image;
    return image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.ImageShader(
        _grainTile(),
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
