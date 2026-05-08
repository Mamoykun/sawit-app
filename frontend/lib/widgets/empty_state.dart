import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable empty state with optional custom illustration.
///
/// Three variants:
///  - [EmptyState.illustrated] — uses [_LeafIllustration] painter (default)
///  - [EmptyState.icon] — simple icon in tinted circle
///  - [EmptyState.custom] — provide your own [icon] widget
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final Widget? illustration;
  final Widget? action;
  final Color accent;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration,
    this.action,
    this.accent = AppColors.primary,
  });

  /// Default leaf-and-seed illustration that matches brand identity.
  factory EmptyState.illustrated({
    Key? key,
    required String title,
    required String message,
    Widget? action,
    Color accent = AppColors.primary,
  }) =>
      EmptyState(
        key: key,
        title: title,
        message: message,
        action: action,
        accent: accent,
        illustration: _LeafIllustration(color: accent),
      );

  /// Compact icon variant (tinted circle).
  ///
  /// Pass [actionLabel] + [onAction] together to render a CTA button.
  /// Alternatively pass a fully custom [action] widget.
  factory EmptyState.icon({
    Key? key,
    required IconData iconData,
    required String title,
    required String message,
    Widget? action,
    String? actionLabel,
    VoidCallback? onAction,
    Color accent = AppColors.primary,
  }) {
    final resolvedAction = action ??
        (actionLabel != null && onAction != null
            ? _ActionButton(label: actionLabel, onTap: onAction, accent: accent)
            : null);
    return EmptyState(
      key: key,
      title: title,
      message: message,
      action: resolvedAction,
      accent: accent,
      illustration: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(iconData, size: 38, color: accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              illustration!,
              const SizedBox(height: Spacing.xl),
            ],
            Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.display(20)),
            const SizedBox(height: Spacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.body(13, color: AppColors.textMuted)),
            if (action != null) ...[
              const SizedBox(height: Spacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal CTA button used by EmptyState.icon when actionLabel+onAction are set.
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accent;
  const _ActionButton({required this.label, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );
}

/// Leaf-and-seed brand illustration. Three stylized fronds + gold seed
/// inside a soft tinted disk. Matches SawitLogo motif at empty-state scale.
class _LeafIllustration extends StatelessWidget {
  final Color color;
  const _LeafIllustration({required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 120,
        height: 120,
        child: CustomPaint(
          painter: _LeafIllustrationPainter(color: color),
        ),
      );
}

class _LeafIllustrationPainter extends CustomPainter {
  final Color color;
  _LeafIllustrationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w / 2;

    // Tinted background disk
    final diskPaint = Paint()..color = color.withOpacity(0.08);
    canvas.drawCircle(Offset(cx, cy), r * 0.95, diskPaint);

    // Inner accent ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.72, ringPaint);

    // Three fronds radiating from center
    _drawFrond(canvas, Offset(cx, cy), r, -90, 0.55);
    _drawFrond(canvas, Offset(cx, cy), r, -90 - 50, 0.48);
    _drawFrond(canvas, Offset(cx, cy), r, -90 + 50, 0.48);

    // Gold seed center
    final seedPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(AppColors.gold, Colors.white, 0.4) ?? AppColors.gold,
          AppColors.gold,
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.18));
    canvas.drawCircle(Offset(cx, cy), r * 0.13, seedPaint);
  }

  void _drawFrond(Canvas canvas, Offset center, double r,
      double angleDeg, double length) {
    final angle = angleDeg * math.pi / 180;
    final tipX = center.dx + math.cos(angle) * r * length;
    final tipY = center.dy + math.sin(angle) * r * length;

    final perp = angle + math.pi / 2;
    final width = r * 0.10;
    final ctrlX = center.dx + math.cos(angle) * r * length * 0.55;
    final ctrlY = center.dy + math.sin(angle) * r * length * 0.55;

    final lx1 = center.dx + math.cos(perp) * width * 0.25;
    final ly1 = center.dy + math.sin(perp) * width * 0.25;
    final lcx = ctrlX + math.cos(perp) * width;
    final lcy = ctrlY + math.sin(perp) * width;

    final rx1 = center.dx - math.cos(perp) * width * 0.25;
    final ry1 = center.dy - math.sin(perp) * width * 0.25;
    final rcx = ctrlX - math.cos(perp) * width;
    final rcy = ctrlY - math.sin(perp) * width;

    final path = Path()
      ..moveTo(lx1, ly1)
      ..quadraticBezierTo(lcx, lcy, tipX, tipY)
      ..quadraticBezierTo(rcx, rcy, rx1, ry1)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.55),
          color.withOpacity(0.85),
        ],
      ).createShader(Rect.fromPoints(center, Offset(tipX, tipY)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeafIllustrationPainter old) =>
      old.color != color;
}
