# تشخيص مشكلتَي تصدير PDF

> تقرير تشخيصي (قراءة فقط — لم يُعدَّل أي ملف في `lib/core/pdf/` ولا في أي ملف آخر).
> التحقّق تم فعلياً بتكرار المشكلتين بتوليد ملفات حقيقية وفحصها (انظر «الأدلة»).

---

## الخلاصة التنفيذية

| المشكلة | السبب الجذري | الملف المعني | جاهزية الإصلاح |
|---|---|---|---|
| **1 — «الف يطلع صور دائماً»** | محرّك الرسم المتجهي **يعمل سليماً**، لكن **كل مسارات التصدير الفعلية في التطبيق تمرّر `type` الافتراضي `PdfExportType.images`** ولا تعرض حوار الاختيار إلا في مكان واحد (معاينة الـ PDF). فزر التصدير الرئيسي في المحرّر وزر التوليد الجماعي **يتجاهلان اختيار المستخدم** وتصدّر نقطي دائماً. | `template_editor_view.dart:1260`، `bulk_generation.dart:457,548`، `invitation_export_service.dart:154` | جاهز — تمرير `type` + عرض الحوار في نقاط الدخول |
| **2 — الشهادة الأولى بلا لوجو/توقيع/اسم** | **`OffscreenWidgetRenderer` يلتقط الصورة قبل اكتمال تحميل الصور غير المتزامنة.** الـ `BuildOwner` يُبنى **بلا** `onBuildScheduled`، فلا تُعاد أي عناصر اكتسبت صورها بعد البناء الأول؛ و`await 100ms` لا يفيد لأن المشكلة **ليست توقيتية** بل غياب إعادة البناء. الصفحة الأولى = ذاكرة صور `imageCache` **باردة** ⇒ الصور غائبة؛ الصفحات التالية = الذاكرة **دافئة** ⇒ تُحلّ الصور متزامنة أثناء البناء وتظهر. | `offscreen_widget_renderer.dart:72-74, 121-135` | جاهز — تهيئة `BuildOwner` + حلقة إعادة بناء/طلاء حتى السكون |

**ملاحظة حاسمة:** النقطي هو المسار الافتراضي لكل الاستدعاءات (لأن `type` لا يُمرَّر أبداً)، لذا **المشكلة 2 تظهر في كل PDF يصدّره التطبيق عملياً** — ولهذا يلاحظها المستخدم في «الشهادة الأولى».

---

## المشكلة 1 — «المستخدم يختار فيكتور والملف يطلع صور»

### مسار الاختيار (سليم)

`pdf_template_preview.dart:324-340` — `_export()` يعرض `PdfExportTypeDialog` ثم:

```dart
switch (type) {
  case PdfExportType.images: await _exportImages();   // يحفظ `_bytes` النقطية
  case PdfExportType.vector: await _exportVector();   // يعيد توليد بالمحرّك المتجهي
}
```

`_exportVector():389-407` يستدعي `service.exportVector(...)` → `generateBatch(type: vector)` → `_buildVector()` → `PdfRenderer(...).build(...)` (صفحة واحدة ⇒ على الخيط الرئيسي، بلا isolate). **هذا المسار سليم ومُتحقَّق منه:** أنتج ملفاً متجهياً حقيقياً (‏4 خطوط مضمّنة + محتوى نصّي، مقابل 9 KB مقابل 68 KB للنسخة النقطية).

### أين يتعثّر — الاستدعاءات التي تتجاهل النوع

كل هذه تستخدم الافتراضي `PdfExportType.images` ولا تمرّر `type` ولا تعرض حواراً:

| الموقع | الاستدعاء | النتيجة |
|---|---|---|
| `template_editor_view.dart:1260` | `service.generate(document:, data:)` | **دائمًا نقطي** (زر «تصدير PDF» الرئيسي في المحرّر) |
| `bulk_generation.dart:457` | `generator.generateBatch(...)` | **دائمًا نقطي** (التوليد الجماعي) |
| `bulk_generation.dart:548` | `generator.generate(...)` | **دائمًا نقطي** |
| `invitation_export_service.dart:154` | `_generator.generate(...)` | **دائمًا نقطي** (الدعوات — ممنوع اللمس) |

بمعنى آخر: **حوار الاختيار موجود في مسار واحد فقط (معاينة الـ PDF)، بينما التصدير الحقيقي للمستند (من المحرّر) ومن مسارات التجميع يمرّ مباشرة على النقطي.** فلا عجب أن يرى المستخدم «الخيارين → نفس النتيجة (صور)» متى استخدم أي زر غير زر المعاينة.

### فرضية داعمة (أثر بناء قديم)

مفتاحا l10n `pdfExportTypeComingSoon` / `pdfExportTypeComingSoonMessage`
(«تصدير الفيكتور قيد التطوير — سيتوفر قريباً.») ما زالا معرّفين في ملفات `generated` **دون أي استخدام** في الكود. هذا يدلّ على أن حوار الاختيار مرّ بمرحلة سابقة كان فيها الفيكتور معطّلاً. إن كان نسخ التطبيق المُختبَر بناءً قديماً قبل توصيل المحرّك المتجهي، فهذا يفسّر ملاحظة المستخدم حرفياً. **التوصية: إعادة بناء التطبيق والتأكّد من أن الحالة الحالية مُختبَرة قبل أي استنتاج.**

### التوصية — المشكلة 1

1. **تمرير النوع فعلياً** في كل نقاط الدخول:
   * `template_editor_view.dart` `_exportPdf()`: اعرض `PdfExportTypeDialog` ثم `service.generate(..., type: chosen)`.
   * `bulk_generation.dart`: انقل `PdfExportType` عبر `generateBatch`/`generate` وأضِ خياراً في واجهة المعالج الدفعي.
   * `invitation_export_service.dart`: (**ممنوع اللمس** — يُبلَّغ مسؤوله بتمرير `type`).
2. اجعل الافتراضي واضحاً في الواجهة (أي أنّ ما تراه المعاينة النقطية هو افتراضي، والفيكتور خيار صريح).

---

## المشكلة 2 — الشهادة الأولى تفقد اللوجو + الإمضاء + اسم المدير

### السبب الجذري (مُتحقَّق منه بالتكرار)

`offscreen_widget_renderer.dart` — دالة `_renderWidgetToImage()`:

```dart
final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager()); // ① بلا onBuildScheduled
...
buildOwner.buildScope(rootElement);   // ② بناء واحد فقط
buildOwner.finalizeTree();
pipelineOwner.flushLayout(); ...; pipelineOwner.flushPaint();
await Future<void>.delayed(const Duration(milliseconds: 100)); // ③ انتظار أعمى
pipelineOwner.flushLayout(); ...; pipelineOwner.flushPaint();  // ④ طلاء بدون إعادة بناء
final ui.Image image = await repaintBoundary.toImage(...);      // ⑤ لقطة
```

* عناصر الصور (`Image`/`MemoryImage`) تُحمَّل الصورة في **`ImageStream` غير متزامن**. عند اكتمالها تستدعي المستمع → `setState` في ودجت `Image` → `markNeedsBuild` → `BuildOwner.scheduleBuildFor`.
* لكن **`onBuildScheduled == null`** (١)، فلا يُجدول أي `buildScope` لاحق؛ ودالة التصدير لا تستدعي `buildScope` ثانية (٤ طلاء فقط). ⇒ **الإطار الذي بُني في (٢) هو الذي يُصوَّر في (٥) مهما انتظرنا.**
* انتظار الـ 100ms (٣) **لا يحلّ المشكلة** لأن الصورة وإن اكتملت لا تُعاد بناء العنصر الذي يعرضها — hence this is **not** a timing/race issue that a longer delay fixes.

### لماذا «الأولى» فقط؟

`PaintingBinding.instance.imageCache` **عالمية** بين الصفحات، و`RasterizedPdfBuilder` ي render كل صف بالتتابع عبر `renderDocumentToImageBytes`:

* **صفحة ١:** الذاكرة **باردة** ⇒ `MemoryImage` يبدأ فكّ/رفع الصورة غير متزامن ⇒ غائبة عند اللقطة.
* **صفحة ٢ فما بعد:** الصورة **محفوظة في الذاكرة** ⇒ `ImageStream` يُحلّها **متزامنة أثناء البناء** ⇒ تظهر.

هذا مطابق تماماً للعرض الذي يراه المستخدم: الأولى ناقصة والثانيات صحيحة، والـ PNG (المعالج الدفعي يحوّل الصفحات عبر `Printing.raster`، ومسار الشهادة المفردة عبر `page.toPng()`) سليم لأنه **لا يمرّ بـ `OffscreenWidgetRenderer`** إطلاقاً.

### الأدلة (تكرار فعلي)

توليد مستند احتوى: نص «المدير: أحمد محمد» + صورة لوجو (‏dataUri) + كتلة توقيع بصورة، وعرضه ثلاث مرات متتالية:

| الملف | لوجو | صورة التوقيع | اسم المدير/النص |
|---|---|---|---|
| `raster_page1.png` | **غائب** ❌ | **غائب** ❌ | حاضر ✔ |
| `raster_page2.png` | حاضر ✔ | حاضر ✔ | حاضر ✔ |
| `raster_page3.png` | حاضر ✔ | حاضر ✔ | حاضر ✔ |

(النص ظهر كمربعات في هذه التجربة لأن خطوط عربية غير مسجّلة في بيئة الاختبار — لا علاقة له بالمشكلة.)

**دقيقاً كما يشكو المستخدم: الأولى بلا لوجو وبلا توقيع، والثانيات سليمة.**

### عن «اسم المدير» في تقرير المستخدم

في التكرار ظهر النصّ في الصفحة الأولى (لأنه غير متزامن). إن كان اسم المدير في قالب المستخدم **صورة** (لوحة اسم بخط عربي جاهزة — شائع في الشهادات) أو جزءاً من صور الكتلة، فهو يختفي ضمن نفس العطل ويُصلحه الإصلاح ذاته. إن كان نصاً صريحاً فعلاً ويظل مفقوداً بعد الإصلاح، فذلك استثناء يستحق مراجعة مستقلة لقالب المستخدم تحديداً.

### التوصية — المشكلة 2

في `offscreen_widget_renderer.dart` (وهو خارج `lib/core/pdf/` الممنوع — يقع في `lib/core/pdf/offscreen_widget_renderer.dart`... **ملاحظة:** الملف فعلياً *داخل* `lib/core/pdf/`، فالأولى تنفيذ الإصلاح بتنسيق مقترح وتسليمه لمسؤول المجلد الممنوع، أو عبر موافقته):

1. **تهيئة `BuildOwner` بجدولة إعادة بناء:**
   ```dart
   final BuildOwner buildOwner = BuildOwner(
     focusManager: FocusManager(),
     onBuildScheduled: (_) => _scheduleRebuild(), // يعيد buildScope عند أي setState متأخر
   );
   ```
2. **حلقة ضبط حتمية** بدل الانتظار الأعمى: كرّر `(buildScope → flushLayout → flushCompositingBits → flushPaint)` حتى لا يبقَ عنصر قذر، مع حدّ أقصى للمحاولات و`await` قصير بينها.
3. **(بديل أنظف) تهيئة الصور قبل الشجرة:** اجمع كل `ImageProvider` التي ستستخدمها عناصر المستند (نفس منطق `ElementView` للمستخدم/‏Base64) واستدعِ `resolve` وانتظر إطارها الأول **قبل** `attachToRenderTree`، فتُحلّ الصور متزامنة داخل البناء الأول ولا تعتمد اللقطة على أي تهيئة متأخرة.
4. أضِ اختبار回归 يصوّر مستنداً فيه صور ثلاث مرات ويقارن حضور البكسلات في الأولى مع الثانية (يمنع تراجع هذا المسار الحرج).

---

## الأدلة والملفات المفهرسة (قراءة فقط)

* `lib/core/pdf/pdf_export_type.dart` — تعريف النوعين.
* `lib/core/pdf/pdf_render_engine.dart:212-269` — حلقة الصفحات (لا فرق بين الأولى والثانية).
* `lib/core/pdf/rasterized_pdf_builder.dart:26-43` — توالّي `renderDocumentToImageBytes` لكل صف.
* `lib/core/pdf/offscreen_widget_renderer.dart:67-146` — **موضع العطل** (بناء واحد + طلاء بعد انتظار أعمى).
* `lib/core/editor/widgets/element_view.dart:571-766` — الصور عبر `Image`/`MemoryImage` غير المتزامنة.
* `lib/core/services/pdf_generator_service.dart:299-459` — `generate`/`generateBatch`/`exportVector`/`_buildVector` (الافتراضي `images`).
* `lib/core/widgets/pdf_template_preview.dart:324-407, 763-846` — حوار الاختيار والمساران (سليمان).
* نقاط الاستدعاء المتجاهلة للنوع: `template_editor_view.dart:1260`، `bulk_generation.dart:457,548`، `invitation_export_service.dart:154`.
* مفاتيح l10n اليتيمة `pdfExportTypeComingSoon*` في `lib/l10n/generated/*`.

## ما لم يُلمس

لم يُغيَّر أي ملف. حُذف ملف التشخيص المؤقت `test/zz_diag_pdf_repro_test.dart`. لم يُمَس `lib/core/pdf/` ولا `jood_writer` ولا `admin` ولا `auth` ولا `invitations`.
