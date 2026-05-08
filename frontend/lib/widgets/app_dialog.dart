import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDialog {
  /// Standard confirmation dialog with Cancel + Confirm buttons.
  /// Returns true if user confirmed.
  ///
  /// [destructive] = true makes confirm button red (for delete actions).
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: destructive ? AppColors.danger : AppColors.primary,
                  size: 24),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(title,
                  style: AppTextStyles.display(17, color: AppColors.text)),
            ),
          ],
        ),
        content: Text(message,
            style: AppTextStyles.body(14, color: AppColors.textMid)),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel,
                style: AppTextStyles.body(14,
                    color: AppColors.textMuted, weight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor:
                  destructive ? AppColors.danger : AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmLabel,
                style: AppTextStyles.body(14,
                    color: Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
