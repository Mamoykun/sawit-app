import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small "?" info icon yang muncul next to istilah agronomi.
/// Tap → bottom sheet dengan penjelasan.
class HelpTooltip extends StatelessWidget {
  final String term;
  final String explanation;
  final double size;

  const HelpTooltip({
    super.key,
    required this.term,
    required this.explanation,
    this.size = 16,
  });

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(term,
                        style:
                            AppTextStyles.display(17, color: AppColors.text)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(explanation,
                  style: AppTextStyles.body(14, color: AppColors.textMid)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showHelp(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.help_outline_rounded,
          size: size,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}
