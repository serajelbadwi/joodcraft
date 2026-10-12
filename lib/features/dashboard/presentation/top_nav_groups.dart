import 'package:flutter/material.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/app_l10n.dart';

/// بند داخل قائمة منسدلة من الشريط العلوي.
class TopNavMenuEntry {
  const TopNavMenuEntry({
    required this.path,
    required this.label,
    required this.icon,
  });

  /// مسار الوجهة — نفس قيم [AppRoutes] المدمجة في `dashboardDestinations`.
  final String path;

  final String label;
  final IconData icon;
}

/// مجموعة تنقّل واحدة في الشريط العلوي المُعاد تنظيمه.
///
/// عرض الشريط السابق كان يمرّر **كل وجهة على حدة** (١١ تبويباً)، فصار مزدحماً.
/// هنا تُجمَّع الوجهات في خمس مجموعات تنقّل + عنصر الحساب:
///
/// | المجموعة   | النوع  | البنود                                        |
/// |-------------|--------|-----------------------------------------------|
/// | لوحة التحكم | مباشر  | `/dashboard`                                  |
/// | المحرّكات   | منسدلة | الشهادات · العقود · جود كاتب · محرك الدعوات      |
/// | التوليد الجماعي | مباشر | `/batch-processor` (يشمل الدعوات)          |
/// | المكتبات    | منسدلة | القوالب · الأصول · الهوية                     |
/// | الإدارة     | منسدلة | إدارة المديرين                                |
/// | الحساب      | منسدلة | (يُبنى في الشريط نفسه — بروفايل/خروج)        |
///
/// **لا يمسّ هذا الملف ترتيب `dashboardDestinations`:** فهرس تلك القائمة هو
/// نفسه فهرس فروع `StatefulShellRoute`، وحذف بند منها يزحزح فهارس الأقسام.
/// كل مجموعات هنا تشير إلى المسارات نفسها — الإخفاء تمثيلي فقط.
class TopNavGroup {
  const TopNavGroup({
    required this.id,
    required this.label,
    required this.icon,
    this.path,
    this.entries = const <TopNavMenuEntry>[],
  });

  /// معرّف ثابت يستعمل مفتاحاً للـwidget وللاختبارات.
  final String id;

  final String label;
  final IconData icon;

  /// مسار مباشر حين لا تكون مجموعة [entries]؛ وإلا `null`.
  final String? path;

  /// بنود القائمة المنسدلة — فارغة للمباشر.
  final List<TopNavMenuEntry> entries;

  /// هل هذه مجموعة قائمة منسدلة (لا مسار مباشر)؟
  bool get hasMenu => entries.isNotEmpty;

  /// هل يقع المسار النشط داخل هذه المجموعة؟
  ///
  /// يُبرِز التبويب أيضاً حين يكون المستخدم في أحد أبنائها (فلا يبدو التبويب
  /// مطفأً وهو المفتوح فعلاً).
  bool containsPath(String currentPath) =>
      path == currentPath ||
      entries.any((TopNavMenuEntry e) => e.path == currentPath);
}

/// الخمس مجموعات الرئيسية — مصدر واحد يُبنى منه الشريط العلوي.
///
/// عنصر الحساب **ليس هنا**: يُبنى في الشريط نفسه (صورة رمزية + قائمة
/// بروفايل/خروج) لأنه لا يرتبط بمسار.
List<TopNavGroup> topNavGroups(BuildContext context) => <TopNavGroup>[
      // 1) لوحة التحكم — مباشر بلا قائمة.
      TopNavGroup(
        id: 'dashboard',
        label: context.l10n?.destDashboard ?? 'لوحة التحكم',
        icon: Icons.space_dashboard_rounded,
        path: AppRoutes.dashboard,
      ),
      // 2) المحرّكات — الشهادات والعقود وجود كاتب.
      TopNavGroup(
        id: 'editors',
        label: context.l10n?.navEditors ?? 'المحرّكات',
        icon: Icons.edit_note_rounded,
        entries: <TopNavMenuEntry>[
          TopNavMenuEntry(
            path: AppRoutes.certificateBuilder,
            label: context.l10n?.destCertificates ?? 'محـرّك الشهادات',
            icon: Icons.workspace_premium_rounded,
          ),
          TopNavMenuEntry(
            path: AppRoutes.contractBuilder,
            label: context.l10n?.destContracts ?? 'محـرّك العقود',
            icon: Icons.article_rounded,
          ),
          TopNavMenuEntry(
            path: AppRoutes.joodWriter,
            label: context.l10n?.destJoodWriter ?? 'جود كاتب',
            icon: Icons.menu_book_rounded,
          ),
          // محرك الدعوات الشخصية: رمضان/عيد/زفاف فئاتٌ **داخلية** للصفحة —
          // لا بنوداً في القائمة المنسدلة (اسم فقط بلا وصف).
          TopNavMenuEntry(
            path: AppRoutes.invitations,
            label: context.l10n?.navInvitationsEngine ?? 'محرك الدعوات',
            icon: Icons.redeem_rounded,
          ),
        ],
      ),
      // 3) التوليد الجماعي — محرك واحد يضمّ الدعوات الشخصية أيضاً.
      TopNavGroup(
        id: 'bulk',
        label: context.l10n?.destBatch ?? 'التوليد الجماعي',
        icon: Icons.table_view_rounded,
        path: AppRoutes.batchProcessor,
      ),
      // 4) المكتبات — القوالب والأصول والهوية.
      TopNavGroup(
        id: 'libraries',
        label: context.l10n?.navLibraries ?? 'المكتبات',
        icon: Icons.collections_bookmark_rounded,
        entries: <TopNavMenuEntry>[
          TopNavMenuEntry(
            path: AppRoutes.templates,
            label: context.l10n?.destTemplates ?? 'مكتبة القوالب',
            icon: Icons.collections_bookmark_rounded,
          ),
          // قوالب الدعوات: يفتح المكتبة مباشرةً على قسم الدعوات (وسم
          // `?section=invitations`) — مسار مميّز عن «مكتبة القوالب» فلا
          // يتشابه قيم عناصر القائمة المنسدلة.
          TopNavMenuEntry(
            path: '${AppRoutes.templates}?section=invitations',
            label: context.l10n?.navInvitationTemplates ?? 'قوالب الدعوات',
            icon: Icons.redeem_rounded,
          ),
          TopNavMenuEntry(
            path: AppRoutes.assets,
            label: context.l10n?.destAssets ?? 'الأصول والتوقيعات',
            icon: Icons.folder_special_rounded,
          ),
          TopNavMenuEntry(
            path: AppRoutes.brand,
            label: context.l10n?.destBrand ?? 'الهوية والبروفايل',
            icon: Icons.business_rounded,
          ),
        ],
      ),
      // 5) الإدارة — إدارة المديرين المحليين + لوحة تحكم القرى.
      TopNavGroup(
        id: 'admin',
        label: context.l10n?.navAdmin ?? 'الإدارة',
        icon: Icons.admin_panel_settings_rounded,
        entries: <TopNavMenuEntry>[
          TopNavMenuEntry(
            path: AppRoutes.admins,
            label: context.l10n?.admTitle ?? 'إدارة المديرين',
            icon: Icons.people_rounded,
          ),
          // نصّ عربي ثابت كالنصّ في `VillageAdminText` — اللوحة أداة أحادية
          // اللغة لصاحب المكتب خارج دورة الترجمة العشر لغات.
          TopNavMenuEntry(
            path: AppRoutes.villageAdmin,
            label: 'لوحة تحكم القرى',
            icon: Icons.villa_rounded,
          ),
        ],
      ),
      // 6) تطبيق فرح — مباشر بلا قائمة (نصوصه عربية أحادية اللغة، فلا
      // مفتاح ترجمة له؛ يُضاف هنا في النهاية كي لا يزحزح أي فهرس).
      TopNavGroup(
        id: 'farah',
        label: 'تطبيق فرح',
        icon: Icons.celebration_rounded,
        path: AppRoutes.farah,
      ),
    ];
