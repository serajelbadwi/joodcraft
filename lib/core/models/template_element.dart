import 'dart:math' as math;

import '../pdf/pdf_font_catalog.dart';
import 'decoration.dart';

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
      'line' || 'divider' => ShapeElement.fromJson(json, id, ShapeKind.line),
      'seal' || 'stamp' => SealElement.fromJson(json, id),
      'decoration' || 'decor' || 'ornament' =>
        DecorationElement.fromJson(json, id),
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

  static TextElement fromJson(Map<String, dynamic> json, String id) {
    double num_(String key, double fallback) {
      final Object? value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    return TextElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      text: '${json['text'] ?? json['value'] ?? ''}',
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
  }) {
    return TextElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
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
        if (rotation != 0) 'rotation': rotation,
      };
}

// ===========================================================================
//  الأشكال
// ===========================================================================
enum ShapeKind { rect, ellipse, line }

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
    this.opacity = 1,
  });

  final ShapeKind kind;
  final String? fillHex;
  final String? strokeHex;
  final double strokeWidth;

  /// نصف قطر الزوايا (للمستطيل).
  final double radius;
  final double opacity;

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

    return ShapeElement(
      id: id,
      box: ElementBox.fromJson(json),
      rotation: TemplateElement.readRotation(json),
      kind: kind,
      fillHex: json['fill'] as String?,
      strokeHex: json['stroke'] as String?,
      strokeWidth: num_('strokeWidth', kind == ShapeKind.line ? 1 : 0),
      radius: num_('radius', 0),
      opacity: num_('opacity', 1),
    );
  }

  ShapeElement copyWith({
    ElementBox? box,
    double? rotation,
    Object? fillHex = _unset,
    Object? strokeHex = _unset,
    double? strokeWidth,
    double? radius,
    double? opacity,
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
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  ShapeElement withBox(ElementBox box) => copyWith(box: box);

  @override
  ShapeElement withRotation(double rotation) => copyWith(rotation: rotation);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': switch (kind) {
          ShapeKind.rect => 'rect',
          ShapeKind.ellipse => 'ellipse',
          ShapeKind.line => 'line',
        },
        ...box.toJson(),
        if (fillHex != null) 'fill': fillHex,
        if (strokeHex != null) 'stroke': strokeHex,
        if (strokeWidth != 0) 'strokeWidth': strokeWidth,
        if (radius != 0) 'radius': radius,
        if (opacity != 1) 'opacity': opacity,
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

final class ImageElement extends TemplateElement {
  const ImageElement({
    required super.id,
    required super.box,
    required this.sourceKind,
    required this.path,
    super.rotation,
    this.fit = ImageFit.contain,
    this.opacity = 1,
    this.data,
  });

  final ImageSourceKind sourceKind;
  final String path;
  final ImageFit fit;
  final double opacity;

  /// نسخة Base64 مضمّنة من الصورة (بلا بادئة data URI).
  ///
  /// **نسخة احتياطية**: تُكتب عند إدراج أصل من مكتبة أصولي حتى يبقى الإطار
  /// قابلاً للرسم في الـ PDF حتى لو حُذف الأصل من المكتبة لاحقاً. الأولوية
  /// تبقى للمرجع الحيّ ([path]) ما دام الأصل موجوداً، وهذا حقل ناجع عند فقده.
  final String? data;

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
      data: embedded,
    );
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
    Object? data = _unset,
  }) {
    return ImageElement(
      id: id,
      box: box ?? this.box,
      rotation: rotation ?? this.rotation,
      sourceKind: sourceKind ?? this.sourceKind,
      path: path ?? this.path,
      fit: fit ?? this.fit,
      opacity: opacity ?? this.opacity,
      data: data == _unset ? this.data : data as String?,
    );
  }

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
