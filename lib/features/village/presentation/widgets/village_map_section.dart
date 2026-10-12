/// قسم «موقع القرية» **القابل للطيّ** — يبدأ مُغلقاً لتبقى الصفحة خفيفة وسريعة.
///
/// زرّ واحد يتبدّل بين الحالتين داخل البطاقة:
/// * مغلقة: زرّ [VillageText.villageMapShow] يفتح الخريطة بانتقال أنيس.
/// * مفتوحة: زرّ [VillageText.villageMapHide] يُغلقها ويعيد الطيّ.
///
/// الإطار (iframe) لا يُبنى إلا عند الفتح — لا يُحمَّل الخريطة قبل الحاجة،
/// وعند الإغلاق يخرج من الشجرة تماماً.
library;

import 'package:flutter/material.dart';

import '../../domain/village_validators.dart';
import '../village_theme.dart';
import 'village_external_link.dart';
import 'village_map_embed.dart';
import 'village_section_card.dart';

/// بطاقة «موقع القرية»: عنوان + زرّ الطيّ + الخريطة عند الفتح.
class VillageMapSection extends StatefulWidget {
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
  State<VillageMapSection> createState() => _VillageMapSectionState();
}

class _VillageMapSectionState extends State<VillageMapSection> {
  /// الخريطة تبدأ **مغلقة** — زرّ «عرض الخريطة» يفتحها عند الحاجة.
  bool _expanded = false;

  /// مدة انتقال الفتح/الغلق.
  static const Duration _toggleDuration = Duration(milliseconds: 280);

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
          // زرّ التبديل: يفتح الخريطة المطويّة ويُغلقها المفتوحة.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey<String>('village-map-toggle'),
              onPressed: _toggle,
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.map_outlined,
                size: 20,
              ),
              label: Text(
                _expanded
                    ? VillageText.villageMapHide
                    : VillageText.villageMapShow,
              ),
            ),
          ),
          // ارتفاع ينمو/يتراجع بسلاسة — والخريطة لا تُبنى إلا وهي مفتوحة.
          // في الحالة المطويّة يبقى فيلّار بنفس مفتاح الخريطة (null ارتفاعاً)
          // فلا يختفي «مرساة» موضع القسم من ترتيب الصفحة.
          AnimatedSize(
            duration: _toggleDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _buildExpandedMap()
                : const SizedBox(
                    key: ValueKey<String>('village-map'),
                    width: double.infinity,
                  ),
          ),
        ],
      ),
    );
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  /// محتوى الحالة المفتوحة: الخريطة + شرحها + زرّ الفتح في خرائط جوجل.
  Widget _buildExpandedMap() {
    return Padding(
      padding: const EdgeInsets.only(top: VillageMetrics.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          VillageMapEmbed(query: widget.query, height: widget.height),
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
                  VillageMapUrls.search(widget.query),
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
