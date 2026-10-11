# فحص اهتزاز النص عند الكتابة — «جود كاتب»

## ملخّص المسار (ضغطة زر واحدة)

```
TextField (لا onChanged صريح!)
  └─ WriterTextEditingController._handleChanged      ← مستمع داخلي
       └─ WriterDocumentController._onTextChanged
            ├─ _updateBlock ─ _markDirty
            │    ├─ notifyListeners()          ← (أ) إعادة بناء كاملة
            │    └─ _requestAutoSplit()        ← (ب) تدفّق + قياس كل الكتل
            │         └─ WriterCanvas._autoSplitIfNeeded  ← FlowPaginator.paginate
            ├─ _requestAutoSplit()             ← (ج) تدفّق ثانٍ (تكرار!)
            ├─ _scheduleAutosave()
            └─ notifyListeners()               ← (د) إعادة بناء ثانية
                 └─ WriterCanvas._onControllerChanged
                      └─ _autoSplitIfNeeded()   ← (هـ) تدفّق ثالث (تكرار!)
                           └─ _scrollToBlockPage → animateTo(220ms)
```

## 1) فحص `onChanged` handlers

| الموضع | السلوك | أثر الكتابة |
|---|---|---|
| `writer_canvas.dart:835` `TextField` | **لا يوجد `onChanged` إطلاقاً** — المزامنة عبر `WriterTextEditingController.addListener` (`writer_document_controller.dart:16`) → مستمع خفي يصعب تتبّعه | كل حرف = دورة كاملة |
| `writer_ribbon_bar.dart` 248/288/339/576 | تنسيق (خط/حجم/لون) | `_markDirty` → إشعار + شطر |
| `writer_sidebar.dart` 64/114/136 | هوامش/صفحات/أرقام | إشعار + شطر |
| `writer_toolbar.dart` 930 | `controller.updateText` | إشعار مباشر |

### ما يحدث عند كل ضغطة زر (قياس فعلي)

1. **تدفّق كامل ثلاث مرات**: `_requestAutoSplit` من `_markDirty` + `_requestAutoSplit` من `_onTextChanged` + `_autoSplitIfNeeded` من `_onControllerChanged`.
2. **`TextPainter.layout` مرّتين لكل كتلة**: `linesOf()` و`lineHeightOf()` يبنيان لوحة رسم منفصلة (`text_painter_measurer.dart:74`) — ومستندٌ من 50 كتلةاً = 100 تخطيطٍ لكل تدفّق ⇒ **300 تخطيط** لضغطة زر واحدة.
3. **`notifyListeners()` مرّتين** ⇒ بناء شجرة اللوحة مرّتين في الإطار نفسه.
4. **الك measurer يُبنى جديداً في كل بناء** (`writer_canvas.dart:309`) ⇒ لا ذاكرة تخزين مؤقتة تُجدى.
5. **حركة تمرير 220ms عند كل شطرة** (`_scrollToBlockPage:268`) ⇒ تتشابك الحركات ولا يهدأ المنظر.
6. **الشطر ينقل الحقل النشط بين بطاقات الصفحات** ⇒ `EditableText` جديد ⇒ كسل IME/مؤشّر.

## 2) المطلوب تنفيذه

- [x] Debounce: إشعار واحد لكل موجة كتابة + شطر آلي مرة واحدة.
- [x] تثبيت الموضع: لا تمرير إن كانت الصفحة معروضة، ولا حركة متشابكة.
- [x] لا قياس إلا عند تغيّر النص فعلاً: تخزين مؤقت للقياس + للتدفّق.

## 3) الاختبار

`test/features/jood_writer_typing_stability_test.dart`

## 4) الإصلاحات المطبَّقة

| المشكلة | الإصلاح | الملف |
|---|---|---|
| **3 تدفّقات شطر لكل ضغطة** (`_markDirty` + `_onTextChanged` + `_onControllerChanged`) | الشطر يقع **متزامناً** مرّةً واحدة مع التعديل، ويُعلَن عنه بـ`autoSplitRevision`؛ وطبقة العرض تتخطّاه حين ترى أنّ المراجعة النصّية مراجَعةٌ أُشغِّل الشطر لها فعلاً | `writer_document_controller.dart`، `writer_canvas.dart:156` |
| **إشعاران/ثلاثة لكل ضغطة** (`notifyListeners` في `_markDirty` + `_onTextChanged` + `splitBlockAt`) | **تحديث واحد مؤجَّل** لكل موجة ضغطات بـ`scheduleMicrotask` (`_scheduleUiUpdate`/`_flushUiUpdate`)، بلا تأخير مرئي وبلا قطع لخطوة البناء | `writer_document_controller.dart:161` |
| إشعارات متفرّقة في مسار التحرير (`setActiveBlock`، `insertPageBreakAtCaret`، `mergeWithPreviousBlock`) | تُدمج في إشعار الموجة نفسه — والدمج لا يحتاج إشعاراً ثانياً لأنّ `_markDirty` ذاعه | `writer_document_controller.dart` |
| **`TextPainter.layout` مرتين لكل كتلة** (`linesOf` + `lineHeightOf`)، ومخزون بلا فائدة | مخزون LRU (سعة 512) بمفتاح **بصمة محتوى** (لأنّ `JoodWriterBlock` لا يعرّف `==`)، ونتيجة التخطيط تُخزَّن لا اللوحة نفسها، و`dispose()` بعد الاستخراج | `text_painter_measurer.dart` |
| **مقياس جديد في كل استدعاء** (`_splitOnce`، `_scrollToBlockPage`، `build`) ⇒ المخزون لا يعمل أبداً | مقياسٌ **مشترك حيٌّ** بين الإطارات، يُعاد بناؤه فقط عند تغيّر العرض أو مقياس الخط (`measurerFor`) | `writer_canvas.dart:94` |
| **`animateTo(220ms)` عند كل شطر** حتى لو كانت الصفحة الهدف معروضة أو حركة تمرير جارية | لا حركة إن كان صفّ الهدف هو صفّ سطح النظر بالفعل، ولا حركة فوق نشاط تمرير جارٍ (`isScrollingNotifier`) | `writer_canvas.dart:341` |

### الأثر

- ضغطة مفتاح واحدة: **تدفّق شطر واحد** بدل ثلاثة، و**إشعار واحد** بدل اثنين/ثلاثة، و**قياس واحد** للكتلة المتغيّرة بدل قياس كل كتل المستند ثلاث مرّات.
- الكتابة التي لا تتجاوز صفحتها: **لا تحرير، ولا حركة تمرير إطلاقاً**، والنصّ يبقى في موضعه حرفاً حرفاً.

## 5) التحقّق

`test/features/jood_writer_typing_stability_test.dart` — 17 اختباراً: مخزون القياس (عدم إعادة القياس، البصمة، السقف)، إشعار الموجة الواحدة، تجاوز الشطر المكرّر، وثبات التمرير أثناء الكتابة وانتقال النشاط.

مجموعة القبول (58 اختباراً) كلّها ناجحة:

```
flutter test test/features/jood_writer_flow_test.dart test/features/jood_writer_pagination_test.dart test/features/jood_writer_a4_split_test.dart test/features/jood_writer_typing_stability_test.dart
```
