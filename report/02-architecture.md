# 2 — المعمارية

## 2.1 الشجرة العامة

```
JoodCraft/
├── lib/
│   ├── main.dart                     # نقطة الانطلاق: تهيئة محلية ثم runApp
│   ├── app/
│   │   ├── app.dart                  # JoodCraftApp: MaterialApp.router + المزوّدون
│   │   └── router/
│   │       ├── app_routes.dart       # مصدر واحد لمسارات التطبيق
│   │       └── app_router.dart       # GoRouter + بوابة الدخول + 10 فروع
│   ├── core/                         # 139 ملف / 41,099 سطر — البنية التحتية
│   │   ├── assets/       # مكتبة الأصول (Base64) + كاش القرص + صور مصغّرة
│   │   ├── audit/        # سجل التصدير (ExportAuditLog)
│   │   ├── brand/        # هوية المؤسسة (شعار/أختام/توقيعات/ألوان/خطوط)
│   │   ├── constants/    # الثوابت + الوحدات + env + الحقول الديناميكية
│   │   ├── editor/       # ⭐ المحرّك البصري المشترك (1814 سطر متحكم + ودجات 12k سطر)
│   │   ├── errors/       # AppException + ErrorMapper (عربنة كل الأخطاء)
│   │   ├── fonts/        # الخطوط المرفوعة + خطوط نظام Windows + الفاحص
│   │   ├── gender/       # كشف جنس الاسم العربي (تذكير/تأنيث)
│   │   ├── l10n/ locale/ # وصول مرن للترجمة + حالات اللغة والاتجاه
│   │   ├── models/       # TemplateDocument / TemplateElement / TextFlow / …
│   │   ├── pdf/          # محرّكات الـ PDF (نقطي + متجه + تجميع + خطوط)
│   │   ├── print/        # التجميع للطباعة (Imposition) + علامات القصّ
│   │   ├── projects/     # قاعدة المشاريع المحلية (Hive) + صيغة .jood
│   │   ├── services/     # PdfGeneratorService + env loader + batch output
│   │   ├── templates/    # الفهرس الجاهز (presets) + القوالب المترجمة + الدعوات
│   │   ├── theme/        # الثيم الفاتح/الداكن + AppColors
│   │   ├── utils/ widgets/  # أدوات وودجات مشتركة (الشعار، المعاينة، …)
│   └── features/                     # 66 ملف / 23,308 سطر — وحدات مغلقة
│       ├── assets_manager/  brand/  invitations/  jood_writer/  project_hub/
│       ├── auth/  batch_processor/  certificate_builder/  contract_builder/
│       ├── dashboard/  templates/
├── test/          # 157 ملف / 31,338 سطر
│   ├── e2e/  features/  integration/  support/  unit/
├── integration_test/  # auth_flow_test.dart (قديم — مسار Supabase)
├── assets/  fonts(5MB)  images  templates  env/
└── tool/  # سكربتات Python لتوليد الخطوط المصغّرة + ensure_env.dart
```

## 2.2 القواعد المعمارية المُلزَظة في الكود

1. **Feature-first صارم:** كل ميزة في `lib/features/<name>/(data|domain|presentation)`،
   ولا استيراد مباشر بين ميزتين — يمرّ كل شيء عبر `core`.
2. **`core` هو الجسر:** `core/editor` و`core/pdf` و`core/projects` و`core/templates` يملكها
   الجميع، فمحرّك الشهادات ومحرّك العقود يتشاركان المحرّر بالكامل والفارق بينهما
   **التصنيف واتجاه الورقة فقط**.
3. **عربنة إلزامية:** كل خطأ خارجي → `AppException` عربي عبر `ErrorMapper`؛ ممنوع
   تسرّب رسالة إنجليزية للمستخدم (كود خطأ + تفصيل يترجمانهما الواجهة).
4. **Local-first حازم:** لا شبكة في مسار التشغيل. المشاريع في Hive، الأصول في
   `SharedPreferences` (Base64)، الحسابات محلية، الخطوط محزومة.
5. **مصدر وحيد للحقيقة:** `AppRoutes` للمسارات، `SheetReaders.supportedExtensions`
   لامتدادات الملفات، `ProjectRecord` لشكل جدول المشاريع، `dashboardDestinations`
   لترتيب الأقسام (ويجب أن يطابق ترتيب فروع الموجّه).

## 2.3 تدفّق الإقلاع (`lib/main.dart`)

الترتيب مقصود ومحكوم بالتعليقات في الكود:

```
1. WidgetsFlutterBinding.ensureInitialized()
2. CustomFontController.restore()          ← خطوط المستخدم المرفوعة
3. CustomFontController.scanSystemFonts()  ← في الخلفية (Windows)
4. AssetsController.restore()              ← مكتبة الأصول
5. AssetsController.pruneImageCache()      ← في الخلفية
6. BrandProfileController.restore()        ← هوية المؤسسة
7. ThemeController.load()                  ← قبل runApp (لا وميض)
8. LocaleController.load()                 ← قبل runApp
9. ProjectsController.restore()            ← فتح Hive وقراءة الجدول مرة واحدة
10. LocalAuthRepository.create()           ← الحسابات والجلسة من SharedPreferences
11. ExportAuditLog.restore()
12. runApp(JoodCraftApp(...))
13. PdfFontSet.warmUp()                    ← في الخلفية بعد runApp
```

## 2.4 البوابة والتنقّل (`app_router.dart`)

- `GoRouter` واحد، `initialLocation = /dashboard`، `refreshListenable = auth`.
- **بوابة إلزامية:** غير المسجّل ⇒ `/login`. المسجّل على `/login` ⇒ `/dashboard`.
  الشرط `auth.isServiceAvailable`: إن لم يُمرَّر مستودع مصادقة (اختبارات الودجات) لا
  تُفرض بوابة — وإلّا حُبس المستخدم في شاشة لا يمكن تجاوزها.
- **`StatefulShellRoute.indexedStack`** بعشرة فروع: dashboard · new-project ·
  certificate-builder · contract-builder · batch-processor · templates · assets ·
  brand · admin-accounts · jood-writer.
  الفائدة: كل قسم يبقى حيّاً في `IndexedStack`، فتبديل التبويبات **لا يفقد** محرّراً
  مفتوحاً ولا جلسة توليد ولا تعديلات غير محفوظة.
- تمرير البيانات عبر `state.extra` محوَّل بأنواع آمنة (`TemplateRecord` / `TemplateDraft`).

## 2.5 طبقة البيانات المحلية

| المستودع | الموقع | الثبات |
|----------|--------|--------|
| **جدول المشاريع** | `core/projects/` فوق Hive (صندوق `projects`) | `ProjectRecord(id, title, width, height, layers_data, updated_at, thumbnail_path)` |
| **مكتبة الأصول** | `core/assets/` فوق SharedPreferences | Base64 للنوع (شعار/ختم/توقيع/إطار) + كاش قرص للصور |
| **الخطوط المرفوعة** | `core/fonts/` | JSON + TTF على القرص (SharedPreferences على الويب) |
| **هوية المؤسسة** | `core/brand/` | شعار/أختام/توقيعات/ألوان/خطوط |
| **حسابات المديرين** | `features/auth/data/` | JSON في SharedPreferences + PBKDF2 لكلمات المرور |
| **سجل التصدير** | `core/audit/` | أرشيف محلي لكل ملف صُدِّر مع المدير وتاريخه |
| **مستندات جود كاتب** | `features/jood_writer` | JSON في SharedPreferences + حفظ تلقائي كل 800ms |

- **الكتابة مصدرها واحد:** المحرّر والمكتبة ومولّد الدفعات يكتبون في الجدول نفسه، فما
  يُحفظ يظهر فوراً في «المشاريع الأخيرة» والمكتبة بلا مزامنة.
- **القراءة من الذاكرة:** الجدول يُقرأ مرة واحدة عند الإقلاع (`ProjectsController.restore`).

## 2.6 مسار التوليد (القلب)

```
ملف xlsx/csv
   └─▶ SheetReaders ──▶ SheetData (عناوين + صفوف)      [تفكيك في isolate > 48KB]
        └─▶ ColumnMapping.autoDetect + FieldAliases  (ربط العمود بالحقل {{...}})
             └─▶ ArabicGender (تصحيح الجنس لكل صف)
                  └─▶ BulkGenerationService ──▶ PdfGeneratorService.generateBatch
                       └─▶ RasterizedPdfBuilder  ⚠️  ← التفصيل الخطير في القسم 5
                            └─▶ OffscreenWidgetRenderer (RepaintBoundary → PNG @3.5x)
                                 └─▶ pw.Document + pw.MemoryImage  → PDF
                       └─▶ BatchOutputBackend (حفظ/مشاركة)
```

## 2.7 ملاحظة معمارية: كُتلة على حدود «core»

- `core/editor/widgets` وحده **12,232 سطر** في 16 ملف، و`property_toolbar.dart`
  **3,293 سطر**، و`template_editor_view.dart` **2,106 سطر**. هذه ملفات ضخمة يصعب
  صيانتها ومراجعتها، وهي مرشّحة للتقسيم (لوحة الخصائص لكل نوع عنصر على حدة).
- `core/pdf/pdf_render_engine.dart` (‎1,558 سطر) **لم يبقَ مستخدماً في المسار الرئيسي**
  إلا لتصدير نوع `PdfDocumentMetadata`؛ وكذلك `core/pdf/arabic_text_engine.dart`
  (‎485 سطر) و`core/pdf/pdf_generation_isolate.dart` (‎132 سطر). أي أن محرّك التشكيل
  العربي الكامل (تشكيل + ترتيب بصري + كشيدة + bidi) أصبح **شيفرة ميتة** في مسار
  التصدير الفعلي — انظر القسم 5.2.
