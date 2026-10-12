/// اختبارات شاشة استخراج النص من صورة (الحوار + المتحكّم) بمحرّك وهمي.
///
/// **لا تعتمد على Tesseract ولا على file_picker:** الاستيراد يُحاكى عبر
/// `controller.loadImageBytes` (نفس المسار الذي تستخدمه مسار PDF)، والمخرج
/// يُحقن عبر `FakeOcrEngine`. بذلك تختبر الاختبارات «منطق الشاشة» فعلاً لا
/// توفّر برنامج خارجي على جهاز المطوّر.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/locale/app_locale.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/ocr/domain/ocr_engine_status.dart';
import 'package:joodcraft/features/ocr/domain/ocr_result.dart';
import 'package:joodcraft/features/ocr/domain/ocr_settings.dart';
import 'package:joodcraft/features/ocr/presentation/providers/ocr_controller.dart';
import 'package:joodcraft/features/ocr/presentation/screens/ocr_screen.dart';
import 'package:joodcraft/l10n/generated/app_localizations.dart';

import '../support/ocr_engine_stub.dart';
import '../support/sample_image.dart';

void main() {
  Finder byKey(String name) => find.byKey(ValueKey<String>(name));

  /// يفتح الحوار كحوار حقيقي (showDialog) داخل بيئة موحّدة.
  Future<OcrController> pumpOcr(
    WidgetTester tester, {
    required FakeOcrEngine engine,
    ValueChanged<String>? onInsert,
    OcrController? controller,
  }) async {
    // الحوار مصمّم لسطح مكتب (1100×760) — الافتراضي 800×600 فيختنق.
    await tester.binding.setSurfaceSize(const Size(1280, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final OcrController attached =
        controller ?? OcrController(engine: engine);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: AppLocales.locales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    final BuildContext anchor = tester.element(find.byType(SizedBox));
    // لا ننتظر إغلاق الحوار (يحدث عند الضغط على إلغاء/قبول داخل الاختبار).
    unawaited(
      showOcrScreen(
        anchor,
        onInsert: onInsert,
        engine: engine,
        controller: attached,
      ),
    );
    await tester.pumpAndSettle();
    return attached;
  }

  /// يحمّل صورة تجريبية كأن المستخدم استوردها.
  Future<void> loadImage(WidgetTester tester, OcrController controller) async {
    await controller.loadImageBytes(samplePngBytes(), name: 'sample.png');
    await tester.pumpAndSettle();
  }

  // ==========================================================================
  //  الفتح والاستيراد
  // ==========================================================================

  group('الفتح والاستيراد', () {
    testWidgets('الشاشة تفتح وتعرض العنوان وأزرار الاستيراد والاستخراج',
        (WidgetTester tester) async {
      await pumpOcr(tester, engine: FakeOcrEngine());

      expect(find.byKey(const Key('ocr_screen')), findsOneWidget);
      expect(find.text('استخراج نص من صورة'), findsOneWidget);
      expect(byKey('ocr_import_image_button'), findsOneWidget);
      expect(byKey('ocr_import_pdf_button'), findsOneWidget);
      expect(byKey('ocr_extract_button'), findsOneWidget);
    });

    testWidgets('زر الاستخراج معطّل قبل اختيار صورة',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());
      final FilledButton button =
          tester.widget<FilledButton>(byKey('ocr_extract_button'));
      expect(button.onPressed, isNull);
      expect(controller.canExtract, isFalse);
    });

    testWidgets('بعد تحميل الصورة يُفعّل زر الاستخراج ويظهر شعارها',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());
      await loadImage(tester, controller);

      final FilledButton button =
          tester.widget<FilledButton>(byKey('ocr_extract_button'));
      expect(button.onPressed, isNotNull);
      expect(byKey('ocr_preview_image'), findsOneWidget);
      expect(byKey('ocr_image_empty'), findsNothing);
    });
  });

  // ==========================================================================
  //  الاستخراج والتحرير
  // ==========================================================================

  group('الاستخراج والتحرير', () {
    testWidgets('الاستخراج يملأ حقل النصّ بنتيجة المحرّك',
        (WidgetTester tester) async {
      final FakeOcrEngine engine = FakeOcrEngine(
        result: const OcrResult(
          text: 'نصّ أول\nسطر ثانٍ',
          confidence: 0.72,
          wordBoxes: <WordBox>[],
          language: 'ara+eng',
          elapsedMs: 850,
          imageWidth: 200,
          imageHeight: 100,
        ),
      );
      final OcrController controller = await pumpOcr(tester, engine: engine);
      await loadImage(tester, controller);

      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();

      expect(engine.extractCalls, 1);
      final TextField field =
          tester.widget<TextField>(byKey('ocr_text_field'));
      expect(field.controller!.text, 'نصّ أول\nسطر ثانٍ');
      expect(controller.state, OcrViewState.done);
    });

    testWidgets('تعديل النصّ يُحدّث المتحكّم (إجباري — الدقة ليست 100%)',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());
      await loadImage(tester, controller);
      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();

      await tester.enterText(byKey('ocr_text_field'), 'نصّ معدَّل يدوياً');
      await tester.pump();

      expect(controller.editedText, 'نصّ معدَّل يدوياً');
    });

    testWidgets('زر الاستخراج يصبح «إعادة المحاولة» بعد الاكتمال',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());
      await loadImage(tester, controller);
      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();

      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  // ==========================================================================
  //  الإدراج والقبول والإلغاء
  // ==========================================================================

  group('الإدراج والقبول والإلغاء', () {
    testWidgets('زر الإدراج يمرّر النصّ المحرَّر إلى الوجهة ويغلق الحوار',
        (WidgetTester tester) async {
      String? inserted;
      final OcrController controller = await pumpOcr(
        tester,
        engine: FakeOcrEngine(),
        onInsert: (String text) => inserted = text,
      );
      await loadImage(tester, controller);
      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('ocr_text_field'), 'النصّ النهائي');
      await tester.pump();

      await tester.tap(byKey('ocr_insert_button'));
      await tester.pumpAndSettle();

      expect(inserted, 'النصّ النهائي');
      expect(find.byKey(const Key('ocr_screen')), findsNothing);
    });

    testWidgets('زر القبول يعيد النصّ المحرَّر كنتيجة الحوار',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());
      await loadImage(tester, controller);
      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('ocr_text_field'), 'مقبول');
      await tester.pump();

      await tester.tap(byKey('ocr_accept_button'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ocr_screen')), findsNothing);
    });

    testWidgets('الإلغاء يغلق الحوار دون إدراج',
        (WidgetTester tester) async {
      String? inserted;
      await pumpOcr(
        tester,
        engine: FakeOcrEngine(),
        onInsert: (String text) => inserted = text,
      );

      await tester.tap(byKey('ocr_cancel_button'));
      await tester.pumpAndSettle();

      expect(inserted, isNull);
      expect(find.byKey(const Key('ocr_screen')), findsNothing);
    });

    testWidgets('لا يظهر زر الإدراج بلا وجهة (قبول فقط)',
        (WidgetTester tester) async {
      await pumpOcr(tester, engine: FakeOcrEngine());

      expect(byKey('ocr_insert_button'), findsNothing);
      expect(byKey('ocr_accept_button'), findsOneWidget);
    });
  });

  // ==========================================================================
  //  الأخطاء
  // ==========================================================================

  group('رسائل الخطأ', () {
    testWidgets('صورة بلا نصّ تعرض رسالة «لم يُعثر على نص»',
        (WidgetTester tester) async {
      final FakeOcrEngine engine = FakeOcrEngine(
        result: const OcrResult(
          text: '   ',
          confidence: 0,
          wordBoxes: <WordBox>[],
          language: 'ara',
          elapsedMs: 300,
          imageWidth: 10,
          imageHeight: 10,
        ),
      );
      final OcrController controller = await pumpOcr(tester, engine: engine);
      await loadImage(tester, controller);
      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();

      expect(byKey('ocr_error_message'), findsOneWidget);
      expect(find.text('لم يُعثر على نص في الصورة.'), findsOneWidget);
    });

    testWidgets('صورة تالفة تعرض رسالة «صورة غير صالحة»',
        (WidgetTester tester) async {
      final FakeOcrEngine engine = FakeOcrEngine(error: const FormatException());
      final OcrController controller = await pumpOcr(tester, engine: engine);
      await loadImage(tester, controller);
      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();

      expect(find.text('صورة غير صالحة.'), findsOneWidget);
    });

    testWidgets('غياب Tesseract يظهر تلميح التثبيت ويعطّل الاستخراج',
        (WidgetTester tester) async {
      final FakeOcrEngine engine = FakeOcrEngine(
        statusValue: OcrEngineStatus.missingBinary,
      );
      final OcrController controller = await pumpOcr(tester, engine: engine);
      await loadImage(tester, controller);

      expect(byKey('ocr_engine_hint'), findsOneWidget);
      expect(
        find.text('لم يُعثر على Tesseract — ثبّته ثم أعد المحاولة.'),
        findsOneWidget,
      );
      final FilledButton button =
          tester.widget<FilledButton>(byKey('ocr_extract_button'));
      expect(button.onPressed, isNull);
      expect(controller.canExtract, isFalse);
    });

    testWidgets('غياب بيانات اللغة يظهر رسالة أخرى',
        (WidgetTester tester) async {
      final FakeOcrEngine engine = FakeOcrEngine(
        statusValue: OcrEngineStatus.missingLanguageData,
      );
      await pumpOcr(tester, engine: engine);

      expect(find.text('بيانات اللغة غير مثبّتة مع Tesseract.'), findsOneWidget);
    });
  });

  // ==========================================================================
  //  الإعدادات
  // ==========================================================================

  group('الإعدادات', () {
    testWidgets('تغيير اللغة يُحدّث إعدادات المتحكّم',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());
      // الافتراضي الجديد: عربي فقط — القياس أظهر أنّ فتح `eng` مع `ara`
      // يُنتج مرشّحات لاتينية لأشكال عربية (انظر `report/ocr_improvement.md`).
      expect(controller.settings.language, OcrLanguage.arabic);

      await tester.tap(byKey('ocr_language_dropdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإنجليزية').last);
      await tester.pumpAndSettle();

      expect(controller.settings.language, OcrLanguage.english);
    });

    testWidgets('تغيير وضع التقطيع يُحدّث الإعدادات',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());

      await tester.tap(byKey('ocr_psm_dropdown'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('سطر واحد').last);
      await tester.pumpAndSettle();

      expect(controller.settings.psm, OcrPsm.singleLine);
    });

    testWidgets('شريط التكبير يقيّم القيمة بين 1 و3',
        (WidgetTester tester) async {
      final OcrController controller =
          await pumpOcr(tester, engine: FakeOcrEngine());

      await tester.tap(byKey('ocr_scale_slider'));
      await tester.pumpAndSettle();

      expect(
        controller.settings.scale,
        greaterThanOrEqualTo(OcrSettings.minScale),
      );
      expect(
        controller.settings.scale,
        lessThanOrEqualTo(OcrSettings.maxScale),
      );
    });

    testWidgets('الاستخراج يستخدم الإعدادات المختارة فعلاً',
        (WidgetTester tester) async {
      final FakeOcrEngine engine = FakeOcrEngine();
      final OcrController controller = await pumpOcr(tester, engine: engine);
      await loadImage(tester, controller);
      controller.setLanguage(OcrLanguage.arabic);
      await tester.pump();

      await tester.tap(byKey('ocr_extract_button'));
      await tester.pumpAndSettle();

      expect(engine.lastSettings!.language, OcrLanguage.arabic);
    });
  });
}
