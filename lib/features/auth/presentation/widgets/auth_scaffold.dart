import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/joodcraft_logo.dart';

/// الهيكل البصري الموحّد لشاشات المصادقة.
///
/// * على الشاشات العريضة: لوحة هوية كحلية (يمين) + بطاقة النموذج (يسار).
/// * على الشاشات الضيقة: ترويسة هوية مختصرة أعلى النموذج.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;

  /// محتوى النموذج (الحقول والأزرار).
  final Widget child;

  /// سطر سفلي (رابط الانتقال بين الدخول والتسجيل).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 1000;
          final Widget form = _FormArea(
            title: title,
            subtitle: subtitle,
            footer: footer,
            child: child,
          );

          if (wide) {
            return Row(
              children: <Widget>[
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 7, child: form),
              ],
            );
          }

          return Column(
            children: <Widget>[
              const _BrandHeaderCompact(),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: form,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// لوحة الهوية (الشاشات العريضة).
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const List<String> _features = <String>[
    'معالجة محلية كاملة لملفات Excel — بياناتك لا تغادر جهازك',
    'توليد PDF بخطوط عربية عالية الجودة مع دعم كامل للاتجاه RTL',
    'قوالبك محفوظة في حسابك وجاهزة لإعادة الاستخدام',
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[AppColors.navy, AppColors.navyDeep],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // لمسة زخرفية ذهبية شفافة (لا تؤثر على القراءة).
          Positioned(
            bottom: -90,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // حد ذهبي رقيق يفصل لوحة الهوية عن النموذج.
          const Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: SizedBox(
              width: 1.5,
              child: ColoredBox(color: AppColors.gold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const JoodCraftWordmark(markSize: 56, onDark: true),
                const Spacer(),
                Text(
                  'شهاداتك وعقودك الرسمية…\nبجودة تُطبع بثقة.',
                  style: text.displaySmall?.copyWith(
                    color: AppColors.onNavy,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                Container(
                  width: 64,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.space32),
                for (final String feature in _features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            feature,
                            style: text.bodyLarge?.copyWith(
                              color: AppColors.onNavy.withValues(alpha: 0.82),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  '${AppConstants.appNameAr} • الإصدار ${AppConstants.appVersion}',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.onNavy.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ترويسة هوية مختصرة (الشاشات الضيقة).
class _BrandHeaderCompact extends StatelessWidget {
  const _BrandHeaderCompact();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[AppColors.navy, AppColors.navyDeep],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const JoodCraftWordmark(markSize: 40, onDark: true),
              const SizedBox(height: AppTheme.space12),
              Text(
                AppConstants.appTagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onNavy.withValues(alpha: 0.75),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// منطقة بطاقة النموذج.
class _FormArea extends StatelessWidget {
  const _FormArea({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space24,
            vertical: AppTheme.space32,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                    Text(title, style: text.headlineSmall),
                    const SizedBox(height: AppTheme.space8),
                    Text(subtitle, style: text.bodyMedium),
                    const SizedBox(height: AppTheme.space24),
                    child,
                    if (footer != null) ...<Widget>[
                      const SizedBox(height: AppTheme.space20),
                      const Divider(),
                      const SizedBox(height: AppTheme.space12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
