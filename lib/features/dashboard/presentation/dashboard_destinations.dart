import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/app_l10n.dart';

/// عنصر تنقل واحد في اللوحة الجانبية.
class DashboardDestination {
  const DashboardDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String path;
  final String label;
  final IconData icon;
  final String description;
}

/// عناصر التنقل الرئيسية — مصدر واحد تُبنى منه اللوحة الجانبية والبطاقات.
List<DashboardDestination> dashboardDestinations(BuildContext context) {
  return <DashboardDestination>[
    DashboardDestination(
      path: AppRoutes.dashboard,
      label: context.l10n?.destDashboard ?? 'لوحة التحكم',
      icon: Icons.space_dashboard_rounded,
      description:
          context.l10n?.destDashboardDesc ?? 'نظرة عامة على مشاريعك وقوالبك.',
    ),
    DashboardDestination(
      path: AppRoutes.certificateBuilder,
      label: context.l10n?.destCertificates ?? 'محـرّك الشهادات',
      icon: Icons.workspace_premium_rounded,
      description: context.l10n?.destCertificatesDesc ??
          'تصميم شهادات أفقية (Landscape) من قالب قابل للتعديل.',
    ),
    DashboardDestination(
      path: AppRoutes.contractBuilder,
      label: context.l10n?.destContracts ?? 'محـرّك العقود',
      icon: Icons.article_rounded,
      description: context.l10n?.destContractsDesc ??
          'صياغة عقود رأسية (Portrait) بحقول ديناميكية.',
    ),
    DashboardDestination(
      path: AppRoutes.batchProcessor,
      label: context.l10n?.destBatch ?? 'التوليد الجماعي',
      icon: Icons.table_view_rounded,
      description: context.l10n?.destBatchDesc ??
          'قراءة ملف Excel محلياً وتوليد مئات الشهادات دفعة واحدة.',
    ),
    DashboardDestination(
      path: AppRoutes.templates,
      label: context.l10n?.destTemplates ?? 'مكتبة القوالب',
      icon: Icons.collections_bookmark_rounded,
      description: context.l10n?.destTemplatesDesc ??
          'إدارة قوالبك المحفوظة وتصنيفها وإعادة استخدامها.',
    ),
    DashboardDestination(
      path: AppRoutes.assets,
      label: context.l10n?.destAssets ?? 'الأصول والتوقيعات',
      icon: Icons.folder_special_rounded,
      description: context.l10n?.destAssetsDesc ??
          'الشعار والختم والتوقيع والإطارات الخاصة بك.',
    ),
  ];
}

/// إيجاد العنصر المطابق لمسار حالي.
DashboardDestination destinationForPath(BuildContext context, String path) {
  final List<DashboardDestination> items = dashboardDestinations(context);
  return items.firstWhere(
    (DashboardDestination item) => item.path == path,
    orElse: () => items.first,
  );
}
