/// قسم «موقع القرية»: خريطة جوجل **مُضمَّنة** بلا مفتاح API.
///
/// الطريقة: وسم `iframe` على نقطة تضمين جوجل العامة
/// (`...&output=embed`) — تعمل بلا مفتاح ولا فوترة. على الويب يُبنى الإطار
/// الحقيقي عبر `HtmlElementView`، وفي أي بيئة أخرى (اختبارات/سطح مكتب) تُعرض
/// بطاقة بديلة أنيقة فلا تُكسر الشاشة.
///
/// لتبديل الخريطة إلى إحداثيات دقيقة: مرّر `lat,lng` في [query] (مثل
/// `26.8206,30.8025`) — لا تغيير في الكود.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_external_link.dart';
import 'village_map_embed_stub.dart'
    if (dart.library.js_interop) 'village_map_embed_web.dart' as impl;
import 'village_section_card.dart';

/// قسم كامل: بطاقة + خريطة + رابط الفتح في تطبيق الخرائط.
class VillageMapSection extends StatelessWidget {
  const VillageMapSection({
    super.key,
    this.query = VillageText.mapQuery,
    this.height = VillageMetrics.mapHeight,
  });

  /// ما يُبحث عنه في الخريطة (اسم القرية أو إحداثيات).
  final String query;

  /// ارتفاع إطار الخريطة.
  final double height;

  @override
  Widget build(BuildContext context) {
    return VillageSectionCard(
      title: VillageText.mapTitle,
      icon: Icons.map_rounded,
      accent: VillageColors.tealSoft,
      subtitle: VillageText.villageRegion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          VillageMapEmbed(query: query, height: height),
          const SizedBox(height: VillageMetrics.space12),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  VillageText.mapCaption,
                  style: TextStyle(
                    fontSize: 13,
                    color: VillageColors.muted,
                    height: 1.7,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => VillageExternalLink.open(
                  VillageMapUrls.search(query),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('افتح في الخرائط'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// إطار الخريطة نفسه — ملفوف بحواف مستديرة وحائط داكن.
class VillageMapEmbed extends StatelessWidget {
  const VillageMapEmbed({
    super.key,
    required this.query,
    this.height = VillageMetrics.mapHeight,
  });

  final String query;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('village-map'),
      height: height,
      decoration: BoxDecoration(
        color: VillageColors.surfaceHigh,
        borderRadius: BorderRadius.circular(VillageMetrics.radiusMd),
        border: Border.all(color: VillageColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: impl.buildMapEmbed(
        iframeUrl: VillageMapUrls.embed(query),
        query: query,
        height: height,
      ),
    );
  }
}

/// روابط الخرائط — مصدر واحد للصيغتين (تضمين/بحث).
abstract final class VillageMapUrls {
  const VillageMapUrls._();

  /// رابط التضمين بلا مفتاح API (يفتح في إطار داخل الصفحة).
  static String embed(String query) =>
      'https://www.google.com/maps?q=${Uri.encodeComponent(query)}'
      '&hl=ar&z=14&output=embed';

  /// رابط الفتح في تطبيق/موقع الخرائط.
  static String search(String query) =>
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(query)}';
}
