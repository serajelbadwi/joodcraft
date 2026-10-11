import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/joodcraft_logo.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// شاشة «حول JoodCraft» — تعريف كامل بالمنصة: هويتها، نبذة عنها، مميزاتها،
/// مطوّرها، وروابط التراخيص والملاحظات.
///
/// **لماذا شاشة كاملة بدل حوار؟** حوار `showAboutDialog` القصير كان يعرض الاسم
/// والإصدار فقط؛ وهذه الشاشة تجمع كل ما يحتاجه المستخدم ليثق بالبرنامج
/// (مميزاته، وسياسة الخصوصية العمليّة: لا رفع لأي بيانات) ولمن يريد مراسلة
/// المطوّر — بأقسام واضحة تستفيد من مساحة الشاشة المكتبية.
///
/// كل النصوص المعروضة تأتي من مفاتيح `about*` في ملفات الـ arb، فتعمل بعشر
/// لغات بلا أي نصّ صلب في الكود (ما عدا بيانات المطوّر الثابتة).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// بريد المطوّر لاستقبال الملاحظات — يُنسَخ إلى الحافظة بلا أي إضافة خارجية
  /// (بلا `url_launcher`) ثم تُعرض رسالة تؤكّد النسخ.
  static const String developerEmail = 'serajelroh@gmail.com';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.aboutTitle ?? 'حول JoodCraft')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _heading(context, text),
                const SizedBox(height: AppTheme.space16),
                _section(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: l10n?.aboutSummaryTitle ?? 'نبذة',
                  keyName: 'about-summary',
                  child: Text(
                    l10n?.aboutSummaryBody ??
                        'جودكرافت منصة مكتبية وويب تعمل بالكامل على جهازك: تقرأ '
                            'ملفات Excel، وتولّد شهادات وعقوداً بصيغة PDF بخطوط '
                            'عربية محزومة داخل التطبيق. كل المشاريع والقوالب '
                            'والأصول تُحفظ في قاعدة محلية على الجهاز، ولا يُرفع أي '
                            'ملف إلى أي خادم — فبياناتك تبقى ملكك وحده.',
                    style: text.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                _section(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  title: l10n?.aboutFeaturesTitle ?? 'المميزات الرئيسية',
                  keyName: 'about-features',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final MapEntry<String, String> feature in _features(
                        l10n,
                      ))
                        _featureRow(
                          context,
                          keyName: 'about-feature-${feature.key}',
                          text: feature.value,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                _section(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: l10n?.aboutDeveloperTitle ?? 'المطوّر',
                  keyName: 'about-developer',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _infoRow(
                        context,
                        keyName: 'about-developer-name',
                        icon: Icons.badge_outlined,
                        text: l10n?.aboutDeveloperName ?? 'سراج عبدالله البدوي',
                      ),
                      const SizedBox(height: AppTheme.space8),
                      _infoRow(
                        context,
                        keyName: 'about-developer-email',
                        icon: Icons.mail_outline_rounded,
                        text: l10n?.aboutDeveloperEmail ?? developerEmail,
                        direction: TextDirection.ltr,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      _statusChip(context),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                _section(
                  context,
                  icon: Icons.link_rounded,
                  title: l10n?.aboutLinksTitle ?? 'روابط',
                  keyName: 'about-links',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _linkTile(
                        context,
                        keyName: 'about-licenses',
                        icon: Icons.description_outlined,
                        title: l10n?.aboutLicenses ?? 'عرض التراخيص',
                        onTap: (BuildContext tileContext) => showLicensePage(
                          context: tileContext,
                          applicationName: AppConstants.appName,
                          applicationVersion: AppConstants.appVersion,
                          applicationIcon: const AppIcon(size: 40),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      _linkTile(
                        context,
                        keyName: 'about-feedback',
                        icon: Icons.feedback_outlined,
                        title: l10n?.aboutFeedback ?? 'إرسال ملاحظات',
                        subtitle: l10n?.aboutDeveloperEmail ?? developerEmail,
                        direction: TextDirection.ltr,
                        onTap: _copyEmail,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                _section(
                  context,
                  icon: Icons.favorite_outline_rounded,
                  title: l10n?.aboutCreditsTitle ?? 'شكر وتقدير',
                  keyName: 'about-credits',
                  child: Text(
                    l10n?.aboutCreditsBody ??
                        'بُني هذا التطبيق باستخدام Flutter ومكتبات مفتوحة '
                            'المصدر — شكرٌّ لمجتمع Flutter ولكل من ساهم في تلك '
                            'المكتبات.',
                    style: text.bodyMedium?.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Center(
                  child: Text(
                    l10n?.aboutVersion(AppConstants.appVersion) ??
                        'الإصدار ${AppConstants.appVersion}',
                    key: const ValueKey<String>('about-version'),
                    style: text.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //  الترويسة: الأيقونة + الاسم + الوصف + الإصدار
  // ==========================================================================
  Widget _heading(BuildContext context, TextTheme text) {
    final AppLocalizations? l10n = context.l10n;
    return Column(
      key: const ValueKey<String>('about-heading'),
      children: <Widget>[
        // الشعار الرسمي المحزوم (أيقونة البرنامج) لا الرسم البرمجي: يسقط
        // تلقائياً إلى [AppIcon] المتجهي إن تعذّر قراءة الأصل فلا تفرغ الهوية.
        const JoodCraftLogo(size: 120),
        const SizedBox(height: AppTheme.space12),
        Text(
          AppConstants.appName,
          key: const ValueKey<String>('about-app-name'),
          textDirection: TextDirection.ltr,
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Text(
            l10n?.aboutTagline ?? AppConstants.appTagline,
            key: const ValueKey<String>('about-tagline'),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// نصوص المميزات السبعة (مرتبطة بمفاتيح الـ arb).
  List<MapEntry<String, String>> _features(AppLocalizations? l10n) {
    final String offline =
        l10n?.aboutFeatureOffline ??
        'أوفلاين بالكامل: بلا إنترنت وبلا رفع أي بيانات';
    final String fonts =
        l10n?.aboutFeatureArabicFonts ??
        'خطوط عربية محزومة مع تشكيل واتجاه RTL دقيق';
    final String excel =
        l10n?.aboutFeatureExcel ??
        'قراءة Excel وCSV وربط الأعمدة بحقول القالب تلقائياً';
    final String batch =
        l10n?.aboutFeatureBatch ??
        'توليد مئات الشهادات دفعة واحدة — ملف مجمع أو ملف لكل شخص';
    final String editor =
        l10n?.aboutFeatureVisualEditor ??
        'محرّر بصري بالسحب والإفلات مع تحديد متعدد وتراجع وإعادة';
    final String invitations =
        l10n?.aboutFeatureInvitations ??
        'دعوات جاهزة لرمضان والعيد والزفاف بمقاسات السوشيال والطباعة';
    final String exports =
        l10n?.aboutFeatureExports ??
        'تصدير PDF وPNG ومشاريع جود قابلة للمشاركة';
    return <MapEntry<String, String>>[
      MapEntry<String, String>('offline', offline),
      MapEntry<String, String>('fonts', fonts),
      MapEntry<String, String>('excel', excel),
      MapEntry<String, String>('batch', batch),
      MapEntry<String, String>('editor', editor),
      MapEntry<String, String>('invitations', invitations),
      MapEntry<String, String>('exports', exports),
    ];
  }

  /// سطر ميزة واحدة: علامة صحّة ملوّنة + النص.
  Widget _featureRow(
    BuildContext context, {
    required String keyName,
    required String text,
  }) {
    return Padding(
      key: ValueKey<String>(keyName),
      padding: const EdgeInsets.only(top: AppTheme.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  //  عناصر مشتركة
  // ==========================================================================

  /// قسم داخل بطاقة: عنوان بأيقونة + محتواه.
  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String keyName,
    required Widget child,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey<String>(keyName),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: AppTheme.space8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }

  /// سطر معلومة في قسم المطوّر.
  Widget _infoRow(
    BuildContext context, {
    required String keyName,
    required IconData icon,
    required String text,
    TextDirection? direction,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      key: ValueKey<String>(keyName),
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium,
            textDirection: direction,
          ),
        ),
      ],
    );
  }

  /// شارة حالة المشروع: «مشروع شخصي — تحت التطوير».
  Widget _statusChip(BuildContext context) {
    final AppLocalizations? l10n = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const ValueKey<String>('about-developer-status'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space6,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldSoft,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(
          l10n?.aboutDeveloperStatus ?? 'مشروع شخصي — تحت التطوير',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.goldDeep),
        ),
      ),
    );
  }

  /// صفّ رابط قابل للنقر (تراخيص / ملاحظات).
  ///
  /// [onTap] يستقبل سياق البطاقة نفسه (لا سياق الشاشة) كي يجد
  /// `ScaffoldMessenger` التابع لها ويُظهر التنبيه في المكان الصحيح.
  Widget _linkTile(
    BuildContext context, {
    required String keyName,
    required IconData icon,
    required String title,
    required void Function(BuildContext tileContext) onTap,
    String? subtitle,
    TextDirection? direction,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      key: ValueKey<String>(keyName),
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Builder(
        builder: (BuildContext tileContext) => InkWell(
          onTap: () => onTap(tileContext),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: text.titleSmall),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: AppTheme.space2),
                        Text(
                          subtitle,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textDirection: direction,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  //  الأفعال
  // ==========================================================================

  /// نسخ بريد المطوّر إلى الحافظة (بلا `url_launcher`) مع تأكيد مرئي.
  Future<void> _copyEmail(BuildContext context) async {
    final AppLocalizations? l10n = context.l10n;
    await Clipboard.setData(const ClipboardData(text: developerEmail));
    if (!context.mounted) return;
    context.showSuccess(
      l10n?.aboutFeedbackCopied ??
          'تم نسخ البريد الإلكتروني — أرسل ملاحظاتك في أي وقت',
    );
  }
}
