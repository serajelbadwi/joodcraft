/// حالات العرض المشتركة للوحة المالك: خطأ مع إعادة المحاولة، وقائمة فارغة.
///
/// كل الألوان من `Theme.of(context).colorScheme` — لا ثوابت `AppColors`
/// النهارية — فيتبع التبويبان الوضع الليلي كما بقيّة JoodCraft.
library;

import 'package:flutter/material.dart';

/// رسالة خطأ مع زر إعادة المحاولة — تُستدعى حين يفشل جلب البيانات.
class OwnerAdminErrorView extends StatelessWidget {
  const OwnerAdminErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 40, color: scheme.error),
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
class OwnerAdminEmptyView extends StatelessWidget {
  const OwnerAdminEmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
