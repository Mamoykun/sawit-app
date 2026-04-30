import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Organic biophilic background painter.
///
/// Renders:
///  - Soft asymmetric blob shapes (curved leaf-like silhouettes)
///  - Sparse particle dots (suggesting brondolan/seeds floating)
///
/// Used behind splash + auth screens to add atmosphere without competing
/// with foreground content. Performance-friendly (one CustomPaint).
class OrganicBackground extends StatelessWidget {
  final Color blobColor;
  final Color particleColor;
  final double blobOpacity;
  final double particleOpacity;
  final int particleCount;

  const OrganicBackground({
    super.key,
    required this.blobColor,
    required this.particleColor,
    this.blobOpacity = 0.12,
    this.particleOpacity = 0.18,
    this.particleCount = 28,
  });

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _OrganicBackgroundPainter(
              blobColor: blobColor.withOpacity(blobOpacity),
              particleColor: particleColor.withOpacity(particleOpacity),
              particleCount: particleCount,
            ),
          ),
        ),
      );
}

class _OrganicBackgroundPainter extends CustomPainter {
  final Color blobColor;
  final Color particleColor;
  final int particleCount;

  _OrganicBackgroundPainter({
    required this.blobColor,
    required this.particleColor,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-right blob (large, soft)
    final blobPaint = Paint()
      ..color = blobColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);

    final blob1 = Path();
    blob1.moveTo(w * 0.55, -h * 0.05);
    blob1.cubicTo(
      w * 0.92, h * 0.05,
      w * 1.10, h * 0.30,
      w * 0.85, h * 0.42,
    );
    blob1.cubicTo(
      w * 0.65, h * 0.50,
      w * 0.50, h * 0.30,
      w * 0.55, -h * 0.05,
    );
    blob1.close();
    canvas.drawPath(blob1, blobPaint);

    // Bottom-left blob (smaller, lower opacity layered)
    final blob2 = Path();
    blob2.moveTo(-w * 0.10, h * 0.62);
    blob2.cubicTo(
      w * 0.20, h * 0.55,
      w * 0.40, h * 0.78,
      w * 0.30, h * 1.05,
    );
    blob2.cubicTo(
      w * 0.10, h * 1.10,
      -w * 0.20, h * 0.95,
      -w * 0.10, h * 0.62,
    );
    blob2.close();
    canvas.drawPath(blob2, blobPaint);

    // Particles (deterministic random — same pattern every render)
    final rand = math.Random(42);
    final particlePaint = Paint()..color = particleColor;
    for (int i = 0; i < particleCount; i++) {
      final x = rand.nextDouble() * w;
      final y = rand.nextDouble() * h;
      final r = 1.0 + rand.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), r, particlePaint);
    }

    // A few larger soft dots
    final softDot = Paint()
      ..color = particleColor.withOpacity((particleColor.opacity * 0.6))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (int i = 0; i < 5; i++) {
      final x = rand.nextDouble() * w;
      final y = rand.nextDouble() * h;
      canvas.drawCircle(Offset(x, y), 6 + rand.nextDouble() * 4, softDot);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicBackgroundPainter old) =>
      old.blobColor != blobColor ||
      old.particleColor != particleColor ||
      old.particleCount != particleCount;
}
