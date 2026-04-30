import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// SawitKu brand logo — pure Flutter CustomPaint.
///
/// Visual concept:
///  - A circular "harvest sun" disk in earth-green
///  - 3 stylized palm fronds radiating from the top, evoking a young sawit canopy
///  - A small gold seed/dot at the heart, symbolizing the buah/TBS
///
/// Design principles: organic biophilic, geometric balance, no skeuomorphism.
/// Renders crisp at every size (16dp app icon → 200dp splash).
class SawitLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? accentColor;
  final bool withGlow;

  const SawitLogo({
    super.key,
    this.size = 64,
    this.primaryColor,
    this.accentColor,
    this.withGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SawitLogoPainter(
          primary: primaryColor ?? AppColors.primary,
          accent: accentColor ?? AppColors.gold,
          withGlow: withGlow,
        ),
      ),
    );
  }
}

class _SawitLogoPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final bool withGlow;

  _SawitLogoPainter({
    required this.primary,
    required this.accent,
    required this.withGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;

    // Glow halo (optional, for splash & dark backgrounds)
    if (withGlow) {
      final glowPaint = Paint()
        ..color = accent.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy), r * 0.95, glowPaint);
    }

    // Disk (harvest sun) — gradient for depth
    final diskRect = Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.92);
    final diskPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary,
          Color.lerp(primary, Colors.black, 0.18) ?? primary,
        ],
      ).createShader(diskRect);
    canvas.drawCircle(Offset(cx, cy), r * 0.92, diskPaint);

    // Inner ring highlight (subtle organic depth)
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04;
    canvas.drawCircle(Offset(cx, cy + r * 0.04), r * 0.78, ringPaint);

    // Three palm fronds radiating from heart upward
    _drawFrond(canvas, Offset(cx, cy), r, angleDeg: -90, length: 0.62);
    _drawFrond(canvas, Offset(cx, cy), r, angleDeg: -90 - 38, length: 0.55);
    _drawFrond(canvas, Offset(cx, cy), r, angleDeg: -90 + 38, length: 0.55);

    // Two side fronds (lower, shorter)
    _drawFrond(canvas, Offset(cx, cy), r, angleDeg: -90 - 70, length: 0.42);
    _drawFrond(canvas, Offset(cx, cy), r, angleDeg: -90 + 70, length: 0.42);

    // Heart seed (gold buah)
    final seedPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(accent, Colors.white, 0.35) ?? accent,
          accent,
          Color.lerp(accent, Colors.black, 0.25) ?? accent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.18));
    canvas.drawCircle(Offset(cx, cy), r * 0.16, seedPaint);

    // Seed highlight
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.45);
    canvas.drawCircle(
        Offset(cx - r * 0.05, cy - r * 0.05), r * 0.04, highlightPaint);
  }

  void _drawFrond(
    Canvas canvas,
    Offset center,
    double r, {
    required double angleDeg,
    required double length,
  }) {
    final angle = angleDeg * math.pi / 180;
    final tipX = center.dx + math.cos(angle) * r * length;
    final tipY = center.dy + math.sin(angle) * r * length;

    // Frond is a tapered curved blade
    final path = Path();
    final perp = angle + math.pi / 2;
    final width = r * 0.12;
    final ctrlX = center.dx + math.cos(angle) * r * length * 0.55;
    final ctrlY = center.dy + math.sin(angle) * r * length * 0.55;

    // Left edge
    final lx1 = center.dx + math.cos(perp) * width * 0.25;
    final ly1 = center.dy + math.sin(perp) * width * 0.25;
    final lcx = ctrlX + math.cos(perp) * width;
    final lcy = ctrlY + math.sin(perp) * width;

    // Right edge
    final rx1 = center.dx - math.cos(perp) * width * 0.25;
    final ry1 = center.dy - math.sin(perp) * width * 0.25;
    final rcx = ctrlX - math.cos(perp) * width;
    final rcy = ctrlY - math.sin(perp) * width;

    path.moveTo(lx1, ly1);
    path.quadraticBezierTo(lcx, lcy, tipX, tipY);
    path.quadraticBezierTo(rcx, rcy, rx1, ry1);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(math.cos(angle + math.pi), math.sin(angle + math.pi)),
        end: Alignment(math.cos(angle), math.sin(angle)),
        colors: [
          Color.lerp(primary, Colors.white, 0.55) ?? primary,
          Color.lerp(primary, Colors.white, 0.25) ?? primary,
        ],
      ).createShader(Rect.fromPoints(
          Offset(center.dx - r, center.dy - r),
          Offset(center.dx + r, center.dy + r)));
    canvas.drawPath(path, paint);

    // Center vein (darker line)
    final veinPaint = Paint()
      ..color = primary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, center.dy), Offset(tipX, tipY), veinPaint);
  }

  @override
  bool shouldRepaint(covariant _SawitLogoPainter old) =>
      old.primary != primary || old.accent != accent || old.withGlow != withGlow;
}

/// Compact horizontal logo + wordmark — for AppBar usage.
class SawitWordmark extends StatelessWidget {
  final double height;
  final Color textColor;
  final Color? logoPrimary;

  const SawitWordmark({
    super.key,
    this.height = 28,
    this.textColor = Colors.white,
    this.logoPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SawitLogo(
          size: height,
          primaryColor: logoPrimary ?? Colors.white.withOpacity(0.18),
          accentColor: AppColors.gold,
        ),
        SizedBox(width: height * 0.32),
        Text(
          'SawitKu',
          style: AppTextStyles.hero(height * 0.7, color: textColor),
        ),
      ],
    );
  }
}
