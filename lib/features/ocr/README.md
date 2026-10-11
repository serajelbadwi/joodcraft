# feature OCR — استخراج نص من صورة

> أداة **مساعدة للمراجعة البشرية**: Tesseract يقترح النصّ، والإنسان يعدّله قبل
> الإدراج. الدقة المقيسة على عيّنات المشروع 60.5%–75.7%
> (`report/tesseract_benchmark.md`)، ولذلك لا تُدرَج نتيجة خام أبداً.

## البنية

```
lib/features/ocr/
├── domain/
│   ├── ocr_result.dart        نصّ + ثقة + مربّعات كلمات (TSV)
│   ├── ocr_engine.dart        واجهة مجرّدة OcrEngine + استثناءات
│   ├── ocr_engine_status.dart حالة التوفّر (جاهز/مفقود/بيانات لغة)
│   └── ocr_settings.dart      لغة (ara/eng/كلاهما) + PSM + تكبير + معالجة قبلية
├── data/
│   ├── tesseract_engine.dart  تنفيذ العملية الجانبية tesseract.exe
│   └── image_preprocessor.dart تكبير، رمادي، عتبة Otsu (حزمة image المدمجة)
├── presentation/
│   ├── providers/ocr_controller.dart  حالة الشاشة + الاستيراد + الاستخراج
│   └── screens/ocr_screen.dart        Split View: صورة يساراً ونصّ يميناً
└── README.md                  هذا الملف
```

## نقاط الدخول

* `showOcrScreen(context, onInsert: ...)` — يفتح الحوار ويعيد النصّ المقبول.
* `WriterOcrButton` (`lib/features/jood_writer/presentation/widgets/writer_ocr_button.dart`)
  زر مستقلّ لشريط Jood Writer — لا يلمس `writer_sidebar.dart`.
* `EditorOcrButton` (`lib/core/editor/widgets/editor_ocr_button.dart`)
  زر مستقلّ لشريط المحرّر (الشهادات/العقود) — يُنشئ عنصراً نصّياً جديداً.

## قرار التكامل

`Process.run` على `tesseract.exe` مع `--tessdata-dir` صريح — **صفر تبعيات
جديدة** وصفر تعديلات في `pubspec.yaml`. التفاصيل ومقارنة الخيارات في
`report/ocr_integration_decision.md`.

## قيود بيئة الاختبار

`flutter test` لا يشغّل Tesseract ولا `path_provider`، فالاختبارات تحقن
`FakeOcrEngine` (`test/support/ocr_engine_stub.dart`) وتستدعي
`controller.loadImageBytes` مباشرة. الاختبار الحقيقي على الجهاز يمرّ عبر
`test/features/zz_ocr_probe_test.dart` (مؤقّت) أو تشغيل التطبيق يدوياً.
