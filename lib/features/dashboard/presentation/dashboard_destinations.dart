import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../project_hub/presentation/dialogs/new_document_dialog.dart';

/// عنصر تنقل واحد في اللوحة الجانبية.
class DashboardDestination {
  const DashboardDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.description,
    this.inNavigation = true,
  });

  final String path;
  final String label;
  final IconData icon;
  final String description;

  /// هل يظهر هذا العنصر في **قوائم التنقّل** (تبويبات الشريط العلوي واللوحة
  /// المنسدلة)؟
  ///
  /// «مستند جديد» ليس قسم عمل بل **نافذة عائمة**: يبقى في الفهرس (فتُبقى
  /// فهارس الفروع في الموجّه متطابقة) وفي بطاقات لوحة التحكم، ويخرج من
  /// التنقّل حيث كان يزاحم تبويبات المحرّكات — مدخله الآن أمر «مستند جديد…»
  /// في قائمة `ملف` (أو `Ctrl+N`).
  final bool inNavigation;
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
      path: AppRoutes.newProject,
      label: context.l10n?.destNewProject ?? 'مشروع جديد',
      icon: Icons.add_box_rounded,
      description: context.l10n?.destNewProjectDesc ??
          'اختر مقاساً جاهزاً أو مخصّصاً وابدأ التصميم مباشرةً.',
      // ليست محطة في شريط التنقّل: يُفتح من «‎+ جديد» أو قائمة «ملف».
      inNavigation: false,
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
    // الدعوات الشخصية: رمضان/عيد/زفاف — ملف لكل مدعو باسمه.
    //
    // **محجوبة عن قوائم التنقّل**: صارت جزءاً من شاشة «التوليد الجماعي»
    // الموحّدة (اختيار «نوع القالب ← دعوة»)، فلو بقيت في الشريط لصارت
    // وجهة مكرّرة. المسار وشاشته وفرع الموجّه كما هي — تُفتح من الشاشة
    // الموحّدة أو بالرابط المباشر، فلا يُحذف شيء.
    DashboardDestination(
      path: AppRoutes.invitations,
      label: context.l10n?.invBulkModeTitle ?? 'دعوات شخصية جماعية',
      icon: Icons.redeem_rounded,
      description: context.l10n?.invBulkModeHint ??
          'كارت واحد لكل اسم — تصدير فردي.',
      // ليست محطة في شريط التنقّل: مضمّنة في التوليد الجماعي.
      inNavigation: false,
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
    DashboardDestination(
      path: AppRoutes.brand,
      label: context.l10n?.destBrand ?? 'الهوية والبروفايل',
      icon: Icons.business_rounded,
      description: context.l10n?.destBrandDesc ??
          'شعارك وأختامك وتوقيعاتك وألوان هويتك.',
    ),
    // آخر عنصر مقصوداً: ترتيب هذا الفهرس هو نفسه ترتيب فروع الموجّه، وإضافة
    // قسم جديد في النهاية لا تُزحزح فهارس الأقسام القائمة (فلا يُبنى المحرّر
    // مكان المكتبة مثلاً).
    DashboardDestination(
      path: AppRoutes.admins,
      label: context.l10n?.admTitle ?? 'إدارة المديرين',
      icon: Icons.admin_panel_settings_rounded,
      description: context.l10n?.admListTitle ??
          'حسابات المديرين على هذا الجهاز، ونقلها المشفّر بين الأجهزة، وسجل التصدير.',
    ),
    // «جود كاتب»: مستندات وتقارير نصّية بتدفّق صفحات تلقائي. في النهاية
    // مقصوداً (كالسابق) فلا تُزحزح إضافته فهارس الأقسام القائمة.
    DashboardDestination(
      path: AppRoutes.joodWriter,
      label: context.l10n?.destJoodWriter ?? 'جود كاتب',
      icon: Icons.menu_book_rounded,
      description: context.l10n?.destJoodWriterDesc ??
          'مستندات وتقارير نصّية بصفحات متتالية وتدفّق تلقائي للنص.',
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

/// فهرس الوجهة المطابقة لمسار، أو `-1` إن لم تُطابق أي وجهة معروفة.
int destinationIndexForPath(BuildContext context, String path) =>
    dashboardDestinations(context)
        .indexWhere((DashboardDestination item) => item.path == path);

/// مسارات طبقة عليا تُفتح **فوق** مسار المستخدم الحالي بدل استبداله: خارج
/// هيكل الفروع فلا موضع لها في [dashboardDestinations] ولا في فهرس الفروع.
const Set<String> _overlayRoutes = <String>{
  AppRoutes.about,
  // لوحة تحكم القرى أداة تُفتح فوق ما يعمل عليه المستخدم وتُغلق بالرجوع.
  AppRoutes.villageAdmin,
};

/// ينتقل إلى وجهة داخل هيكل اللوحة **دون إتلاف حالة الأقسام الأخرى**.
///
/// يعتمد [StatefulNavigationShell.goBranch] حين يكون السياق داخل هيكل ذي فروع
/// (‏`StatefulShellRoute.indexedStack`) فيبقى كل قسم حيّاً بعمله وتُرَّجَع كل
/// فرع إلى آخر موضعه فيه — فالتنقّل لا يُسقط محرّراً مفتوحاً ولا جلسة توليد.
/// وإن لم يوجد هيكل (اختبار شاشة منفردة مثلاً) نرجع إلى `context.go` العادي.
void navigateToDestination(BuildContext context, String path) {
  // «مشروع جديد» ليس صفحة: نافذة عائمة تُفتح فوق ما يعمل عليه المستخدم الآن
  // (اللوحة أو المحرّر أو أي وحدة) بدل أن تُستبدل مساحة العمل.
  if (path == AppRoutes.newProject) {
    unawaited(openNewDocumentDialog(context));
    return;
  }

  // المسارات الخارجة عن الهيكل تُدفع لا تُستبدل (انظر [_overlayRoutes]).
  if (_overlayRoutes.contains(path)) {
    unawaited(context.push<void>(path));
    return;
  }

  final int index = destinationIndexForPath(context, path);
  final StatefulNavigationShellState? shell =
      StatefulNavigationShell.maybeOf(context);
  if (index < 0 || shell == null) {
    context.go(path);
    return;
  }
  // `initialLocation: false` مقصود: إعادة الضغط على التبويب النشط يجب ألا
  // تُسقط ما في الفرع من عمل — نستعيد موضعه كما هو.
  shell.goBranch(index, initialLocation: false);
}
