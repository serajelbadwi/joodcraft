import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// أدوات موحّدة لعرض الرسائل للمستخدم (نجاح/خطأ/معلومة).
///
/// الهدف: منع تكرار كود `ScaffoldMessenger` داخل الشاشات، وتوحيد شكل الرسائل.
extension UiFeedback on BuildContext {
  /// رسالة نجاح.
  void showSuccess(String message) => _show(
        message,
        icon: Icons.check_circle_rounded,
        accent: AppColors.success,
      );

  /// رسالة خطأ — تُستخدم عادةً مع `AppException.message`.
  void showError(String message) => _show(
        message,
        icon: Icons.error_rounded,
        accent: AppColors.danger,
      );

  /// رسالة تحذير.
  void showWarning(String message) => _show(
        message,
        icon: Icons.warning_amber_rounded,
        accent: AppColors.gold,
      );

  /// رسالة نجاح مع زر إجراء (مثل «تراجع») يمنح المستخدم نافذة لتصحيح تعديل
  /// غير مقصود. تُمنح مدة أطول حتى يتمكن من اللحاق بالزر.
  void showSuccessAction(
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 7),
  }) =>
      _show(
        message,
        icon: Icons.check_circle_rounded,
        accent: AppColors.success,
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          textColor: AppColors.gold,
          onPressed: onAction,
        ),
      );

  void _show(
    String message, {
    required IconData icon,
    required Color accent,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(this);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy,
          duration: duration,
          action: action,
          content: Row(
            children: <Widget>[
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.onNavy,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
