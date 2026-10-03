import 'dart:convert';
import 'dart:ui' show Rect;

import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import 'template_element.dart';

/// مقاسات الورق المدعومة (بالنقاط).
enum PaperSize {
  a4('a4', 'A4', 595.28, 841.89),
  a5('a5', 'A5', 419.53, 595.28);

  const PaperSize(this.jsonValue, this.labelAr, this.widthPt, this.heightPt);

  final String jsonValue;
  final String labelAr;

  /// العرض بالنقاط في الوضع الرأسي.
  final double widthPt;

  /// الارتفاع بالنقاط في الوضع الرأسي.
  final double heightPt;

  String get descriptionAr => '$labelAr (${widthPt.round()}×${heightPt.round()}pt)';

  static PaperSize fromJson(Object? value) {
    final String needle = '${value ?? 'a4'}'.trim().toLowerCase();
    return values.firstWhere(
      (PaperSize size) => size.jsonValue == needle,
      orElse: () => PaperSize.a4,
    );
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
    this.sampleData = const <String, String>{},
    this.assets = const <String, String>{},
    this.canvasWidth,
    this.canvasHeight,
    this.warnings = const <String>[],
  });

  final int schemaVersion;
  final PaperSize paperSize;
  final PageOrientation orientation;
  final String backgroundHex;
  final List<TemplateElement> elements;

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

  bool get isLandscape => orientation == PageOrientation.landscape;

  /// عرض الصفحة بالنقاط.
  double get pageWidthPt =>
      isLandscape ? paperSize.heightPt : paperSize.widthPt;

  /// ارتفاع الصفحة بالنقاط.
  double get pageHeightPt =>
      isLandscape ? paperSize.widthPt : paperSize.heightPt;

  /// عرض مساحة التصميم (وحدات التصميم = بكسل عند 96dpi).
  double get designWidth => canvasWidth ?? pageWidthPt * 96 / 72;

  /// ارتفاع مساحة التصميم.
  double get designHeight => canvasHeight ?? pageHeightPt * 96 / 72;

  /// معامل التحويل من وحدات التصميم إلى نقاط الطباعة (تحجيم موحّد يحفظ النِسب).
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
  /// **مصدر الحقيقة الوحيد** لتحويل الإحداثيات: يستخدمه محرّك الـ PDF، ويجب أن
  /// يطابقه عرض المحرر (‎`CanvasGeometry`‎) — كلاهما تقريب خطّي يحفظ النِسب من
  /// الزاوية العليا اليسرى. [box.width]/[box.height] = 0 يعني الامتداد (مقروء
  /// من المحرّك). الارتفاع الصفري يبقى صفراً ليقرّره المحرّك حسب نوع العنصر.
  Rect boxToPdfRect(ElementBox box) {
    final double left = offsetX + box.x * scale;
    final double top = offsetY + box.y * scale;
    final double width = box.width > 0 ? box.width * scale : pageWidthPt - left;
    final double height = box.height > 0 ? box.height * scale : 0;
    return Rect.fromLTWH(left, top, width, height);
  }

  /// عدد العناصر الفعلية القابلة للرسم.
  int get drawableElementCount => elements
      .where((TemplateElement element) => element is! UnknownElement)
      .length;

  /// هل يحتوي القالب على حقول ديناميكية (`{{...}}`)?
  bool get hasDynamicFields => elements.any(
        (TemplateElement element) =>
            (element is TextElement && element.hasDynamicFields) ||
            (element is QrElement && element.data.contains('{{')),
      );

  /// أسماء الحقول الديناميكية المستخدمة في القالب (تُستخدم لربط أعمدة Excel).
  Set<String> get fieldKeys {
    final Set<String> keys = <String>{};
    final RegExp pattern = _fieldPattern;
    for (final TemplateElement element in elements) {
      final String? payload = switch (element) {
        TextElement(:final String text) => text,
        QrElement(:final String data) => data,
        _ => null,
      };
      if (payload == null) continue;
      for (final RegExpMatch match in pattern.allMatches(payload)) {
        final String? key = match.group(1)?.trim();
        if (key != null && key.isNotEmpty) keys.add(key);
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
      warnings: warnings,
    );
  }

  // ==========================================================================
  //                              الكتابة
  // ==========================================================================

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schema_version': schemaVersion,
        'paper': paperSize.jsonValue,
        'orientation': orientation.dbValue,
        'background': backgroundHex,
        'canvas': <String, dynamic>{
          'width': designWidth,
          'height': designHeight,
          'unit': 'px',
        },
        'elements': elements
            .map((TemplateElement element) => element.toJson())
            .toList(),
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
  /// وهذا ما يستخدمه **المحرر** حتى يرى المصمّم الحقول غير المعبّأة بدل فراغ
  /// صامت، بينما التوليد الفعلي (PDF) يتركها فراغاً.
  String resolveFields(
    String raw,
    Map<String, String>? data, {
    bool keepUnknownTokens = false,
  }) {
    return raw.replaceAllMapped(_fieldPattern, (Match match) {
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
    Map<String, String>? sampleData,
    Map<String, String>? assets,
    double? canvasWidth,
    double? canvasHeight,
  }) {
    return TemplateDocument(
      schemaVersion: schemaVersion,
      paperSize: paperSize ?? this.paperSize,
      orientation: orientation ?? this.orientation,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      elements: elements ?? this.elements,
      sampleData: sampleData ?? this.sampleData,
      assets: assets ?? this.assets,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      warnings: warnings,
    );
  }
}
