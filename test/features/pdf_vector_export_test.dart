import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_export_type.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';
import 'package:joodcraft/core/services/pdf_generator_service.dart';

/// مقارنة **محرّكي التصدير** على القالب نفسه تماماً:
///
/// | | صور (Raster) | فيكتور (Vector) |
/// |---|---|---|
/// | طريقة الرسم | صورة PNG كاملة لكل صفحة | أوامر مسار + محارف |
/// | النص داخل الملف | جزء من الصورة فلا يُنسخ | محرّف حقيقي (`/Font`) |
/// | الحجم | يعتمد على دقّة الصورة | يعتمد على الخطوط المضمّنة |
///
/// يُثبت الاختبار أن خيار **الفيكتور يعمل فعلاً** وأنه ليس اسمًا فقط:
///
/// 1. الملف المتجه يحوي كائنات `/Font` ومخطّط `/ToUnicode` — أي نصّاً حقيقياً
///    قابلاً للنسخ والبحث.
/// 2. الملف المتجه **بلا صورة صفحة** (`/Subtype /Image`) بينما النقطي بها.
/// 3. الملفان يبدأان بـ`%PDF` وكلاهما صالح.
///
/// الحجم الفعلي يُطبع فقط (`debugPrint`) لا يُفهرس عليه: هو تابع لمحتوى
/// القالب والخط المستخدم (تُضمَّن خطوط PDF كاملة بلا تقسيم في `pdf` 3.12)،
/// فلا معنى لتثبيت رقم موحّد هنا.
void main() {
  // الخطوط تُخزَّن مؤقتاً كـ Future مرتبط بالنطاق الزمني (zone)؛ تصفيرها
  // يمنع تسرّب كاش من اختبار آخر.
  setUp(PdfFontSet.resetCache);
  tearDown(PdfFontSet.resetCache);

  TemplateDocument document() => TemplateDocument(
    orientation: PageOrientation.landscape,
    elements: const <TemplateElement>[
      TextElement(
        id: 'title',
        box: ElementBox(x: 120, y: 90, width: 880, height: 120),
        text: 'شهادة إتمام دورة',
        fontSize: 44,
        weight: PdfFontWeight.bold,
        colorHex: '#8B6914',
      ),
      TextElement(
        id: 'name',
        box: ElementBox(x: 120, y: 260, width: 880, height: 90),
        text: 'تُمنح هذه الشهادة إلى: سارة أحمد',
        fontSize: 28,
        colorHex: '#1B2539',
      ),
      TextElement(
        id: 'body',
        box: ElementBox(x: 120, y: 380, width: 880, height: 180),
        text: 'لاتمام متطلبات البرنامج بنجاح وامتياز.',
        fontSize: 20,
        colorHex: '#333333',
      ),
      TextElement(
        id: 'date',
        box: ElementBox(x: 120, y: 620, width: 400, height: 60),
        text: 'التاريخ: 2026/10/10',
        fontSize: 16,
        weight: PdfFontWeight.semiBold,
        colorHex: '#555555',
      ),
    ],
  );

  const Map<String, String> row = <String, String>{};

  /// ترميز لاتيني صغير لقياس حجم «المحتوى» المجرّد من البايتات غير القابلة
  /// للبحث (خطوط PDF مضغوطة/مصوّرة) — أي النصّ الذي لا يُنسخ.
  String latinOnly(Uint8List bytes) => String.fromCharCodes(
    bytes.where((int b) => b >= 0x20 && b < 0x7F),
  );

  testWidgets(
    'الفيكتور يولّد ملفاً نصّه قابلاً للنسخ بلا صورة صفحة، والنقطي بعكسه',
    (WidgetTester tester) async {
      // محاذاة أرضية كما في التطبيق: المعاينة تُبنى داخل `MaterialApp` كاملة.
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      final PdfFontSet? fonts = await tester.runAsync(() => PdfFontSet.load());
      expect(fonts, isNotNull, reason: 'تعذّر تحميل الخطوط في الاختبار');
      final PdfGeneratorService service = PdfGeneratorService(fonts: fonts!);

      final PdfGenerationReport? raster = await tester.runAsync(
        () => service.generate(document: document(), data: row),
      );
      final PdfGenerationReport? vector = await tester.runAsync(
        () => service.exportVector(document: document(), data: row),
      );
      // معامل `type:` في `generate` يسلك المسار ذاته — فلا طريقان مختلفان
      // للـفيكتور في الخدمة.
      final PdfGenerationReport? viaTypeParameter = await tester.runAsync(
        () => service.generate(
          document: document(),
          data: row,
          type: PdfExportType.vector,
        ),
      );
      expect(raster, isNotNull, reason: 'فشل توليد ملف «صور»');
      expect(vector, isNotNull, reason: 'فشل توليد ملف «فيكتور»');

      final Uint8List rasterBytes = raster!.bytes;
      final Uint8List vectorBytes = vector!.bytes;

      // ── 1. الملفان صالحان ────────────────────────────────────────────────
      expect(
        String.fromCharCodes(rasterBytes.sublist(0, 5)),
        '%PDF-',
        reason: 'ملف «صور» ليس PDF صالحاً',
      );
      expect(
        String.fromCharCodes(vectorBytes.sublist(0, 5)),
        '%PDF-',
        reason: 'ملف «فيكتور» ليس PDF صالحاً',
      );
      expect(raster.pageCount, 1);
      expect(vector.pageCount, 1);

      // ── 2. المتجه يحوي نصّاً حقيقياً: خطوط + ToUnicode ────────────────────
      final String vectorLatin = latinOnly(vectorBytes);
      expect(
        vectorLatin.contains('/Font'),
        isTrue,
        reason: 'ملف الفيكتور بلا كائنات خطوط — إذن بلا نصّ قابل للنسخ',
      );
      expect(
        vectorLatin.contains('/ToUnicode'),
        isTrue,
        reason: 'ملف الفيكتور بلا مخطّط ToUnicode — لا يمكن نسخ النص بمعناه',
      );

      // ── 3. النقطي = صورة كاملة للصفحة، والمتجه بلا صورة ──────────────────
      final String rasterLatin = latinOnly(rasterBytes);
      expect(
        rasterLatin.contains('/Subtype /Image') ||
            rasterLatin.contains('/Subtype/Image'),
        isTrue,
        reason: 'ملف «صور» بلا صورة صفحة رغم أنه المسار النقطي',
      );
      expect(
        vectorLatin.contains('/Subtype /Image') ||
            vectorLatin.contains('/Subtype/Image'),
        isFalse,
        reason: 'ملف الفيكتور ما زال يحوي صورة صفحة — ليس متجهاً فعلاً',
      );

      // ── 4. معامل `type: PdfExportType.vector` يسلك المسار ذاته ──────────
      expect(viaTypeParameter, isNotNull, reason: 'فشل مسار `type: vector`');
      final String viaTypeLatin = latinOnly(viaTypeParameter!.bytes);
      expect(
        viaTypeLatin.contains('/Font'),
        isTrue,
        reason: '`type: vector` لم يسلك المسار المتجهي في الخدمة',
      );
      expect(viaTypeLatin.contains('/ToUnicode'), isTrue);
      expect(
        viaTypeLatin.contains('/Subtype /Image') ||
            viaTypeLatin.contains('/Subtype/Image'),
        isFalse,
      );

      // ── 5. تقرير الحجم ليراه المهندس في سجلّ الاختبار ─────────────────────
      final int rasterSize = rasterBytes.lengthInBytes;
      final int vectorSize = vectorBytes.lengthInBytes;
      debugPrint(
        '📊 قياس حجم التصدير (شعارة واحدة): '
        'نقطي = $rasterSize بايت، متجه = $vectorSize بايت، '
        'المتجه أصغر بنسبة ${(100 - vectorSize / rasterSize * 100).toStringAsFixed(0)}%',
      );
    },
  );

  testWidgets(
    'التوليد الجماعي المتجه يخرج من الـisolate بصفحاته وخطوطه سليمة',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      final PdfFontSet? fonts = await tester.runAsync(() => PdfFontSet.load());
      final PdfGeneratorService service = PdfGeneratorService(fonts: fonts!);

      // ثلاثة صفوف تتجاوز حدّ التجزئة الافتراضي (٢) — فيسلك المسار المجزّأ:
      // بايتات الصور والخطوط تُنقل إلى isolate يُبنى فيه الملف.
      expect(service.isolateThreshold, 2);

      final List<int> progress = <int>[];
      final PdfGenerationReport? batch = await tester.runAsync(
        () => service.generateBatch(
          document: document(),
          rows: const <Map<String, String>>[
            <String, String>{'a': '1'},
            <String, String>{'a': '2'},
            <String, String>{'a': '3'},
          ],
          type: PdfExportType.vector,
          onProgress: (int done, int total) => progress.add(done),
        ),
      );

      expect(batch, isNotNull, reason: 'فشل التوليد الجماعي المتجهي');
      expect(
        batch!.pageCount,
        3,
        reason: 'صفوف ثلاثة يجب أن تُخرج ثلاث صفحات',
      );
      final String latin = latinOnly(batch.bytes);
      expect(
        latin.contains('/Font'),
        isTrue,
        reason: 'خيوط الـisolate أعادت ملفاً بلا خطوط — إذن بلا نصّ',
      );
      // التقدّم يُبثّ من الـisolate لحظياً (يُسمح بالتجمّع، لا بالانعدام).
      expect(progress, isNotEmpty, reason: 'التقدّم لم يبلغ من الـisolate أصلاً');

      debugPrint(
        '📊 التوليد الجماعي المتجهي: ${batch.pageCount} صفحات، '
        '${batch.bytes.lengthInBytes} بايت، '
        'التقدّم ${progress.length} بلاغ.',
      );
    },
  );
}
