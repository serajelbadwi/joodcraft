import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/assets/asset_image_cache.dart';
import '../../../../core/assets/asset_image_disk_cache.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/locale/app_locale.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ocr/presentation/screens/ocr_screen.dart';
import '../../../project_hub/presentation/providers/new_document_controller.dart';

/// شريط القوائم العلوي للتطبيق — بطراز برامج سطح المكتب (Photoshop).
///
/// صفٌّ رقيق (**ارتفاعه [height]** فقط) يحمل القوائم الخمس المعتادة:
/// `ملف | تعديل | عرض | أدوات | مساعدة`. غرضه المزدوج:
///
/// 1. **تحرير شريط التنقّل** من أوامر ليست تنقّلاً: «مستند جديد» صار أمراً في
///    قائمة `ملف` (‏`Ctrl+N`)، فبقيت تبويبات المحرّكات للمحرّكات وحدها.
/// 2. **إتاحة أوامر عامّة** بلا مكان واضح في الواجهة: تفريغ الأبعاد الأخيرة
///    وذاكرة الصور، والمظهر واللغة، ومعاينة القوالب النموذجية، وحول البرنامج.
///
/// كل بند هنا **منفَّذ فعلاً** — لا بنود زينة: القوائم تقرأ محرّكات التطبيق
/// ([ThemeController] و[LocaleController] و`AuthProvider`) وتنفّذ أوامر حقيقية.
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({super.key, required this.onNavigate});

  /// الارتفاع الرسمي المضغوط للشريط — فكلفته العمودية شبه معدومة.
  static const double height = 30;

  /// تنقّل داخل هيكل اللوحة (نفس مسار التبويبات، فيبقى الفرع حيّاً).
  final ValueChanged<String> onNavigate;

  /// مفتاح ثابت لقائمة واحدة — مصدر واحد للاختبارات.
  static String menuKey(String id) => 'app-menu-$id';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.brandSurface,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.brandSurfaceSoft)),
        ),
        // قابل للتمرير أفقياً: على النوافذ الضيّقة تنزلق القوائم بدل أن تفيض.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              const SizedBox(width: AppTheme.space6),
              _MenuButton(
                key: const ValueKey<String>('app-menu-file'),
                title: l10n?.menuFile ?? 'ملف',
                entries: _fileEntries,
              ),
              _MenuButton(
                key: const ValueKey<String>('app-menu-edit'),
                title: l10n?.menuEdit ?? 'تعديل',
                entries: _editEntries,
              ),
              _MenuButton(
                key: const ValueKey<String>('app-menu-view'),
                title: l10n?.menuView ?? 'عرض',
                entries: _viewEntries,
              ),
              _MenuButton(
                key: const ValueKey<String>('app-menu-tools'),
                title: l10n?.menuTools ?? 'أدوات',
                entries: _toolsEntries,
              ),
              _MenuButton(
                key: const ValueKey<String>('app-menu-help'),
                title: l10n?.menuHelp ?? 'مساعدة',
                entries: _helpEntries,
              ),
              const SizedBox(width: AppTheme.space6),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //                             محتوى القوائم
  // ==========================================================================

  /// `ملف`: ما يُفتح ويُدار، وفي مقدّمته «مستند جديد…» بـ`Ctrl+N`.
  List<PopupMenuEntry<VoidCallback>> _fileEntries(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    return <PopupMenuEntry<VoidCallback>>[
      _item(
        label: l10n?.menuNewDocument ?? 'مستند جديد…',
        icon: Icons.note_add_outlined,
        shortcut: 'Ctrl+N',
        onSelected: () => onNavigate(AppRoutes.newProject),
      ),
      const PopupMenuDivider(),
      _item(
        label: l10n?.destTemplates ?? 'مكتبة القوالب',
        icon: Icons.collections_bookmark_outlined,
        onSelected: () => onNavigate(AppRoutes.templates),
      ),
      _item(
        label: l10n?.destAssets ?? 'الأصول والتوقيعات',
        icon: Icons.folder_special_outlined,
        onSelected: () => onNavigate(AppRoutes.assets),
      ),
      _item(
        label: l10n?.destBrand ?? 'الهوية والبروفايل',
        icon: Icons.business_outlined,
        onSelected: () => onNavigate(AppRoutes.brand),
      ),
      // «تسجيل الخروج» لا معنى له في تطبيق محلي بلا حساب مربوط — فلا يُعرض
      // إجراء يفشل حتماً. من يربط حساباً لاحقاً يجده هنا كما كان.
      if (context.read<AuthProvider>().isServiceAvailable) ...<PopupMenuEntry<VoidCallback>>[
        const PopupMenuDivider(),
        _item(
          label: l10n?.actionSignOut ?? 'تسجيل الخروج',
          icon: Icons.logout_rounded,
          onSelected: () => unawaited(_signOut(context)),
        ),
      ],
    ];
  }

  /// `تعديل`: أوامر «التفريغ» كما في Photoshop (Purge) — تُفرّغ ما تجمّع في
  /// الجلسة من عناوين وذاكرات، بلا أن تمسّ أي هدف محفوظ.
  List<PopupMenuEntry<VoidCallback>> _editEntries(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    return <PopupMenuEntry<VoidCallback>>[
      _item(
        label: l10n?.menuPurgeRecent ?? 'تفريغ قائمة الأبعاد الأخيرة',
        icon: Icons.history_toggle_off_rounded,
        onSelected: () {
          NewDocumentController.clearRecentSizes();
          context.showSuccess(
            l10n?.menuPurgeRecent ?? 'تفريغ قائمة الأبعاد الأخيرة',
          );
        },
      ),
      _item(
        label: l10n?.menuPurgeImageCache ?? 'تفريغ ذاكرة الصور المؤقتة',
        icon: Icons.cleaning_services_outlined,
        onSelected: () => unawaited(_clearImageCache(context)),
      ),
    ];
  }

  /// `عرض`: المظهر ثم اللغة — كلاهما محرّك حقيقي يُطبَّق فوراً.
  ///
  /// القيم تُقرأ **عند فتح القائمة** لا عند بناء الشريط، فلا يلزم إعادة بناء
  /// شريط القوائم عند تغيير المظهر أو اللغة.
  List<PopupMenuEntry<VoidCallback>> _viewEntries(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    final ThemeController theme = context.read<ThemeController>();
    final LocaleController locale = context.read<LocaleController>();
    String labelOf(ThemeMode mode) => switch (mode) {
          ThemeMode.light => l10n?.themeLight ?? 'فاتح',
          ThemeMode.dark => l10n?.themeDark ?? 'داكن',
          ThemeMode.system => l10n?.themeSystem ?? 'حسب النظام',
        };
    const List<({ThemeMode mode, IconData icon})> themeItems =
        <({ThemeMode mode, IconData icon})>[
      (mode: ThemeMode.light, icon: Icons.light_mode_outlined),
      (mode: ThemeMode.dark, icon: Icons.dark_mode_outlined),
      (mode: ThemeMode.system, icon: Icons.brightness_auto_outlined),
    ];
    return <PopupMenuEntry<VoidCallback>>[
      for (final ({ThemeMode mode, IconData icon}) entry in themeItems)
        _item(
          label: labelOf(entry.mode),
          icon: entry.icon,
          checked: theme.mode == entry.mode,
          onSelected: () => unawaited(theme.setMode(entry.mode)),
        ),
      const PopupMenuDivider(),
      for (final AppLocale entry in supportedAppLocales)
        _item(
          label: entry.nativeName,
          checked: entry.code == locale.appLocale.code,
          onSelected: () => unawaited(locale.setLocale(entry.locale)),
        ),
    ];
  }

  /// `أدوات`: محرّكات العمل ومعايناتها النموذجية.
  List<PopupMenuEntry<VoidCallback>> _toolsEntries(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    return <PopupMenuEntry<VoidCallback>>[
      _item(
        label: l10n?.destBatch ?? 'التوليد الجماعي',
        icon: Icons.table_view_outlined,
        onSelected: () => onNavigate(AppRoutes.batchProcessor),
      ),
      _item(
        // يُفتح كحوار بلا وجهة إدراج — النصّ يُنسخ للحافظة أو يُقبل لاستخدامه.
        label: l10n?.ocrTitle ?? 'استخراج نص من صورة',
        icon: Icons.document_scanner_outlined,
        onSelected: () => unawaited(showOcrScreen(context)),
      ),
      const PopupMenuDivider(),
      _item(
        label: l10n?.menuPreviewCertificate ?? 'معاينة الشهادة النموذجية',
        icon: Icons.workspace_premium_outlined,
        onSelected: () => onNavigate(AppRoutes.certificateSamplePreview),
      ),
      _item(
        label: l10n?.menuPreviewContract ?? 'معاينة العقد النموذجي',
        icon: Icons.article_outlined,
        onSelected: () => onNavigate(AppRoutes.contractSamplePreview),
      ),
    ];
  }

  /// `مساعدة`: تعريف بالبرنامج.
  List<PopupMenuEntry<VoidCallback>> _helpEntries(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    return <PopupMenuEntry<VoidCallback>>[
      _item(
        label: l10n?.menuAbout ?? 'حول JoodCraft',
        icon: Icons.info_outline_rounded,
        onSelected: () => onNavigate(AppRoutes.about),
      ),
    ];
  }

  // ==========================================================================
  //                             أدوات داخلية
  // ==========================================================================

  /// بند قائمة واحد: أيقونة (أو علامة الاختيار) + التسمية + اختصار لوحة المفاتيح.
  PopupMenuItem<VoidCallback> _item({
    required String label,
    required VoidCallback onSelected,
    IconData? icon,
    String? shortcut,
    bool checked = false,
  }) {
    return PopupMenuItem<VoidCallback>(
      value: onSelected,
      height: 36,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            child: checked
                ? const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.gold,
                  )
                : (icon == null
                    ? null
                    : Icon(
                        icon,
                        size: 15,
                        color: AppColors.onNavy.withValues(alpha: 0.72),
                      )),
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.onNavy),
            ),
          ),
          if (shortcut != null) ...<Widget>[
            const SizedBox(width: AppTheme.space16),
            Text(
              shortcut,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.onNavy.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await auth.signOut();
      if (!context.mounted) return;
      context.showSuccess(
        context.l10n?.dashLogoutSuccess ?? 'تم تسجيل الخروج بنجاح.',
      );
    } on Object {
      if (!context.mounted) return;
      context.showError(
        context.l10n?.dashLogoutError ?? 'تعذّر تسجيل الخروج. حاول مرة أخرى.',
      );
    }
  }

  /// يفرّغ ذاكرة الصور المؤقتة والطبقية القرصية — نفس ما تفعله شاشة الأصول.
  Future<void> _clearImageCache(BuildContext context) async {
    final AppLocalizations? l10n = context.l10n;
    await AssetImageDiskCache.instance.clear();
    AssetImageCache.instance.clear();
    if (!context.mounted) return;
    context.showSuccess(l10n?.amCacheCleared ?? 'تم مسح ذاكرة الصور على القرص.');
  }
}

/// زر قائمة واحدة في الشريط: عنوان ظاهر، وقائمة تُبنى عند الفتح.
class _MenuButton extends StatelessWidget {
  const _MenuButton({super.key, required this.title, required this.entries});

  final String title;
  final List<PopupMenuEntry<VoidCallback>> Function(BuildContext context)
      entries;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<VoidCallback>(
      tooltip: '',
      position: PopupMenuPosition.under,
      color: scheme.brandSurfaceDeep,
      elevation: 8,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      onSelected: (VoidCallback action) => action(),
      itemBuilder: entries,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: 6,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            // ارتفاع سطر مثبّت: يضمن أن يبقى الزر داخل ارتفاع الشريط (30px)
            // مهما كانت مقاييس الخط المُختار.
            height: 1.1,
            fontWeight: FontWeight.w500,
            color: AppColors.onNavy.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}
