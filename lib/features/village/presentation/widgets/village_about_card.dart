/// «كلمة عن القرية» — تعريف موجز بالمبادرة والغرض من السجل.
///
/// البنية: فقرات التعريف ثم ثلاث بطاقات مزايا **قابلة للضغط** تفتح لكلٍّ
/// منها نافذة توضيحية (`_AboutFeatureDialog`) تشرح الميزة بسطور موجزة.
///
/// الشبكة: ثلاثة في صفّ واحد على العرض ≥ 700، اثنان في صفّ على ≥ 460، وواحد
/// في عمود على الأضيق — تُحدّدها [LayoutBuilder] فلا يُكسر التصميم على أي
/// مقاس. المسافة بين البطاقات 16px وداخل كلٍّ منها 20px؛ الحدود ذهبية تزداد
/// حدّة والظلّ يرتفع وسطح الكرت يشتدّ مع أثر المرور (hover)، والعناوين بخط
/// Amiri والنصوص بخط Cairo.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_section_card.dart';

class VillageAboutCard extends StatelessWidget {
  const VillageAboutCard({super.key});

  /// مزايا البطاقات الثلاث — أيقونة وعنوان ونصّ التفاصيل (سطور مفصولة
  /// بفاصلة أسطر تُعرض كنقاط في النافذة).
  static const List<_AboutFeature> _features = <_AboutFeature>[
    _AboutFeature(
      icon: Icons.folder_shared_rounded,
      title: VillageText.aboutCard1Title,
      body: VillageText.aboutCard1Body,
    ),
    _AboutFeature(
      icon: Icons.lock_rounded,
      title: VillageText.aboutCard2Title,
      body: VillageText.aboutCard2Body,
    ),
    _AboutFeature(
      icon: Icons.travel_explore_rounded,
      title: VillageText.aboutCard3Title,
      body: VillageText.aboutCard3Body,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return VillageSectionCard(
      title: VillageText.aboutTitle,
      icon: Icons.groups_rounded,
      accent: VillageColors.tealSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // فقرات التعريف — كل فقرة كتلة مستقلة (تُفصلها سطران فارغان).
          for (final String paragraph in VillageText.aboutParagraph
              .split('\n\n')) ...<Widget>[
            Text(
              paragraph,
              style: text.bodyLarge,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: VillageMetrics.space12),
          ],
          const SizedBox(height: VillageMetrics.space8),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // الشبكة: 3×1 على العريض، 2×1 على المتوسط، 1×N على الضيّق،
              // والمسافة بين البطاقات 16px.
              //
              // ⚠️ لا `stretch` مباشرة: الشاشة داخل تمرير رأسي فارتفاعها
              // غير محدود، ويمتدّ `stretch` هذا القيود غير المحدود إلى
              // البطاقات فينهار التخطيط. `IntrinsicHeight` تحسم الارتفاع
              // من ارتفاعات البطاقات نفسها قبل التمديد.
              final double width = constraints.maxWidth;
              final int columns = width >= 700 ? 3 : (width >= 460 ? 2 : 1);
              const double gap = VillageMetrics.space16;
              final List<Widget> cards = <Widget>[
                for (int i = 0; i < _features.length; i++)
                  _AboutFeatureCard(
                    key: ValueKey<String>('village-about-feature-$i'),
                    feature: _features[i],
                  ),
              ];

              // صفوف متساوية الارتفاع: كل صفّ مجموعة من `columns` بطاقات.
              final List<Widget> rows = <Widget>[];
              for (int start = 0; start < cards.length; start += columns) {
                final int end = start + columns > cards.length
                    ? cards.length
                    : start + columns;
                final List<Widget> rowCards = cards.sublist(start, end);
                rows.add(
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (int i = 0; i < rowCards.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: gap),
                          Expanded(child: rowCards[i]),
                        ],
                      ],
                    ),
                  ),
                );
                if (end < cards.length) rows.add(const SizedBox(height: gap));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ميزة واحدة: أيقونة وعنوان ونصّ تفاصيلها.
class _AboutFeature {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// بطاقة الميزة — قابلة للضغط مع أثر مرور (hover) على الويب والمكتب.
///
/// الحدود والسطح يفتحان عند المرور ليشعر المستخدم بأن البطاقة تفاعلية،
/// والمؤشر يتحوّل إلى سهم يد فوقها.
class _AboutFeatureCard extends StatefulWidget {
  const _AboutFeatureCard({super.key, required this.feature});

  final _AboutFeature feature;

  @override
  State<_AboutFeatureCard> createState() => _AboutFeatureCardState();
}

class _AboutFeatureCardState extends State<_AboutFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(VillageMetrics.radiusMd);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // حاوية متحرّكة: اللون والحدّ والظلّ تتبدّل بانسياب عند المرور.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered
              ? VillageColors.surfaceHigh
              : VillageColors.surfaceHigh.withValues(alpha: 0.55),
          borderRadius: radius,
          border: Border.all(
            color: _hovered ? VillageColors.goldSoft : VillageColors.border,
            width: _hovered ? 1.4 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.34 : 0.16),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 6 : 3),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: () => _showDetails(context),
            child: Padding(
              padding: const EdgeInsets.all(VillageMetrics.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // أيقونة ذهبية داخل مربّع ذهبي شفّاف (يزداد لمعاناً عند المرور).
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: VillageColors.gold.withValues(
                        alpha: _hovered ? 0.20 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        VillageMetrics.radiusSm,
                      ),
                      border: Border.all(
                        color: VillageColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      widget.feature.icon,
                      size: 24,
                      color: VillageColors.goldSoft,
                    ),
                  ),
                  const SizedBox(height: VillageMetrics.space12),
                  Text(
                    widget.feature.title,
                    // العناوين بخط Amiri.
                    style: const TextStyle(
                      fontFamily: AppAssets.amiriFont,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                      color: VillageColors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: VillageMetrics.space8),
                  Text(
                    VillageText.aboutCardHint,
                    // النصّ بخط Cairo.
                    style: TextStyle(
                      fontFamily: AppAssets.cairoFont,
                      fontSize: 13,
                      color: VillageColors.goldSoft,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// نافذة تفاصيل الميزة — كل سطر من [body] يُعرض نقطةً مستقلة.
  void _showDetails(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: VillageColors.surface,
        icon: Icon(
          widget.feature.icon,
          size: 32,
          color: VillageColors.goldSoft,
        ),
        title: Text(
          widget.feature.title,
          textAlign: TextAlign.center,
          style: text.headlineSmall?.copyWith(color: VillageColors.white),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final String line in widget.feature.body.split('\n'))
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: VillageMetrics.space12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                          color: VillageColors.goldSoft,
                        ),
                      ),
                      const SizedBox(width: VillageMetrics.space12),
                      Expanded(
                        child: Text(
                          line,
                          style: text.bodyMedium?.copyWith(
                            color: VillageColors.white,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('village-about-card-close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(VillageText.aboutCardClose),
          ),
        ],
      ),
    );
  }
}
