/// حالات العرض المشتركة للوحة النطاقات: خطأ مع إعادة المحاولة، وقائمة فارغة.
///
/// نسخة مستقلة من حالات لوحة المالك (`owner_admin_states.dart`) — تبويب
/// النطاقات محايد الواجهة (`data/domain_repository.dart`) فلا يستورد من
/// ميزة أخرى.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// رسالة خطأ مع زر إعادة المحاولة — تُستدعى حين يفشل جلب البيانات.
class DomainErrorView extends StatelessWidget {
  const DomainErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة «لا نتائج» — قائمة فارغة أو بحث بلا مطابقة.
class DomainEmptyView extends StatelessWidget {
  const DomainEmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
        ),
      ),
    );
  }
}
