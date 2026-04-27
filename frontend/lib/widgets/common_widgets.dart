import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── SECTION TITLE ────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.display(24)),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: AppTextStyles.body(13, color: AppColors.textMuted)),
      ],
      const SizedBox(height: 24),
    ],
  );
}

// ─── APP CARD ─────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.border),
    ),
    child: child,
  );
}

// ─── METRIC CARD ──────────────────────────────────────────────────────────────
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
    radius: 14,
    child: Column(
      children: [
        Text(value, style: AppTextStyles.display(17, color: color)),
        const SizedBox(height: 2),
        Text(unit, style: AppTextStyles.body(10, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(label.toUpperCase(), style: AppTextStyles.label()),
      ],
    ),
  );
}

// ─── PRIMARY BUTTON ───────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.border,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: AppTextStyles.body(16, color: Colors.white, weight: FontWeight.w700)),
    ),
  );
}

// ─── INPUT FIELD ──────────────────────────────────────────────────────────────
class AppInputField extends StatelessWidget {
  final String label;
  final String hint;
  final String suffix;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool highlight;

  const AppInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.controller,
    this.keyboardType,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: AppTextStyles.label()),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryTint : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? AppColors.primary3 : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType ?? TextInputType.number,
                style: AppTextStyles.body(15, weight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.body(15, color: AppColors.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(suffix, style: AppTextStyles.body(13, color: highlight ? AppColors.primary3 : AppColors.textMuted, weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final String severity; // 'high' | 'medium' | 'low'

  const StatusBadge({super.key, required this.label, required this.severity});

  Color get color => severity == 'high'
      ? AppColors.danger
      : severity == 'medium'
          ? AppColors.warn
          : AppColors.primary3;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
    child: Text(
      severity == 'high' ? 'TINGGI' : severity == 'medium' ? 'SEDANG' : 'RENDAH',
      style: AppTextStyles.body(10, color: Colors.white, weight: FontWeight.w700),
    ),
  );
}

// ─── MINI PROGRESS BAR ────────────────────────────────────────────────────────
class MiniProgressBar extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final Color color;

  const MiniProgressBar({super.key, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      backgroundColor: AppColors.surfaceAlt,
      valueColor: AlwaysStoppedAnimation(color),
      minHeight: 6,
    ),
  );
}
