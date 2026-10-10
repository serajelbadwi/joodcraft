import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'joodcraft_logo.dart';
import 'language_menu_button.dart';

/// تُعرض فقط حين لا يُعثر على مفاتيح Supabase في **أي** مصدر عند التشغيل:
/// لا في `--dart-define`، ولا في `env.json` على القرص، ولا في الأصل المحزوم.
///
/// البديل الأمثل هنا بدل الانهيار: التطبيق يعمل، والخطوة الناقصة واضحة.
class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

  static const String _setup = 'cp env.example.json env.json\n'
      'flutter run -d windows';

  static const String _override = 'flutter run -d chrome '
      '--dart-define-from-file=env.json';

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.brandSurface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: JoodCraftWordmark(markSize: 44),
                        ),
                        // منتقي اللغة متاح حتى قبل ربط التطبيق — فيمكن للمستخدم
                        // قراءة سبب التهيئة بلغته.
                        const LanguageMenuButton(showLabel: true),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space24),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.key_off_rounded,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            context.l10n?.configMissingKeysTitle ??
                                'لم يُعثر على مفاتيح الاتصال',
                            style: text.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      context.l10n?.configMissingKeysBody ??
                          'يبحث التطبيق تلقائياً وقت التشغيل في ثلاثة مصادر: '
                              'علامة ‎--dart-define‎، ثم ملف env.json على القرص '
                              '(الجذر أو assets/env/)، ثم النسخة المحزومة داخل '
                              'التطبيق — ولم يُعثر على أيٍّ منها. أنشئ الملف '
                              'واملأه مرة واحدة ثم شغّل بلا أي علامة:',
                      style: text.bodyLarge,
                    ),
                    const SizedBox(height: AppTheme.space20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.brandSurfaceDeep,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: SelectableText(
                        _setup,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.7,
                          color: AppColors.onNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      context.l10n?.cfgOverride(_override) ??
                          'بديل لبناء بقيم محددة يتفوق على الملف:\n$_override',
                      style: text.bodySmall,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            context.l10n?.configEnvNote ??
                                'الحزمة تُعلن مجلد assets/env/ كأصل، لذا غياب '
                                    'الملف لا يُسقط البناء من نسخة نظيفة. أنشئه من '
                                    'env.example.json أو شغّل: dart run '
                                    'tool/ensure_env.dart — والمفتاح المطلوب '
                                    'anon/public فقط، وservice_role لا يُستخدم '
                                    'في التطبيق إطلاقاً.',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
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
