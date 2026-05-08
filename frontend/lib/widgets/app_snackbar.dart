import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SnackbarType { success, error, info }

class AppSnackbar {
  /// Show a styled snackbar. Use BuildContext from State or anywhere with Scaffold.
  ///
  /// Usage:
  /// ```dart
  /// AppSnackbar.show(context, 'Data tersimpan', type: SnackbarType.success);
  /// ```
  static void show(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final cfg = _config(type);

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(cfg.icon, color: cfg.iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: AppTextStyles.body(14,
                    color: Colors.white, weight: FontWeight.w600)),
          ),
        ],
      ),
      backgroundColor: cfg.bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: duration,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    ));
  }

  /// Convenience: show success with checkmark icon.
  static void success(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: SnackbarType.success, duration: duration);
  }

  /// Convenience: show error with X icon.
  static void error(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4)}) {
    show(context, message, type: SnackbarType.error, duration: duration);
  }

  /// Convenience: show info with info icon.
  static void info(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: SnackbarType.info, duration: duration);
  }

  static _SnackbarConfig _config(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarConfig(
          bg: AppColors.primary,
          icon: Icons.check_circle_rounded,
          iconColor: Colors.white,
        );
      case SnackbarType.error:
        return _SnackbarConfig(
          bg: AppColors.danger,
          icon: Icons.error_outline_rounded,
          iconColor: Colors.white,
        );
      case SnackbarType.info:
        return _SnackbarConfig(
          bg: AppColors.textMid,
          icon: Icons.info_outline_rounded,
          iconColor: Colors.white,
        );
    }
  }
}

class _SnackbarConfig {
  final Color bg;
  final IconData icon;
  final Color iconColor;
  const _SnackbarConfig({
    required this.bg,
    required this.icon,
    required this.iconColor,
  });
}
