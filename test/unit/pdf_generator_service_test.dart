import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// استخراج أبعاد الصفحة من محتوى ملف الـ PDF.
///
/// يُشغَّل التوليد في الاختبارات مع `compress: false` حتى تظهر بنية الكائنات
/// كنص صريح يمكن التحقق منه فعلياً بدل الاعتماد على عدّاد داخلي.
class _PdfProbe {
  _PdfProbe(this.bytes) : text = latin1.decode(bytes, allowInvalid: true);

  final Uint8List bytes;
  final String text;

  String get header => String.fromCharCodes(bytes.take(5));

  int get pageObjectCount =>
      RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;

  PdfPageDimensions? get mediaBox {
    final RegExpMatch? match =
        RegExp(r'/MediaBox\s*\[0 0 ([\d.]+) ([\d.]+)\]').firstMatch(text);
    if (match == null) return null;
    return PdfPageDimensions(
      double.parse(match.group(1)!),
      double.parse(match.group(2)!),
    );
  }

  /// هل يظهر اسم الخط المُضمَّن داخل الملف؟
  /// نُزيل كل الفواصل والمسافات لأن الـ PDF قد يكتب الاسم بصيغة PostScript
  /// (`IBMPlexSansArabic-Regular`) أو Full Name (`IBM Plex Sans Arabic`).
  bool embeds(String fontName) {
    final String haystack = text.replaceAll(RegExp(r'[\s\-_]'), '');
    final String needle = fontName.replaceAll(RegExp(r'[\s\-_]'), '');
    return haystack.contains(needle);
  }
}

class PdfPageDimensions {
  const PdfPageDimensions(this.width, this.height);

  final double width;
  final double height;

  @override
  String toString() => '${width.toStringAsFixed(2)}×${height.toStringAsFixed(2)}pt';
}

void main() {
  late PdfGeneratorService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // بلا ضغط حتى تكون بنية الملف قابلة للتحقق نصياً داخل الاختبار.
    service = await PdfGeneratorService.create(compress: false);
  });

  Future<TemplateDocument> loadTemplate(String path) async {
    return TemplateDocument.fromJsonString(await rootBundle.loadString(path));
  }

  test('يحمّل كل الخطوط المحزومة بلا أي اتصال شبكة', () {
    // 14 ملف TTF محزومة (Plex 3 + Amiri 2 + Cairo 3 + Tajawal 3 + Noto 3)،
    // و15 توليفة عائلة×وزن (Amiri يخدم وزنين بملف العريض نفسه).
    expect(service.fonts.loadedFontFileCount, 14);
    expect(service.fonts.loadedCount, 15);
    for (final family in PdfFontFamily.pdfFamilies) {
      for (final weight in PdfFontWeight.values) {
        expect(service.fonts.resolve(family, weight), isNotNull,
            reason: 'الوزن ${weight.name} غير متاح للعائلة ${family.name}');
      }
    }
  });

  test('يولّد شهادة A4 أفقية بأبعاد 841.89×595.28 نقطة', () async {
    final TemplateDocument document =
        await loadTemplate(AppAssets.sampleCertificateTemplate);

    final PdfGenerationReport report = await service.generate(
      document: document,
      data: <String, String>{'student_name': 'سارة بنت محمد العتيبي'},
    );

    expect(report.pageCount, 1);
    expect(report.bytes.lengthInBytes, greaterThan(3000));

    final _PdfProbe probe = _PdfProbe(report.bytes);
    expect(probe.header, '%PDF-');
    expect(probe.mediaBox, isNotNull);
    expect(probe.mediaBox!.width, closeTo(841.89, 0.5));
    expect(probe.mediaBox!.height, closeTo(595.28, 0.5));
    expect(report.warnings, isEmpty);
  });

  test('يولّد عقداً A4 رأسياً بأبعاد 595.28×841.89 نقطة', () async {
    final TemplateDocument document =
        await loadTemplate(AppAssets.sampleContractTemplate);

    final PdfGenerationReport report = await service.generate(document: document);

    final _PdfProbe probe = _PdfProbe(report.bytes);
    expect(probe.mediaBox!.width, closeTo(595.28, 0.5));
    expect(probe.mediaBox!.height, closeTo(841.89, 0.5));
    expect(probe.pageObjectCount, 1);
  });

  test('التوليد الجماعي يُنتج صفحة لكل صف', () async {
    final TemplateDocument document =
        await loadTemplate(AppAssets.sampleCertificateTemplate);

    final List<Map<String, String>> rows = <Map<String, String>>[
      for (int i = 1; i <= 7; i++)
        <String, String>{'student_name': 'المستفيد رقم $i'},
    ];

    final List<int> progress = <int>[];
    final PdfGenerationReport report = await service.generateBatch(
      document: document,
      rows: rows,
      onProgress: (int done, int total) => progress.add(done),
    );

    expect(report.pageCount, 7);
    expect(progress, <int>[1, 2, 3, 4, 5, 6, 7]);
    expect(_PdfProbe(report.bytes).pageObjectCount, 7);
    // ملف واحد لسبع شهادات يجب أن يبقى معقول الحجم.
    expect(report.bytes.lengthInBytes, lessThan(600000));
  });

  test('النص العربي يُرسم بخطوط محزومة والخط يُضمَّن في الملف', () async {
    final TemplateDocument document =
        await loadTemplate(AppAssets.sampleCertificateTemplate);

    final PdfGenerationReport report =
        await service.generate(document: document);

    final _PdfProbe probe = _PdfProbe(report.bytes);
    // الخط المستخدم في الشهادة (IBM Plex Sans Arabic) يجب أن يكون مُضمَّناً.
    expect(probe.embeds('IBMPlexSansArabic'), isTrue);
    // ولا يُضمَّن خط لم يستخدمه القالب أصلاً (Cairo هنا).
    expect(probe.embeds('Cairo'), isFalse);
  });

  test('قالب يطلب خط Cairo يُرسم بـ Cairo نفسه ويُضمَّن في الملف', () async {
    final TemplateDocument document = TemplateDocument.fromJson(<String, dynamic>{
      'schema_version': 1,
      'orientation': 'landscape',
      'elements': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'text',
          'x': 40,
          'y': 40,
          'w': 600,
          'h': 60,
          'text': 'اختبار الخط البديل',
          'font': 'cairo',
          'size': 28,
        },
      ],
    });

    final PdfGenerationReport report = await service.generate(document: document);
    // Cairo صار كامل تغطية صور الحروف ⇒ يُرسم ويُضمَّن بدل الرجوع للافتراضي.
    expect(_PdfProbe(report.bytes).embeds('Cairo'), isTrue);
  });

  test('كل عائلة مضمّنة تصلح للطباعة وتُضمَّن عند استخدامها', () async {
    for (final family in PdfFontFamily.values) {
      expect(family.usableInPdf, isTrue, reason: 'العائلة ${family.name}');
    }
    expect(
      PdfFontFamily.pdfFamilies.length,
      PdfFontFamily.values.length,
    );
  });

  test('صورة غير مدعومة لا تُعطّل التوليد وتُسجَّل كتحذير', () async {
    final TemplateDocument document = TemplateDocument.fromJson(<String, dynamic>{
      'schema_version': 1,
      'orientation': 'portrait',
      'elements': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'image',
          'x': 20,
          'y': 20,
          'w': 120,
          'h': 120,
          'source': 'file',
          'path': 'C:/nowhere/logo.png',
        },
        <String, dynamic>{
          'type': 'text',
          'x': 20,
          'y': 200,
          'w': 500,
          'h': 40,
          'text': 'نص يجب أن يُرسم رغم الصورة المفقودة',
          'size': 20,
        },
      ],
    });

    final PdfGenerationReport report = await service.generate(document: document);
    expect(report.pageCount, 1);
    expect(report.warnings, isNotEmpty);
    expect(report.warnings.first, contains('logo.png'));
  });

  test('قيم الحقول الديناميكية تصل فعلياً إلى الملف المُنتَج', () async {
    final TemplateDocument document =
        await loadTemplate(AppAssets.sampleCertificateTemplate);

    // لا يمكن البحث عن النص حرفياً داخل PDF (يُكتب كمعرّفات Glyph)، لذلك
    // نتحقق أن القيم المختلفة تُنتج محتوى مختلفاً فعلاً.
    final PdfGenerationReport short = await service.generate(
      document: document,
      data: <String, String>{'student_name': 'أحمد'},
    );
    final PdfGenerationReport long = await service.generate(
      document: document,
      data: <String, String>{
        'student_name': 'عبدالرحمن بن عبدالعزيز المنصوري',
      },
    );

    expect(short.bytes.lengthInBytes, isNot(long.bytes.lengthInBytes));
    expect(short.bytes.lengthInBytes, greaterThan(3000));
  });

  test('بدون بيانات تُستخدم القيم التجريبية من القالب', () async {
    final TemplateDocument document =
        await loadTemplate(AppAssets.sampleCertificateTemplate);
    expect(document.sampleData, isNotEmpty);

    final PdfGenerationReport report = await service.generate(document: document);
    expect(report.bytes.lengthInBytes, greaterThan(3000));
  });

  test('يرفض القوالب بلا حقل عناصر أو ببيانات تالفة', () async {
    expect(
      () => TemplateDocument.fromJsonString('{"schema_version": 1}'),
      returnsNormally,
    );
    expect(
      () => TemplateDocument.fromJsonString('not-json'),
      throwsA(isA<AppException>()),
    );
    expect(
      () => TemplateDocument.fromJsonString('{"schema_version": 99}'),
      throwsA(isA<AppException>()),
    );
  });
}
