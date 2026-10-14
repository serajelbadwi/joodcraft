/// شاشة «إدارة المالك» — تبويبان: القرى (إضافة/توليد كود/تعديل/حذف)
/// والتراخيص (إصدار وعرض).
///
/// تُفتح من بوابة [OwnerAdminGateScreen] التي تتحقق من `platform_admins`
/// قبل بنائها؛ فنصوصها عربية أحادية اللغة كبقية أدوات الإدارة.
///
/// **كل الألوان من `Theme.of(context)` لا من ثوابت `AppColors`**: الثوابت
/// النهارية (مثل `AppColors.background` الأبيض و`AppColors.navy`) لا تعرف
/// السطوع، فتُظهر اللوحة بيضاء داخل تطبيق داكن. أما لوحة الألوان
/// (`colorScheme`) فتحمل تبدّلها تلقائياً — راجع `AppTheme`.
library;

import 'package:flutter/material.dart';

import '../../domain/data/domain_repository.dart';
import '../../domain/data/supabase_domain_repository.dart';
import '../../domain/presentation/domains_manager_tab.dart';
import '../data/owner_admin_repository.dart';
import 'owner_licenses_tab.dart';
import 'owner_villages_tab.dart';

class OwnerAdminScreen extends StatelessWidget {
  const OwnerAdminScreen({
    super.key,
    required this.repository,
    this.domainRepository,
  });

  final OwnerAdminRepository repository;

  /// مستودع النطاقات — `null` في التطبيق (يبنى فوق `SupabaseService`)،
  /// وهميّ في الاختبارات.
  final DomainRepository? domainRepository;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // خلفية الهيكل من الثيم: بيضاء نهاراً، وسليت `#3E3E3E` ليلاً.
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('إدارة المالك'),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          bottom: TabBar(
            // الذهبي لون الإبراز الوحيد الدافئ في الوضعين — ثابت هوية لا
            // ثابت لون، فيبقى مؤشّر التبويب ذهبياً في الوضعين.
            indicatorColor: scheme.secondary,
            labelColor: scheme.onSurface,
            unselectedLabelColor: scheme.onSurfaceVariant,
            tabs: const <Widget>[
              Tab(text: 'القرى'),
              Tab(text: 'النطاقات'),
              Tab(text: 'التراخيص'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            OwnerVillagesTab(repository: repository),
            DomainsManagerTab(
              repository: domainRepository ?? const SupabaseDomainRepository(),
            ),
            OwnerLicensesTab(repository: repository),
          ],
        ),
      ),
    );
  }
}
