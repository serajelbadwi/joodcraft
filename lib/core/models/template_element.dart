import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import '../pdf/pdf_font_catalog.dart';
import 'decoration.dart';
import 'text_styling.dart';

/// محاذاة النص الأفقية — `start`/`end` تُحسبان حسب اتجاه النص.
enum ElementTextAlign {
  start('start'),
  center('center'),
  end('end'),
  justify('justify');

  const ElementTextAlign(this.jsonValue);

  final String jsonValue;

  static ElementTextAlign fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'center' || 'centre' || 'middle' => ElementTextAlign.center,
      'end' || 'right' || 'left' => _mapEdge(needle),
      'justify' => ElementTextAlign.justify,
      _ => ElementTextAlign.start,
    };
  }

  static ElementTextAlign _mapEdge(String needle) => needle == 'right'
      ? ElementTextAlign.end
      : needle == 'left'
          ? ElementTextAlign.start
          : ElementTextAlign.end;
}

/// المحاذاة الرأسية داخل صندوق العنصر.
enum ElementVerticalAlign {
  top('top'),
  middle('middle'),
  bottom('bottom');

  const ElementVerticalAlign(this.jsonValue);

  final String jsonValue;

  static ElementVerticalAlign fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'middle' || 'center' || 'centre' => ElementVerticalAlign.middle,
      'bottom' || 'end' => ElementVerticalAlign.bottom,
      _ => ElementVerticalAlign.top,
    };
  }
}

/// طريقة تنفيذ «ضبط» (Justify):
///
/// * [spaces] — توزيع الفراغ الإضافي بين الكلمات (الطريقة الافتراضية).
/// * [kashida] — تطويل الحروف بالكشيدة ( ARABIC TATWEEL U+0640) في مواضع
///   الوصل الصحيحة، فلا تتشتّت الفراغات بين الكلمات (أسلوب الطباعة العربية).
enum JustifyMode {
  spaces('spaces'),
  kashida('kashida');

  const JustifyMode(this.jsonValue);

  final String jsonValue;

  static JustifyMode fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'kashida' || 'tatweel' || 'stretch' => JustifyMode.kashida,
      _ => JustifyMode.spaces,
    };
  }
}

/// اتجاه النص: عربي (rtl) أو لاتيني (ltr) أو تلقائي حسب المحتوى.
enum ElementDirection {
  rtl('rtl'),
  ltr('ltr'),
  auto('auto');

  const ElementDirection(this.jsonValue);

  final String jsonValue;

  bool get isRightToLeft => this != ElementDirection.ltr;

  static ElementDirection fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'ltr' || 'left' => ElementDirection.ltr,
      'auto' => ElementDirection.auto,
      _ => ElementDirection.rtl,
    };
  }
}

/// صندوق العنصر بإحداثيات مساحة التصميم (وليست نقاط الطباعة).
class ElementBox {
  const ElementBox({
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });

  final double x;
  final double y;

  /// عرض الصندوق؛ القيمة `0` تعني "يمتد حتى نهاية المساحة المتاحة".
  final double width;

  /// ارتفاع الصندوق؛ القيمة `0` تعني "يُحسب من المحتوى".
  final double height;

  factory ElementBox.fromJson(Map<String, dynamic> json) {
    double read(List<String> keys) {
      for (final String key in keys) {
        final Object? value = json[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final double? parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    return ElementBox(
      x: read(<String>['x']),
      y: read(<String>['y']),
      width: read(<String>['w', 'width']),
      height: read(<String>['h', 'height']),
    );
  }

  ElementBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return ElementBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// إزاحة الصندوق (السحب).
  ElementBox translated({double dx = 0, double dy = 0}) =>
      copyWith(x: x + dx, y: y + dy);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'x': x,
        'y': y,
        if (width != 0) 'w': width,
        if (height != 0) 'h': height,
      };
}

/// حالة الطبقات المشتركة لكل عنصر: الظهور/القفل/المجموعة المنطقية.
///
/// تُخزَّن في الخريطة `layers` على مستوى المستند (لا داخل كل عنصر) فتكون
/// نقطة الحقيقة واحدة يقرأها المحرّر ومحرّك الطباعة ولوحة الطبقات، ولا ينتفخ
/// JSON كل عنصر بحقول متكرّرة.
@immutable
class ElementLayerState {
  const ElementLayerState({
    this.hidden = false,
    this.locked = false,
    this.groupId,
  });

  /// مخفيّ: لا يُرسم في اللوحة ولا في الـ PDF.
  final bool hidden;

  /// مقفل: يُرسم ويُطبع لكن لا يُحدَّد ولا يُحرَّك من اللوحة.
  final bool locked;

  /// معرّف المجموعة المنطقية — `null` يعني عنصراً مستقلاً.
  final String? groupId;

  bool get isInteractive => !hidden && !locked;

  ElementLayerState copyWith({
    bool? hidden,
    bool? locked,
    Object? groupId = _unset,
  }) =>
      ElementLayerState(
        hidden: hidden ?? this.hidden,
        locked: locked ?? this.locked,
        groupId: groupId == _unset ? this.groupId : groupId as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (hidden) 'hidden': true,
        if (locked) 'locked': true,
        if (groupId != null) 'group': groupId,
      };

  static ElementLayerState fromJson(Object? raw) {
    if (raw is! Map) return const ElementLayerState();
    final Object? group = raw['group'] ?? raw['groupId'] ?? raw['group_id'];
    final String clean = '${group ?? ''}'.trim();
    return ElementLayerState(
      hidden: raw['hidden'] == true || raw['visible'] == false,
      locked: raw['locked'] == true,
      groupId: clean.isEmpty ? null : clean,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ElementLayerState &&
      other.hidden == hidden &&
      other.locked == locked &&
      other.groupId == groupId;

  @override
  int get hashCode => Object.hash(hidden, locked, groupId);
}

/// العنصر الأساسي في القالب (نص، شكل، صورة، ختم، رمز QR).
///
/// كل عنصر يملك `box` (الموضع والحجم بوحدات مساحة التصميم) و`rotation`
/// (الدوران حول المركز بالدرجات). محرر القوالب يعتمد على [withBox] و
/// [withRotation] للتحريك والتحجيم والتدوير دون معرفة النوع الفرعي.
sealed class TemplateElement {
  const TemplateElement({
    required this.id,
    required this.box,
    this.rotation = 0,
  });

  final String id;
  final ElementBox box;

  /// دوران العنصر حول مركزه بالدرجات (0 = بلا دوران).
  final double rotation;

  /// هل العنصر مُدوَّر؟
  bool get hasRotation => rotation != 0;

  /// قراءة الدوران من JSON — مشتركة بين جميع أنواع العناصر.
  static double readRotation(Map<String, dynamic> json) {
    final Object? value = json['rotation'] ?? json['rotate'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// كتابة الدوران في JSON — مشتركة بين جميع أنواع العناصر.
  static void writeRotation(Map<String, dynamic> json, double rotation) {
    if (rotation != 0) json['rotation'] = rotation;
  }

  /// معرّف مجموعة منطقية جديدة (`logical group`) — طابع زمني فريد.
  static String newGroupId() =>
      'group_${DateTime.now().microsecondsSinceEpoch}';

  /// نسخة من العنصر بالصندوق نفسه والخصائص نفسها عدا الصندوق.
  TemplateElement withBox(ElementBox box);

  /// نسخة من العنصر نفسه عدا الدوران.
  TemplateElement withRotation(double rotation);

  /// نسخة مُزاحة (السحب بالماوس/اللمس).
  TemplateElement moved({double dx = 0, double dy = 0}) =>
      withBox(box.translated(dx: dx, dy: dy));

  /// نسخة بأبعاد/موضع جديدة (مقابس التحجيم).
  TemplateElement resized({
    double? x,
    double? y,
    double? width,
    double? height,
  }) =>
      withBox(box.copyWith(x: x, y: y, width: width, height: height));

  /// نسخة **معاد تخطيطها** عند تغيير أبعاد الصفحة (تبديل الاتجاه أو مقاس الورق).
  ///
  /// التحويل محوري مستقلّ: [sx] للعرض و[sy] للارتفاع، فتمتلئ أبعاد الصفحة
  /// الجديدة بالكامل بلا فراغات جانبية. أمّا الأدوات المرتبطة بالحجم (حجم الخط،
  /// سماكة الحدود، نصف القطر، الظل، الخطوط المتقطّعة) فتقاس بـ[fontScale] — وهو
  /// **المتوسط الهندسي** لـ`sx·sy`: فيبقى مقاس النص شبه ثابت عند تبديل الاتجاه
  /// (تحويل يحفظ المساحة)، ويتحجّم بنسبة موحّدة عند تغيير مقاس الورق (A4→A5).
  /// الشكل المركّب يُعاد تخطيط أجزائه تبعاً.
  TemplateElement reflow({
    required double sx,
    required double sy,
    required double fontScale,
  }) {
    final ElementBox scaled = box.copyWith(
      x: box.x * sx,
      y: box.y * sy,
      width: box.width > 0 ? box.width * sx : box.width,
      height: box.height > 0 ? box.height * sy : box.height,
    );
    return switch (this) {
      final TextElement e => e.copyWith(
          box: scaled,
          fontSize: (e.fontSize * fontScale).clamp(1, 400).toDouble(),
          // أحجام النطاقات تتقاس بنفس معامل الحجم الأساسي، فيبقى التنسيق
          // الجزئي متّسقاً مع الفقرة بعد تبديل مقاس الورق.
          spans: <StyledTextSpan>[
            for (final StyledTextSpan span in e.spans) span.scaled(fontScale),
          ],
        ),
      final ShapeElement e => e.copyWith(
          box: scaled,
          strokeWidth: e.strokeWidth * fontScale,
          radius: e.radius * fontScale,
          cornerRadii: e.cornerRadii == null
              ? null
              : <double>[
                  for (final double r in e.cornerRadii!) r * fontScale,
                ],
          dashPattern: e.dashPattern == null
              ? null
              : <double>[
                  for (final double d in e.dashPattern!) d * fontScale,
                ],
          shadow: e.shadow?.copyWith(
            blurRadius: e.shadow!.blurRadius * fontScale,
            spread: e.shadow!.spread * fontScale,
            offsetX: e.shadow!.offsetX * sx,
            offsetY: e.shadow!.offsetY * sy,
          ),
          outerGlow: e.outerGlow?.copyWith(
            radius: e.outerGlow!.radius * fontScale,
            spread: e.outerGlow!.spread * fontScale,
          ),
          innerGlow: e.innerGlow?.copyWith(
            radius: e.innerGlow!.radius * fontScale,
            spread: e.innerGlow!.spread * fontScale,
          ),
          booleanParts: e.isCompound
              ? <ShapeElement>[
                  for (final ShapeElement part in e.booleanParts)
                    part.reflow(sx: sx, sy: sy, fontScale: fontScale)
                        as ShapeElement,
                ]
              : e.booleanParts,
        ),
      final SignatureElement e => e.copyWith(
          box: scaled,
          roleFontSize: (e.roleFontSize * fontScale).clamp(1, 400).toDouble(),
          nameFontSize: (e.nameFontSize * fontScale).clamp(1, 400).toDouble(),
          spacing: e.spacing * sx,
        ),
      final SealElement e => e.copyWith(box: scaled),
      final DecorationElement e => e.copyWith(box: scaled),
      final ImageElement e => e.copyWith(
          box: scaled,
          shadow: e.shadow?.copyWith(
            blurRadius: e.shadow!.blurRadius * fontScale,
            spread: e.shadow!.spread * fontScale,
            offsetX: e.shadow!.offsetX * sx,
            offsetY: e.shadow!.offsetY * sy,
          ),
          outerGlow: e.outerGlow?.copyWith(
            radius: e.outerGlow!.radius * fontScale,
            spread: e.outerGlow!.spread * fontScale,
          ),
        ),
      final QrElement e => e.copyWith(box: scaled),
      final UnknownElement e => e.withBox(scaled),
    };
  }

  /// بناء العنصر من JSON مع دعم **التوافق الأمامي**: أي نوع غير معروف
  /// يُحفظ كما هو في [UnknownElement] بدل أن يُسقِط القالب كله.
  factory TemplateElement.fromJson(Map<String, dynamic> json, int index) {
    final String id = (json['id'] as String?)?.trim().isNotEmpty ?? false
        ? (json['id'] as String).trim()
        : 'element_$index';
    final String type =
        '${json['type'] ?? json['kind'] ?? 'unknown'}'.trim().toLowerCase();

    return switch (type) {
      'text' || 'field' || 'label' => TextElement.fromJson(json, id),
      'rect' || 'rectangle' || 'box' =>
        ShapeElement.fromJson(json, id, ShapeKind.rect),
      'ellipse' || 'circle' => ShapeElement.fromJson(json, id, ShapeKind.ellipse),
      'star' => ShapeElement.fromJson(json, id, ShapeKind.star),
      'polygon' || 'triangle' => ShapeElement.fromJson(json, id, ShapeKind.polygon),
      'line' || 'divider' => ShapeElement.fromJson(json, id, ShapeKind.line),
      'seal' || 'stamp' => SealElement.fromJson(json, id),
      'decoration' || 'decor' || 'ornament' =>
        DecorationElement.fromJson(json, id),
      'signature' || 'signatures' || 'signature_block' || 'signatures_block' =>
        SignatureElement.fromJson(json, id),
      'image' || 'picture' || 'logo' => ImageElement.fromJson(json, id),
      'qr' || 'qrcode' => QrElement.fromJson(json, id),
      _ => UnknownElement(
          id: id,
          box: ElementBox.fromJson(json),
          rotation: TemplateElement.readRotation(json),
          raw: json,
        ),
    };
  }

  Map<String, dynamic> toJson();
}

// ===========================================================================
//  النص
// ===========================================================================
final class TextElement extends TemplateElement {
  const TextElement({
    required super.id,
    required super.box,
    required this.text,
    super.rotation,
    this.family = PdfFontFamily.plex,
    this.customFont,
    this.weight = PdfFontWeight.regular,
    this.fontSize = 16,
    this.colorHex = '#1B2539',
    this.backgroundHex,
    this.align = ElementTextAlign.start,
    this.verticalAlign = ElementVerticalAlign.top,
    this.direction = ElementDirection.rtl,
    this.justifyMode = JustifyMode.spaces,
    this.lineHeight = 1.4,
    this.letterSpacing = 0,
    this.maxLines,
    this.opacity = 1,
    this.shadow,
    this.outerGlow,
    this.innerGlow,
    this.spans = const <StyledTextSpan>[],
  });

  /// النص؛ يقبل الحقول الديناميكية بصيغة `{{field_key}}`.
  final String text;
  final PdfFontFamily family;

  /// اسم خط مخصص رفعه المستخدم (إن وُجد) — يتقدّم على [family] في المحرر
  /// وفي الـ PDF معاً. إن لم يكن الخط مسجَّلاً على هذا الجهاز يُرجع المحرّك
  /// إلى [family] تلقائياً بدل ظهور مربعات فارغة.
  final String? customFont;
  final PdfFontWeight weight;

  /// حجم الخط بوحدات مساحة التصميم (تُقاس إلى نقاط عند الرسم).
  final double fontSize;
  final String colorHex;
  final String? backgroundHex;
  final ElementTextAlign align;
  final ElementVerticalAlign verticalAlign;
  final ElementDirection direction;

  /// طريقة الضبط عند `align == ElementTextAlign.justify` (فراغات أو كشيدة).
  final JustifyMode justifyMode;
  final double lineHeight;
  final double letterSpacing;
  final int? maxLines;
  final double opacity;

  /// ظل النص — يُطبَّق على النص كله بما فيه الحقول الديناميكية المحلولة
  /// داخله، ويحفظ معه في JSON ويُرسم نفسه في المحرر والـ PDF.
  final TextShadow? shadow;

  /// توهّج خارجي حول حروف النص (Outer Glow).
  final GlowEffect? outerGlow;

  /// توهّج داخلي داخل حروف النص (Inner Glow).
  final GlowEffect? innerGlow;

  /// **التنسيق الجزئي**: نطاقات تُطبَّق على مقاطع محدَّدة من [text] (لون كلمة،
  /// خط حرف، حجم سطر…) دون أن تمسّ بقية الفقرة.
  ///
  /// القائمة مُطبَّقة دائماً عبر [StyledTextSpan.normalize]: متصاعدة وغير
  /// متداخلة. غيابها يعني النمط الأساسي لكل الحروف — أي السلوك القديم حرفياً،
  /// فتبقى ملفات القوالب القديمة صالحة بلا أي تغيير.
  final List<StyledTextSpan> spans;

  /// هل يحمل النص تنسيقاً جزئياً؟ (يوجّه اختيار مسار الرسم في اللوحة والـ PDF)
  bool get hasSpans => spans.isNotEmpty;

  static TextElement fromJson(Map<String, dynamic> json, String id) {
    double num_(String key, double fallback) {
      final Object? value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    final String raw = '${json['text'] ?? json['value'] ?? ''}';

    return TextElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      text: raw,
      family: PdfFontFamily.fromJson(json['font'] as String?),
      customFont: (json['font_custom'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['font_custom'] as String).trim(),
      weight: PdfFontWeight.fromJson(json['weight']),
      fontSize: num_('size', 16),
      colorHex: '${json['color'] ?? '#1B2539'}',
      backgroundHex: json['background'] as String?,
      align: ElementTextAlign.fromJson(json['align']),
      verticalAlign: ElementVerticalAlign.fromJson(json['valign']),
      direction: ElementDirection.fromJson(json['direction']),
      justifyMode: JustifyMode.fromJson(json['justifyMode']),
      lineHeight: num_('lineHeight', 1.4),
      letterSpacing: num_('letterSpacing', 0),
      maxLines: (json['maxLines'] as num?)?.toInt(),
      opacity: num_('opacity', 1),
      // `textShadow` اسم قديم محتمل لملفات محفوظة قبل هذا الحقل.
      shadow: TextShadow.fromJson(json['shadow'] ?? json['textShadow']),
      outerGlow: GlowEffect.fromJson(json['outerGlow']),
      innerGlow: GlowEffect.fromJson(json['innerGlow']),
      spans: StyledTextSpan.fromJsonList(json['spans'], raw.length),
    );
  }

  bool get hasDynamicFields => text.contains('{{');

  TextElement copyWith({
    ElementBox? box,
    double? rotation,
    String? text,
    PdfFontFamily? family,
    Object? customFont = _unset,
    PdfFontWeight? weight,
    double? fontSize,
    String? colorHex,
    Object? backgroundHex = _unset,
    ElementTextAlign? align,
    ElementVerticalAlign? verticalAlign,
    ElementDirection? direction,
    JustifyMode? justifyMode,
    double? lineHeight,
    double? letterSpacing,
    Object? maxLines = _unset,
    double? opacity,
    Object? shadow = _unset,
    Object? outerGlow = _unset,
    Object? innerGlow = _unset,      Object? spans = _unset,
  }) {
    final String nextText = text ?? this.text;
    final List<StyledTextSpan> nextSpans;
    if (spans == _unset) {
      // النطاقات تُعاد موضعها إذا عُدِّل النص نفسه، فلا تهرب عن كلماتها.
      nextSpans = text == null || text == this.text
          ? this.spans
          : StyledTextSpan.remapAfterEdit(
              oldText: this.text,
              newText: text,
              spans: this.spans,
            );
    } else {
      nextSpans = StyledTextSpan.normalize(
        spans as List<StyledTextSpan>,
        nextText.length,
      );
    }
    return TextElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      text: nextText,
      family: family ?? this.family,
      customFont: customFont == _unset
          ? this.customFont
          : customFont as String?,
      weight: weight ?? this.weight,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      backgroundHex: backgroundHex == _unset
          ? this.backgroundHex
          : backgroundHex as String?,
      align: align ?? this.align,
      verticalAlign: verticalAlign ?? this.verticalAlign,
      direction: direction ?? this.direction,
      justifyMode: justifyMode ?? this.justifyMode,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      maxLines: maxLines == _unset ? this.maxLines : maxLines as int?,
      opacity: opacity ?? this.opacity,
      shadow: shadow == _unset ? this.shadow : shadow as TextShadow?,
      outerGlow:
          outerGlow == _unset ? this.outerGlow : outerGlow as GlowEffect?,
      innerGlow:
          innerGlow == _unset ? this.innerGlow : innerGlow as GlowEffect?,
      spans: nextSpans,
    );
  }

  @override
  TextElement withBox(ElementBox box) => copyWith(box: box);

  @override
  TextElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': 'text',
        ...box.toJson(),
        'text': text,
        'font': family.jsonValue,
        if (customFont != null) 'font_custom': customFont,
        'weight': weight.jsonValue,
        'size': fontSize,
        'color': colorHex,
        if (backgroundHex != null) 'background': backgroundHex,
        'align': align.jsonValue,
        'valign': verticalAlign.jsonValue,
        'direction': direction.jsonValue,
        if (justifyMode != JustifyMode.spaces) 'justifyMode': justifyMode.jsonValue,
        'lineHeight': lineHeight,
        if (letterSpacing != 0) 'letterSpacing': letterSpacing,
        if (maxLines != null) 'maxLines': maxLines,
        if (opacity != 1) 'opacity': opacity,
        if (shadow != null) 'shadow': shadow!.toJson(),
        if (outerGlow != null) 'outerGlow': outerGlow!.toJson(),
        if (innerGlow != null) 'innerGlow': innerGlow!.toJson(),
        if (spans.isNotEmpty)
          'spans': StyledTextSpan.toJsonList(spans, text.length),
        if (rotation != 0) 'rotation': rotation,
      };
}

/// ظل النص: لون + شفافية + درجة تمويه + إزاحة أفقية/رأسية.
///
/// يُترجم إلى `TextStyle.shadows` في فلاتر (`Shadow`) وإلى نسخ مُزاحة شبه
/// شفّافة في الـ PDF (الحزمة `pdf` لا تدعم `shadows` أصلاً).
final class TextShadow {
  const TextShadow({
    this.colorHex = '#000000',
    this.opacity = 0.5,
    this.blurRadius = 4,
    this.offsetX = 1.5,
    this.offsetY = 1.5,
    this.spread = 0,
  });

  final String colorHex;

  /// شفافية الظل وحدها (0 = لا ظل، 1 = معتم).
  final double opacity;

  /// درجة التمويه/الانتشار (0 = ظل حادّ).
  final double blurRadius;

  final double offsetX;
  final double offsetY;

  /// سماكة الظل (Spread) بوحدات التصميم: يوسّع حدّ الصورة الظلّية قبل التمويه
  /// تماماً كما في Photoshop. الصفر يعني ظلاً بلا توسيع.
  ///
  /// فلاتر لا توفّر `spread` في [Shadow]، فيُبنى التوسيع بإضافة نسخ مُزاحة
  /// على محيط دائرة نصف قطرها [spread] — تُدرك في [editorTextShadows].
  final double spread;

  /// هل يُرسم ظل مرئي فعلاً؟
  bool get isVisible =>
      opacity > 0 &&
      (blurRadius > 0 || offsetX != 0 || offsetY != 0 || spread > 0);

  TextShadow copyWith({
    String? colorHex,
    double? opacity,
    double? blurRadius,
    double? offsetX,
    double? offsetY,
    double? spread,
  }) =>
      TextShadow(
        colorHex: colorHex ?? this.colorHex,
        opacity: opacity ?? this.opacity,
        blurRadius: blurRadius ?? this.blurRadius,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        spread: spread ?? this.spread,
      );

  static TextShadow? fromJson(Object? value) {
    if (value is! Map) return null;
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    double num_(String key, double fallback) {
      final Object? raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? fallback;
      return fallback;
    }

    return TextShadow(
      colorHex: (json['color'] as String?) ?? '#000000',
      opacity: num_('opacity', 0.5).clamp(0, 1).toDouble(),
      blurRadius: num_('blur', 4),
      offsetX: num_('x', 1.5),
      offsetY: num_('y', 1.5),
      spread: num_('spread', 0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': colorHex,
        if (opacity != 0.5) 'opacity': opacity,
        if (blurRadius != 4) 'blur': blurRadius,
        if (offsetX != 1.5) 'x': offsetX,
        if (offsetY != 1.5) 'y': offsetY,
        if (spread != 0) 'spread': spread,
      };

  @override
  bool operator ==(Object other) =>
      other is TextShadow &&
      other.colorHex == colorHex &&
      other.opacity == opacity &&
      other.blurRadius == blurRadius &&
      other.offsetX == offsetX &&
      other.offsetY == offsetY &&
      other.spread == spread;

  @override
  int get hashCode =>
      Object.hash(colorHex, opacity, blurRadius, offsetX, offsetY, spread);
}

// ===========================================================================
//  التأثيرات (توهّج/ضبط لوني) — مشتركة بين النص والشكل والصورة
// ===========================================================================

/// **توهّج** حول العنصر (Outer Glow) أو داخله (Inner Glow).
///
/// يوصف بثلاثة أرقام فقط — بنفس معنى Photoshop:
/// * [radius]: نصف قطر التمويه (كلما كبر اتّسع التلاشي).
/// * [spread]: توسيع الحدّ قبل التمويه (0 = بلا توسيع).
/// * [opacity]: شدة التوهّج وحدها (0 = مطفأ).
///
/// يُحفظ في JSON باسم `outerGlow` / `innerGlow` على العنصر، فتُقرأ بنفس
/// المفاتيح في المحرر ومحرّك الطباعة بلا خريطة وسيطة.
final class GlowEffect {
  const GlowEffect({
    this.colorHex = '#FFD166',
    this.radius = 8,
    this.spread = 0,
    this.opacity = 0.85,
  });

  final String colorHex;
  final double radius;
  final double spread;
  final double opacity;

  /// هل للتوهّج أثر مرئي؟ (بلا تمويه ولا توسيع لا شيء يُرسم.)
  bool get isVisible => opacity > 0 && (radius > 0 || spread > 0);

  GlowEffect copyWith({
    String? colorHex,
    double? radius,
    double? spread,
    double? opacity,
  }) =>
      GlowEffect(
        colorHex: colorHex ?? this.colorHex,
        radius: radius ?? this.radius,
        spread: spread ?? this.spread,
        opacity: opacity ?? this.opacity,
      );

  static GlowEffect? fromJson(Object? value) {
    if (value is! Map) return null;
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    double num_(String key, double fallback) {
      final Object? raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? fallback;
      return fallback;
    }

    return GlowEffect(
      colorHex: (json['color'] as String?) ?? '#FFD166',
      radius: num_('radius', 8).clamp(0, 200).toDouble(),
      spread: num_('spread', 0).clamp(0, 200).toDouble(),
      opacity: num_('opacity', 0.85).clamp(0, 1).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': colorHex,
        if (radius != 8) 'radius': radius,
        if (spread != 0) 'spread': spread,
        if (opacity != 0.85) 'opacity': opacity,
      };

  @override
  bool operator ==(Object other) =>
      other is GlowEffect &&
      other.colorHex == colorHex &&
      other.radius == radius &&
      other.spread == spread &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(colorHex, radius, spread, opacity);
}

/// **ضبط لوني** لعنصر نقطي: سطوع، تباين، تدوير لوني، تشبّع.
///
/// القيم مطبَّعة في المجال `-1..1` عدا [hue] بالدرجات `-180..180` — فيبقى
/// المنزلق واحداً لكل خاصية، وتتحوّل إلى مصفوفة `ColorFilter` واحدة للوحة
/// ([toMatrix]) وإلى معاملات مستقلة لمحرّك الطباعة (`image.adjustColor`).
///
/// القيم الافتراضية صفر ⇒ [isIdentity] صحيحة ⇒ لا مصفوفة ولا معالجة إطلاقاً،
/// فلا يتغيّر شكل أي عنصر قديم ولا يُعاد ترميز أي صورة بلا داعٍ.
final class ElementAdjustments {
  const ElementAdjustments({
    this.brightness = 0,
    this.contrast = 0,
    this.hue = 0,
    this.saturation = 0,
  });

  /// بلا أي ضبط — الحالة الافتراضية.
  static const ElementAdjustments none = ElementAdjustments();

  final double brightness;
  final double contrast;

  /// تدوير اللون حول عجلة الألوان بالدرجات.
  final double hue;

  final double saturation;

  bool get isIdentity =>
      brightness == 0 && contrast == 0 && hue == 0 && saturation == 0;

  ElementAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? hue,
    double? saturation,
  }) =>
      ElementAdjustments(
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        hue: hue ?? this.hue,
        saturation: saturation ?? this.saturation,
      );

  /// معامل السطوع لعائلة `image` (1 = بلا تغيير).
  double get brightnessFactor => 1 + brightness.clamp(-1, 1);

  /// معامل التباين لعائلة `image` (1 = بلا تغيير).
  double get contrastFactor => 1 + contrast.clamp(-1, 1);

  /// معامل التشبّع لعائلة `image` (1 = بلا تغيير).
  double get saturationFactor => 1 + saturation.clamp(-1, 1);

  /// بصمة قصيرة تدخل في مفتاح الصورة المعالجة — فلا تتصادم نسختان مختلفتا
  /// الضبط في ذاكرة محرّك الطباعة.
  String get key => isIdentity
      ? ''
      : 'b${brightness.toStringAsFixed(2)}'
          'c${contrast.toStringAsFixed(2)}'
          'h${hue.toStringAsFixed(0)}'
          's${saturation.toStringAsFixed(2)}';

  /// مصفوفة `ColorFilter` النهائية (4×5) — تُطبَّق على الصورة في اللوحة.
  List<double> toMatrix() {
    List<double> multiply(List<double> a, List<double> b) {
      final List<double> out = List<double>.filled(20, 0);
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 5; col++) {
          double sum = 0;
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + col];
          }
          if (col == 4) sum += a[row * 5 + 4];
          out[row * 5 + col] = sum;
        }
      }
      return out;
    }

    // (1) السطوع والتباين: مقياس حول المنتصف + إزاحة.
    final double scale = contrastFactor;
    final double shift = (1 - scale) * 127.5 + brightness.clamp(-1, 1) * 255;
    final List<double> tone = <double>[
      scale, 0, 0, 0, shift,
      0, scale, 0, 0, shift,
      0, 0, scale, 0, shift,
      0, 0, 0, 1, 0,
    ];

    // (2) التشبّع حول الإضاءة المدرَكة (معاملات Rec. 709).
    const double lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final double s = saturationFactor;
    final List<double> saturationMatrix = <double>[
      lr + (1 - lr) * s, lg - lg * s, lb - lb * s, 0, 0,
      lr - lr * s, lg + (1 - lg) * s, lb - lb * s, 0, 0,
      lr - lr * s, lg - lg * s, lb + (1 - lb) * s, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // (3) تدوير اللون (مصفوفة SVG feColorMatrix القياسية).
    final double angle = hue.clamp(-180, 180) * math.pi / 180;
    final double cos = math.cos(angle);
    final double sin = math.sin(angle);
    final List<double> hueMatrix = <double>[
      0.213 + cos * 0.787 - sin * 0.213,
      0.715 - cos * 0.715 - sin * 0.715,
      0.072 - cos * 0.072 + sin * 0.928,
      0, 0,
      0.213 - cos * 0.213 + sin * 0.143,
      0.715 + cos * 0.285 + sin * 0.140,
      0.072 - cos * 0.072 - sin * 0.283,
      0, 0,
      0.213 - cos * 0.213 - sin * 0.787,
      0.715 - cos * 0.715 + sin * 0.715,
      0.072 + cos * 0.928 + sin * 0.072,
      0, 0,
      0, 0, 0, 1, 0,
    ];

    return multiply(hueMatrix, multiply(saturationMatrix, tone));
  }

  static ElementAdjustments? fromJson(Object? value) {
    if (value is! Map) return null;
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    double num_(String key) {
      final Object? raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? 0;
      return 0;
    }

    final ElementAdjustments result = ElementAdjustments(
      brightness: num_('brightness').clamp(-1, 1).toDouble(),
      contrast: num_('contrast').clamp(-1, 1).toDouble(),
      hue: num_('hue').clamp(-180, 180).toDouble(),
      saturation: num_('saturation').clamp(-1, 1).toDouble(),
    );
    return result.isIdentity ? null : result;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (brightness != 0) 'brightness': brightness,
        if (contrast != 0) 'contrast': contrast,
        if (hue != 0) 'hue': hue,
        if (saturation != 0) 'saturation': saturation,
      };

  @override
  bool operator ==(Object other) =>
      other is ElementAdjustments &&
      other.brightness == brightness &&
      other.contrast == contrast &&
      other.hue == hue &&
      other.saturation == saturation;

  @override
  int get hashCode => Object.hash(brightness, contrast, hue, saturation);
}

// ===========================================================================
//  الأشكال
// ===========================================================================
enum ShapeKind { rect, ellipse, star, polygon, line }

/// نوع تعبئة الشكل: لون واحد أو تدرّج (خطي/شعاعي).
enum ShapeFillKind {
  solid('solid'),
  linearGradient('linear'),
  radialGradient('radial');

  const ShapeFillKind(this.jsonValue);

  final String jsonValue;

  bool get isGradient => this != ShapeFillKind.solid;

  static ShapeFillKind fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'linear' || 'lineargradient' || 'linear_gradient' =>
        ShapeFillKind.linearGradient,
      'radial' || 'radialgradient' || 'radial_gradient' =>
        ShapeFillKind.radialGradient,
      _ => ShapeFillKind.solid,
    };
  }
}

/// عملية الدمج المنطقي بين مسارات الأشكال.
///
/// * [union] يجمع المسارات في مسار واحد بحذف الحدود المتداخلة.
/// * [subtract] يطرح الأشكال العليا من الشكل السفلي (تفريغ).
/// * [intersect] يُبقي منطقة التقاطع وحدها.
/// * [exclude] يحذف منطقة التقاطع ويُبقي الأطراف الخارجية (XOR).
enum ShapeBooleanOp {
  union('union'),
  subtract('subtract'),
  intersect('intersect'),
  exclude('exclude');

  const ShapeBooleanOp(this.jsonValue);

  final String jsonValue;

  static ShapeBooleanOp? fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'union' || 'merge' => ShapeBooleanOp.union,
      'subtract' || 'difference' => ShapeBooleanOp.subtract,
      'intersect' || 'intersection' => ShapeBooleanOp.intersect,
      'exclude' || 'xor' || 'exclusion' => ShapeBooleanOp.exclude,
      _ => null,
    };
  }
}

/// تدرّج تعبئة الشكل (لونان وزاوية).
final class ShapeGradient {
  const ShapeGradient({
    required this.startHex,
    required this.endHex,
    this.angle = 0,
    this.kind = ShapeFillKind.linearGradient,
  });

  final String startHex;
  final String endHex;

  /// زاوية التدرّج بالدرجات (0 = من أعلى لأسفل... انظر المُصيّر).
  final double angle;
  final ShapeFillKind kind;

  ShapeGradient copyWith({
    String? startHex,
    String? endHex,
    double? angle,
    ShapeFillKind? kind,
  }) =>
      ShapeGradient(
        startHex: startHex ?? this.startHex,
        endHex: endHex ?? this.endHex,
        angle: angle ?? this.angle,
        kind: kind ?? this.kind,
      );

  static ShapeGradient? fromJson(Object? value) {
    if (value is! Map) return null;
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    final String? start = json['start'] as String?;
    final String? end = json['end'] as String?;
    if (start == null && end == null) return null;
    double num_() {
      final Object? raw = json['angle'];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? 0;
      return 0;
    }

    return ShapeGradient(
      startHex: start ?? '#FFFFFF',
      endHex: end ?? '#000000',
      angle: num_(),
      kind: ShapeFillKind.fromJson(json['kind']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'start': startHex,
        'end': endHex,
        if (angle != 0) 'angle': angle,
        'kind': kind.jsonValue,
      };
}

/// ظل الشكل (لون + تمويه + إزاحة + انتشار + شفافية).
///
/// يُستخدم أيضاً كظل **الصور** (نفس الدلالة تماماً: تمويه/إزاحة/توسيع/شفافية)
/// فلا داعي لنموذج ثانٍ يكرّر الحقول نفسها.
final class ShapeShadow {
  const ShapeShadow({
    this.colorHex = '#000000',
    this.blurRadius = 8,
    this.offsetX = 4,
    this.offsetY = 4,
    this.spread = 0,
    this.opacity = 1,
  });

  final String colorHex;
  final double blurRadius;
  final double offsetX;
  final double offsetY;
  final double spread;

  /// شفافية الظل وحدها (0 = مطفأ، 1 = بأقصى كثافة متاحة).
  ///
  /// تُضرب في كثافة الطبقات الأساسية فلا يتغيّر الظل القديم: القيمة الافتراضية
  /// 1 تعني «نفس المظهر السابق تماماً».
  final double opacity;

  /// هل للظل أثر مرئي؟
  bool get isVisible => opacity > 0;

  ShapeShadow copyWith({
    String? colorHex,
    double? blurRadius,
    double? offsetX,
    double? offsetY,
    double? spread,
    double? opacity,
  }) =>
      ShapeShadow(
        colorHex: colorHex ?? this.colorHex,
        blurRadius: blurRadius ?? this.blurRadius,
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        spread: spread ?? this.spread,
        opacity: opacity ?? this.opacity,
      );

  static ShapeShadow? fromJson(Object? value) {
    if (value is! Map) return null;
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    double num_(String key, double fallback) {
      final Object? raw = json[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) return double.tryParse(raw) ?? fallback;
      return fallback;
    }

    return ShapeShadow(
      colorHex: (json['color'] as String?) ?? '#000000',
      blurRadius: num_('blur', 8),
      offsetX: num_('x', 4),
      offsetY: num_('y', 4),
      spread: num_('spread', 0),
      opacity: num_('opacity', 1).clamp(0, 1).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'color': colorHex,
        if (blurRadius != 8) 'blur': blurRadius,
        if (offsetX != 4) 'x': offsetX,
        if (offsetY != 4) 'y': offsetY,
        if (spread != 0) 'spread': spread,
        if (opacity != 1) 'opacity': opacity,
      };

  @override
  bool operator ==(Object other) =>
      other is ShapeShadow &&
      other.colorHex == colorHex &&
      other.blurRadius == blurRadius &&
      other.offsetX == offsetX &&
      other.offsetY == offsetY &&
      other.spread == spread &&
      other.opacity == opacity;

  @override
  int get hashCode =>
      Object.hash(colorHex, blurRadius, offsetX, offsetY, spread, opacity);
}

final class ShapeElement extends TemplateElement {
  const ShapeElement({
    required super.id,
    required super.box,
    required this.kind,
    super.rotation,
    this.fillHex,
    this.strokeHex,
    this.strokeWidth = 0,
    this.radius = 0,
    this.cornerRadii,
    this.points = 5,
    this.innerRadius = 0.45,
    this.gradient,
    this.shadow,
    this.outerGlow,
    this.innerGlow,
    this.dashPattern,
    this.flipH = false,
    this.flipV = false,
    this.booleanOp,
    this.booleanParts = const <ShapeElement>[],
    this.opacity = 1,
    this.fillOpacity = 1,
  });

  final ShapeKind kind;
  final String? fillHex;
  final String? strokeHex;
  final double strokeWidth;

  /// نصف قطر الزوايا الموحّد (للمستطيل) — يُستخدم إن غاب [cornerRadii].
  final double radius;

  /// أنصاف أقطار الزوايا الأربع (أعلى-يسار، أعلى-يمين، أسفل-يمين،
  /// أسفل-يسار) — للمستطيل المنحني بزوايا مختلفة.
  final List<double>? cornerRadii;

  /// عدد رؤوس النجمة أو أضلاع المضلّع.
  final int points;

  /// نسبة نصف القطر الداخلي إلى الخارجي (نجمة).
  final double innerRadius;

  /// تدرّج التعبئة — إن وُجد يتقدّم على [fillHex].
  final ShapeGradient? gradient;

  /// ظل الشكل — إن وُجد يُرسم خلف التعبئة.
  final ShapeShadow? shadow;

  /// توهّج خارجي حول حدّ الشكل (يُرسم خلف التعبئة).
  final GlowEffect? outerGlow;

  /// توهّج داخلي على حدّ الشكل من الداخل (يُرسم فوق التعبئة).
  final GlowEffect? innerGlow;

  /// نمط الشرطات (طول شرطة، فجوة، ...) — فارغ يعني خطاً متّصلاً.
  final List<double>? dashPattern;

  /// قلب أفقي/رأسي حول مركز الشكل.
  final bool flipH;
  final bool flipV;

  /// عملية الدمج المنطقي (إن كان الشكل شكلاً مركّباً).
  final ShapeBooleanOp? booleanOp;

  /// الأشكال المكوِّنة للشكل المركّب (بإحداثيات مساحة التصميم نفسها).
  final List<ShapeElement> booleanParts;

  final double opacity;

  /// شفافية التعبئة وحدها (0 = بلا تعبئة، 1 = معتمة).
  ///
  /// منفصلة عن [opacity] الكلّية: تسمح بإطار معتم وتعبئة شبه شفافة (تظليل)
  /// بلا أن تفقد الحدود قوّتها — كما في أدوات التصميم الاحترافية.
  final double fillOpacity;

  /// هل هذا شكل مركّب ناتج عن عملية دمج منطقي؟
  bool get isCompound => booleanParts.length >= 2 && booleanOp != null;

  /// نوع الشكل من نصّ JSON.
  static ShapeKind? kindFromType(String type) => switch (type) {
        'rect' || 'rectangle' || 'box' => ShapeKind.rect,
        'ellipse' || 'circle' => ShapeKind.ellipse,
        'star' => ShapeKind.star,
        'polygon' || 'triangle' => ShapeKind.polygon,
        'line' || 'divider' => ShapeKind.line,
        _ => null,
      };

  /// نوع الشكل المُرَشَّح لـ JSON.
  static String typeOf(ShapeKind kind) => switch (kind) {
        ShapeKind.rect => 'rect',
        ShapeKind.ellipse => 'ellipse',
        ShapeKind.star => 'star',
        ShapeKind.polygon => 'polygon',
        ShapeKind.line => 'line',
      };

  static ShapeElement fromJson(
    Map<String, dynamic> json,
    String id,
    ShapeKind kind,
  ) {
    double num_(String key, double fallback) {
      final Object? value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int int_(String key, int fallback) {
      final Object? value = json[key];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    List<double>? doubleList(Object? value) {
      if (value is! List) return null;
      final List<double> parsed = <double>[
        for (final Object? item in value)
          if (item is num)
            item.toDouble()
          else if (item is String)
            double.tryParse(item) ?? 0
          else
            0,
      ];
      return parsed.isEmpty ? null : parsed;
    }

    final Object? rawParts = json['parts'];
    final List<ShapeElement> parts = rawParts is List
        ? <ShapeElement>[
            for (int i = 0; i < rawParts.length; i++)
              if (rawParts[i] is Map)
                ShapeElement.fromJson(
                  (rawParts[i] as Map).cast<String, dynamic>(),
                  '${(rawParts[i] as Map)['id'] ?? '${id}_part$i'}',
                  ShapeElement.kindFromType(
                        '${(rawParts[i] as Map)['type'] ?? 'rect'}',
                      ) ??
                      ShapeKind.rect,
                ),
          ]
        : const <ShapeElement>[];

    return ShapeElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      kind: kind,
      fillHex: json['fill'] as String?,
      strokeHex: json['stroke'] as String?,
      strokeWidth: num_('strokeWidth', kind == ShapeKind.line ? 1 : 0),
      radius: num_('radius', 0),
      cornerRadii: doubleList(json['corners']),
      points: int_('points', 5),
      innerRadius: num_('innerRadius', 0.45),
      gradient: ShapeGradient.fromJson(json['gradient']),
      shadow: ShapeShadow.fromJson(json['shadow']),
      outerGlow: GlowEffect.fromJson(json['outerGlow']),
      innerGlow: GlowEffect.fromJson(json['innerGlow']),
      dashPattern: doubleList(json['dash']),
      flipH: json['flipH'] == true,
      flipV: json['flipV'] == true,
      booleanOp: ShapeBooleanOp.fromJson(json['boolean']),
      booleanParts: parts,
      opacity: num_('opacity', 1),
      fillOpacity: num_('fillOpacity', 1),
    );
  }

  ShapeElement copyWith({
    ElementBox? box,
    double? rotation,
    Object? fillHex = _unset,
    Object? strokeHex = _unset,
    double? strokeWidth,
    double? radius,
    Object? cornerRadii = _unset,
    int? points,
    double? innerRadius,
    Object? gradient = _unset,
    Object? shadow = _unset,
    Object? outerGlow = _unset,
    Object? innerGlow = _unset,
    Object? dashPattern = _unset,
    bool? flipH,
    bool? flipV,
    Object? booleanOp = _unset,
    List<ShapeElement>? booleanParts,
    double? opacity,
    double? fillOpacity,
  }) {
    return ShapeElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      kind: kind,
      fillHex: fillHex == _unset ? this.fillHex : fillHex as String?,
      strokeHex: strokeHex == _unset ? this.strokeHex : strokeHex as String?,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      radius: radius ?? this.radius,
      cornerRadii: cornerRadii == _unset
          ? this.cornerRadii
          : cornerRadii as List<double>?,
      points: points ?? this.points,
      innerRadius: innerRadius ?? this.innerRadius,
      gradient:
          gradient == _unset ? this.gradient : gradient as ShapeGradient?,
      shadow: shadow == _unset ? this.shadow : shadow as ShapeShadow?,
      outerGlow:
          outerGlow == _unset ? this.outerGlow : outerGlow as GlowEffect?,
      innerGlow:
          innerGlow == _unset ? this.innerGlow : innerGlow as GlowEffect?,
      dashPattern: dashPattern == _unset
          ? this.dashPattern
          : dashPattern as List<double>?,
      flipH: flipH ?? this.flipH,
      flipV: flipV ?? this.flipV,
      booleanOp: booleanOp == _unset
          ? this.booleanOp
          : booleanOp as ShapeBooleanOp?,
      booleanParts: booleanParts ?? this.booleanParts,
      opacity: opacity ?? this.opacity,
      fillOpacity: fillOpacity ?? this.fillOpacity,
    );
  }

  @override
  ShapeElement withBox(ElementBox box) => copyWith(box: box);

  @override
  ShapeElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': ShapeElement.typeOf(kind),
        ...box.toJson(),
        if (fillHex != null) 'fill': fillHex,
        if (strokeHex != null) 'stroke': strokeHex,
        if (strokeWidth != 0) 'strokeWidth': strokeWidth,
        if (radius != 0) 'radius': radius,
        if (cornerRadii != null) 'corners': cornerRadii,
        if (points != 5) 'points': points,
        if (innerRadius != 0.45) 'innerRadius': innerRadius,
        if (gradient != null) 'gradient': gradient!.toJson(),
        if (shadow != null) 'shadow': shadow!.toJson(),
        if (outerGlow != null) 'outerGlow': outerGlow!.toJson(),
        if (innerGlow != null) 'innerGlow': innerGlow!.toJson(),
        if (dashPattern != null && dashPattern!.isNotEmpty) 'dash': dashPattern,
        if (flipH) 'flipH': flipH,
        if (flipV) 'flipV': flipV,
        if (booleanOp != null) 'boolean': booleanOp!.jsonValue,
        if (booleanParts.isNotEmpty)
          'parts': <Map<String, dynamic>>[
            for (final ShapeElement part in booleanParts) part.toJson(),
          ],
        if (opacity != 1) 'opacity': opacity,
        if (fillOpacity != 1) 'fillOpacity': fillOpacity,
        if (rotation != 0) 'rotation': rotation,
      };
}

// ===========================================================================
//  الختم (يُرسم متجهاً — بلا أي صورة)
// ===========================================================================
final class SealElement extends TemplateElement {
  const SealElement({
    required super.id,
    required super.box,
    super.rotation,
    this.fillHex = '#C7A26B',
    this.ringHex = '#F9FAFB',
    this.starHex = '#1B2539',
    this.starRatio = 0.5,
    this.opacity = 1,
  });

  final String fillHex;
  final String ringHex;
  final String starHex;

  /// نسبة حجم النجمة إلى نصف قطر الختم.
  final double starRatio;
  final double opacity;

  /// طول ضلع مربّع الختم بوحدات التصميم.
  ///
  /// مصدر حقيقة مشترك بين المحرر ومحرّك الـ PDF: الختم يُرسم دائماً مربّعاً
  /// بأصغر ضلعين (كان المحرر يستخدم [min] بينما الـ PDF يستخدم العرض، فيترحّل
  /// الختم عند اختلاف العرض والارتفاع).
  double squareSide([ElementBox? box]) {
    final ElementBox target = box ?? this.box;
    final double width = target.width > 0 ? target.width : 80;
    final double height = target.height > 0 ? target.height : width;
    return math.min(width, height);
  }

  static SealElement fromJson(Map<String, dynamic> json, String id) {
    String text_(String key, String fallback) => '${json[key] ?? fallback}';

    return SealElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      fillHex: text_('fill', '#C7A26B'),
      ringHex: text_('ring', '#F9FAFB'),
      starHex: text_('star', '#1B2539'),
      starRatio: (json['starRatio'] as num?)?.toDouble() ?? 0.5,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
    );
  }

  SealElement copyWith({
    ElementBox? box,
    double? rotation,
    String? fillHex,
    String? ringHex,
    String? starHex,
    double? starRatio,
    double? opacity,
  }) {
    return SealElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      fillHex: fillHex ?? this.fillHex,
      ringHex: ringHex ?? this.ringHex,
      starHex: starHex ?? this.starHex,
      starRatio: starRatio ?? this.starRatio,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  SealElement withBox(ElementBox box) => copyWith(box: box);

  @override
  SealElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': 'seal',
        ...box.toJson(),
        'fill': fillHex,
        'ring': ringHex,
        'star': starHex,
        if (starRatio != 0.5) 'starRatio': starRatio,
        if (opacity != 1) 'opacity': opacity,
        if (rotation != 0) 'rotation': rotation,
      };
}

// ===========================================================================
//  الزخرفة المتجهية الإجرائية (بلا صور — تُولَّد هندسياً)
// ===========================================================================
final class DecorationElement extends TemplateElement {
  const DecorationElement({
    required super.id,
    required super.box,
    super.rotation,
    this.spec = const DecorSpec(),
    this.opacity = 1,
  });

  /// وصف الزخرفة (النوع والألوان والطبقات) — يُحفظ داخل القالب.
  final DecorSpec spec;
  final double opacity;

  static DecorationElement fromJson(Map<String, dynamic> json, String id) {
    final Object? raw = json['spec'] ?? json['decor'];
    return DecorationElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      spec: raw is Map
          ? DecorSpec.fromJson(raw.cast<String, dynamic>())
          : DecorSpec.fromJson(json),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
    );
  }

  DecorationElement copyWith({
    ElementBox? box,
    double? rotation,
    DecorSpec? spec,
    double? opacity,
  }) =>
      DecorationElement(
        id: id,
        box: box ?? this.box,
        rotation: rotation ?? this.rotation,
        spec: spec ?? this.spec,
        opacity: opacity ?? this.opacity,
      );

  @override
  DecorationElement withBox(ElementBox box) => copyWith(box: box);

  @override
  DecorationElement withRotation(double rotation) =>
      copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': 'decoration',
        ...box.toJson(),
        'spec': spec.toJson(),
        if (opacity != 1) 'opacity': opacity,
        if (rotation != 0) 'rotation': rotation,
      };
}

// ===========================================================================
//  التوقيعات المتعددة (حتى 3 خانات جنباً إلى جنب)
// ===========================================================================

/// خانات التوقيع المتراصة أفقياً.
///
/// ثلاث خانات هي الحد العملي لشهادات/على عقود A4: توزيع متساوٍ يبقي كل خانة
/// واسعة بما يكفي لصورة التوقيع واسم صاحبها تحتها.
enum SignatureSlots {
  one(1, 'توقيع واحد'),
  two(2, 'توقيعان'),
  three(3, 'ثلاثة توقيعات');

  const SignatureSlots(this.count, this.labelAr);

  /// عدد الخانات المعروضة (تُرسم الخانات الممتلئة فقط).
  final int count;

  final String labelAr;

  /// أقصى عدد خانات يدعمه المحرّك.
  static const int max = 3;

  /// من رقم مطلق إلى أقرب وضع مدعوم (1..3).
  static SignatureSlots fromCount(Object? value) {
    final int count = switch (value) {
      final num n => n.toInt(),
      final String s => int.tryParse(s.trim()) ?? 1,
      _ => 1,
    };
    return values.firstWhere(
      (SignatureSlots slot) => slot.count == count.clamp(1, max),
      orElse: () => SignatureSlots.one,
    );
  }
}

/// محاذاة صورة التوقيع داخل خانتها.
enum SignatureAlign {
  start('start'),
  center('center'),
  end('end');

  const SignatureAlign(this.jsonValue);

  final String jsonValue;

  static SignatureAlign fromJson(Object? value) {
    final String needle = '${value ?? ''}'.trim().toLowerCase();
    return switch (needle) {
      'start' || 'right' => SignatureAlign.start,
      'end' || 'left' => SignatureAlign.end,
      _ => SignatureAlign.center,
    };
  }
}

/// خانة توقيع واحدة: الدور + اسم صاحبها + صورة التوقيع.
///
/// الصورة تُخزَّن بنفس نموذج [ImageElement] (مرجع حيّ + نسخة Base64 احتياطية)
/// حتى يعمل الرسم في المحرر وفي الـ PDF بعدّاد واحد بلا منطق مكرّر.
class SignatureSlot {
  const SignatureSlot({
    this.role = '',
    this.name = '',
    this.imagePath = '',
    this.imageSource = ImageSourceKind.userAsset,
    this.imageData,
  });

  /// الدور/المسمى الوظيفي (مثل: «المدير العام»، «الموارد البشرية»).
  final String role;

  /// اسم صاحب التوقيع (مثل: «أحمد حمدي»)؛ يقبل الحقول الديناميكية `{{...}}`.
  final String name;

  /// مسار/معرّف صورة التوقيع (بلا صورة إن كان فراغاً).
  final String imagePath;

  final ImageSourceKind imageSource;

  /// نسخة Base64 احتياطية للصورة (بلا بادئة data URI).
  final String? imageData;

  bool get isEmpty =>
      role.trim().isEmpty &&
      name.trim().isEmpty &&
      imagePath.trim().isEmpty;

  bool get hasImage => imagePath.trim().isNotEmpty;

  /// هل يحمل النص حقولاً ديناميكية `{{...}}`؟
  bool get hasDynamicFields => role.contains('{{') || name.contains('{{');

  SignatureSlot copyWith({
    String? role,
    String? name,
    String? imagePath,
    ImageSourceKind? imageSource,
    Object? imageData = _unset,
  }) =>
      SignatureSlot(
        role: role ?? this.role,
        name: name ?? this.name,
        imagePath: imagePath ?? this.imagePath,
        imageSource: imageSource ?? this.imageSource,
        imageData: imageData == _unset ? this.imageData : imageData as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (role.trim().isNotEmpty) 'role': role,
        if (name.trim().isNotEmpty) 'name': name,
        if (imagePath.trim().isNotEmpty) 'imagePath': imagePath,
        if (imagePath.trim().isNotEmpty) 'imageSource': imageSource.jsonValue,
        if (imageData != null && imageData!.trim().isNotEmpty)
          'imageData': imageData,
      };

  factory SignatureSlot.fromJson(Map<String, dynamic> json) {
    final String? embedded = json['imageData'] as String?;
    final String clean = stripBase64DataUri(embedded ?? '');
    return SignatureSlot(
      role: '${json['role'] ?? json['title'] ?? json['label'] ?? ''}',
      name: '${json['name'] ?? json['assignee'] ?? json['person'] ?? ''}',
      imagePath:
          '${json['imagePath'] ?? json['image'] ?? json['path'] ?? ''}'.trim(),
      imageSource: ImageSourceKind.fromJson(
        json['imageSource'] ?? json['source'],
      ),
      imageData: clean.isEmpty ? null : clean,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SignatureSlot &&
      other.role == role &&
      other.name == name &&
      other.imagePath == imagePath &&
      other.imageSource == imageSource &&
      other.imageData == imageData;

  @override
  int get hashCode =>
      Object.hash(role, name, imagePath, imageSource, imageData);
}

/// عنصر توقيعات متعددة: حتى ثلاث خانات جنباً إلى جنب مع محاذاة وتباعد
/// وتحجيم تلقائي.
///
/// يحلّ محلّ «العمل بالصور الخام»: خانة واحدة تحتوي صورة التوقيع ومسمى الدور
/// واسم صاحب التوقيع، ويوزّعها المحرّك بالتساوي داخل صندوق العنصر فيتطابق
/// المحرر والـ PDF (نفس القاعدة الحسابية `slotLayout`).
final class SignatureElement extends TemplateElement {
  const SignatureElement({
    required super.id,
    required super.box,
    super.rotation,
    this.slots = const <SignatureSlot>[],
    this.slotCount = SignatureSlots.max,
    this.roleFontSize = 12,
    this.nameFontSize = 15,
    this.roleColorHex = '#5B6779',
    this.nameColorHex = '#1B2539',
    this.family = PdfFontFamily.plex,
    this.customFont,
    this.spacing = 24,
    this.imageScale = 1,
    this.align = SignatureAlign.center,
    this.showDivider = true,
    this.direction = ElementDirection.rtl,
    this.opacity = 1,
  });

  /// الخانات بترتيبها المنطقي (الخانة الأولى هي الأهم).
  ///
  /// الترتيب الفيزيائي يتبع [direction]: في الوضع العربي (rtl) تقع الخانة
  /// الأولى في أقصى **اليمين** كما هو معتاد في المستندات العربية.
  final List<SignatureSlot> slots;

  /// عدد الخانات المعروضة (1..3) — مستقلّ عن طول [slots] حتى لا يُفقَد محتوى
  /// خانة عند تصغير العدد ثم تكبيره من جديد.
  final int slotCount;

  /// حجم خط مسمى الدور (وحدات تصميم).
  final double roleFontSize;

  /// حجم خط اسم صاحب التوقيع (وحدات تصميم).
  final double nameFontSize;

  final String roleColorHex;
  final String nameColorHex;
  final PdfFontFamily family;

  /// خط مخصص (يتقدّم على [family] إن كان مسجَّلاً على هذا الجهاز).
  final String? customFont;

  /// الفراغ الأفقي بين الخانات (وحدات تصميم).
  final double spacing;

  /// معامل تحجيم صورة التوقيع داخل خانتتها (1 = الملاءمة الكاملة).
  final double imageScale;

  final SignatureAlign align;

  /// رسم خط رقيق فوق اسم كل صاحب توقيع (خط التوقيع الكتابي).
  final bool showDivider;

  /// اتجاه ترتيب الخانات (عربي = الأولى يميناً).
  final ElementDirection direction;

  final double opacity;

  /// الخانات المعروضة والمملوءة (بلا خانات فارغة) بترتيبها المنطقي.
  List<SignatureSlot> get activeSlots => slots
      .take(slotCount.clamp(0, SignatureSlots.max))
      .where((SignatureSlot slot) => !slot.isEmpty)
      .toList(growable: false);

  /// الخانات مرتبة فيزيائياً حسب [direction] — مصدر وحيد للمحرر والـ PDF.
  List<SignatureSlot> get orderedSlots {
    final List<SignatureSlot> active = activeSlots;
    return direction == ElementDirection.ltr
        ? active
        : active.reversed.toList(growable: false);
  }

  /// خانة برقمها مع إرجاع خانة فارغة إن لم تكن مضبوطة بعد.
  SignatureSlot slotAt(int index) => index >= 0 && index < slots.length
      ? slots[index]
      : const SignatureSlot();

  /// هل يحمل أي خانة حقولاً ديناميكية؟
  bool get hasDynamicFields =>
      slots.any((SignatureSlot slot) => slot.hasDynamicFields);

  /// ارتفاع صورة التوقيع (وحدات تصميم) بحسب عرض خانتتها ومعامل التحجيم.
  ///
  /// قاعدة مشتركة بين المحرر والـ PDF: الصورة تحتل ~42% من عرض الخانة مضروباً
  /// في [imageScale]، ولا تتجاوز عرض الخانة أو ارتفاع صندوق العنصر.
  double imageHeightFor(double slotWidth, {double boxHeight = 0}) {
    final double base = slotWidth * 0.42 * imageScale;
    final double cap = boxHeight > 0 ? boxHeight * 0.7 : slotWidth;
    return base.clamp(0, slotWidth < cap ? slotWidth : cap);
  }

  /// توزيع الخانات على عرض متاح — **مصدر الحساب الوحيد** المشترك بين المحرر
  /// والـ PDF حتى لا يترحّل التوزيع بينهما.
  ///
  /// يعيد عرض كل خانة وإزاحتها الأفقية داخل [width].
  List<SignatureSlotRect> slotLayout(double width, {int? slotCountOverride}) {
    final int count = (slotCountOverride ?? activeSlots.length)
        .clamp(0, SignatureSlots.max);
    if (count <= 0 || width <= 0) return const <SignatureSlotRect>[];
    final double gap = spacing.clamp(0, width);
    final double usable = (width - gap * (count - 1)).clamp(0, width);
    final double each = usable / count;
    return <SignatureSlotRect>[
      for (int i = 0; i < count; i++)
        SignatureSlotRect(
          index: i,
          left: i * (each + gap),
          width: each,
        ),
    ];
  }

  static SignatureElement fromJson(Map<String, dynamic> json, String id) {
    double num_(String key, double fallback) {
      final Object? value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    final Object? rawSlots = json['slots'] ?? json['signatures'];
    final List<SignatureSlot> slots = <SignatureSlot>[];
    if (rawSlots is List) {
      for (final Object? raw in rawSlots) {
        if (raw is! Map) continue;
        slots.add(SignatureSlot.fromJson(raw.cast<String, dynamic>()));
        if (slots.length >= SignatureSlots.max) break;
      }
    }

    return SignatureElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      slots: slots,
      slotCount: SignatureSlots.fromCount(
        json['slotCount'] ?? (slots.isEmpty ? SignatureSlots.max : slots.length),
      ).count,
      roleFontSize: num_('roleFontSize', 12),
      nameFontSize: num_('nameFontSize', 15),
      roleColorHex: '${json['roleColor'] ?? '#5B6779'}',
      nameColorHex: '${json['nameColor'] ?? '#1B2539'}',
      family: PdfFontFamily.fromJson(json['font'] as String?),
      customFont: (json['font_custom'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['font_custom'] as String).trim(),
      spacing: num_('spacing', 24),
      imageScale: num_('imageScale', 1),
      align: SignatureAlign.fromJson(json['align']),
      showDivider: json['showDivider'] as bool? ?? true,
      direction: ElementDirection.fromJson(json['direction']),
      opacity: num_('opacity', 1),
    );
  }

  SignatureElement copyWith({
    ElementBox? box,
    double? rotation,
    List<SignatureSlot>? slots,
    int? slotCount,
    double? roleFontSize,
    double? nameFontSize,
    String? roleColorHex,
    String? nameColorHex,
    PdfFontFamily? family,
    Object? customFont = _unset,
    double? spacing,
    double? imageScale,
    SignatureAlign? align,
    bool? showDivider,
    ElementDirection? direction,
    double? opacity,
  }) =>
      SignatureElement(
        id: id,
        box: box ?? this.box,
        rotation: rotation ?? this.rotation,
        slots: slots ?? this.slots,
        slotCount: slotCount ?? this.slotCount,
        roleFontSize: roleFontSize ?? this.roleFontSize,
        nameFontSize: nameFontSize ?? this.nameFontSize,
        roleColorHex: roleColorHex ?? this.roleColorHex,
        nameColorHex: nameColorHex ?? this.nameColorHex,
        family: family ?? this.family,
        customFont:
            customFont == _unset ? this.customFont : customFont as String?,
        spacing: spacing ?? this.spacing,
        imageScale: imageScale ?? this.imageScale,
        align: align ?? this.align,
        showDivider: showDivider ?? this.showDivider,
        direction: direction ?? this.direction,
        opacity: opacity ?? this.opacity,
      );

  /// نسخة بخانة واحدة معدّلة (توسّع القائمة تلقائياً عند الحاجة).
  SignatureElement withSlot(int index, SignatureSlot slot) {
    if (index < 0 || index >= SignatureSlots.max) return this;
    final List<SignatureSlot> next = <SignatureSlot>[...slots];
    while (next.length <= index) {
      next.add(const SignatureSlot());
    }
    next[index] = slot;
    return copyWith(slots: next);
  }

  /// ضبط عدد الخانات المعروضة (1..3) بلا حذف محتوى أي خانة.
  SignatureElement withSlotCount(int count) =>
      copyWith(slotCount: count.clamp(1, SignatureSlots.max));

  @override
  SignatureElement withBox(ElementBox box) => copyWith(box: box);

  @override
  SignatureElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': 'signature',
        ...box.toJson(),
        'slots': slots
            .take(SignatureSlots.max)
            .map((SignatureSlot slot) => slot.toJson())
            .toList(growable: false),
        'slotCount': slotCount.clamp(1, SignatureSlots.max),
        'roleFontSize': roleFontSize,
        'nameFontSize': nameFontSize,
        'roleColor': roleColorHex,
        'nameColor': nameColorHex,
        'font': family.jsonValue,
        if (customFont != null) 'font_custom': customFont,
        'spacing': spacing,
        if (imageScale != 1) 'imageScale': imageScale,
        'align': align.jsonValue,
        if (!showDivider) 'showDivider': showDivider,
        'direction': direction.jsonValue,
        if (opacity != 1) 'opacity': opacity,
        if (rotation != 0) 'rotation': rotation,
      };
}

/// مستطيل خانة توقيع داخل صندوق العنصر (وحدات تصميم).
class SignatureSlotRect {
  const SignatureSlotRect({
    required this.index,
    required this.left,
    required this.width,
  });

  final int index;
  final double left;
  final double width;
}

// ===========================================================================
//  الصورة
// ===========================================================================
enum ImageSourceKind {
  /// صورة محزومة في أصول التطبيق (مسار الأصل).
  asset('asset'),

  /// ملف محلي (غير مدعوم في الوضع غير المتصل مباشرةً).
  file('file'),

  /// بيانات مضمّنة (Base64 خام داخل `path`).
  dataUri('data'),

  /// أصل من مكتبة أصول المستخدم (الشعار/الختم/التوقيع) — `path` = معرّف الأصل.
  ///
  /// يُحلّ عند العرض والطباعة من [AssetsController] المحلي، فلا ينتفخ سجل
  /// القالب ببيانات الصور، ويفقد القالب الصورة بأناقة إذا حُذف الأصل.
  userAsset('user_asset');

  const ImageSourceKind(this.jsonValue);

  final String jsonValue;

  static ImageSourceKind fromJson(Object? value) {
    final String needle = '${value ?? 'asset'}'.trim().toLowerCase();
    return switch (needle) {
      'file' || 'path' => ImageSourceKind.file,
      'data' || 'base64' || 'datauri' => ImageSourceKind.dataUri,
      'user_asset' || 'userasset' || 'asset_ref' || 'library' =>
        ImageSourceKind.userAsset,
      _ => ImageSourceKind.asset,
    };
  }
}

enum ImageFit { contain, cover, fill }

/// يزيل بادئة data URI عن Base64 الخام (مثل `data:image/png;base64,AAAA`)
/// ويعيد النص مُقلَّماً — فلا تفشل فكّ الترميز عندما يخزّن المستدعي بادئة.
String stripBase64DataUri(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final int comma = trimmed.indexOf(',');
  if (comma != -1 &&
      trimmed.substring(0, comma).toLowerCase().contains('base64')) {
    return trimmed.substring(comma + 1).trim();
  }
  return trimmed;
}

/// مفتاح صورة موحّد (`نوع:مسار` أو `نوع:مسار#rrggbb`) — يُبنى منه مفتاح العنصر
/// في المحرّر ومفتاح خرائط محرّر الطباعة، فلا ينحرف أحدهما عن الآخر.
///
/// اللون المُلوّن يُكتب بلا `#` وبأحرف صغيرة، فيبقى المفتاح بفاصل واحد فقط.
String imageKeyFor(
  ImageSourceKind kind,
  String path, {
  String? tintHex,
  String? adjustKey,
}) {
  final String base = '${kind.jsonValue}:$path';
  final StringBuffer key = StringBuffer(base);
  final String tint = (tintHex ?? '').trim();
  if (tint.isNotEmpty) {
    final String body = tint.startsWith('#') ? tint.substring(1) : tint;
    if (body.isNotEmpty) key.write('#${body.toLowerCase()}');
  }
  // بصمة الضبط اللوني تُفصل بـ`~` فلا تلتبس مع لون التلوين أبداً.
  final String adjust = (adjustKey ?? '').trim();
  if (adjust.isNotEmpty) key.write('~$adjust');
  return key.toString();
}

final class ImageElement extends TemplateElement {
  const ImageElement({
    required super.id,
    required super.box,
    required this.sourceKind,
    required this.path,
    super.rotation,
    this.fit = ImageFit.contain,
    this.opacity = 1,
    this.tintHex,
    this.data,
    this.shadow,
    this.outerGlow,
    this.adjustments,
  });

  final ImageSourceKind sourceKind;
  final String path;
  final ImageFit fit;
  final double opacity;

  /// لون تلوين العنصر (`#RRGGBB`) — `null` يعني بكسلات الصورة الأصلية.
  ///
  /// عند وجوده تُلوّن الصورة بـ`BlendMode.srcIn` في المحرّر وفي الطباعة معاً:
  /// يُستبدل لون البكسلات المرسومة (الخطوط/الزخرفة) ويُحفظ شفافُ الخلفية كما هو.
  /// مفيد لصكّات الخط العربي/الإطارات الأحادية اللون على خلفية شفافة.
  final String? tintHex;

  /// هل للعنصر تلوين فعّال؟
  bool get hasTint => (tintHex ?? '').trim().isNotEmpty;

  /// نسخة Base64 مضمّنة من الصورة (بلا بادئة data URI).
  ///
  /// **نسخة احتياطية**: تُكتب عند إدراج أصل من مكتبة أصولي حتى يبقى الإطار
  /// قابلاً للرسم في الـ PDF حتى لو حُذف الأصل من المكتبة لاحقاً. الأولوية
  /// تبقى للمرجع الحيّ ([path]) ما دام الأصل موجوداً، وهذا حقل ناجع عند فقده.
  final String? data;

  /// ظل العنصر النقطي (Drop Shadow) — نفس دلالة ظل الشكل: إزاحة/تمويه/توسيع/
  /// شفافية/لون، يُرسم في اللوحة تحت الصورة بصورتها الظلّية (silhouette).
  final ShapeShadow? shadow;

  /// توهّج خارجي حول حدود الصورة غير الشفافة (Outer Glow).
  final GlowEffect? outerGlow;

  /// ضبط لوني حيّ (سطوع/تباين/تدوير لوني/تشبّع) — يُطبَّق في اللوحة كمصفوفة
  /// `ColorFilter` وفي الطباعة كمعالجة بكسلات قبل التضمين.
  final ElementAdjustments? adjustments;

  /// هل للعنصر ضبط لوني فعّال؟
  bool get hasAdjustments => adjustments != null && !adjustments!.isIdentity;

  static ImageElement fromJson(Map<String, dynamic> json, String id) {
    // نقبل شكلين للبيانات المضمّنة: سلسلة Base64 مباشرة، أو كائن يحمل مفتاح
    // `base64`/`data` (مثل `{'base64': '...'}`) — للتوافق مع القوالب القديمة
    // والجديدة بلا كسر أي منهما.
    final String? embedded =
        _readEmbeddedImage(json['data']) ?? _readEmbeddedImage(json['data_base64']);
    return ImageElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      sourceKind: ImageSourceKind.fromJson(json['source']),
      path: '${json['path'] ?? json['src'] ?? ''}',
      fit: switch ('${json['fit'] ?? 'contain'}'.toLowerCase()) {
        'cover' => ImageFit.cover,
        'fill' || 'stretch' => ImageFit.fill,
        _ => ImageFit.contain,
      },
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
      tintHex: _readTintHex(json),
      data: embedded,
      shadow: ShapeShadow.fromJson(json['shadow']),
      outerGlow: GlowEffect.fromJson(json['outerGlow']),
      adjustments: ElementAdjustments.fromJson(
        json['adjust'] ?? json['adjustments'],
      ),
    );
  }

  /// يقرأ لون التلوين من JSON (نقبل عدة أسماء للتوافق مع القوالب القديمة).
  static String? _readTintHex(Map<String, dynamic> json) {
    for (final String key in const <String>[
      'tint',
      'tintColor',
      'tint_hex',
      'color',
    ]) {
      final Object? value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// يستخرج Base64 المضمّن من قيمة JSON قد تكون سلسلة أو كائناً؛ يعيد `null`
  /// إن لم يجد بيانات صالحة.
  static String? _readEmbeddedImage(Object? raw) {
    String? candidate;
    if (raw is String) {
      candidate = raw;
    } else if (raw is Map) {
      for (final String key in const <String>['base64', 'data', 'value', 'bytes']) {
        final Object? value = raw[key];
        if (value is String && value.trim().isNotEmpty) {
          candidate = value;
          break;
        }
      }
    }
    final String clean = stripBase64DataUri(candidate ?? '');
    return clean.isEmpty ? null : clean;
  }

  bool get hasEmbeddedData => data != null && data!.trim().isNotEmpty;

  ImageElement copyWith({
    ElementBox? box,
    double? rotation,
    ImageSourceKind? sourceKind,
    String? path,
    ImageFit? fit,
    double? opacity,
    Object? tintHex = _unset,
    Object? data = _unset,
    Object? shadow = _unset,
    Object? outerGlow = _unset,
    Object? adjustments = _unset,
  }) {
    return ImageElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      sourceKind: sourceKind ?? this.sourceKind,
      path: path ?? this.path,
      fit: fit ?? this.fit,
      opacity: opacity ?? this.opacity,
      tintHex: tintHex == _unset ? this.tintHex : tintHex as String?,
      data: data == _unset ? this.data : data as String?,
      shadow: shadow == _unset ? this.shadow : shadow as ShapeShadow?,
      outerGlow:
          outerGlow == _unset ? this.outerGlow : outerGlow as GlowEffect?,
      adjustments: adjustments == _unset
          ? this.adjustments
          : adjustments as ElementAdjustments?,
    );
  }

  /// مفتاح الصورة في خرائط محرّك الطباعة (`نوع:مسار`) — يشاركه المحرّر والـ PDF.
  String get imageKey => imageKeyFor(sourceKind, path);

  /// مفتاح نسخة الصورة **الملوّنة**، أو `null` إن كان العنصر بلا تلوين.
  ///
  /// يضمّ اللون نفسه كي تتشارك الصورة الواحدة أكثر من تلوين بلا تصادم،
  /// ويضمّ بصمة الضبط اللوني إن وُجد.
  String? get tintedImageKey => hasTint
      ? imageKeyFor(
          sourceKind,
          path,
          tintHex: tintHex,
          adjustKey: adjustments?.key,
        )
      : null;

  /// مفتاح نسخة الصورة **المعالجة** (تلوين و/أو ضبط لوني)، أو `null` إن كانت
  /// بلا معالجة — فيُستعمل [imageKey] الأصلي عندها بلا نسخة زائدة.
  String? get processedImageKey =>
      (hasTint || hasAdjustments)
          ? imageKeyFor(
              sourceKind,
              path,
              tintHex: hasTint ? tintHex : null,
              adjustKey: adjustments?.key,
            )
          : null;

  @override
  ImageElement withBox(ElementBox box) => copyWith(box: box);

  @override
  ImageElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': 'image',
        ...box.toJson(),
        'source': sourceKind.jsonValue,
        'path': path,
        'fit': fit.name,
        if (opacity != 1) 'opacity': opacity,
        if (hasTint) 'tint': tintHex,
        if (shadow != null) 'shadow': shadow!.toJson(),
        if (outerGlow != null) 'outerGlow': outerGlow!.toJson(),
        if (hasAdjustments) 'adjust': adjustments!.toJson(),
        if (rotation != 0) 'rotation': rotation,
        if (hasEmbeddedData) 'data': data,
      };
}

// ===========================================================================
//  رمز الاستجابة السريعة (تحقّق من صحة الشهادة)
// ===========================================================================
final class QrElement extends TemplateElement {
  const QrElement({
    required super.id,
    required super.box,
    required this.data,
    super.rotation,
    this.colorHex = '#1B2539',
    this.backgroundHex = '#FFFFFF',
  });

  final String data;
  final String colorHex;
  final String backgroundHex;

  static QrElement fromJson(Map<String, dynamic> json, String id) {
    return QrElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      data: '${json['data'] ?? json['text'] ?? ''}',
      colorHex: '${json['color'] ?? '#1B2539'}',
      backgroundHex: '${json['background'] ?? '#FFFFFF'}',
    );
  }

  QrElement copyWith({
    ElementBox? box,
    double? rotation,
    String? data,
    String? colorHex,
    String? backgroundHex,
  }) {
    return QrElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      data: data ?? this.data,
      colorHex: colorHex ?? this.colorHex,
      backgroundHex: backgroundHex ?? this.backgroundHex,
    );
  }

  @override
  QrElement withBox(ElementBox box) => copyWith(box: box);

  @override
  QrElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': 'qr',
        ...box.toJson(),
        'data': data,
        'color': colorHex,
        'background': backgroundHex,
        if (rotation != 0) 'rotation': rotation,
      };
}

// ===========================================================================
//  عنصر غير معروف (توافق أمامي مع إصدارات أحدث من المحرر)
// ===========================================================================
final class UnknownElement extends TemplateElement {
  const UnknownElement({
    required super.id,
    required super.box,
    required this.raw,
    super.rotation,
  });

  final Map<String, dynamic> raw;

  String get typeName => '${raw['type'] ?? 'unknown'}';

  @override
  UnknownElement withBox(ElementBox box) =>
      UnknownElement(id: id, box: box, raw: raw, rotation: rotation);

  @override
  UnknownElement withRotation(double rotation) =>
      UnknownElement(id: id, box: box, raw: raw, rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        ...raw,
        'id': id,
        if (rotation != 0) 'rotation': rotation,
      };
}

/// قيمة تفيد "لم يُمرَّر" لتمييزها عن "مُرِّرت كـ null" في `copyWith`.
const Object _unset = Object();
