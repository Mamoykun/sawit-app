import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── PENYEBAB ICON RESOLVER ───────────────────────────────────────────────────
/// Maps an iconKey string (eco/water/bug/thermostat/warning) to a Material icon.
IconData penyebabIconData(String iconKey) {
  switch (iconKey) {
    case 'eco':            return Icons.eco_rounded;
    case 'water':          return Icons.water_drop_rounded;
    case 'bug':            return Icons.bug_report_rounded;
    case 'thermostat':     return Icons.wb_sunny_rounded;
    case 'local_fire':     return Icons.local_fire_department_rounded;
    case 'wb_sunny':       return Icons.wb_sunny_rounded;
    case 'warning':        return Icons.warning_amber_rounded;
    default:               return Icons.info_outline_rounded;
  }
}

// ─── SECTION TITLE ────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.display(22)),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(subtitle!, style: AppTextStyles.body(13, color: AppColors.textMuted)),
      ],
      const SizedBox(height: 20),
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
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.radius = 18,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(elevated ? 0.08 : 0.04),
          blurRadius: elevated ? 16 : 8,
          offset: const Offset(0, 2),
        ),
      ],
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: AppTextStyles.mono(20,
                color: color, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        Text(unit, style: AppTextStyles.body(10, color: AppColors.textMuted)),
        const SizedBox(height: 6),
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
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !loading && onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(Radii.md),
          splashColor: Colors.white.withOpacity(0.12),
          highlightColor: Colors.white.withOpacity(0.04),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primary2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isEnabled ? null : AppColors.border,
              borderRadius: BorderRadius.circular(Radii.md),
              boxShadow: isEnabled
                  ? Elevations.primaryGlow(AppColors.primary)
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon,
                              size: 18,
                              color: isEnabled
                                  ? Colors.white
                                  : AppColors.textMuted),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.body(15,
                              color: isEnabled
                                  ? Colors.white
                                  : AppColors.textMuted,
                              weight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SECONDARY BUTTON ─────────────────────────────────────────────────────────
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          splashColor: c.withOpacity(0.08),
          highlightColor: c.withOpacity(0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: c.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: c),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.body(14,
                        color: c, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    this.suffix = '',
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            if (suffix.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  suffix,
                  style: AppTextStyles.body(12,
                      color: highlight ? AppColors.primary3 : AppColors.textMuted,
                      weight: FontWeight.w600),
                ),
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

  Color get _bg => severity == 'high'
      ? AppColors.danger
      : severity == 'medium'
          ? AppColors.warn
          : AppColors.primary3;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(99)),
    child: Text(
      severity == 'high' ? 'TINGGI' : severity == 'medium' ? 'SEDANG' : 'RENDAH',
      style: AppTextStyles.body(10, color: Colors.white, weight: FontWeight.w700),
    ),
  );
}

// ─── MINI PROGRESS BAR ────────────────────────────────────────────────────────
class MiniProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const MiniProgressBar({super.key, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0),
      backgroundColor: AppColors.surfaceAlt,
      valueColor: AlwaysStoppedAnimation(color),
      minHeight: 5,
    ),
  );
}
