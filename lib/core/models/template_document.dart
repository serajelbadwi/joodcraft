import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart' show immutable;

import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../gender/arabic_gender.dart';
import 'template_element.dart';

/// أبعاد دقيقة لمساحة التصميم تُخزَّن حين يختار المستخدم مقاساً مخصّصاً (بـ
/// السنتيمتر/المليمتر/البوصة) وتُحوَّل إلى نقاط عند التصدير. يبقى المحرك
/// مستخدماً لنقاط الطباعة بغض النظر عن الوحدة المحدّثة.
class CustomPageSize {
  const CustomPageSize({
    required this.width,
    required this.height,
    required this.unit,
  });

  final double width;
  final double height;
  final MeasurementUnit unit;

  /// عرض الصفحة بالنجوم في الوضع الرأسي (إشارة الاتجاه في PDF).
  double get widthPt => unit.toPoints(width);

  /// ارتفاع الصفحة بالنجوم في الوضع الرأسي.
  double get heightPT => unit.toPoints(height);

  /// عرض الصفحة بالنجوم في الوضع الأفقي (عند تدوير الورقة).
  double get landscapeWidthPt => heightPT;

  /// ارتفاع الصفحة بالنجوم في الوضع الأفقي.
  double get landscapeHeightPt => widthPt;

  CustomPageSize copyWith({
    double? width,
    double? height,
    MeasurementUnit? unit,
  }) =>
      CustomPageSize(
        width: width ?? this.width,
        height: height ?? this.height,
        unit: unit ?? this.unit,
      );
}

/// اتجاه تدرّج خلفية الورقة (مطابق لدلالة `LinearGradient` في اللوحة والـ PDF).
enum GradientDirection {
  vertical('vertical'),
  horizontal('horizontal'),
  diagonal('diagonal');

  const GradientDirection(this.jsonValue);

  final String jsonValue;

  static GradientDirection fromJson(Object? value) {
    final String needle = '${value ?? 'vertical'}'.trim().toLowerCase();
    return values.firstWhere(
      (GradientDirection direction) => direction.jsonValue == needle,
      orElse: () => GradientDirection.vertical,
    );
  }
}

/// تدرّج خلفية المستند: لونان واتجاه — بلا أي حزمة إضافية.
///
/// يُرسم في اللوحة بـ`LinearGradient` وفي الـ PDF بـ`pw.LinearGradient`، فما
/// يراه المستخدم هو ما يُطبع. اللونان بصيغة `#RRGGBB`.
@immutable
class BackgroundGradient {
  const BackgroundGradient({
    required this.startHex,
    required this.endHex,
    this.direction = GradientDirection.vertical,
  });

  final String startHex;
  final String endHex;
  final GradientDirection direction;

  BackgroundGradient copyWith({
    String? startHex,
    String? endHex,
    GradientDirection? direction,
  }) =>
      BackgroundGradient(
        startHex: startHex ?? this.startHex,
        endHex: endHex ?? this.endHex,
        direction: direction ?? this.direction,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'start': startHex,
        'end': endHex,
        'direction': direction.jsonValue,
      };

  static BackgroundGradient? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final String start = '${raw['start'] ?? raw['from'] ?? ''}'.trim();
    final String end = '${raw['end'] ?? raw['to'] ?? ''}'.trim();
    if (start.isEmpty || end.isEmpty) return null;
    return BackgroundGradient(
      startHex: start,
      endHex: end,
      direction: GradientDirection.fromJson(raw['direction'] ?? raw['dir']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BackgroundGradient &&
      other.startHex == startHex &&
      other.endHex == endHex &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(startHex, endHex, direction);
}

/// مقاسات الورق المدعومة (بالنقاط).
enum PaperSize {
  a4('a4', 'A4', 595.28, 841.89),
  a5('a5', 'A5', 419.53, 595.28),
  letter('letter', 'Letter', 612, 792),
  legal('legal', 'Legal', 612, 1008);

  const PaperSize(this.jsonValue, this.labelAr, this.widthPt, this.heightPt);

  final String jsonValue;
  final String labelAr;

  /// العرض بالنقاط في الوضع الرأسي.
  final double widthPt;

  /// الارتفاع بالنقاط في الوضع الرأسي.
  final double heightPt;

  /// الوصف العربي.
  String get descriptionAr => '$labelAr (${widthPt.round()}×${heightPt.round()}pt)';

  /// واردات وحدات قياس الصيغ عند الطباعة (باستخدام نقاط→v). يُنفذ كدالة مساعدة.
  static const Map<String, CustomPageSize> allPresets = <String, CustomPageSize>{
    'a4': CustomPageSize(width: 21.0, height: 29.7, unit: MeasurementUnit.cm),
    'a3': CustomPageSize(width: 29.7, height: 42.0, unit: MeasurementUnit.cm),
    'a5': CustomPageSize(width: 14.8, height: 21.0, unit: MeasurementUnit.cm),
    'letter': CustomPageSize(width: 8.5, height: 11.0, unit: MeasurementUnit.inch),
    'legal': CustomPageSize(width: 8.5, height: 14.0, unit: MeasurementUnit.inch),
    'a4_us': CustomPageSize(width: 8.5, height: 11.0, unit: MeasurementUnit.inch),
  };

  static PaperSize fromJson(Object? value) {
    final String needle = '${value ?? 'a4'}'.trim().toLowerCase();
    return values.firstWhere(
      (PaperSize size) => size.jsonValue == needle,
      orElse: () => PaperSize.a4,
    );
  }

  /// وارد الدخول المخصصة — معاودة تحويلها إلى نقاط بدقة الفاحصة.
  static CustomPageSize fromCustom(double width, double height, MeasurementUnit unit) {
    if (width <= 0 || height <= 0) {
      throw const AppException(
        AppErrorCode.customPageSize,
        message: 'الأبعاد المخصصة يجب أن تكون أرقاماً موجبة (وكبيراً من الصفر).',
      );
    }
    return CustomPageSize(width: width, height: height, unit: unit);
  }
}

/// مستند قالب كامل: الورق + الاتجاه + العناصر.
///
/// هذا النموذج هو المقابل الدقيق لحقل `layout_data` في جدول `templates`، وهو
/// المصدر الوحيد لمحرّك الـ PDF ومحرر القوالب (المرحلة 3).
class TemplateDocument {
  const TemplateDocument({
    required this.elements,
    this.schemaVersion = AppConstants.layoutSchemaVersion,
    this.paperSize = PaperSize.a4,
    this.orientation = PageOrientation.landscape,
    this.backgroundHex = '#FFFFFF',
    this.dpi = defaultDpi,
    this.resolutionUnit = ResolutionUnit.ppi,
    this.colorMode = DocumentColorMode.rgb,
    this.sampleData = const <String, String>{},
    this.assets = const <String, String>{},
    this.canvasWidth,
    this.canvasHeight,
    this.warnings = const <String>[],
    this.customPageSize,
    this.layers = const <String, ElementLayerState>{},
    this.backgroundGradient,
  });

  final int schemaVersion;
  final PaperSize paperSize;
  final CustomPageSize? customPageSize;
  final PageOrientation orientation;

  /// لون خلفية الورقة (يُستخدم عندما لا يوجد تدرّج).
  final String backgroundHex;

  /// دقّة الطباعة المستهدفة بالنقطة/بوصة — يحدّدها المستخدم في نافذة المستند
  /// الجديد (300 للطباعة، 72 للشاشة).
  ///
  /// تُمرَّر إلى محرّك الرسم فتُعاد بها الصور المضمّنة عند تلك الدقّة، أي إنها
  /// **دقّة فعلية** لا حقلاً معروضاً وحده.
  final int dpi;

  /// وحدة عرض [dpi] (PPI/PPCM) — طبقة عرض تُحوَّل عند الإدخال والعرض.
  final ResolutionUnit resolutionUnit;

  /// نمط لون المستند (RGB/CMYK) — نيّة طباعة تُحفظ مع القالب.
  final DocumentColorMode colorMode;

  /// تدرّج خلفية الورقة — يتقدّم على [backgroundHex] عند وجوده.
  ///
  /// يجعل جذر المستند خلفية قابلة للتحرير كاملة (لون مفرد أو تدرّج)، ويُصدَّر
  /// كما هو في الـ PDF، فالخلفية ليست مجرّد لون ثابت بعد الآن.
  final BackgroundGradient? backgroundGradient;

  final List<TemplateElement> elements;

  /// حالة الطبقات لكل عنصر (ظهور/قفل/مجموعة) بمفتاح معرّف العنصر.
  ///
  /// منفصلة عن العناصر نفسها كي تبقى القوالب القديمة بلا تغيير، وتكون نقطة
  /// حقيقة واحدة تقرأها اللوحة ومحرّك الطباعة ولوحة الطبقات معاً.
  final Map<String, ElementLayerState> layers;

  /// بيانات تجريبية تُستخدم في المعاينة عندما لا توجد بيانات حقيقية من Excel.
  final Map<String, String> sampleData;

  /// أصول مضمّنة على مستوى القالب: معرّف الأصل ← Base64 (بلا بادئة data URI).
  ///
  /// تُستخدم كنسخة احتياطية عند رسم إطار/شعار حُذف من مكتبة أصولي، فلا يخرج
  /// العنصر أبيض في الـ PDF. تُخزَّن مرة واحدة لكل معرّف (بخلاف `ImageElement.data`
  /// الذي يخصّ عنصراً بعينه).
  final Map<String, String> assets;

  /// أبعاد مساحة التصميم (اختيارية). عند غيابها تُشتق من مقاس الورق عند 96dpi.
  final double? canvasWidth;
  final double? canvasHeight;

  /// ملاحظات تحذيرية عند القراءة (عناصر مجهولة، إصدار قديم…).
  final List<String> warnings;

  // ==========================================================================
  //                              القياسات
  // ==========================================================================

  /// الدقّة الافتراضية للمستندات الجديدة (نقطة/بوصة).
  static const int defaultDpi = 300;

  /// هل الدقّة افتراضية (فلا تُكتب في الـ JSON)؟
  bool get hasDefaultDpi => dpi == defaultDpi;

  /// [dpi] بوحدة المستخدم المختارة ([resolutionUnit]).
  double get dpiInUnit => resolutionUnit.fromDpi(dpi.toDouble());

  bool get isLandscape => orientation == PageOrientation.landscape;

  /// عرض الصفحة بالنقاط — من المقاس المخصّص إن وُجد، وإلا من القياسي.
  ///
  /// هذا هو الرابط الذي يجعل الأبعاد المخصّصية (سم/بوصة) تنعكس فعلاً على
  /// اللوحة والطباعة معاً بدل أن تبقى حقولاً محفوظة بلا أثر.
  double get pageWidthPt {
    final CustomPageSize? custom = customPageSize;
    if (custom != null) {
      return isLandscape ? custom.landscapeWidthPt : custom.widthPt;
    }
    return isLandscape ? paperSize.heightPt : paperSize.widthPt;
  }

  /// ارتفاع الصفحة بالنقاط — من المقاس المخصّص إن وُجد، وإلا من القياسي.
  double get pageHeightPt {
    final CustomPageSize? custom = customPageSize;
    if (custom != null) {
      return isLandscape ? custom.landscapeHeightPt : custom.heightPT;
    }
    return isLandscape ? paperSize.widthPt : paperSize.heightPt;
  }

  /// المقاس المُسلَّم بالوحدة المحدَّثة — إما مقاساً قياسياً (الملف `paper`) أو
  /// مخصّصاً (الحقل `customPageSize`).
  CustomPageSize get resolvedPageSize =>
      customPageSize ??
          (PaperSize.allPresets.containsKey(paperSize.jsonValue)
              ? PaperSize.allPresets[paperSize.jsonValue]!
              : const CustomPageSize(width: 21.0, height: 29.7, unit: MeasurementUnit.cm));

  /// هل المقاس الحالي مخصّص (مُدخل بالسنتيمتر/البوصة) لا قياسياً؟
  bool get hasCustomSize => customPageSize != null;

  // ==========================================================================
  //                          حالة الطبقات
  // ==========================================================================

  ElementLayerState layerOf(String elementId) =>
      layers[elementId] ?? const ElementLayerState();

  bool isHidden(String elementId) => layerOf(elementId).hidden;
  bool isLocked(String elementId) => layerOf(elementId).locked;
  String? groupIdOf(String elementId) => layerOf(elementId).groupId;

  /// هل العنصر مرئي (يُرسم في اللوحة وفي الـ PDF)؟
  bool isVisible(TemplateElement element) => !isHidden(element.id);

  /// هل العنصر قابل للتحديد والتحريك من اللوحة؟
  bool isInteractive(TemplateElement element) =>
      layerOf(element.id).isInteractive;

  /// العناصر المرئية فقط (المخفي لا يُرسم ولا يُطبع).
  List<TemplateElement> get visibleElements => elements
      .where((TemplateElement element) => isVisible(element))
      .toList(growable: false);

  /// كل أعضاء المجموعة المنطقية [groupId] بترتيب الرسم.
  List<TemplateElement> elementsInGroup(String groupId) => elements
      .where((TemplateElement element) => groupIdOf(element.id) == groupId)
      .toList(growable: false);

  /// إضافة معرّف كل عضو في مجموعة [elementId] إلى [into] (بلا تكرار).
  void collectGroupMembers(String elementId, Set<String> into) {
    final String? group = groupIdOf(elementId);
    if (group == null) {
      into.add(elementId);
      return;
    }
    for (final TemplateElement member in elementsInGroup(group)) {
      into.add(member.id);
    }
  }

  /// نسخة بحالة طبقة عنصر واحد معدّلة — تُزيل المدخل إن صار افتراضياً.
  TemplateDocument withLayer(
    String elementId,
    ElementLayerState Function(ElementLayerState current) update,
  ) {
    final ElementLayerState next = update(layerOf(elementId));
    final Map<String, ElementLayerState> updated =
        Map<String, ElementLayerState>.from(layers);
    if (next == const ElementLayerState()) {
      updated.remove(elementId);
    } else {
      updated[elementId] = next;
    }
    return copyWith(layers: updated);
  }

  /// نسخة بحالة طبقات عدة عناصر (عملية جماعية واحدة = خطوة تراجع واحدة).
  TemplateDocument withLayers(
    Iterable<String> elementIds,
    ElementLayerState Function(ElementLayerState current) update,
  ) {
    final Map<String, ElementLayerState> updated =
        Map<String, ElementLayerState>.from(layers);
    for (final String id in elementIds) {
      final ElementLayerState next = update(updated[id] ?? const ElementLayerState());
      if (next == const ElementLayerState()) {
        updated.remove(id);
      } else {
        updated[id] = next;
      }
    }
    return copyWith(layers: updated);
  }

  /// دقّة مساحة التصميم (بكسل/بوصة): **وحدة تصميم واحدة = بكسل شاشة واحد
  /// عند 96 نقطة/بوصة**. كل إحداثيات العناصر ومقاسات خطوطها بهذه الوحدة.
  static const double designDpi = 96;

  /// معامل التحويل الموحّد (**Matrix Mapping**) من وحدة تصميم إلى نقطة طباعة:
  /// ‎72/96 = 0.75‎ نقطة لكل وحدة. وهو الجسر الوحيد بين الشاشة والورقة، فعند
  /// المقاس الافتراضي (الذي تُشتقّ منه مساحة التصميم) يساوي [scale] هذه القيمة
  /// تماماً ⇒ **تحويل 1:1** بلا تحجيم ولا إزاحة ولا إعادة حساب.
  static const double ptPerDesignUnit = 72 / designDpi;

  /// عرض مساحة التصميم (وحدات التصميم = بكسل عند [designDpi]).
  double get designWidth => canvasWidth ?? pageWidthPt * designDpi / 72;

  /// ارتفاع مساحة التصميم.
  double get designHeight => canvasHeight ?? pageHeightPt * designDpi / 72;

  /// معامل التحويل من وحدات التصميم إلى نقاط الطباعة.
  ///
  /// **هو التحويل المصفوفي الموحّد الوحيد**: تشابه (Similarity) واحد يطبَّق
  /// على كل شيء — موضع العنصر، أبعاد صندوقه، مقاس خطّه، سماكة إطاره، وحدود
  /// توهّجه — فلا يوجد مسار ثانٍ يعيد حساب الموضع أو المقاس فينحرف شيء عن
  /// الشاشة. وعند غياب حجم تصميم مخصّص يساوي [ptPerDesignUnit] بالضبط (لا
  /// تحجيم)، فالمعامل لا يفعّل شيئاً في المستندات العادية.
  double get scale {
    final double byWidth = pageWidthPt / designWidth;
    final double byHeight = pageHeightPt / designHeight;
    return byWidth < byHeight ? byWidth : byHeight;
  }

  /// إزاحة أفقية لتوسيط التصميم إن اختلفت النِسب.
  double get offsetX => (pageWidthPt - designWidth * scale) / 2;

  /// إزاحة رأسية لتوسيط التصميم إن اختلفت النِسب.
  double get offsetY => (pageHeightPt - designHeight * scale) / 2;

  /// تحويل صندوق من وحدات التصميم إلى مستطيل بنقاط الطباعة.
  ///
  /// **مصدر الحقيقة الوحيد** لتحويل الإحداثيات (ولا يُعاد حساب أي موضع في
  /// محرّك الـ PDF بعد هذه الدالة — لا للنصّ ولا للصور): يستخدمه محرّك الـ PDF،
  /// ويجب أن يطابقه عرض المحرر (`CanvasGeometry`) — كلاهما نفس التحويل الخطّي
  /// من الزاوية العليا اليسرى. [box.width]/[box.height] = 0 يعني الامتداد
  /// (مقروء من المحرّك). الارتفاع الصفري يبقى صفراً ليقرّره المحرّك حسب نوع
  /// العنصر.
  Rect boxToPdfRect(ElementBox box) {
    final double left = offsetX + box.x * scale;
    final double top = offsetY + box.y * scale;
    final double width = box.width > 0 ? box.width * scale : pageWidthPt - left;
    final double height = box.height > 0 ? box.height * scale : 0;
    return Rect.fromLTWH(left, top, width, height);
  }

  // ==========================================================================
  //                    إعادة التخطيط التلقائي (تجاوب المقاس/الاتجاه)
  // ==========================================================================

  /// نسخة **معاد تخطيطها** بعد تغيير الاتجاه و/أو مقاس الورق.
  ///
  /// هذا هو محرّك «التجاوب التلقائي»: عند تبديل الاتجاه (عرضي↔طولي) أو تغيير
  /// المقاس (A4/Letter/A5…) تُحدَّث أبعاد مساحة التصميم فوراً، ويُحجَّم كل عنصر
  /// محورياً ليمتلئ المقاس الجديد بلا فراغات ولا خروج عن الحدود — فالنصّ والإطار
  /// والختم والتوقيع ورمز الـ QR يعيدون التوزيع معاً بدل أن تبقى إحداثياتهم على
  /// المقاس القديم فتنكسر التركيبة.
  ///
  /// القاعدة:
  /// * `sx = العرض الجديد / العرض القديم` و `sy = الارتفاع الجديد / الارتفاع القديم`
  ///   (تحويل محوري مستقلّ يملأ الصفحة كاملةً).
  /// * أدوات الحجم تُقاس بالمتوسط الهندسي `sqrt(sx·sy)` فيبقى النص مقروءاً عند
  ///   تبديل الاتجاه (تحويل متساوٍ بالمساحة) ويتحجّم بنسبة موحّدة عند تغيير المقاس.
  /// * مساحة التصميم تُعاد ضبطها على أبعاد الصفحة الجديدة (بالبكسل عند 96dpi)
  ///   فتبقى إزاحات التوسيط صفراً ويتطابق المحرّر مع الـ PDF.
  TemplateDocument refit({
    PageOrientation? orientation,
    PaperSize? paperSize,
    Object? customPageSize = _unset,
  }) {
    final TemplateDocument target = copyWith(
      orientation: orientation,
      paperSize: paperSize,
      customPageSize: customPageSize,
    );

    final double oldWidth = designWidth;
    final double oldHeight = designHeight;
    final double newWidth = target.pageWidthPt * 96 / 72;
    final double newHeight = target.pageHeightPt * 96 / 72;

    // مقاس غير صالح أو بلا تغيير فعلي ⇒ تحديث الحدود فقط بلا تحجيم.
    if (oldWidth <= 0 ||
        oldHeight <= 0 ||
        newWidth <= 0 ||
        newHeight <= 0) {
      return target.copyWith(canvasWidth: newWidth, canvasHeight: newHeight);
    }

    final double sx = newWidth / oldWidth;
    final double sy = newHeight / oldHeight;
    final bool unchanged =
        (sx - 1).abs() < 1e-9 && (sy - 1).abs() < 1e-9;
    if (unchanged) {
      return target.copyWith(canvasWidth: newWidth, canvasHeight: newHeight);
    }

    final double fontScale = math.sqrt(sx * sy);
    final List<TemplateElement> resized = <TemplateElement>[
      for (final TemplateElement element in elements)
        element.reflow(sx: sx, sy: sy, fontScale: fontScale),
    ];
    return target.copyWith(
      elements: resized,
      canvasWidth: newWidth,
      canvasHeight: newHeight,
    );
  }

  /// عدد العناصر الفعلية القابلة للرسم.
  int get drawableElementCount => elements
      .where((TemplateElement element) => element is! UnknownElement)
      .length;

  /// هل يحتوي القالب على حقول ديناميكية (`{{...}}`)?
  bool get hasDynamicFields => elements.any(
        (TemplateElement element) =>
            (element is TextElement && element.hasDynamicFields) ||
            (element is QrElement && element.data.contains('{{')) ||
            (element is SignatureElement && element.hasDynamicFields),
      );

  /// أسماء الحقول الديناميكية المستخدمة في القالب (تُستخدم لربط أعمدة Excel).
  Set<String> get fieldKeys {
    final Set<String> keys = <String>{};
    final RegExp pattern = _fieldPattern;
    for (final TemplateElement element in elements) {
      final String? payload = switch (element) {
        TextElement(:final String text) => text,
        QrElement(:final String data) => data,
        // أدوار التوقيعات وأسماء أصحابها قد تحمل حقولاً ديناميكية أيضاً
        // (مثل اسم المتدرّب في توقيع المدرب) فتُربط بأعمدة Excel كغيرها.
        SignatureElement() => element.slots
            .map((SignatureSlot slot) => '${slot.role} ${slot.name}')
            .join(' '),
        _ => null,
      };
      if (payload == null) continue;
      for (final RegExpMatch match in pattern.allMatches(payload)) {
        final String? key = match.group(1)?.trim();
        if (key == null || key.isEmpty) continue;
        // الصيغة الشرطية `{{الجنس: ذكر | أنثى}}` ليست حقلاً يُربط بعمود Excel:
        // جنسها يُحلّ تلقائياً من الاسم أو من عمود الجنس الصريح.
        if (GenderGrammar.isConditionInner(key)) continue;
        keys.add(key);
      }
    }
    return keys;
  }

  static final RegExp _fieldPattern = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

  // ==========================================================================
  //                              القراءة
  // ==========================================================================

  factory TemplateDocument.fromJsonString(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (error) {
      throw AppException(
        AppErrorCode.templateFormat,
        message: 'ملف القالب ليس JSON صالحاً: $error',
        cause: error,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AppException(
        AppErrorCode.templateFormat,
        message: 'بنية القالب يجب أن تكون كائناً JSON في الجذر.',
      );
    }
    return TemplateDocument.fromJson(decoded);
  }

  factory TemplateDocument.fromJson(Map<String, dynamic> json) {
    final List<String> warnings = <String>[];

    final int schemaVersion = switch (json['schema_version']) {
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 1,
      _ => 1,
    };
    if (schemaVersion > AppConstants.layoutSchemaVersion) {
      throw AppException(
        AppErrorCode.unsupportedSchema,
        message: 'إصدار القالب ($schemaVersion) أحدث من إصدار المحرك المدعوم '
            '(${AppConstants.layoutSchemaVersion}). حدّث التطبيق لفتح هذا القالب.',
      );
    }
    if (!json.containsKey('schema_version')) {
      warnings.add('القالب لا يحتوي schema_version — تم افتراض الإصدار 1.');
    }

    final Map<String, dynamic> canvas =
        (json['canvas'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final PageOrientation orientation = switch (
        '${json['orientation'] ?? canvas['orientation'] ?? 'landscape'}'
            .trim()
            .toLowerCase()) {
      'portrait' => PageOrientation.portrait,
      _ => PageOrientation.landscape,
    };

    final Object? rawElements = json['elements'];
    final List<Map<String, dynamic>> elementMaps = rawElements is List
        ? rawElements
            .whereType<Map>()
            .map((Map<dynamic, dynamic> e) => e.cast<String, dynamic>())
            .toList()
        : <Map<String, dynamic>>[];
    if (rawElements is! List) {
      warnings.add('لا توجد قائمة عناصر (elements) في القالب.');
    }

    final List<TemplateElement> elements = <TemplateElement>[];
    for (int i = 0; i < elementMaps.length; i++) {
      final TemplateElement element =
          TemplateElement.fromJson(elementMaps[i], i);
      if (element is UnknownElement) {
        warnings.add(
          'عنصر بنوع غير معروف "${element.typeName}" تم الحفاظ عليه دون رسم.',
        );
      }
      elements.add(element);
    }

    final Map<String, String> sampleData = <String, String>{};
    final Object? rawSample = json['sample_data'] ?? json['data'];
    if (rawSample is Map) {
      rawSample.forEach((Object? key, Object? value) {
        if (key == null || value == null) return;
        sampleData['$key'] = '$value';
      });
    }

    return TemplateDocument(
      schemaVersion: schemaVersion,
      paperSize: PaperSize.fromJson(json['paper'] ?? canvas['paper']),
      orientation: orientation,
      backgroundHex: '${json['background'] ?? '#FFFFFF'}',
      dpi: switch (json['dpi']) {
        final num value when value > 0 => value.round(),
        final String value => int.tryParse(value) ?? defaultDpi,
        _ => defaultDpi,
      },
      resolutionUnit: ResolutionUnit.fromJson(json['resolution_unit']),
      colorMode: DocumentColorMode.fromJson(json['color_mode']),
      elements: elements,
      sampleData: sampleData,
      assets: _readAssets(json['assets']),
      canvasWidth: switch (canvas['width']) {
        final num value when value > 0 => value.toDouble(),
        _ => null,
      },
      canvasHeight: switch (canvas['height']) {
        final num value when value > 0 => value.toDouble(),
        _ => null,
      },
      customPageSize: switch (canvas['paperSize']) {
        final Map<String, dynamic> psz when psz.containsKey('width') && psz.containsKey('height') && psz.containsKey('unit') =>
          CustomPageSize(
            width: psz['width']?.toDouble() ?? 0,
            height: psz['height']?.toDouble() ?? 0,
            unit: MeasurementUnit.fromJson(psz['unit']),
          ),
        _ => null,
      },
      warnings: warnings,
      backgroundGradient: BackgroundGradient.fromJson(json['gradient']),
      layers: _readLayers(json['layers']),
    );
  }

  /// قراءة حالة الطبقات (ظهور/قفل/مجموعة) مع تجاهل المداخل الفارغة.
  static Map<String, ElementLayerState> _readLayers(Object? raw) {
    if (raw is! Map) return const <String, ElementLayerState>{};
    final Map<String, ElementLayerState> layers =
        <String, ElementLayerState>{};
    raw.forEach((Object? key, Object? value) {
      final String id = '${key ?? ''}'.trim();
      if (id.isEmpty) return;
      final ElementLayerState state = ElementLayerState.fromJson(value);
      if (state == const ElementLayerState()) return;
      layers[id] = state;
    });
    return layers;
  }

  // ==========================================================================
  //                              الكتابة
  // ==========================================================================

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schema_version': schemaVersion,
        'paper': paperSize.jsonValue,
        'orientation': orientation.dbValue,
        'background': backgroundHex,
        // الحقول الافتراضية لا تُكتب: تبقى قوالب ما قبل هذه الحقول بنفس
        // التوقيع بايتاً ببايت، فلا ينكسر أي ترحيل أو مقارنة قديمة.
        if (dpi != defaultDpi) 'dpi': dpi,
        if (resolutionUnit != ResolutionUnit.ppi)
          'resolution_unit': resolutionUnit.jsonValue,
        if (colorMode != DocumentColorMode.rgb) 'color_mode': colorMode.jsonValue,
        if (backgroundGradient != null)
          'gradient': backgroundGradient!.toJson(),
        'canvas': <String, dynamic>{
          'width': designWidth,
          'height': designHeight,
          'unit': 'px',
          if (customPageSize != null)
            'paperSize': <String, dynamic>{
              'width': customPageSize!.width,
              'height': customPageSize!.height,
              'unit': customPageSize!.unit.jsonValue,
            }
        },
        'elements': elements
            .map((TemplateElement element) => element.toJson())
            .toList(),
        if (layers.isNotEmpty)
          'layers': <String, dynamic>{
            for (final MapEntry<String, ElementLayerState> entry
                in layers.entries)
              entry.key: entry.value.toJson(),
          },
        if (sampleData.isNotEmpty) 'sample_data': sampleData,
        if (assets.isNotEmpty) 'assets': assets,
      };

  /// قراءة خريطة الأصول المضمّنة (‎assetId ← Base64‎) مع تجاهل القيم الفارغة.
  static Map<String, String> _readAssets(Object? raw) {
    if (raw is! Map) return const <String, String>{};
    final Map<String, String> assets = <String, String>{};
    raw.forEach((Object? key, Object? value) {
      if (key == null || value is! String) return;
      final String id = '$key'.trim();
      final String data = value.trim();
      if (id.isEmpty || data.isEmpty) return;
      assets[id] = data;
    });
    return assets;
  }

  // ==========================================================================
  //                              الحقول الديناميكية
  // ==========================================================================

  /// استبدال الحقول `{{key}}` بالقيم، مع الرجوع إلى `sampleData` ثم إلى فراغ.
  ///
  /// [keepUnknownTokens] يبقي الصيغة `{{key}}` كما هي عندما لا توجد قيمة —
  /// وهو ما يستخدمه **المحرر** حتى يرى المصمّم الحقول غير المعبّأة بدل فراغ
  /// صامت، بينما التوليد الفعلي (PDF) يتركها فراغاً.
  ///
  /// [gender] يُحلّ به كل صيغة شرطية `{{الجنس: ذكر | أنثى}}`: إن كان `null`
  /// يُستنتج من عمود الجنس في [data] (أو `sampleData`) وإلا من الاسم، وإلا
  /// يُرجع إلى **المذكّر** (الفرع الأول) — لا تخرج صيغة أنثوية بالخطأ أبداً.
  String resolveFields(
    String raw,
    Map<String, String>? data, {
    bool keepUnknownTokens = false,
    Gender? gender,
  }) {
    String resolved = raw;
    // حلّ الصيغ الشرطية أولاً وقبل كل شيء: هي تحتوي `|` و`{{` معاً فلو مرّت
    // على مُطابِق الحقول لاعتُبرت حقلاً باسم «الجنس: …».
    if (resolved.contains('|') && GenderGrammar.containsCondition(resolved)) {
      final Gender effective =
          gender ?? GenderResolver.resolve(data, fallback: sampleData);
      resolved = GenderGrammar.apply(resolved, effective);
    }
    if (!resolved.contains('{{')) return resolved;
    return resolved.replaceAllMapped(_fieldPattern, (Match match) {
      final String key = match.group(1)?.trim() ?? '';
      final String? value = data?[key] ?? sampleData[key];
      if (value != null) return value;
      return keepUnknownTokens ? match.group(0)! : '';
    });
  }

  TemplateDocument copyWith({
    List<TemplateElement>? elements,
    PaperSize? paperSize,
    PageOrientation? orientation,
    String? backgroundHex,
    int? dpi,
    ResolutionUnit? resolutionUnit,
    DocumentColorMode? colorMode,
    Map<String, String>? sampleData,
    Map<String, String>? assets,
    double? canvasWidth,
    double? canvasHeight,
    Object? customPageSize = _unset,
    Object? backgroundGradient = _unset,
    Map<String, ElementLayerState>? layers,
  }) =>
      TemplateDocument(
        schemaVersion: schemaVersion,
        paperSize: paperSize ?? this.paperSize,
        orientation: orientation ?? this.orientation,
        backgroundHex: backgroundHex ?? this.backgroundHex,
        dpi: dpi ?? this.dpi,
        resolutionUnit: resolutionUnit ?? this.resolutionUnit,
        colorMode: colorMode ?? this.colorMode,
        backgroundGradient: backgroundGradient == _unset
            ? this.backgroundGradient
            : backgroundGradient as BackgroundGradient?,
        sampleData: sampleData ?? this.sampleData,
        assets: assets ?? this.assets,
        canvasWidth: canvasWidth ?? this.canvasWidth,
        canvasHeight: canvasHeight ?? this.canvasHeight,
        customPageSize: customPageSize == _unset
            ? this.customPageSize
            : customPageSize as CustomPageSize?,
        layers: layers ?? this.layers,
        elements: elements ?? this.elements,
        warnings: warnings,
      );
}

/// قيمة «غير مُمرَّرة» للتفريق بين تمرير `null` صراحةً وعدم التمرير.
const Object _unset = Object();
