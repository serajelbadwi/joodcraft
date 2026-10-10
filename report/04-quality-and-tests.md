# 4 — الجودة: نتائج الفحص الفعلي

كل الأرقام في هذا القسم **مُقاسة على الجهاز** بتاريخ 2026-10-10 بـ
`Flutter 3.38.7 · Dart 3.10.7`، لا منسوخةً من README.

---

## 4.1 `flutter analyze` — 🔴 فاشل

```
25 issues found.   (2 warnings + 22 errors + 1 info)
```

### الأخطاء (كلها في ملف واحد)

| الموقع | الرسالة | السبب الجذري |
|--------|---------|--------------|
| `invitations_screen.dart:67` | `Undefined class 'FilePickerResult'` | الكود كُتب لواجهة `file_picker` ‎8.x/9.x؛ المثبَّت **13.1.0** التي تُعيد `List<PlatformFile>` مباشرة |
| `invitations_screen.dart:70` | `The named parameter 'withData' isn't defined` | أُزيل المعامل في الإصدارات الحديثة |
| `invitations_screen.dart:73,74` | `The getter 'bytes' isn't defined for the type 'PlatformFile'` | `PlatformFile` صار غير يحمل البايتات في هذا المسار |
| `invitations_screen.dart:137,138,145,151,172,180,262,276,365,371,434,440,460` | `The getter/method 'inv*' isn't defined for the type 'AppLocalizations'` | **مفاتيح الترجمة غير موجودة** في أي من ملفات ARB العشرة (`invBulkModeTitle`, `invBulkModeHint`, `invPreviewTitle`, `invExportFormat`, `invNameFieldMissing`, `invDuplicateNames`, `invEmptyNames`, `invZIPOption`, `invIndexCSVOption`, `invProgressText`) |
| `invitations_screen.dart:301` | `Undefined name 'CrossWrap'` | لا وجود لهذا النوع في Flutter (الصحيح `WrapCrossAlignment`) |
| `invitations_screen.dart:382,391` | `Undefined class 'InvitationRowPlan'` | الملف **لا يستورد** `invitation_name_file.dart` حيث يُعرَّف النوع |
| `invitations_screen.dart:610` | `Undefined class 'AppLocalizations'` | انكسار سلسلة الاستيراد بعد إعادة الهيكلة |
| `invitations_screen.dart:67` (info) | `unnecessary_nullable_for_final_variable_declarations` | انعكاس للخطأ أعلاه |

### التحذيران

| الموقع | الرسالة |
|--------|---------|
| `pdf_generator_service.dart:493` | `_customFontBytes` isn't referenced — شيفرة ميتة |
| `pdf_generator_service.dart:600` | `_resolveImageBytes` isn't referenced — شيفرة ميتة |

> **أثر:** `.github/workflows/ci.yml` يُشغّل `flutter analyze` كخطوة إلزامية
> (fail-fast) ⇒ **CI أحمر على كل push**. كما أن أي `flutter build` للويب/التحليل في
> IDE سيُظهر 22 خطأً.

---

## 4.2 `flutter test` — 🔴 لا يكتمل

```
42:19 +1509 ~3 -64: Some tests failed.
TimeoutException after 0:10:00.000000: Test timed out after 10 minutes.
```

### النتيجة المجمّعة

| المقياس | القيمة |
|--------|--------|
| الاختبارات التي وصلت إلى التشغيل | 1,576 |
| ✅ نجحت | **1,509** |
| ⏭️ تخطّت (`live`) | 3 |
| ❌ فشلت | **64** |
| ⏱️ اختبار تجاوز المهلة (10 دقائق) | 1 |
| ⏱️ زمن التشغيل حتى التوقّف | 42 دقيقة |
| 📁 ملفات الاختبار التي **لم تُنفَّذ إطلاقاً** | ‎~127 من 157 (نُفِّذت 30 فقط) |

### 🔴 نقطة حرجة: الجلسة **قُطعت**

الجلسة توقّفت عند `test/features/batch_processor_screen_test.dart` (الساعة 42:19) ولم
تُكمّل بقية الملفات رغم أن الأمر لم يُلَغ. أي أن:

- ملفات مثل `jood_writer_*_test`, `invitations_bulk_test`, `template_library_screen_test`,
  `top_nav_bar_test`, `property_toolbar_test`, `local_projects_test`,
  `imposition_calculator_test`, `template_localization_test`, `project_preset_test`,
  `local_admin_system_test` … **لم تُنفَّذ**.
- `invitations_bulk_test.dart` يستورد `invitations_screen.dart` المعطوب — لو نُفِّذ
  لسقط الملف كاملاً بخطأ تصرّف.

⇒ **لا يمكن لأي مطور حالياً تشغيل `flutter test` والحصول على إشارة موثوقة.** هذه
أخطر مشكلة عملية في المشروع لأنها تُسقِط شبكة الأمان بالكامل.

### توزيع الـ64 فشلاً حسب ملف الاختبار

| # | ملف الاختبار | عدد | التصنيف الجذري |
|---|--------------|----:|----------------|
| 1 | `test/unit/text_alignment_parity_test.dart` | 12 | 🔴 PDF نقطي |
| 2 | `test/features/batch_processor_screen_test.dart` | 8 | 🔴 PDF نقطي + مهلة/قيم فارغة |
| 3 | `test/unit/pdf_visual_parity_test.dart` | 7 | 🔴 PDF نقطي |
| 4 | `test/unit/pdf_generator_service_test.dart` | 5 | 🔴 PDF نقطي |
| 5 | `test/unit/pdf_visual_parity_pixels_test.dart` | 4 | 🔴 PDF نقطي |
| 6 | `test/unit/pdf_font_fallback_test.dart` | 3 | 🔴 PDF نقطي |
| 6 | `test/unit/bulk_generation_test.dart` | 3 | 🔴 PDF نقطي |
| 6 | `test/unit/pdf_matrix_quality_test.dart` | 3 | 🔴 PDF نقطي |
| 9 | `test/unit/preset_visual_parity_test.dart` | 2 | 🔴 PDF نقطي |
| 9 | `test/unit/rich_text_spans_test.dart` | 2 | 🔴 PDF نقطي |
| 9 | `test/unit/pdf_text_shadow_test.dart` | 2 | 🔴 PDF نقطي |
| 9 | `test/unit/custom_font_controller_test.dart` | 2 | 🔴 PDF نقطي |
| 13 | `test/unit/asset_pdf_integration_test.dart` | 1 | 🔴 PDF نقطي |
| 13 | `test/unit/embedded_asset_fallback_test.dart` | 1 | 🔴 PDF نقطي |
| 13 | `test/unit/signature_element_test.dart` | 1 | 🔴 PDF نقطي |
| 13 | `test/unit/pdf_effect_parity_test.dart` | 1 | 🔴 PDF نقطي |
| 13 | `test/unit/cyrillic_font_coverage_test.dart` | 1 | 🔴 PDF نقطي |
| 13 | `test/features/custom_font_journey_test.dart` | 1 | 🔴 PDF نقطي |
| 20 | `test/unit/flow_paginator_test.dart` | 1 | 🟠 منطق جود كاتب |
| 20 | `test/features/editor_shortcuts_test.dart` | 2 | 🟠 مؤقّت معلّق في الاختبار |
| 20 | `test/features/new_document_dialog_test.dart` | 2 | 🟠 فيض تخطيط + نقر خارج الشاشة |
| 20 | `test/features/template_editor_view_test.dart` | 1 | 🟠 شريط الخصائص |
| **المجموع** | **22 ملفاً** | **64** | |

> **48 من 64 فشلاً (75%) سببها مباشرةً واحد:** استبدال محرّك الـ PDF المتجه بمحوّل
> نقطي. تفصيله في `05-defects-and-gaps.md` §5.2.

### أمثلة حرفية من سجل التشغيل

```
test/unit/pdf_font_fallback_test.dart: النص الروسي يُضمَّن فيه خط الاحتياط المحزوم
  Expected: contains 'NotoSans-Regular'
    Actual: '%PDF-1.5\n'
            '<</Type/Catalog/Version/1.7/Pages 1 0 R/PageMode/UseNone>>\n'
            '<</Creator(JoodCraft Raster Engine)/Producer(JoodCraft '
            '(High-Fidelity) (https://github.com/DavBfr/dart_pdf))/…>>\n'
            '… <</Type/XObject/Subtype/Image/…/Filter/ASCII85Decode…'
```
⇒ الملف لا يحوي أي خطّ مُضمَّن، وصفحته **صورة واحدة فقط** بلا أي نص متجه.

```
test/unit/flow_paginator_test.dart: فيض كتلة طويلة ⇒ شطرها على صفحتين
  Expected: an object with length of <2>
    Actual: [Instance of 'JoodPage', Instance of 'JoodPage', Instance of 'JoodPage']
```

```
test/features/editor_shortcuts_test.dart: النقر على عنصر ينقل التركيز للوحة
  A Timer is still pending even after the widget tree was disposed.
  … _TemplateEditorViewState._showScrollbarsTemporarily (template_editor_view.dart:194)
```

```
test/features/new_document_dialog_test.dart: نطاق الشاشات والمعايدات يجمع المقاسات الرقمية
  A RenderFlex overflowed by 7.1 pixels on the right.
  Row: lib/features/project_hub/presentation/dialogs/new_document_dialog.dart:1190
```

---

## 4.3 CI/CD

| الملف | الوظيفة | الحالة |
|-------|---------|--------|
| `.github/workflows/ci.yml` | `flutter pub get` → `flutter analyze` → `flutter test` على ubuntu-latest بـ Flutter 3.38.x | 🔴 **أحمر حتماً** (التحليل يفشل، والاختبار يفشل) |
| `.github/workflows/release.yml` | `flutter build windows --release` + رفع artifact (تشغيل يدوي) | 🟡 قد ينجح تقنياً، لكنه يسلّم منتجاً بحجم PDF كارثي |

> `CHANGELOG.md` فيه بند واحد فقط (`Unreleased / Added: إعداد CI/CD`) — أي أن
> التوثيق الزمني للمشروع غير مُدار.

## 4.4 حالة Git

| البند | القيمة |
|-------|--------|
| الفرع | `master` (لا يوجد `main` — لكن CI يستهدف `main` فقط!) |
| آخر commit | `be9fe6a refactor(invitations): update invitation templates` |
| ملفات معدَّلة غير ملتزمة | 29 (+1,779 / ‎-618 سطر) |
| ملفات محذوفة غير ملتزمة | 3 (`invitation_group.dart`, `invitation_size.dart`, `invitation_templates.dart`) |
| ملفات جديدة غير متتبَّعة (لحظة الفحص) | `lib/core/templates/invitation_{gallery,group,size}.dart`, `lib/features/dashboard/presentation/top_nav_groups.dart`, `lib/features/invitations/data/`, `lib/features/invitations/domain/invitation_export_service.dart`, `lib/features/invitations/presentation/`, `test/features/invitations_bulk_test.dart`, `tool/ocr_test/` |

> ⚠️ **الشجرة العاملة في منتصف إعادة هيكلة غير مكتملة**: حُذفت ملفات `domain` ونُقلت إلى
> `core/templates`، لكن `invitations_screen.dart` و`invitations_controller.dart` ما زالا
> يستوردان المسارات القديمة. هذا هو **السبب المباشر** لانفجار أخطاء التصرّف.
>
> ⚠️ **الشجرة تتغيّر أثناء الفحص**: لوحظ نشاط متزامن يضيف ملفات ويعدّل
> `batch_processor` و`dashboard` — أي أن لقطة Git هذه لحظية لا نهائية. لم يكتب هذا
> التقرير أي ملف في `lib/` أو `test/`.
>
> ⚠️ **CI مستهدف `main` والفرع الفعلي `master`** ⇒ لن يعمل CI أبداً عند الدفع.
>
> ⚠️ `assets/env/env.json` يحوي مفتاح Supabase حقيقياً على القرص. هو **مُستثنى في
> `.gitignore` وغير متتبَّع في Git** (سليم)، لكنه موجود في صندوق البناء المحلي —
> يجب ألّا يُرفع أبداً وأن يُدوَّر (rotated) إن كان قد شارِك.
