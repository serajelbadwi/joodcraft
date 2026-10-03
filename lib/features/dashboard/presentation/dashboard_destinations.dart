import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';

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
const List<DashboardDestination> dashboardDestinations = <DashboardDestination>[
  DashboardDestination(
    path: AppRoutes.dashboard,
    label: 'لوحة التحكم',
    icon: Icons.space_dashboard_rounded,
    description: 'نظرة عامة على مشاريعك وقوالبك.',
  ),
  DashboardDestination(
    path: AppRoutes.certificateBuilder,
    label: 'محـرّك الشهادات',
    icon: Icons.workspace_premium_rounded,
    description: 'تصميم شهادات أفقية (Landscape) من قالب قابل للتعديل.',
  ),
  DashboardDestination(
    path: AppRoutes.contractBuilder,
    label: 'محـرّك العقود',
    icon: Icons.article_rounded,
    description: 'صياغة عقود رأسية (Portrait) بحقول ديناميكية.',
  ),
  DashboardDestination(
    path: AppRoutes.batchProcessor,
    label: 'التوليد الجماعي',
    icon: Icons.table_view_rounded,
    description: 'قراءة ملف Excel محلياً وتوليد مئات الشهادات دفعة واحدة.',
  ),
  DashboardDestination(
    path: AppRoutes.templates,
    label: 'مكتبة القوالب',
    icon: Icons.collections_bookmark_rounded,
    description: 'إدارة قوالبك المحفوظة وتصنيفها وإعادة استخدامها.',
  ),
  DashboardDestination(
    path: AppRoutes.assets,
    label: 'الأصول والتوقيعات',
    icon: Icons.folder_special_rounded,
    description: 'الشعار والختم والتوقيع والإطارات الخاصة بك.',
  ),
];

/// إيجاد العنصر المطابق لمسار حالي.
DashboardDestination destinationForPath(String path) {
  return dashboardDestinations.firstWhere(
    (DashboardDestination item) => item.path == path,
    orElse: () => dashboardDestinations.first,
  );
}
