import '../models/template_document.dart';
import '../models/template_element.dart';

/// حزمة محتوى بلد واحد (Locale Content Pack).
///
/// كل حزمة تحمل شيئين فقط، وتبقى **الهندسة والألوان كما هي** بلا أي مساس:
/// 1. [texts]: ترجمة النصوص الثابتة المكتوبة داخل القوالب. المفتاح هو النص
///    العربي كما هو حرفياً (رموز `{{الحقل}}` محفوظة داخل النص)، والقيمة هي
///    النص المترجم مع **نفس الرموز**، فيعمل الربط مع Excel كما هو.
/// 2. [sampleValues]: قيم البيانات التجريبية **الخاصة بالبلد** (أسماء الأشخاص
///    والمنشآت والعملة وصيغة التاريخ)، بمفاتيح الحقول نفسها.
///
/// هذه البنية تجعل إضافة لغة جديدة عمليةً واحدة: املأ خريطتين فقط.
class TemplateContentPack {
  const TemplateContentPack({
    this.texts = const <String, String>{},
    this.sampleValues = const <String, String>{},
  });

  /// نص عربي ← نص البلد (الرموز `{{...}}` محفوظة كما هي).
  final Map<String, String> texts;

  /// مفتاح حقل ديناميكي ← قيمة تجريبية محلية (اسم/تاريخ/عملة/صيغة).
  final Map<String, String> sampleValues;
}

/// **ترجمة محتوى القوالب** (Certificates & Contracts) إلى نصوص البلد.
///
/// لماذا محرّك منفصل عن `l10n`؟ لأن `l10n` يترجم **واجهة** التطبيق (أزرار
/// وتسميات)، أما هنا فالترجمة تمسّ **محتوى المستند نفسه**: نص الشهادة، صيغة
/// العقد، واسم المتدرّج والجهة المانحة والتاريخ. فالمستخدم الفرنسي يريد شهادة
/// بأسماء فرنسية وصيغة فرنسية، لا مجرد واجهة فرنسية حول نصّ عربي.
///
/// لا يُلزَم أي قالب بالترجمة: أي نص لا يوجد له مدخل في الحزمة **يبقى عربياً**
/// كما صُمِّم، فالتغطية تتوسّع بلا كسر أي قالب قائم.
abstract final class TemplateLocalization {
  const TemplateLocalization._();

  /// اللغة الأساسية للمحتوى (العربية) — لا حزمة لها لأن القوالب عربية أصلاً.
  static const String baseLanguageCode = 'ar';

  /// اللغات التي تُكتب من اليمين إلى اليسار (تُبقي اتجاه النص كما هو).
  static const Set<String> rtlLanguages = <String>{'ar', 'ur', 'he', 'fa'};

  /// الحزم المتاحة: مفتاحها رمز اللغة القصير (`ar`، `fr`، `en`…).
  static const Map<String, TemplateContentPack> packs =
      <String, TemplateContentPack>{
    'en': TemplateContentPack(texts: _enTexts, sampleValues: _enSamples),
    'fr': TemplateContentPack(texts: _frTexts, sampleValues: _frSamples),
    'es': TemplateContentPack(texts: _esTexts, sampleValues: _esSamples),
    'de': TemplateContentPack(texts: _deTexts, sampleValues: _deSamples),
    'tr': TemplateContentPack(texts: _trTexts, sampleValues: _trSamples),
    'id': TemplateContentPack(texts: _idTexts, sampleValues: _idSamples),
    'ru': TemplateContentPack(texts: _ruTexts, sampleValues: _ruSamples),
    'zh': TemplateContentPack(texts: _zhTexts, sampleValues: _zhSamples),
    'ur': TemplateContentPack(texts: _urTexts, sampleValues: _urSamples),
  };

  /// الرمز القصير للغة (`fr-CA` ← `fr`).
  static String shortCode(String? languageCode) {
    final String code = (languageCode ?? baseLanguageCode).trim().toLowerCase();
    final int dash = code.indexOf(RegExp('[-_]'));
    return dash == -1 ? code : code.substring(0, dash);
  }

  /// حزمة اللغة إن وُجدت (والعربية بلا حزمة لأنها الأصل).
  static TemplateContentPack? packFor(String? languageCode) =>
      packs[shortCode(languageCode)];

  /// هل اللغة تُكتب من اليمين إلى اليسار؟
  static bool isRtl(String? languageCode) =>
      rtlLanguages.contains(shortCode(languageCode));

  /// هل يوجد محتوى محلي لهذه اللغة (ترجمة نصوص أو قيم تجريبية)؟
  static bool hasContent(String? languageCode) {
    final TemplateContentPack? pack = packFor(languageCode);
    if (pack == null) return false;
    return pack.texts.isNotEmpty || pack.sampleValues.isNotEmpty;
  }

  /// النص المترجم لسلسلة عربية (أو نفسها إن لم توجد ترجمة).
  static String text(String? languageCode, String arabic) =>
      packFor(languageCode)?.texts[arabic] ?? arabic;

  /// القيمة التجريبية المحلية لمفتاح حقل (أو القيمة الأصلية).
  static String sampleValue(
    String? languageCode,
    String key, {
    required String fallback,
  }) =>
      packFor(languageCode)?.sampleValues[key] ?? fallback;

  /// يعيد **نسخة محلية** من المستند:
  ///
  /// * كل نص ثابت له ترجمة يُستبدل بها، ويُضبط اتجاهه إلى LTR للغات اللاتينية
  ///   (فتصبح محاذاة `start` يسارية كما يقتضي العقد الفرنسي/الإنجليزي).
  /// * كل قيمة تجريبية معروفة تُستبدل بقيمة البلد (أسماء/تاريخ/عملة).
  ///
  /// الهندسة (المقاسات والإحداثيات والألوان والخطوط) لا تُمسّ إطلاقاً.
  /// تُعيد المستند نفسه إن لم توجد حزمة للغة (مثل العربية).
  static TemplateDocument localize(
    TemplateDocument document,
    String? languageCode,
  ) {
    final TemplateContentPack? pack = packFor(languageCode);
    if (pack == null) return document;

    final bool latin = !isRtl(languageCode);
    final List<TemplateElement> elements = <TemplateElement>[
      for (final TemplateElement element in document.elements)
        _localizeElement(element, pack, latin: latin),
    ];

    Map<String, String> sampleData = document.sampleData;
    if (pack.sampleValues.isNotEmpty && sampleData.isNotEmpty) {
      sampleData = <String, String>{
        for (final MapEntry<String, String> entry in sampleData.entries)
          entry.key: pack.sampleValues[entry.key] ?? entry.value,
      };
    }

    final bool sameElements = identical(elements, document.elements) ||
        _sameElements(elements, document.elements);
    if (sameElements && identical(sampleData, document.sampleData)) {
      return document;
    }
    return document.copyWith(elements: elements, sampleData: sampleData);
  }

  /// يترجم عنصر نص واحد إن وُجدت له ترجمة.
  static TemplateElement _localizeElement(
    TemplateElement element,
    TemplateContentPack pack, {
    required bool latin,
  }) {
    if (element is! TextElement) return element;
    final String? translated = pack.texts[element.text];
    if (translated != null) {
      return element.copyWith(
        text: translated,
        // القوالب عربية الاتجاه أصلاً؛ اللغات اللاتينية تحتاج LTR صريحاً لتصبح
        // محاذاة `start` يسارية (عقود وإفادات) بلا انقلاب الترتيب.
        direction: latin ? ElementDirection.ltr : element.direction,
      );
    }
    // نصّ مكوّن من رموز فقط (كاسم المتدرّب أو الجهة المانحة) لا يحتاج ترجمة،
    // لكن اتجاهه يجب أن يصير لاتينياً ليُحاذى الاسم ضمن مستند لاتيني.
    if (latin && isPlaceholderOnly(element.text)) {
      return element.copyWith(direction: ElementDirection.ltr);
    }
    return element;
  }

  /// هل النص مكوّن من رموز `{{...}}` وفراغات فقط بلا أي حرف؟
  ///
  /// تُستخدم للتمييز بين نص يحتاج ترجمة، ونصّ ليس له معنى ثابت أصلاً (اسم
  /// متدرّب أو تاريخ يُدرجه المستخدم)، فلا معنى لإدخاله في خريطة الترجمات.
  static bool isPlaceholderOnly(String text) {
    final String remainder =
        text.replaceAll(RegExp(r'\{\{[^}]*\}\}'), '');
    // ما بقي بعد إزالة الرموز لا يحمل أي حرف (عربي أو لاتيني) — أي فراغات
    // وشرطات/فواصل فقط — فهذا نص رمزي لا يحتاج ترجمة.
    return !RegExp(r'[A-Za-z\u0600-\u06FF]').hasMatch(remainder);
  }

  static bool _sameElements(
    List<TemplateElement> a,
    List<TemplateElement> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}

// ===========================================================================
//  English
// ===========================================================================

const Map<String, String> _enTexts = <String, String>{
  // ---- عناوين القوالب (تظهر أيضاً كعنوان البطاقة في المكتبة) ----
  'شهادة شكر وتقدير': 'Certificate of Appreciation',
  'شهادة إتمام دورة تدريبية': 'Certificate of Course Completion',
  'شهادة تفوق وتميّز': 'Certificate of Excellence',
  'إفادة خبرة': 'Certificate of Employment',
  'عقد عمل': 'Employment Contract',
  'عقد تقديم خدمات': 'Service Agreement',
  'شهادة تقدير كلاسيكية': 'Classic Certificate of Appreciation',
  'شهادة إنجاز بارز': 'Certificate of Outstanding Achievement',
  'شهادة حضور وتدريب': 'Certificate of Attendance',
  'شهادة تقدّم علمي': 'Certificate of Academic Progress',
  'عقد عمل مؤقت': 'Fixed-Term Employment Contract',
  'شهادة ملكية كحلية': 'Royal Navy Certificate',
  'شهادة الجدارة العنابية': 'Burgundy Merit Certificate',
  'شهادة الاستحقاق الملكي': 'Imperial Merit Certificate',
  'شهادة عصرية هادئة': 'Minimal Pastel Certificate',
  'شهادة هندسية زرقاء': 'Geometric Blue Certificate',
  'شهادة التدرّج الناعم': 'Soft Gradient Certificate',
  'شهادة رسمية مؤسسية': 'Corporate Official Certificate',
  'شهادة تنفيذية': 'Executive Certificate',
  'شهادة الاعتماد المهني': 'Professional Accreditation Certificate',
  'شهادة أكاديمية بختم': 'Academic Certificate with Seal',
  'شهادة تقدير أنيقة': 'Elegant Certificate of Appreciation',
  'شهادة مرتبة الشرف': 'Honours Certificate',
  // ---- نصوص الشهادات ----
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      'The management of {{الجهة_المانحة}} certifies that',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} certifies that',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'demonstrated outstanding effort and exemplary performance worthy of '
          'recognition and praise. We wish them continued success.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'has successfully completed the training programme “{{اسم_الدورة}}” of '
          '{{مدة_الدورة}} under the supervision of {{المدرب}}, showing '
          'commitment and outstanding performance.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      'for achieving {{مستوى_الأداء}} in {{اسم_الدورة}}, in recognition of '
          'their diligence, excellence and eagerness to learn.',
  'التاريخ: {{التاريخ}}': 'Date: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'Executive Director — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}':
      'Executive Director — {{اسم_المنشأة}}',
  'التوقيع المعتمد': 'Authorised signature',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'To verify this certificate: {{رقم_الشهادة}}',
  'مدير الأكاديمية': 'Academy Director',
  'مدير المدرسة': 'School Principal',
  // ---- الإفادات ----
  'إلى من يهمه الأمر،': 'To whom it may concern,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'We certify that {{اسم_الطرف_الثاني}} was employed by {{اسم_المنشأة}} '
          'from {{تاريخ_البداية}} to {{تاريخ_النهاية}}, and demonstrated '
          'competence, discipline and full commitment in performing the duties '
          'assigned to them.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'This certificate is issued at their request for submission to the '
          'competent authorities when needed, without any liability on the '
          'establishment.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.':
      'Please accept our highest regards and appreciation.',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'This certificate was issued electronically via the JoodCraft platform.',
  // ---- العقود ----
  'الرقم المرجعي: {{رقم_العقد}}': 'Reference no.: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      'On {{تاريخ_البداية}}, it was agreed between:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      'On {{تاريخ_العقد}}, it was agreed between:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'First party (the employer): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'Second party (the employee): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'First party: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'Second party: {{اسم_الطرف_الثاني}}',
  'البند الأول: المدة': 'Clause one: Term',
  'البند الثاني: الأجر': 'Clause two: Remuneration',
  'البند الثاني: المقابل المالي': 'Clause two: Fees',
  'البند الأول: نطاق العمل': 'Clause one: Scope of work',
  'البند الثالث: الأحكام العامة': 'Clause three: General provisions',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'This contract begins on {{تاريخ_البداية}} and ends on '
          '{{تاريخ_النهاية}}, and may be renewed by written agreement between '
          'the parties.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'The second party is entitled to remuneration of {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'The second party is entitled to fees of {{قيمة_العقد}} for the '
          'services. {{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'This contract is governed by the labour regulations in force in the '
          'Kingdom of Saudi Arabia, and any dispute arising from it shall be '
          'referred to the competent authority.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'This contract is governed by the laws of the Kingdom of Saudi Arabia, '
          'and any dispute arising from it shall be referred to the competent '
          'judicial authority.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'The second party undertakes to provide the agreed services in '
          'accordance with the specifications and terms set out in the '
          'technical annex to this contract.',
  'الطرف الأول': 'First party',
  'الطرف الثاني': 'Second party',
  // ---- إكمال تغطية قوالب المعرض (20/20) ----
  'شهادة أكاديمية': 'Academic certificate',
  'شهادة إتمام': 'Certificate of completion',
  'شهادة إتمام معتمدة': 'Certified completion certificate',
  'شهادة الجدارة والتميّز': 'Certificate of merit and excellence',
  'شهادة تقدير ملكية': 'Royal certificate of appreciation',
  'شهادة تنفيذية معتمدة': 'Certified executive certificate',
  'شهادة معتمدة رسمياً': 'Officially certified certificate',
  'عقد تقديم استشارات': 'Consultancy services agreement',
  'الجهة المانحة': 'Issuing authority',
  'الرئيس التنفيذي': 'Chief Executive Officer',
  'المدرب': 'Trainer',
  'المدرّب المعتمد': 'Certified trainer',
  'المدير الأكاديمي': 'Academic director',
  'المدير التنفيذي': 'Executive director',
  'المدير العام': 'General manager',
  'الموارد البشرية': 'Human resources',
  'مدير البرنامج': 'Programme director',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'Programme director — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Head of judging',
  'مدير المركز': 'Centre director',
  'عميد الكلية': 'Dean of the faculty',
  'عميد المعهد': 'Dean of the institute',
  'يتقدّم المعهد بالتهنئة إلى': 'The institute congratulates',
  'يُكرَّم المتدرب': 'The trainee is honoured',
  'تُمنح هذه الشهادة إلى': 'This certificate is awarded to',
  'تُمنح بمرتبة الشرف إلى': 'conferred with honours upon',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} certifies that',
  'رقم الشهادة: {{رقم_الشهادة}}': 'Certificate no.: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'Certificate no.: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Verification: {{رقم_الشهادة}}',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'This certificate was issued electronically via the JoodCraft platform.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'Issued electronically via JoodCraft — {{رقم_الشهادة}}',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'has successfully completed the “{{اسم_الدورة}}” of {{مدة_الدورة}} '
          'under the supervision of {{المدرب}}.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'has successfully completed the “{{اسم_الدورة}}” of {{مدة_الدورة}} '
          'under the supervision of {{المدرب}}, achieving {{مستوى_الأداء}}.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'has successfully completed the training programme “{{اسم_الدورة}}” of '
          '{{مدة_الدورة}} under the supervision of {{المدرب}}.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'has successfully completed the “{{اسم_الدورة}}” programme of '
          '{{مدة_الدورة}}, showing commitment and outstanding performance.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'has attended and passed the training programme “{{اسم_الدورة}}” of '
          '{{مدة_الدورة}} under the supervision of {{المدرب}}, showing excellent '
          'commitment and discipline.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'has successfully completed the “{{اسم_الدورة}}” programme and is '
          'honoured for achieving {{مستوى_الأداء}}.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'has completed the “{{اسم_الدورة}}” programme with success and '
          'distinction, and is honoured for achieving {{مستوى_الأداء}} in '
          'appreciation of outstanding academic effort.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'in acknowledgement of completing “{{اسم_الدورة}}” of {{مدة_الدورة}} '
          'under the supervision of {{المدرب}}.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      'for achieving {{مستوى_الأداء}} in “{{اسم_الدورة}}”, in recognition of '
          'their excellence and sustained diligence.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      'for achieving {{مستوى_الأداء}} in {{اسم_الدورة}}, in recognition of '
          'their excellence, sustained diligence and pursuit of distinction.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'in recognition of outstanding performance, successful completion of '
          '“{{اسم_الدورة}}”, and achievement of {{مستوى_الأداء}}.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'in recognition of their diligence, excellence and eagerness to learn, '
          'having achieved {{مستوى_الأداء}} in {{اسم_الدورة}}.',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'for the commitment and mastery shown, which deserve recognition, and '
          'for achieving {{مستوى_الأداء}} in {{اسم_الدورة}}.',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'in recognition of outstanding effort and exemplary performance. We wish '
          'them continued success.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'in recognition of distinguished effort and outstanding performance '
          'worthy of our values. We wish them continued success.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'in recognition of distinguished effort and outstanding performance '
          'worthy of our values, a model of mastery and commitment. We wish them '
          'continued success.',
  'البند الأول: مدة العقد': 'Clause one: Contract term',
  'البند الثاني: الأجر وطريقة الدفع':
      'Clause two: Remuneration and payment method',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'This contract is concluded for a fixed term beginning on '
          '{{تاريخ_البداية}} and ending on {{تاريخ_النهاية}}, and may not be '
          'extended except by prior written agreement between the parties.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'The second party is entitled to remuneration of {{قيمة_العقد}}, paid '
          'regularly in accordance with {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'The second party is entitled to consultancy fees of {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'The second party undertakes to provide the agreed consultancy services '
          'in accordance with the specifications and terms set out in the '
          'technical annex attached to this contract.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'This contract is governed by the labour regulations in force, and any '
          'dispute arising from it shall be referred to the competent authority '
          'in accordance with the applicable procedures.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'This contract was drawn up electronically via the JoodCraft platform.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'This contract was drawn up electronically via the JoodCraft platform '
          'on {{تاريخ_العقد}}',
};

const Map<String, String> _enSamples = <String, String>{
  'اسم_المتدرب': 'Daniel Whitfield',
  'اسم_الدورة': 'Professional Project Management',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 January 2026',
  'الجهة_المانحة': 'JoodCraft Academy',
  'المدرب': 'Dr. Sarah Mitchell',
  'مدة_الدورة': '40 training hours',
  'مستوى_الأداء': 'First place',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'Jood Trading Company',
  'اسم_الطرف_الثاني': 'Horizon Contracting LLC',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 January 2026',
  'تاريخ_البداية': '1 February 2026',
  'تاريخ_النهاية': '1 December 2026',
  'قيمة_العقد': 'SAR 150,000',
  'طريقة_الدفع': '40% advance payment and the balance on delivery.',
  'اسم_المنشأة': 'JoodCraft',
};

// ===========================================================================
//  Français
// ===========================================================================

const Map<String, String> _frTexts = <String, String>{
  'شهادة شكر وتقدير': 'Certificat de reconnaissance',
  'شهادة إتمام دورة تدريبية': 'Certificat de fin de formation',
  'شهادة تفوق وتميّز': 'Certificat d’excellence',
  'إفادة خبرة': 'Attestation de travail',
  'عقد عمل': 'Contrat de travail',
  'عقد تقديم خدمات': 'Contrat de prestation de services',
  'شهادة تقدير كلاسيكية': 'Certificat de reconnaissance classique',
  'شهادة إنجاز بارز': 'Certificat de réalisation remarquable',
  'شهادة حضور وتدريب': 'Certificat de présence et de formation',
  'شهادة تقدّم علمي': 'Certificat de progrès académique',
  'عقد عمل مؤقت': 'Contrat de travail à durée déterminée',
  'شهادة ملكية كحلية': 'Certificat royal bleu nuit',
  'شهادة الجدارة العنابية': 'Certificat de mérite bordeaux',
  'شهادة الاستحقاق الملكي': 'Certificat de mérite impérial',
  'شهادة عصرية هادئة': 'Certificat minimaliste pastel',
  'شهادة هندسية زرقاء': 'Certificat géométrique bleu',
  'شهادة التدرّج الناعم': 'Certificat dégradé doux',
  'شهادة رسمية مؤسسية': 'Certificat officiel d’entreprise',
  'شهادة تنفيذية': 'Certificat exécutif',
  'شهادة الاعتماد المهني': 'Certificat d’accréditation professionnelle',
  'شهادة أكاديمية بختم': 'Certificat académique avec sceau',
  'شهادة تقدير أنيقة': 'Certificat de reconnaissance élégant',
  'شهادة مرتبة الشرف': 'Certificat de mention honorable',
  // ---- en-têtes latins déjà présents dans les modèles ----
  'CERTIFICATE OF APPRECIATION': 'CERTIFICAT DE RECONNAISSANCE',
  'CERTIFICATE OF COMPLETION': 'CERTIFICAT DE FIN DE FORMATION',
  'CERTIFICATE OF EXCELLENCE': 'CERTIFICAT D’EXCELLENCE',
  'CERTIFICATE OF ACHIEVEMENT': 'CERTIFICAT DE RÉALISATION',
  'CERTIFICATE OF ATTENDANCE': 'CERTIFICAT DE PRÉSENCE',
  'CERTIFICATE OF PROGRESS': 'CERTIFICAT DE PROGRÈS',
  // ---- textes des certificats ----
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      'La direction de {{الجهة_المانحة}} certifie que',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} certifie que',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'a fait preuve d’efforts remarquables et d’une performance exemplaire '
          'digne de reconnaissance et d’éloges. Nous lui souhaitons une '
          'réussite continue.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'a achevé avec succès le programme de formation « {{اسم_الدورة}} » d’une '
          'durée de {{مدة_الدورة}} sous la supervision de {{المدرب}}, en '
          'faisant preuve d’engagement et d’excellence.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      'pour avoir obtenu {{مستوى_الأداء}} en {{اسم_الدورة}}, en reconnaissance '
          'de sa diligence, de son excellence et de son goût de l’apprentissage.',
  'التاريخ: {{التاريخ}}': 'Date : {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'Directeur général — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}': 'Directeur général — {{اسم_المنشأة}}',
  'التوقيع المعتمد': 'Signature autorisée',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'Pour vérifier ce certificat : {{رقم_الشهادة}}',
  'مدير الأكاديمية': 'Directeur de l’académie',
  'مدير المدرسة': 'Directeur de l’école',
  // ---- attestations ----
  'إلى من يهمه الأمر،': 'À qui de droit,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'Nous attestons que {{اسم_الطرف_الثاني}} a été employé(e) par '
          '{{اسم_المنشأة}} du {{تاريخ_البداية}} au {{تاريخ_النهاية}}, et a '
          'fait preuve de compétence, de discipline et d’un plein engagement '
          'dans l’exécution des tâches confiées.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'Cette attestation est délivrée à sa demande pour être présentée aux '
          'autorités compétentes en cas de besoin, sans aucune responsabilité '
          'pour l’établissement.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.':
      'Veuillez agréer nos salutations les plus respectueuses.',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'Cette attestation a été délivrée électroniquement via la plateforme '
          'JoodCraft.',
  // ---- contrats ----
  'الرقم المرجعي: {{رقم_العقد}}': 'Référence : {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      'Le {{تاريخ_البداية}}, il a été convenu entre :',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      'Le {{تاريخ_العقد}}, il a été convenu entre :',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'Première partie (l’employeur) : {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'Seconde partie (l’employé) : {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}':
      'Première partie : {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}':
      'Seconde partie : {{اسم_الطرف_الثاني}}',
  'البند الأول: المدة': 'Article premier : Durée',
  'البند الثاني: الأجر': 'Article deux : Rémunération',
  'البند الثاني: المقابل المالي': 'Article deux : Honoraires',
  'البند الأول: نطاق العمل': 'Article premier : Objet de la prestation',
  'البند الثالث: الأحكام العامة': 'Article trois : Dispositions générales',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'Le présent contrat prend effet le {{تاريخ_البداية}} et se termine le '
          '{{تاريخ_النهاية}} ; il peut être renouvelé par accord écrit entre '
          'les parties.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'La seconde partie percevra une rémunération de {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'La seconde partie percevra pour ses services la somme de {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'Le présent contrat est régi par la réglementation du travail en vigueur '
          'au Royaume d’Arabie saoudite, et tout litige sera soumis à l’autorité '
          'compétente.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'Le présent contrat est régi par les lois du Royaume d’Arabie saoudite, '
          'et tout litige sera soumis à l’autorité judiciaire compétente.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'La seconde partie s’engage à fournir les services convenus conformément '
          'aux spécifications et conditions figurant à l’annexe technique du '
          'présent contrat.',
  'الطرف الأول': 'Première partie',
  'الطرف الثاني': 'Seconde partie',
  // ---- إكمال تغطية قوالب المعرض (20/20) ----
  'ACADEMIC CERTIFICATE': 'CERTIFICAT ACADÉMIQUE',
  'CERTIFICATE OF DISTINCTION': 'CERTIFICAT DE DISTINCTION',
  'CERTIFIED COMPLETION': 'ACHÈVEMENT CERTIFIÉ',
  'HONORS CERTIFICATE': 'CERTIFICAT DE MENTION HONORABLE',
  'IMPERIAL CERTIFICATE OF HONOR': 'CERTIFICAT IMPÉRIAL D HONNEUR',
  'OFFICIAL CERTIFICATE': 'CERTIFICAT OFFICIEL',
  'PROFESSIONAL ACCREDITATION': 'ACCRÉDITATION PROFESSIONNELLE',
  'ROYAL CERTIFICATE OF MERIT': 'CERTIFICAT ROYAL DE MÉRITE',
  'شهادة أكاديمية': 'Certificat académique',
  'شهادة إتمام': 'Certificat de fin de formation',
  'شهادة إتمام معتمدة': 'Certificat d’achèvement certifié',
  'شهادة الجدارة والتميّز': 'Certificat de mérite et d’excellence',
  'شهادة تقدير ملكية': 'Certificat royal de reconnaissance',
  'شهادة تنفيذية معتمدة': 'Certificat exécutif certifié',
  'شهادة معتمدة رسمياً': 'Certificat officiellement certifié',
  'عقد تقديم استشارات': 'Contrat de prestation de conseil',
  'الجهة المانحة': 'Organisme émetteur',
  'الرئيس التنفيذي': 'Président-directeur général',
  'المدرب': 'Formateur',
  'المدرّب المعتمد': 'Formateur agréé',
  'المدير الأكاديمي': 'Directeur académique',
  'المدير التنفيذي': 'Directeur exécutif',
  'المدير العام': 'Directeur général',
  'الموارد البشرية': 'Ressources humaines',
  'مدير البرنامج': 'Directeur du programme',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'Directeur du programme — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Responsable du jury',
  'مدير المركز': 'Directeur du centre',
  'عميد الكلية': 'Doyen de la faculté',
  'عميد المعهد': 'Directeur de l’institut',
  'يتقدّم المعهد بالتهنئة إلى': 'L’institut félicite',
  'يُكرَّم المتدرب': 'Le stagiaire est honoré',
  'تُمنح هذه الشهادة إلى': 'Ce certificat est décerné à',
  'تُمنح بمرتبة الشرف إلى': 'décerné avec mention honorable à',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} certifie que',
  'رقم الشهادة: {{رقم_الشهادة}}': 'N° de certificat : {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'N° de certificat : {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Vérification : {{رقم_الشهادة}}',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'Ce certificat a été délivré électroniquement via la plateforme '
          'JoodCraft.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'Délivré électroniquement via JoodCraft — {{رقم_الشهادة}}',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'a achevé avec succès « {{اسم_الدورة}} » d’une durée de {{مدة_الدورة}} '
          'sous la supervision de {{المدرب}}.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'a achevé avec succès « {{اسم_الدورة}} » d’une durée de {{مدة_الدورة}} '
          'sous la supervision de {{المدرب}}, avec l’obtention de '
          '{{مستوى_الأداء}}.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'a achevé avec succès le programme de formation « {{اسم_الدورة}} » d’une '
          'durée de {{مدة_الدورة}} sous la supervision de {{المدرب}}.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'a achevé avec succès le programme « {{اسم_الدورة}} » d’une durée de '
          '{{مدة_الدورة}}, en faisant preuve d’engagement et d’excellence.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'a suivi et réussi le programme de formation « {{اسم_الدورة}} » d’une '
          'durée de {{مدة_الدورة}} sous la supervision de {{المدرب}}, en faisant '
          'preuve d’un engagement et d’une discipline excellents.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'a achevé avec succès le programme « {{اسم_الدورة}} » et est honoré(e) '
          'pour avoir obtenu {{مستوى_الأداء}}.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'a achevé avec succès et excellence le programme « {{اسم_الدورة}} » et '
          'est honoré(e) pour avoir obtenu {{مستوى_الأداء}}, en reconnaissance '
          'de son remarquable apport académique.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'en attestation de la réussite de « {{اسم_الدورة}} » d’une durée de '
          '{{مدة_الدورة}} sous la supervision de {{المدرب}}.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      'pour avoir obtenu {{مستوى_الأداء}} en « {{اسم_الدورة}} », en '
          'reconnaissance de son excellence et de sa diligence constante.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      'pour avoir obtenu {{مستوى_الأداء}} en {{اسم_الدورة}}, en reconnaissance '
          'de son excellence, de sa diligence constante et de sa recherche de '
          'la distinction.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'en reconnaissance d’une performance remarquable, de la réussite de '
          '« {{اسم_الدورة}} » et de l’obtention de {{مستوى_الأداء}}.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'en reconnaissance de sa diligence, de son excellence et de son goût de '
          'l’apprentissage, ayant obtenu {{مستوى_الأداء}} en {{اسم_الدورة}}.',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'pour l’engagement et la maîtrise démontrés, qui méritent '
          'reconnaissance, et pour avoir obtenu {{مستوى_الأداء}} en '
          '{{اسم_الدورة}}.',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'en reconnaissance de ses efforts remarquables et d’une performance '
          'exemplaire. Nous lui souhaitons une réussite continue.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'en reconnaissance de ses efforts distingués et d’une performance '
          'remarquable digne de nos valeurs, avec nos vœux de réussite '
          'continue.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'en reconnaissance de ses efforts distingués et d’une performance '
          'remarquable digne de nos valeurs, exemple de maîtrise et '
          'd’engagement. Nous lui souhaitons une réussite continue.',
  'البند الأول: مدة العقد': 'Article premier : Durée du contrat',
  'البند الثاني: الأجر وطريقة الدفع':
      'Article deux : Rémunération et modalités de paiement',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'Le présent contrat est conclu pour une durée déterminée commençant le '
          '{{تاريخ_البداية}} et se terminant le {{تاريخ_النهاية}} ; il ne peut '
          'être prolongé que par accord écrit préalable entre les parties.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'La seconde partie percevra une rémunération de {{قيمة_العقد}}, versée '
          'régulièrement conformément à {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'La seconde partie percevra pour ses prestations de conseil la somme de '
          '{{قيمة_العقد}}. {{طريقة_الدفع}}',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'La seconde partie s’engage à fournir les prestations de conseil '
          'convenues conformément aux spécifications et conditions figurant à '
          'l’annexe technique jointe au présent contrat.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'Le présent contrat est régi par la réglementation du travail en '
          'vigueur, et tout litige sera soumis à l’autorité compétente selon les '
          'procédures applicables.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'Ce contrat a été établi électroniquement via la plateforme JoodCraft.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'Ce contrat a été établi électroniquement via la plateforme JoodCraft le '
          '{{تاريخ_العقد}}',
};

const Map<String, String> _frSamples = <String, String>{
  'اسم_المتدرب': 'Camille Dubois',
  'اسم_الدورة': 'Gestion de projet professionnelle',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 janvier 2026',
  'الجهة_المانحة': 'Académie JoodCraft',
  'المدرب': 'Dr Claire Moreau',
  'مدة_الدورة': '40 heures de formation',
  'مستوى_الأداء': 'Première place',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'Société Jood Commerce',
  'اسم_الطرف_الثاني': 'Horizon Travaux SARL',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 janvier 2026',
  'تاريخ_البداية': '1er février 2026',
  'تاريخ_النهاية': '1er décembre 2026',
  'قيمة_العقد': '150 000 SAR',
  'طريقة_الدفع': '40 % à la commande et le solde à la livraison.',
  'اسم_المنشأة': 'JoodCraft',
};

// ===========================================================================
//  بقية اللغات (الإسبانية والألمانية والتركية والإندونيسية والروسية
//  والصينية والأردية): ترجمة كاملة لنصوص القوالب + قيم بيانات تجريبية
//  خاصة بكل بلد (أسماء وصيغ تاريخ وعملة).
//
//  النصوص الثابتة مفتاحها النص العربي حرفياً والقيمة ترجمته، مع الحفاظ على
//  رموز `{{الحقل}}` كما هي فيعمل الربط مع Excel بلا كسر. أما قيم البيانات
//  التجريبية فتجعل اسم المتدرّج والتاريخ والعملة بلغة البلد فوراً.
// ===========================================================================

const Map<String, String> _esTexts = <String, String>{
  'شهادة شكر وتقدير': 'Certificado de reconocimiento',
  'شهادة إتمام دورة تدريبية': 'Certificado de fin de curso',
  'شهادة تفوق وتميّز': 'Certificado de excelencia',
  'إفادة خبرة': 'Certificado laboral',
  'عقد عمل': 'Contrato de trabajo',
  'عقد تقديم خدمات': 'Contrato de prestación de servicios',
  'شهادة تقدير كلاسيكية': 'Certificado de reconocimiento clásico',
  'شهادة إنجاز بارز': 'Certificado de logro destacado',
  'شهادة حضور وتدريب': 'Certificado de asistencia y formación',
  'شهادة تقدّم علمي': 'Certificado de progreso académico',
  'عقد عمل مؤقت': 'Contrato de trabajo temporal',
  'شهادة ملكية كحلية': 'Certificado azul marino real',
  'شهادة الجدارة العنابية': 'Certificado de mérito burdeos',
  'شهادة الاستحقاق الملكي': 'Certificado de mérito imperial',
  'شهادة عصرية هادئة': 'Certificado minimalista pastel',
  'شهادة هندسية زرقاء': 'Certificado geométrico azul',
  'شهادة التدرّج الناعم': 'Certificado de degradado suave',
  'شهادة رسمية مؤسسية': 'Certificado oficial corporativo',
  'شهادة تنفيذية': 'Certificado ejecutivo',
  'شهادة الاعتماد المهني': 'Certificado de acreditación profesional',
  'شهادة أكاديمية بختم': 'Certificado académico con sello',
  'شهادة تقدير أنيقة': 'Certificado de reconocimiento elegante',
  'شهادة مرتبة الشرف': 'Certificado de mención honorífica',
  'شهادة أكاديمية': 'Certificado académico',
  'شهادة إتمام': 'Certificado de finalización',
  'شهادة إتمام معتمدة': 'Certificado de finalización acreditado',
  'شهادة الجدارة والتميّز': 'Certificado de mérito y excelencia',
  'شهادة تقدير ملكية': 'Certificado real de reconocimiento',
  'شهادة تنفيذية معتمدة': 'Certificado ejecutivo acreditado',
  'شهادة معتمدة رسمياً': 'Certificado oficialmente acreditado',
  'عقد تقديم استشارات': 'Contrato de prestación de consultoría',
  'ACADEMIC CERTIFICATE': 'CERTIFICADO ACADÉMICO',
  'CERTIFICATE OF DISTINCTION': 'CERTIFICADO DE DISTINCIÓN',
  'CERTIFIED COMPLETION': 'FINALIZACIÓN CERTIFICADA',
  'HONORS CERTIFICATE': 'CERTIFICADO DE HONORES',
  'IMPERIAL CERTIFICATE OF HONOR': 'CERTIFICADO IMPERIAL DE HONOR',
  'OFFICIAL CERTIFICATE': 'CERTIFICADO OFICIAL',
  'PROFESSIONAL ACCREDITATION': 'ACREDITACIÓN PROFESIONAL',
  'ROYAL CERTIFICATE OF MERIT': 'CERTIFICADO REAL DE MÉRITO',
  'CERTIFICATE OF APPRECIATION': 'CERTIFICADO DE RECONOCIMIENTO',
  'CERTIFICATE OF COMPLETION': 'CERTIFICADO DE FIN DE CURSO',
  'CERTIFICATE OF EXCELLENCE': 'CERTIFICADO DE EXCELENCIA',
  'CERTIFICATE OF ACHIEVEMENT': 'CERTIFICADO DE LOGRO',
  'CERTIFICATE OF ATTENDANCE': 'CERTIFICADO DE ASISTENCIA',
  'CERTIFICATE OF PROGRESS': 'CERTIFICADO DE PROGRESO',
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      'La dirección de {{الجهة_المانحة}} certifica que',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} certifica que',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} certifica que',
  'الجهة المانحة': 'Organismo emisor',
  'الرئيس التنفيذي': 'Director general',
  'المدرب': 'Formador',
  'المدرّب المعتمد': 'Formador acreditado',
  'المدير الأكاديمي': 'Director académico',
  'المدير التنفيذي': 'Director ejecutivo',
  'المدير العام': 'Gerente general',
  'الموارد البشرية': 'Recursos humanos',
  'مدير الأكاديمية': 'Director de la academia',
  'مدير المدرسة': 'Director del centro escolar',
  'مدير البرنامج': 'Director del programa',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'Director del programa — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Responsable del jurado',
  'مدير المركز': 'Director del centro',
  'عميد الكلية': 'Decano de la facultad',
  'عميد المعهد': 'Director del instituto',
  'التوقيع المعتمد': 'Firma autorizada',
  'التاريخ: {{التاريخ}}': 'Fecha: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'Director ejecutivo — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}':
      'Director ejecutivo — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': 'N.º de certificado: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'N.º de certificado: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Verificación: {{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'Para verificar este certificado: {{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': 'El instituto felicita a',
  'يُكرَّم المتدرب': 'Se distingue al alumno',
  'تُمنح هذه الشهادة إلى': 'Este certificado se otorga a',
  'تُمنح بمرتبة الشرف إلى': 'otorgado con mención honorífica a',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'Este certificado se emitió electrónicamente a través de la plataforma '
          'JoodCraft.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'Emitido electrónicamente por JoodCraft — {{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'ha demostrado un esfuerzo sobresaliente y un desempeño ejemplar dignos '
          'de reconocimiento. Le deseamos un éxito continuo.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'ha completado con éxito el programa «{{اسم_الدورة}}» de '
          '{{مدة_الدورة}} bajo la supervisión de {{المدرب}}, mostrando '
          'compromiso y un desempeño sobresaliente.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      'por alcanzar {{مستوى_الأداء}} en {{اسم_الدورة}}, en reconocimiento a su '
          'esfuerzo, excelencia e interés por aprender.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'ha completado con éxito «{{اسم_الدورة}}» de {{مدة_الدورة}} bajo la '
          'supervisión de {{المدرب}}.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'ha completado con éxito «{{اسم_الدورة}}» de {{مدة_الدورة}} bajo la '
          'supervisión de {{المدرب}}, obteniendo {{مستوى_الأداء}}.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'ha completado con éxito el programa de formación «{{اسم_الدورة}}» de '
          '{{مدة_الدورة}} bajo la supervisión de {{المدرب}}.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'ha completado con éxito el programa «{{اسم_الدورة}}» de '
          '{{مدة_الدورة}}, mostrando compromiso y excelencia.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'ha asistido y superado el programa de formación «{{اسم_الدورة}}» de '
          '{{مدة_الدورة}} bajo la supervisión de {{المدرب}}, con un compromiso '
          'y una disciplina excelentes.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'ha completado con éxito el programa «{{اسم_الدورة}}» y se le distingue '
          'por obtener {{مستوى_الأداء}}.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'ha completado con éxito y distinción el programa «{{اسم_الدورة}}» y se '
          'le distingue por obtener {{مستوى_الأداء}}, en reconocimiento a su '
          'destacada aportación académica.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'en constancia de haber completado «{{اسم_الدورة}}» de {{مدة_الدورة}} '
          'bajo la supervisión de {{المدرب}}.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      'por obtener {{مستوى_الأداء}} en «{{اسم_الدورة}}», en reconocimiento a '
          'su excelencia y constancia.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      'por obtener {{مستوى_الأداء}} en {{اسم_الدورة}}, en reconocimiento a su '
          'excelencia, constancia y afán de distinción.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'en reconocimiento a su desempeño sobresaliente, a la finalización de '
          '«{{اسم_الدورة}}» y a la obtención de {{مستوى_الأداء}}.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'en reconocimiento a su esfuerzo, excelencia e interés por aprender, '
          'habiendo obtenido {{مستوى_الأداء}} en {{اسم_الدورة}}.',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'por el compromiso y la maestría demostrados, dignos de reconocimiento, '
          'y por obtener {{مستوى_الأداء}} en {{اسم_الدورة}}.',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'en reconocimiento a su esfuerzo sobresaliente y desempeño ejemplar. Le '
          'deseamos un éxito continuo.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'en reconocimiento a su esfuerzo distinguido y desempeño sobresaliente, '
          'dignos de nuestros valores. Le deseamos un éxito continuo.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'en reconocimiento a su esfuerzo distinguido y desempeño sobresaliente, '
          'dignos de nuestros valores y ejemplo de maestría y compromiso. Le '
          'deseamos un éxito continuo.',
  'إلى من يهمه الأمر،': 'A quien corresponda,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'Certificamos que {{اسم_الطرف_الثاني}} ha trabajado en '
          '{{اسم_المنشأة}} desde el {{تاريخ_البداية}} hasta el '
          '{{تاريخ_النهاية}}, demostrando competencia, disciplina y pleno '
          'compromiso en el desempeño de las tareas encomendadas.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'Este certificado se expide a petición del interesado para presentarlo '
          'ante las autoridades competentes cuando sea necesario, sin '
          'responsabilidad alguna para la entidad.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.':
      'Reciban nuestro más alto respeto y consideración.',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'Este certificado se emitió electrónicamente a través de la plataforma '
          'JoodCraft.',
  'الرقم المرجعي: {{رقم_العقد}}': 'Referencia: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      'El {{تاريخ_البداية}}, se acordó entre:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      'El {{تاريخ_العقد}}, se acordó entre:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'Primera parte (el empleador): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'Segunda parte (el trabajador): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'Primera parte: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'Segunda parte: {{اسم_الطرف_الثاني}}',
  'الطرف الأول': 'Primera parte',
  'الطرف الثاني': 'Segunda parte',
  'البند الأول: المدة': 'Cláusula primera: Duración',
  'البند الثاني: الأجر': 'Cláusula segunda: Remuneración',
  'البند الثاني: المقابل المالي': 'Cláusula segunda: Honorarios',
  'البند الأول: نطاق العمل': 'Cláusula primera: Alcance del trabajo',
  'البند الثالث: الأحكام العامة': 'Cláusula tercera: Disposiciones generales',
  'البند الأول: مدة العقد': 'Cláusula primera: Duración del contrato',
  'البند الثاني: الأجر وطريقة الدفع':
      'Cláusula segunda: Remuneración y forma de pago',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'La duración de este contrato comienza el {{تاريخ_البداية}} y finaliza '
          'el {{تاريخ_النهاية}}, y podrá renovarse por acuerdo escrito entre '
          'las partes.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'La segunda parte percibirá una remuneración de {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'La segunda parte percibirá por sus servicios {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'La segunda parte percibirá una remuneración de {{قيمة_العقد}}, abonada '
          'regularmente conforme a {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'La segunda parte percibirá por sus servicios de consultoría '
          '{{قيمة_العقد}}. {{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'Este contrato se rige por la normativa laboral vigente en el Reino de '
          'Arabia Saudí, y cualquier controversia se remitirá a la autoridad '
          'competente.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'Este contrato se rige por las leyes del Reino de Arabia Saudí, y '
          'cualquier controversia se remitirá a la autoridad judicial '
          'competente.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'Este contrato se rige por la normativa laboral vigente, y cualquier '
          'controversia se remitirá a la autoridad competente conforme a los '
          'procedimientos aplicables.',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'Este contrato se celebra por un plazo determinado que comienza el '
          '{{تاريخ_البداية}} y finaliza el {{تاريخ_النهاية}}, y no podrá '
          'prorrogarse salvo por acuerdo escrito previo entre las partes.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'La segunda parte se compromete a prestar los servicios acordados '
          'conforme a las especificaciones y condiciones del anexo técnico de '
          'este contrato.',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'La segunda parte se compromete a prestar los servicios de consultoría '
          'acordados conforme a las especificaciones y condiciones del anexo '
          'técnico adjunto a este contrato.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'Este contrato se redactó electrónicamente a través de la plataforma '
          'JoodCraft.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'Este contrato se redactó electrónicamente a través de la plataforma '
          'JoodCraft el {{تاريخ_العقد}}',
};

const Map<String, String> _esSamples = <String, String>{
  'اسم_المتدرب': 'Lucía Fernández',
  'اسم_الدورة': 'Gestión de proyectos profesionales',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 de enero de 2026',
  'الجهة_المانحة': 'Academia JoodCraft',
  'المدرب': 'Dra. Sara Molina',
  'مدة_الدورة': '40 horas de formación',
  'مستوى_الأداء': 'Primer lugar',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'Sociedad Jood Comercio',
  'اسم_الطرف_الثاني': 'Horizonte Construcciones S.L.',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 de enero de 2026',
  'تاريخ_البداية': '1 de febrero de 2026',
  'تاريخ_النهاية': '1 de diciembre de 2026',
  'قيمة_العقد': '150.000 SAR',
  'طريقة_الدفع': '40 % por adelantado y el resto a la entrega.',
  'اسم_المنشأة': 'JoodCraft',
};

const Map<String, String> _deTexts = <String, String>{
  'شهادة شكر وتقدير': 'Anerkennungsurkunde',
  'شهادة إتمام دورة تدريبية': 'Zertifikat über den Kursabschluss',
  'شهادة تفوق وتميّز': 'Exzellenzzertifikat',
  'إفادة خبرة': 'Arbeitsbescheinigung',
  'عقد عمل': 'Arbeitsvertrag',
  'عقد تقديم خدمات': 'Dienstleistungsvertrag',
  'شهادة تقدير كلاسيكية': 'Klassische Anerkennungsurkunde',
  'شهادة إنجاز بارز': 'Zertifikat für herausragende Leistungen',
  'شهادة حضور وتدريب': 'Teilnahmebescheinigung',
  'شهادة تقدّم علمي': 'Zertifikat für wissenschaftlichen Fortschritt',
  'عقد عمل مؤقت': 'Befristeter Arbeitsvertrag',
  'شهادة ملكية كحلية': 'Königliches marineblaues Zertifikat',
  'شهادة الجدارة العنابية': 'Bordeauxrote Verdiensturkunde',
  'شهادة الاستحقاق الملكي': 'Kaiserliche Verdiensturkunde',
  'شهادة عصرية هادئة': 'Minimalistisches Pastellzertifikat',
  'شهادة هندسية زرقاء': 'Geometrisches blaues Zertifikat',
  'شهادة التدرّج الناعم': 'Zertifikat mit sanftem Farbverlauf',
  'شهادة رسمية مؤسسية': 'Offizielles Firmenzertifikat',
  'شهادة تنفيذية': 'Führungszertifikat',
  'شهادة الاعتماد المهني': 'Zertifikat für berufliche Akkreditierung',
  'شهادة أكاديمية بختم': 'Akademisches Zertifikat mit Siegel',
  'شهادة تقدير أنيقة': 'Elegante Anerkennungsurkunde',
  'شهادة مرتبة الشرف': 'Ehrenurkunde',
  'شهادة أكاديمية': 'Akademisches Zertifikat',
  'شهادة إتمام': 'Abschlusszertifikat',
  'شهادة إتمام معتمدة': 'Zertifiziertes Abschlusszertifikat',
  'شهادة الجدارة والتميّز': 'Verdienst- und Exzellenzzertifikat',
  'شهادة تقدير ملكية': 'Königliche Anerkennungsurkunde',
  'شهادة تنفيذية معتمدة': 'Zertifiziertes Führungszertifikat',
  'شهادة معتمدة رسمياً': 'Offiziell zertifiziertes Zertifikat',
  'عقد تقديم استشارات': 'Beratungsvertrag',
  'ACADEMIC CERTIFICATE': 'AKADEMISCHES ZERTIFIKAT',
  'CERTIFICATE OF DISTINCTION': 'ZERTIFIKAT MIT AUSZEICHNUNG',
  'CERTIFIED COMPLETION': 'ZERTIFIZIERTER ABSCHLUSS',
  'HONORS CERTIFICATE': 'EHRENURKUNDE',
  'IMPERIAL CERTIFICATE OF HONOR': 'KAISERLICHE EHRENURKUNDE',
  'OFFICIAL CERTIFICATE': 'OFFIZIELLES ZERTIFIKAT',
  'PROFESSIONAL ACCREDITATION': 'BERUFLICHE AKKREDITIERUNG',
  'ROYAL CERTIFICATE OF MERIT': 'KÖNIGLICHE VERDIENSTURKUNDE',
  'CERTIFICATE OF APPRECIATION': 'ANERKENNUNGSURKUNDE',
  'CERTIFICATE OF COMPLETION': 'ABSCHLUSSZERTIFIKAT',
  'CERTIFICATE OF EXCELLENCE': 'EXZELLENZZERTIFIKAT',
  'CERTIFICATE OF ACHIEVEMENT': 'LEISTUNGSZERTIFIKAT',
  'CERTIFICATE OF ATTENDANCE': 'TEILNAHMEBESCHEINIGUNG',
  'CERTIFICATE OF PROGRESS': 'FORTSCHRITTSZERTIFIKAT',
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      'Die Leitung von {{الجهة_المانحة}} bescheinigt, dass',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} bescheinigt, dass',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} bescheinigt, dass',
  'الجهة المانحة': 'Ausstellende Stelle',
  'الرئيس التنفيذي': 'Vorstandsvorsitzender',
  'المدرب': 'Trainer',
  'المدرّب المعتمد': 'Zertifizierter Trainer',
  'المدير الأكاديمي': 'Akademischer Leiter',
  'المدير التنفيذي': 'Geschäftsführer',
  'المدير العام': 'Generaldirektor',
  'الموارد البشرية': 'Personalabteilung',
  'مدير الأكاديمية': 'Leiter der Akademie',
  'مدير المدرسة': 'Schulleiter',
  'مدير البرنامج': 'Programmdirektor',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'Programmdirektor — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Leiter der Jury',
  'مدير المركز': 'Zentrumsleiter',
  'عميد الكلية': 'Dekan der Fakultät',
  'عميد المعهد': 'Institutsleiter',
  'التوقيع المعتمد': 'Bevollmächtigte Unterschrift',
  'التاريخ: {{التاريخ}}': 'Datum: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'Geschäftsführer — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}': 'Geschäftsführer — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': 'Zertifikats-Nr.: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'Zertifikats-Nr.: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Prüfung: {{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'Zur Überprüfung dieses Zertifikats: {{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': 'Das Institut gratuliert',
  'يُكرَّم المتدرب': 'Der Teilnehmer wird ausgezeichnet',
  'تُمنح هذه الشهادة إلى': 'Dieses Zertifikat wird verliehen an',
  'تُمنح بمرتبة الشرف إلى': 'mit Auszeichnung verliehen an',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'Dieses Zertifikat wurde elektronisch über die Plattform JoodCraft '
          'ausgestellt.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'Elektronisch ausgestellt über JoodCraft — {{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'hat herausragende Anstrengungen und beispielhafte Leistungen gezeigt, '
          'die Anerkennung verdienen. Wir wünschen weiterhin viel Erfolg.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'hat das Programm «{{اسم_الدورة}}» im Umfang von {{مدة_الدورة}} unter '
          'der Leitung von {{المدرب}} erfolgreich abgeschlossen und dabei '
          'Engagement und herausragende Leistungen gezeigt.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      'für das Erreichen von {{مستوى_الأداء}} in {{اسم_الدورة}}, in '
          'Anerkennung von Fleiß, Exzellenz und Lernbereitschaft.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'hat «{{اسم_الدورة}}» im Umfang von {{مدة_الدورة}} unter der Leitung '
          'von {{المدرب}} erfolgreich abgeschlossen.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'hat «{{اسم_الدورة}}» im Umfang von {{مدة_الدورة}} unter der Leitung '
          'von {{المدرب}} erfolgreich abgeschlossen und {{مستوى_الأداء}} '
          'erreicht.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'hat das Ausbildungsprogramm «{{اسم_الدورة}}» im Umfang von '
          '{{مدة_الدورة}} unter der Leitung von {{المدرب}} erfolgreich '
          'abgeschlossen.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'hat das Programm «{{اسم_الدورة}}» im Umfang von {{مدة_الدورة}} '
          'erfolgreich abgeschlossen und dabei Engagement und hervorragende '
          'Leistungen gezeigt.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'hat das Ausbildungsprogramm «{{اسم_الدورة}}» im Umfang von '
          '{{مدة_الدورة}} unter der Leitung von {{المدرب}} besucht und '
          'bestanden und dabei hervorragendes Engagement und Disziplin gezeigt.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'hat das Programm «{{اسم_الدورة}}» erfolgreich abgeschlossen und wird '
          'für das Erreichen von {{مستوى_الأداء}} ausgezeichnet.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'hat das Programm «{{اسم_الدورة}}» mit Erfolg und Auszeichnung '
          'abgeschlossen und wird für das Erreichen von {{مستوى_الأداء}} '
          'ausgezeichnet, in Anerkennung herausragender akademischer Leistungen.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'als Nachweis des Abschlusses von «{{اسم_الدورة}}» im Umfang von '
          '{{مدة_الدورة}} unter der Leitung von {{المدرب}}.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      'für das Erreichen von {{مستوى_الأداء}} in «{{اسم_الدورة}}», in '
          'Anerkennung von Exzellenz und beständigem Fleiß.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      'für das Erreichen von {{مستوى_الأداء}} in {{اسم_الدورة}}, in '
          'Anerkennung von Exzellenz, beständigem Fleiß und dem Streben nach '
          'Auszeichnung.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'in Anerkennung herausragender Leistungen, des erfolgreichen Abschlusses '
          'von «{{اسم_الدورة}}» und des Erreichens von {{مستوى_الأداء}}.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'in Anerkennung von Fleiß, Exzellenz und Lernbereitschaft sowie des '
          'Erreichens von {{مستوى_الأداء}} in {{اسم_الدورة}}.',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'für das gezeigte Engagement und die Meisterschaft, die Anerkennung '
          'verdienen, und für das Erreichen von {{مستوى_الأداء}} in '
          '{{اسم_الدورة}}.',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'in Anerkennung herausragender Anstrengungen und beispielhafter '
          'Leistungen. Wir wünschen weiterhin viel Erfolg.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'in Anerkennung herausragender Anstrengungen und Leistungen, die unseren '
          'Werten entsprechen. Wir wünschen weiterhin viel Erfolg.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'in Anerkennung herausragender Anstrengungen und Leistungen, die unseren '
          'Werten entsprechen und ein Beispiel für Meisterschaft und Engagement '
          'sind. Wir wünschen weiterhin viel Erfolg.',
  'إلى من يهمه الأمر،': 'An alle, die es betrifft,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'Wir bescheinigen, dass {{اسم_الطرف_الثاني}} vom {{تاريخ_البداية}} '
          'bis zum {{تاريخ_النهاية}} bei {{اسم_المنشأة}} beschäftigt war und '
          'dabei Kompetenz, Disziplin und volle Einsatzbereitschaft bei der '
          'Erfüllung der übertragenen Aufgaben gezeigt hat.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'Diese Bescheinigung wird auf eigenen Wunsch ausgestellt, um sie bei '
          'Bedarf den zuständigen Stellen vorzulegen, ohne jede Haftung des '
          'Unternehmens.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.': 'Mit vorzüglicher Hochachtung.',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'Diese Bescheinigung wurde elektronisch über die Plattform JoodCraft '
          'ausgestellt.',
  'الرقم المرجعي: {{رقم_العقد}}': 'Referenz-Nr.: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      'Am {{تاريخ_البداية}} wurde zwischen den folgenden Parteien vereinbart:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      'Am {{تاريخ_العقد}} wurde zwischen den folgenden Parteien vereinbart:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'Erste Partei (Arbeitgeber): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'Zweite Partei (Arbeitnehmer): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'Erste Partei: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'Zweite Partei: {{اسم_الطرف_الثاني}}',
  'الطرف الأول': 'Erste Partei',
  'الطرف الثاني': 'Zweite Partei',
  'البند الأول: المدة': 'Klausel eins: Laufzeit',
  'البند الثاني: الأجر': 'Klausel zwei: Vergütung',
  'البند الثاني: المقابل المالي': 'Klausel zwei: Honorar',
  'البند الأول: نطاق العمل': 'Klausel eins: Leistungsumfang',
  'البند الثالث: الأحكام العامة': 'Klausel drei: Allgemeine Bestimmungen',
  'البند الأول: مدة العقد': 'Klausel eins: Vertragslaufzeit',
  'البند الثاني: الأجر وطريقة الدفع':
      'Klausel zwei: Vergütung und Zahlungsweise',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'Die Laufzeit dieses Vertrags beginnt am {{تاريخ_البداية}} und endet am '
          '{{تاريخ_النهاية}}; eine Verlängerung ist nur durch vorherige '
          'schriftliche Vereinbarung der Parteien möglich.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Die zweite Partei erhält eine Vergütung in Höhe von {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Die zweite Partei erhält für ihre Leistungen {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'Die zweite Partei erhält eine Vergütung in Höhe von {{قيمة_العقد}}, die '
          'regelmäßig nach {{طريقة_الدفع}} ausgezahlt wird',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Die zweite Partei erhält für ihre Beratungsleistungen {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'Dieser Vertrag unterliegt dem geltenden Arbeitsrecht des Königreichs '
          'Saudi-Arabien; Streitigkeiten werden der zuständigen Stelle '
          'vorgelegt.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'Dieser Vertrag unterliegt den Gesetzen des Königreichs Saudi-Arabien; '
          'Streitigkeiten werden dem zuständigen Gericht vorgelegt.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'Dieser Vertrag unterliegt dem geltenden Arbeitsrecht; Streitigkeiten '
          'werden der zuständigen Stelle nach den geltenden Verfahren '
          'vorgelegt.',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'Dieser Vertrag wird für eine bestimmte Laufzeit geschlossen, die am '
          '{{تاريخ_البداية}} beginnt und am {{تاريخ_النهاية}} endet, und darf '
          'nur durch vorherige schriftliche Vereinbarung der Parteien verlängert '
          'werden.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'Die zweite Partei verpflichtet sich, die vereinbarten Leistungen gemäß '
          'den Spezifikationen und Bedingungen des technischen Anhangs zu diesem '
          'Vertrag zu erbringen.',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'Die zweite Partei verpflichtet sich, die vereinbarten '
          'Beratungsleistungen gemäß den Spezifikationen und Bedingungen des '
          'diesem Vertrag beigefügten technischen Anhangs zu erbringen.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'Dieser Vertrag wurde elektronisch über die Plattform JoodCraft erstellt.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'Dieser Vertrag wurde am {{تاريخ_العقد}} elektronisch über die Plattform '
          'JoodCraft erstellt.',
};

const Map<String, String> _deSamples = <String, String>{
  'اسم_المتدرب': 'Lena Schmidt',
  'اسم_الدورة': 'Professionelles Projektmanagement',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15. Januar 2026',
  'الجهة_المانحة': 'JoodCraft Akademie',
  'المدرب': 'Dr. Sara Müller',
  'مدة_الدورة': '40 Trainingsstunden',
  'مستوى_الأداء': 'Erster Platz',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'Jood Handels GmbH',
  'اسم_الطرف_الثاني': 'Horizon Bau GmbH',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15. Januar 2026',
  'تاريخ_البداية': '1. Februar 2026',
  'تاريخ_النهاية': '1. Dezember 2026',
  'قيمة_العقد': '150.000 SAR',
  'طريقة_الدفع': '40 % Anzahlung, Restzahlung bei Lieferung.',
  'اسم_المنشأة': 'JoodCraft',
};

const Map<String, String> _trTexts = <String, String>{
  'شهادة شكر وتقدير': 'Takdir Belgesi',
  'شهادة إتمام دورة تدريبية': 'Kurs Tamamlama Belgesi',
  'شهادة تفوق وتميّز': 'Üstün Başarı Belgesi',
  'إفادة خبرة': 'İş Deneyim Belgesi',
  'عقد عمل': 'İş Sözleşmesi',
  'عقد تقديم خدمات': 'Hizmet Sözleşmesi',
  'شهادة تقدير كلاسيكية': 'Klasik Takdir Belgesi',
  'شهادة إنجاز بارز': 'Olağanüstü Başarı Belgesi',
  'شهادة حضور وتدريب': 'Katılım ve Eğitim Belgesi',
  'شهادة تقدّم علمي': 'Bilimsel İlerleme Belgesi',
  'عقد عمل مؤقت': 'Belirli Süreli İş Sözleşmesi',
  'شهادة ملكية كحلية': 'Kraliyet Lacivert Belgesi',
  'شهادة الجدارة العنابية': 'Bordo Liyakat Belgesi',
  'شهادة الاستحقاق الملكي': 'İmparatorluk Liyakat Belgesi',
  'شهادة عصرية هادئة': 'Minimal Pastel Belge',
  'شهادة هندسية زرقاء': 'Geometrik Mavi Belge',
  'شهادة التدرّج الناعم': 'Yumuşak Degrade Belgesi',
  'شهادة رسمية مؤسسية': 'Kurumsal Resmî Belge',
  'شهادة تنفيذية': 'Yönetici Belgesi',
  'شهادة الاعتماد المهني': 'Mesleki Akreditasyon Belgesi',
  'شهادة أكاديمية بختم': 'Mühürlü Akademik Belge',
  'شهادة تقدير أنيقة': 'Zarif Takdir Belgesi',
  'شهادة مرتبة الشرف': 'Onur Belgesi',
  'شهادة أكاديمية': 'Akademik Belge',
  'شهادة إتمام': 'Tamamlama Belgesi',
  'شهادة إتمام معتمدة': 'Onaylı Tamamlama Belgesi',
  'شهادة الجدارة والتميّز': 'Liyakat ve Üstün Başarı Belgesi',
  'شهادة تقدير ملكية': 'Kraliyet Takdir Belgesi',
  'شهادة تنفيذية معتمدة': 'Onaylı Yönetici Belgesi',
  'شهادة معتمدة رسمياً': 'Resmî Onaylı Belge',
  'عقد تقديم استشارات': 'Danışmanlık Hizmet Sözleşmesi',
  'ACADEMIC CERTIFICATE': 'AKADEMİK BELGE',
  'CERTIFICATE OF DISTINCTION': 'ÜSTÜN BAŞARI BELGESİ',
  'CERTIFIED COMPLETION': 'ONAYLI TAMAMLAMA',
  'HONORS CERTIFICATE': 'ONUR BELGESİ',
  'IMPERIAL CERTIFICATE OF HONOR': 'İMPARATORLUK ONUR BELGESİ',
  'OFFICIAL CERTIFICATE': 'RESMÎ BELGE',
  'PROFESSIONAL ACCREDITATION': 'MESLEKİ AKREDİTASYON',
  'ROYAL CERTIFICATE OF MERIT': 'KRALİYET LİYAKAT BELGESİ',
  'CERTIFICATE OF APPRECIATION': 'TAKDİR BELGESİ',
  'CERTIFICATE OF COMPLETION': 'TAMAMLAMA BELGESİ',
  'CERTIFICATE OF EXCELLENCE': 'ÜSTÜN BAŞARI BELGESİ',
  'CERTIFICATE OF ACHIEVEMENT': 'BAŞARI BELGESİ',
  'CERTIFICATE OF ATTENDANCE': 'KATILIM BELGESİ',
  'CERTIFICATE OF PROGRESS': 'İLERLEME BELGESİ',
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      '{{الجهة_المانحة}} yönetimi şunu tasdik eder:',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} şunu tasdik eder:',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} şunu tasdik eder:',
  'الجهة المانحة': 'Düzenleyen kurum',
  'الرئيس التنفيذي': 'İcra Kurulu Başkanı',
  'المدرب': 'Eğitmen',
  'المدرّب المعتمد': 'Yetkili eğitmen',
  'المدير الأكاديمي': 'Akademik müdür',
  'المدير التنفيذي': 'Genel müdür',
  'المدير العام': 'Genel müdür',
  'الموارد البشرية': 'İnsan kaynakları',
  'مدير الأكاديمية': 'Akademi müdürü',
  'مدير المدرسة': 'Okul müdürü',
  'مدير البرنامج': 'Program müdürü',
  'مدير البرنامج — {{الجهة_المانحة}}': 'Program müdürü — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Jüri başkanı',
  'مدير المركز': 'Merkez müdürü',
  'عميد الكلية': 'Fakülte dekanı',
  'عميد المعهد': 'Enstitü müdürü',
  'التوقيع المعتمد': 'Onaylı imza',
  'التاريخ: {{التاريخ}}': 'Tarih: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}': 'Genel müdür — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}': 'Genel müdür — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': 'Belge no: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'Belge no: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Doğrulama: {{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'Bu belgeyi doğrulamak için: {{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': 'Enstitü tebrik eder:',
  'يُكرَّم المتدرب': 'Kursiyer onurlandırılır',
  'تُمنح هذه الشهادة إلى': 'Bu belge şu kişiye verilmiştir:',
  'تُمنح بمرتبة الشرف إلى': 'onur derecesiyle verilmiştir:',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'Bu belge JoodCraft platformu üzerinden elektronik olarak '
          'düzenlenmiştir.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'JoodCraft üzerinden elektronik olarak düzenlenmiştir — '
          '{{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'takdire değer üstün çaba ve örnek bir performans sergilemiştir. '
          'Başarılarının devamını dileriz.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      '«{{اسم_الدورة}}» programını {{مدة_الدورة}} süresinde {{المدرب}} '
          'gözetiminde başarıyla tamamlamış; bağlılık ve üstün performans '
          'göstermiştir.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      '{{اسم_الدورة}} alanında {{مستوى_الأداء}} elde ettiği için; çalışkanlığı, '
          'üstün başarısı ve öğrenme azmi takdir edilmiştir.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '«{{اسم_الدورة}}» programını {{مدة_الدورة}} süresinde {{المدرب}} '
          'gözetiminde başarıyla tamamlamıştır.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      '«{{اسم_الدورة}}» programını {{مدة_الدورة}} süresinde {{المدرب}} '
          'gözetiminde başarıyla tamamlamış ve {{مستوى_الأداء}} elde etmiştir.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '«{{اسم_الدورة}}» eğitim programını {{مدة_الدورة}} süresinde '
          '{{المدرب}} gözetiminde başarıyla tamamlamıştır.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      '«{{اسم_الدورة}}» programını {{مدة_الدورة}} süresinde başarıyla '
          'tamamlamış; bağlılık ve üstün performans göstermiştir.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      '«{{اسم_الدورة}}» eğitim programına {{مدة_الدورة}} süresinde '
          '{{المدرب}} gözetiminde katılmış ve başarıyla geçmiş; mükemmel bir '
          'bağlılık ve disiplin göstermiştir.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      '«{{اسم_الدورة}}» programını başarıyla tamamlamış ve {{مستوى_الأداء}} '
          'elde ettiği için onurlandırılmıştır.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      '«{{اسم_الدورة}}» programını başarı ve üstün dereceyle tamamlamış ve '
          '{{مستوى_الأداء}} elde ettiği için, üstün akademik katkısı takdir '
          'edilerek onurlandırılmıştır.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '«{{اسم_الدورة}}» programını {{مدة_الدورة}} süresinde {{المدرب}} '
          'gözetiminde tamamladığının belgesi olarak.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      '«{{اسم_الدورة}}» alanında {{مستوى_الأداء}} elde ettiği için; üstün '
          'başarısı ve sürekli çalışkanlığı takdir edilmiştir.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      '{{اسم_الدورة}} alanında {{مستوى_الأداء}} elde ettiği için; üstün '
          'başarısı, sürekli çalışkanlığı ve mükemmellik arayışı takdir '
          'edilmiştir.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'üstün performansı, «{{اسم_الدورة}}» programını başarıyla tamamlaması ve '
          '{{مستوى_الأداء}} elde etmesi nedeniyle.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'çalışkanlığı, üstün başarısı ve öğrenme azmi; {{اسم_الدورة}} alanında '
          '{{مستوى_الأداء}} elde etmesi nedeniyle.',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'gösterdiği ve takdire değer bağlılık ile ustalık; {{اسم_الدورة}} '
          'alanında {{مستوى_الأداء}} elde etmesi nedeniyle.',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'üstün çabaları ve örnek performansı nedeniyle. Başarılarının devamını '
          'dileriz.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'değerlerimize yakışır üstün çabaları ve olağanüstü performansı nedeniyle. '
          'Başarılarının devamını dileriz.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'değerlerimize yakışır üstün çabaları ve olağanüstü performansı; ustalık '
          've bağlılıkta örnek olması nedeniyle. Başarılarının devamını dileriz.',
  'إلى من يهمه الأمر،': 'İlgili makama,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      '{{اسم_الطرف_الثاني}} kişisinin {{تاريخ_البداية}} ile '
          '{{تاريخ_النهاية}} tarihleri arasında {{اسم_المنشأة}} bünyesinde '
          'çalıştığını ve bu süre boyunca yetkinlik, disiplin ve verilen '
          'görevleri eksiksiz yerine getirme konusunda tam bağlılık '
          'gösterdiğini tasdik ederiz.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'Bu belge, talebi üzerine gerektiğinde ilgili makamlara sunulmak üzere '
          'düzenlenmiş olup kurum için hiçbir sorumluluk doğurmaz.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.':
      'Saygılarımızı ve takdirlerimizi sunarız.',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'Bu belge JoodCraft platformu üzerinden elektronik olarak '
          'düzenlenmiştir.',
  'الرقم المرجعي: {{رقم_العقد}}': 'Referans no: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      '{{تاريخ_البداية}} tarihinde aşağıdaki taraflar arasında anlaşmaya '
          'varılmıştır:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      '{{تاريخ_العقد}} tarihinde aşağıdaki taraflar arasında anlaşmaya '
          'varılmıştır:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'Birinci taraf (işveren): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'İkinci taraf (çalışan): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'Birinci taraf: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'İkinci taraf: {{اسم_الطرف_الثاني}}',
  'الطرف الأول': 'Birinci taraf',
  'الطرف الثاني': 'İkinci taraf',
  'البند الأول: المدة': 'Birinci madde: Süre',
  'البند الثاني: الأجر': 'İkinci madde: Ücret',
  'البند الثاني: المقابل المالي': 'İkinci madde: Bedel',
  'البند الأول: نطاق العمل': 'Birinci madde: İşin kapsamı',
  'البند الثالث: الأحكام العامة': 'Üçüncü madde: Genel hükümler',
  'البند الأول: مدة العقد': 'Birinci madde: Sözleşme süresi',
  'البند الثاني: الأجر وطريقة الدفع': 'İkinci madde: Ücret ve ödeme yöntemi',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'Bu sözleşmenin süresi {{تاريخ_البداية}} tarihinde başlar ve '
          '{{تاريخ_النهاية}} tarihinde sona erer; tarafların yazılı anlaşmasıyla '
          'yenilenebilir.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'İkinci taraf, {{قيمة_العقد}} tutarında ücret alacaktır. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'İkinci taraf, hizmetleri karşılığında {{قيمة_العقد}} alacaktır. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'İkinci taraf, {{قيمة_العقد}} tutarında ve {{طريقة_الدفع}} uyarınca '
          'düzenli olarak ödenen bir ücret alacaktır',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'İkinci taraf, danışmanlık hizmetleri karşılığında {{قيمة_العقد}} '
          'alacaktır. {{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'Bu sözleşme, Suudi Arabistan Krallığında yürürlükte olan iş '
          'mevzuatına tabidir ve doğacak uyuşmazlıklar yetkili makama iletilir.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'Bu sözleşme Suudi Arabistan Krallığı yasalarına tabidir ve doğacak '
          'uyuşmazlıklar yetkili yargı makamına iletilir.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'Bu sözleşme yürürlükteki iş mevzuatına tabidir ve doğacak '
          'uyuşmazlıklar, geçerli usullere göre yetkili makama iletilir.',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'Bu sözleşme, {{تاريخ_البداية}} tarihinde başlayıp {{تاريخ_النهاية}} '
          'tarihinde sona eren belirli bir süre için yapılmıştır ve tarafların '
          'önceden yazılı anlaşması olmaksızın uzatılamaz.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'İkinci taraf, sözleşmenin teknik ekinde belirtilen şartname ve koşullara '
          'uygun olarak kararlaştırılan hizmetleri sunmayı taahhüt eder.',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'İkinci taraf, bu sözleşmeye ekli teknik ekte belirtilen şartname ve '
          'koşullara uygun olarak kararlaştırılan danışmanlık hizmetlerini '
          'sunmayı taahhüt eder.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'Bu sözleşme JoodCraft platformu üzerinden elektronik olarak '
          'düzenlenmiştir.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'Bu sözleşme {{تاريخ_العقد}} tarihinde JoodCraft platformu üzerinden '
          'elektronik olarak düzenlenmiştir.',
};

const Map<String, String> _trSamples = <String, String>{
  'اسم_المتدرب': 'Elif Yılmaz',
  'اسم_الدورة': 'Profesyonel Proje Yönetimi',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 Ocak 2026',
  'الجهة_المانحة': 'JoodCraft Akademi',
  'المدرب': 'Dr. Selin Kaya',
  'مدة_الدورة': '40 saat eğitim',
  'مستوى_الأداء': 'Birinci sıra',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'Jood Ticaret A.Ş.',
  'اسم_الطرف_الثاني': 'Ufuk İnşaat Ltd. Şti.',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 Ocak 2026',
  'تاريخ_البداية': '1 Şubat 2026',
  'تاريخ_النهاية': '1 Aralık 2026',
  'قيمة_العقد': '150.000 SAR',
  'طريقة_الدفع': '%40 peşin, kalanı teslimatta.',
  'اسم_المنشأة': 'JoodCraft',
};

const Map<String, String> _idTexts = <String, String>{
  // ---- judul templat ----
  'شهادة شكر وتقدير': 'Sertifikat Penghargaan',
  'شهادة إتمام دورة تدريبية': 'Sertifikat Penyelesaian Kursus',
  'شهادة تفوق وتميّز': 'Sertifikat Keunggulan',
  'إفادة خبرة': 'Surat Keterangan Kerja',
  'عقد عمل': 'Perjanjian Kerja',
  'عقد تقديم خدمات': 'Perjanjian Penyediaan Jasa',
  'شهادة تقدير كلاسيكية': 'Sertifikat Penghargaan Klasik',
  'شهادة إنجاز بارز': 'Sertifikat Prestasi Luar Biasa',
  'شهادة حضور وتدريب': 'Sertifikat Kehadiran dan Pelatihan',
  'شهادة تقدّم علمي': 'Sertifikat Kemajuan Akademik',
  'عقد عمل مؤقت': 'Perjanjian Kerja Waktu Tertentu',
  'شهادة ملكية كحلية': 'Sertifikat Biru Laut Kerajaan',
  'شهادة الجدارة العنابية': 'Sertifikat Jasa Merah Marun',
  'شهادة الاستحقاق الملكي': 'Sertifikat Jasa Kekaisaran',
  'شهادة عصرية هادئة': 'Sertifikat Minimalis Pastel',
  'شهادة هندسية زرقاء': 'Sertifikat Geometris Biru',
  'شهادة التدرّج الناعم': 'Sertifikat Gradasi Lembut',
  'شهادة رسمية مؤسسية': 'Sertifikat Resmi Perusahaan',
  'شهادة تنفيذية': 'Sertifikat Eksekutif',
  'شهادة الاعتماد المهني': 'Sertifikat Akreditasi Profesional',
  'شهادة أكاديمية بختم': 'Sertifikat Akademik dengan Segel',
  'شهادة تقدير أنيقة': 'Sertifikat Penghargaan Elegan',
  'شهادة مرتبة الشرف': 'Sertifikat Kehormatan',
  'شهادة أكاديمية': 'Sertifikat akademik',
  'شهادة إتمام': 'Sertifikat penyelesaian',
  'شهادة إتمام معتمدة': 'Sertifikat penyelesaian tersertifikasi',
  'شهادة الجدارة والتميّز': 'Sertifikat jasa dan keunggulan',
  'شهادة تقدير ملكية': 'Sertifikat penghargaan kerajaan',
  'شهادة تنفيذية معتمدة': 'Sertifikat eksekutif tersertifikasi',
  'شهادة معتمدة رسمياً': 'Sertifikat resmi tersertifikasi',
  'عقد تقديم استشارات': 'Perjanjian penyediaan konsultasi',
  // ---- tajuk Latin yang sudah ada di templat ----
  'ACADEMIC CERTIFICATE': 'SERTIFIKAT AKADEMIK',
  'CERTIFICATE OF DISTINCTION': 'SERTIFIKAT PRESTASI ISTIMEWA',
  'CERTIFIED COMPLETION': 'PENYELESAIAN TERSERTIFIKASI',
  'HONORS CERTIFICATE': 'SERTIFIKAT KEHORMATAN',
  'IMPERIAL CERTIFICATE OF HONOR': 'SERTIFIKAT KEHORMATAN KEKAISARAN',
  'OFFICIAL CERTIFICATE': 'SERTIFIKAT RESMI',
  'PROFESSIONAL ACCREDITATION': 'AKREDITASI PROFESIONAL',
  'ROYAL CERTIFICATE OF MERIT': 'SERTIFIKAT JASA KERAJAAN',
  'CERTIFICATE OF APPRECIATION': 'SERTIFIKAT PENGHARGAAN',
  'CERTIFICATE OF COMPLETION': 'SERTIFIKAT PENYELESAIAN',
  'CERTIFICATE OF EXCELLENCE': 'SERTIFIKAT KEUNGGULAN',
  'CERTIFICATE OF ACHIEVEMENT': 'SERTIFIKAT PENCAPAIAN',
  'CERTIFICATE OF ATTENDANCE': 'SERTIFIKAT KEHADIRAN',
  'CERTIFICATE OF PROGRESS': 'SERTIFIKAT KEMAJUAN',
  // ---- teks sertifikat ----
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      'Manajemen {{الجهة_المانحة}} menyatakan bahwa',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} menyatakan bahwa',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} menyatakan bahwa',
  'الجهة المانحة': 'Lembaga penerbit',
  'الرئيس التنفيذي': 'Direktur Utama',
  'المدرب': 'Pelatih',
  'المدرّب المعتمد': 'Pelatih tersertifikasi',
  'المدير الأكاديمي': 'Direktur akademik',
  'المدير التنفيذي': 'Direktur eksekutif',
  'المدير العام': 'Manajer umum',
  'الموارد البشرية': 'Sumber daya manusia',
  'مدير الأكاديمية': 'Direktur akademi',
  'مدير المدرسة': 'Kepala sekolah',
  'مدير البرنامج': 'Direktur program',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'Direktur program — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Ketua juri',
  'مدير المركز': 'Direktur pusat',
  'عميد الكلية': 'Dekan fakultas',
  'عميد المعهد': 'Direktur institut',
  'التوقيع المعتمد': 'Tanda tangan resmi',
  'التاريخ: {{التاريخ}}': 'Tanggal: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'Direktur eksekutif — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}':
      'Direktur eksekutif — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': 'Nomor sertifikat: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'Nomor sertifikat: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Verifikasi: {{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'Untuk memverifikasi sertifikat ini: {{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': 'Institut mengucapkan selamat kepada',
  'يُكرَّم المتدرب': 'Peserta dihormati',
  'تُمنح هذه الشهادة إلى': 'Sertifikat ini diberikan kepada',
  'تُمنح بمرتبة الشرف إلى': 'dianugerahkan dengan pujian kepada',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'Sertifikat ini diterbitkan secara elektronik melalui platform JoodCraft.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'Diterbitkan secara elektronik melalui JoodCraft — {{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'telah menunjukkan usaha yang luar biasa dan kinerja teladan yang layak '
          'mendapat penghargaan. Kami mendoakan keberhasilan berkelanjutan.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'telah berhasil menyelesaikan program pelatihan «{{اسم_الدورة}}» selama '
          '{{مدة_الدورة}} di bawah bimbingan {{المدرب}}, dengan menunjukkan '
          'komitmen dan kinerja yang unggul.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      'atas pencapaian {{مستوى_الأداء}} dalam {{اسم_الدورة}}, sebagai '
          'penghargaan atas ketekunan, keunggulan, dan semangat belajarnya.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'telah berhasil menyelesaikan «{{اسم_الدورة}}» selama {{مدة_الدورة}} di '
          'bawah bimbingan {{المدرب}}.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'telah berhasil menyelesaikan «{{اسم_الدورة}}» selama {{مدة_الدورة}} di '
          'bawah bimbingan {{المدرب}}, dengan meraih {{مستوى_الأداء}}.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'telah berhasil menyelesaikan program pelatihan «{{اسم_الدورة}}» selama '
          '{{مدة_الدورة}} di bawah bimbingan {{المدرب}}.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'telah berhasil menyelesaikan program «{{اسم_الدورة}}» selama '
          '{{مدة_الدورة}}, dengan menunjukkan komitmen dan kinerja yang unggul.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'telah mengikuti dan lulus program pelatihan «{{اسم_الدورة}}» selama '
          '{{مدة_الدورة}} di bawah bimbingan {{المدرب}}, dengan menunjukkan '
          'komitmen dan disiplin yang sangat baik.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'telah berhasil menyelesaikan program «{{اسم_الدورة}}» dan dihormati '
          'karena meraih {{مستوى_الأداء}}.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'telah menyelesaikan program «{{اسم_الدورة}}» dengan sukses dan '
          'istimewa, dan dihormati karena meraih {{مستوى_الأداء}} atas '
          'kontribusi akademiknya yang luar biasa.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'sebagai bukti penyelesaian «{{اسم_الدورة}}» selama {{مدة_الدورة}} di '
          'bawah bimbingan {{المدرب}}.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      'atas pencapaian {{مستوى_الأداء}} dalam «{{اسم_الدورة}}», sebagai '
          'penghargaan atas keunggulan dan ketekunannya.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      'atas pencapaian {{مستوى_الأداء}} dalam {{اسم_الدورة}}, sebagai '
          'penghargaan atas keunggulan, ketekunan, dan semangatnya untuk unggul.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'sebagai penghargaan atas kinerjanya yang luar biasa, penyelesaian '
          '«{{اسم_الدورة}}» dengan sukses, dan pencapaian {{مستوى_الأداء}}.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'sebagai penghargaan atas ketekunan, keunggulan, dan semangat '
          'belajarnya, serta pencapaian {{مستوى_الأداء}} dalam {{اسم_الدورة}}.',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'atas komitmen dan penguasaan yang ditunjukkannya, yang layak mendapat '
          'penghargaan, serta pencapaian {{مستوى_الأداء}} dalam {{اسم_الدورة}}.',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'sebagai penghargaan atas usahanya yang luar biasa dan kinerja teladan. '
          'Kami mendoakan keberhasilan berkelanjutan.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'sebagai penghargaan atas usahanya yang istimewa dan kinerja luar biasa '
          'yang sejalan dengan nilai-nilai kami. Kami mendoakan keberhasilan '
          'berkelanjutan.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'sebagai penghargaan atas usahanya yang istimewa dan kinerja luar biasa '
          'yang sejalan dengan nilai-nilai kami, serta teladan dalam penguasaan '
          'dan komitmen. Kami mendoakan keberhasilan berkelanjutan.',
  // ---- surat keterangan ----
  'إلى من يهمه الأمر،': 'Kepada yang berkepentingan,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'Kami menyatakan bahwa {{اسم_الطرف_الثاني}} telah bekerja di '
          '{{اسم_المنشأة}} sejak {{تاريخ_البداية}} hingga {{تاريخ_النهاية}}, '
          'dan selama itu menunjukkan kompetensi, disiplin, serta komitmen '
          'penuh dalam menjalankan tugas yang diberikan.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'Surat keterangan ini diberikan atas permintaannya untuk diserahkan '
          'kepada pihak berwenang bila diperlukan, tanpa tanggung jawab apa pun '
          'pada perusahaan.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.': 'Hormat kami,',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'Surat keterangan ini diterbitkan secara elektronik melalui platform '
          'JoodCraft.',
  // ---- kontrak ----
  'الرقم المرجعي: {{رقم_العقد}}': 'Nomor referensi: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      'Pada {{تاريخ_البداية}}, telah disepakati antara:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      'Pada {{تاريخ_العقد}}, telah disepakati antara:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'Pihak pertama (pemberi kerja): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'Pihak kedua (pekerja): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'Pihak pertama: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'Pihak kedua: {{اسم_الطرف_الثاني}}',
  'الطرف الأول': 'Pihak pertama',
  'الطرف الثاني': 'Pihak kedua',
  'البند الأول: المدة': 'Pasal pertama: Jangka waktu',
  'البند الثاني: الأجر': 'Pasal kedua: Upah',
  'البند الثاني: المقابل المالي': 'Pasal kedua: Imbalan',
  'البند الأول: نطاق العمل': 'Pasal pertama: Ruang lingkup pekerjaan',
  'البند الثالث: الأحكام العامة': 'Pasal ketiga: Ketentuan umum',
  'البند الأول: مدة العقد': 'Pasal pertama: Jangka waktu perjanjian',
  'البند الثاني: الأجر وطريقة الدفع':
      'Pasal kedua: Upah dan cara pembayaran',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'Jangka waktu perjanjian ini dimulai pada {{تاريخ_البداية}} dan '
          'berakhir pada {{تاريخ_النهاية}}, dan dapat diperpanjang dengan '
          'kesepakatan tertulis antara kedua pihak.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Pihak kedua berhak atas upah sebesar {{قيمة_العقد}}. {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Pihak kedua berhak atas imbalan sebesar {{قيمة_العقد}} atas jasanya. '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'Pihak kedua berhak atas upah sebesar {{قيمة_العقد}}, yang dibayarkan '
          'secara teratur sesuai {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Pihak kedua berhak atas imbalan konsultasi sebesar {{قيمة_العقد}}. '
          '{{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'Perjanjian ini tunduk pada peraturan ketenagakerjaan yang berlaku di '
          'Kerajaan Arab Saudi, dan setiap perselisihan yang timbul akan '
          'diajukan kepada pihak berwenang.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'Perjanjian ini tunduk pada hukum Kerajaan Arab Saudi, dan setiap '
          'perselisihan yang timbul akan diajukan kepada otoritas yudisial '
          'yang berwenang.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'Perjanjian ini tunduk pada peraturan ketenagakerjaan yang berlaku, dan '
          'setiap perselisihan yang timbul akan diajukan kepada pihak berwenang '
          'sesuai prosedur yang berlaku.',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'Perjanjian ini dibuat untuk jangka waktu tertentu yang dimulai pada '
          '{{تاريخ_البداية}} dan berakhir pada {{تاريخ_النهاية}}, dan tidak '
          'dapat diperpanjang kecuali dengan kesepakatan tertulis sebelumnya '
          'antara kedua pihak.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'Pihak kedua berkomitmen menyediakan jasa yang disepakati sesuai '
          'spesifikasi dan syarat yang tercantum dalam lampiran teknis '
          'perjanjian ini.',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'Pihak kedua berkomitmen menyediakan jasa konsultasi yang disepakati '
          'sesuai spesifikasi dan syarat yang tercantum dalam lampiran teknis '
          'yang dilampirkan pada perjanjian ini.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'Perjanjian ini dibuat secara elektronik melalui platform JoodCraft.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'Perjanjian ini dibuat secara elektronik melalui platform JoodCraft '
          'pada {{تاريخ_العقد}}',
};

const Map<String, String> _idSamples = <String, String>{
  'اسم_المتدرب': 'Dewi Anggraini',
  'اسم_الدورة': 'Manajemen Proyek Profesional',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 Januari 2026',
  'الجهة_المانحة': 'Akademi JoodCraft',
  'المدرب': 'Dr. Sari Wulandari',
  'مدة_الدورة': '40 jam pelatihan',
  'مستوى_الأداء': 'Peringkat pertama',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'PT Jood Perdagangan',
  'اسم_الطرف_الثاني': 'PT Horizon Konstruksi',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 Januari 2026',
  'تاريخ_البداية': '1 Februari 2026',
  'تاريخ_النهاية': '1 Desember 2026',
  'قيمة_العقد': '150.000 SAR',
  'طريقة_الدفع': 'Pembayaran awal 40% dan sisanya saat penyerahan.',
  'اسم_المنشأة': 'JoodCraft',
};

const Map<String, String> _ruTexts = <String, String>{
  // ---- названия шаблонов ----
  'شهادة شكر وتقدير': 'Благодарственная грамота',
  'شهادة إتمام دورة تدريبية': 'Сертификат об окончании курса',
  'شهادة تفوق وتميّز': 'Сертификат об отличии',
  'إفادة خبرة': 'Справка о трудовом стаже',
  'عقد عمل': 'Трудовой договор',
  'عقد تقديم خدمات': 'Договор об оказании услуг',
  'شهادة تقدير كلاسيكية': 'Классическая благодарственная грамота',
  'شهادة إنجاز بارز': 'Сертификат о выдающемся достижении',
  'شهادة حضور وتدريب': 'Сертификат о посещении и обучении',
  'شهادة تقدّم علمي': 'Сертификат об академическом прогрессе',
  'عقد عمل مؤقت': 'Срочный трудовой договор',
  'شهادة ملكية كحلية': 'Королевский тёмно-синий сертификат',
  'شهادة الجدارة العنابية': 'Бордовая грамота о заслугах',
  'شهادة الاستحقاق الملكي': 'Имперский сертификат о заслугах',
  'شهادة عصرية هادئة': 'Минималистичный пастельный сертификат',
  'شهادة هندسية زرقاء': 'Синий геометрический сертификат',
  'شهادة التدرّج الناعم': 'Сертификат с мягким градиентом',
  'شهادة رسمية مؤسسية': 'Официальный корпоративный сертификат',
  'شهادة تنفيذية': 'Сертификат руководителя',
  'شهادة الاعتماد المهني': 'Сертификат профессиональной аккредитации',
  'شهادة أكاديمية بختم': 'Академический сертификат с печатью',
  'شهادة تقدير أنيقة': 'Элегантная благодарственная грамота',
  'شهادة مرتبة الشرف': 'Диплом с отличием',
  'شهادة أكاديمية': 'Академический сертификат',
  'شهادة إتمام': 'Сертификат об окончании',
  'شهادة إتمام معتمدة': 'Заверенный сертификат об окончании',
  'شهادة الجدارة والتميّز': 'Сертификат о заслугах и отличии',
  'شهادة تقدير ملكية': 'Королевская благодарственная грамота',
  'شهادة تنفيذية معتمدة': 'Заверенный сертификат руководителя',
  'شهادة معتمدة رسمياً': 'Официально заверенный сертификат',
  'عقد تقديم استشارات': 'Договор об оказании консультационных услуг',
  // ---- латинские заголовки в шаблонах ----
  'ACADEMIC CERTIFICATE': 'АКАДЕМИЧЕСКИЙ СЕРТИФИКАТ',
  'CERTIFICATE OF DISTINCTION': 'СЕРТИФИКАТ ОБ ОТЛИЧИИ',
  'CERTIFIED COMPLETION': 'ЗАВЕРЕННОЕ ОКОНЧАНИЕ',
  'HONORS CERTIFICATE': 'ДИПЛОМ С ОТЛИЧИЕМ',
  'IMPERIAL CERTIFICATE OF HONOR': 'ИМПЕРСКИЙ ПОЧЁТНЫЙ СЕРТИФИКАТ',
  'OFFICIAL CERTIFICATE': 'ОФИЦИАЛЬНЫЙ СЕРТИФИКАТ',
  'PROFESSIONAL ACCREDITATION': 'ПРОФЕССИОНАЛЬНАЯ АККРЕДИТАЦИЯ',
  'ROYAL CERTIFICATE OF MERIT': 'КОРОЛЕВСКИЙ СЕРТИФИКАТ О ЗАСЛУГАХ',
  'CERTIFICATE OF APPRECIATION': 'БЛАГОДАРСТВЕННАЯ ГРАМОТА',
  'CERTIFICATE OF COMPLETION': 'СЕРТИФИКАТ ОБ ОКОНЧАНИИ',
  'CERTIFICATE OF EXCELLENCE': 'СЕРТИФИКАТ ОБ ОТЛИЧИИ',
  'CERTIFICATE OF ACHIEVEMENT': 'СЕРТИФИКАТ О ДОСТИЖЕНИИ',
  'CERTIFICATE OF ATTENDANCE': 'СЕРТИФИКАТ О ПОСЕЩЕНИИ',
  'CERTIFICATE OF PROGRESS': 'СЕРТИФИКАТ О ПРОГРЕССЕ',
  // ---- тексты сертификатов ----
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      'Руководство {{الجهة_المانحة}} подтверждает, что',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} подтверждает, что',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} подтверждает, что',
  'الجهة المانحة': 'Выдающая организация',
  'الرئيس التنفيذي': 'Генеральный директор',
  'المدرب': 'Тренер',
  'المدرّب المعتمد': 'Сертифицированный тренер',
  'المدير الأكاديمي': 'Академический директор',
  'المدير التنفيذي': 'Исполнительный директор',
  'المدير العام': 'Генеральный менеджер',
  'الموارد البشرية': 'Отдел кадров',
  'مدير الأكاديمية': 'Директор академии',
  'مدير المدرسة': 'Директор школы',
  'مدير البرنامج': 'Директор программы',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'Директор программы — {{الجهة_المانحة}}',
  'مدير التحكيم': 'Председатель жюри',
  'مدير المركز': 'Директор центра',
  'عميد الكلية': 'Декан факультета',
  'عميد المعهد': 'Директор института',
  'التوقيع المعتمد': 'Уполномоченная подпись',
  'التاريخ: {{التاريخ}}': 'Дата: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'Исполнительный директор — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}':
      'Исполнительный директор — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': 'Номер сертификата: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'Номер сертификата: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'Проверка: {{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'Для проверки сертификата: {{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': 'Институт поздравляет',
  'يُكرَّم المتدرب': 'Слушатель награждается',
  'تُمنح هذه الشهادة إلى': 'Настоящий сертификат вручается',
  'تُمنح بمرتبة الشرف إلى': 'вручается с отличием',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'Настоящий сертификат оформлен в электронном виде на платформе '
          'JoodCraft.',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'Оформлен в электронном виде на JoodCraft — {{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'проявил(а) выдающиеся усилия и образцовую работу, достойные '
          'признания. Желаем дальнейших успехов.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'успешно завершил(а) программу обучения «{{اسم_الدورة}}» '
          'продолжительностью {{مدة_الدورة}} под руководством {{المدرب}}, '
          'проявив приверженность и высокие результаты.',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      'за достижение {{مستوى_الأداء}} в «{{اسم_الدورة}}» в знак признания '
          'усердия, отличия и стремления к знаниям.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'успешно завершил(а) «{{اسم_الدورة}}» продолжительностью '
          '{{مدة_الدورة}} под руководством {{المدرب}}.',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'успешно завершил(а) «{{اسم_الدورة}}» продолжительностью '
          '{{مدة_الدورة}} под руководством {{المدرب}}, получив '
          '{{مستوى_الأداء}}.',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'успешно завершил(а) программу обучения «{{اسم_الدورة}}» '
          'продолжительностью {{مدة_الدورة}} под руководством {{المدرب}}.',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'успешно завершил(а) программу «{{اسم_الدورة}}» продолжительностью '
          '{{مدة_الدورة}}, проявив приверженность и высокие результаты.',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'посетил(а) и успешно прошёл(ла) программу обучения «{{اسم_الدورة}}» '
          'продолжительностью {{مدة_الدورة}} под руководством {{المدرب}}, '
          'показав отличную приверженность и дисциплину.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'успешно завершил(а) программу «{{اسم_الدورة}}» и награждается за '
          'достижение {{مستوى_الأداء}}.',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'успешно и с отличием завершил(а) программу «{{اسم_الدورة}}» и '
          'награждается за достижение {{مستوى_الأداء}} в знак признания '
          'выдающегося академического вклада.',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'в подтверждение прохождения «{{اسم_الدورة}}» продолжительностью '
          '{{مدة_الدورة}} под руководством {{المدرب}}.',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      'за достижение {{مستوى_الأداء}} в «{{اسم_الدورة}}» в знак признания '
          'отличия и постоянного усердия.',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      'за достижение {{مستوى_الأداء}} в «{{اسم_الدورة}}» в знак признания '
          'отличия, постоянного усердия и стремления к совершенству.',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'в знак признания выдающихся результатов, успешного завершения '
          '«{{اسم_الدورة}}» и достижения {{مستوى_الأداء}}.',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'в знак признания усердия, отличия и стремления к знаниям, а также '
          'достижения {{مستوى_الأداء}} в «{{اسم_الدورة}}».',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'за проявленную приверженность и мастерство, достойные признания, а '
          'также достижение {{مستوى_الأداء}} в «{{اسم_الدورة}}».',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'в знак признания выдающихся усилий и образцовой работы. Желаем '
          'дальнейших успехов.',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'в знак признания выдающихся усилий и результатов, соответствующих '
          'нашим ценностям. Желаем дальнейших успехов.',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'в знак признания выдающихся усилий и результатов, соответствующих '
          'нашим ценностям, а также примера мастерства и приверженности. '
          'Желаем дальнейших успехов.',
  // ---- справки ----
  'إلى من يهمه الأمر،': 'Всем заинтересованным лицам,',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'Настоящим подтверждаем, что {{اسم_الطرف_الثاني}} работал(а) в '
          '{{اسم_المنشأة}} с {{تاريخ_البداية}} по {{تاريخ_النهاية}} и за это '
          'время проявил(а) компетентность, дисциплину и полную '
          'приверженность при выполнении порученных задач.',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'Настоящая справка выдана по его/её просьбе для представления '
          'компетентным органам при необходимости и не налагает на организацию '
          'никакой ответственности.',
  'وتفضلوا بقبول فائق الاحترام والتقدير.': 'С уважением и признательностью.',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'Настоящая справка выдана в электронном виде на платформе JoodCraft.',
  // ---- договоры ----
  'الرقم المرجعي: {{رقم_العقد}}': 'Номер документа: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      '{{تاريخ_البداية}} между сторонами достигнуто соглашение:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      '{{تاريخ_العقد}} между сторонами достигнуто соглашение:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'Первая сторона (работодатель): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'Вторая сторона (работник): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'Первая сторона: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'Вторая сторона: {{اسم_الطرف_الثاني}}',
  'الطرف الأول': 'Первая сторона',
  'الطرف الثاني': 'Вторая сторона',
  'البند الأول: المدة': 'Пункт первый: Срок',
  'البند الثاني: الأجر': 'Пункт второй: Вознаграждение',
  'البند الثاني: المقابل المالي': 'Пункт второй: Гонорар',
  'البند الأول: نطاق العمل': 'Пункт первый: Объём работ',
  'البند الثالث: الأحكام العامة': 'Пункт третий: Общие положения',
  'البند الأول: مدة العقد': 'Пункт первый: Срок договора',
  'البند الثاني: الأجر وطريقة الدفع':
      'Пункт второй: Вознаграждение и порядок оплаты',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'Срок действия настоящего договора начинается {{تاريخ_البداية}} и '
          'заканчивается {{تاريخ_النهاية}}; он может быть продлён по '
          'письменному соглашению сторон.',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Вторая сторона имеет право на вознаграждение в размере '
          '{{قيمة_العقد}}. {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Вторая сторона имеет право на вознаграждение за свои услуги в размере '
          '{{قيمة_العقد}}. {{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'Вторая сторона имеет право на вознаграждение в размере '
          '{{قيمة_العقد}}, выплачиваемое регулярно в соответствии с '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'Вторая сторона имеет право на вознаграждение за консультационные '
          'услуги в размере {{قيمة_العقد}}. {{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'Настоящий договор регулируется действующим трудовым законодательством '
          'Королевства Саудовская Аравия, а любой возникающий спор передаётся '
          'в компетентный орган.',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'Настоящий договор регулируется законодательством Королевства '
          'Саудовская Аравия, а любой возникающий спор передаётся в '
          'компетентный судебный орган.',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'Настоящий договор регулируется действующим трудовым законодательством, '
          'а любой возникающий спор передаётся в компетентный орган в '
          'соответствии с применимыми процедурами.',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'Настоящий договор заключён на определённый срок, который начинается '
          '{{تاريخ_البداية}} и заканчивается {{تاريخ_النهاية}}, и не может '
          'быть продлён иначе как по предварительному письменному соглашению '
          'сторон.',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'Вторая сторона обязуется предоставлять согласованные услуги в '
          'соответствии со спецификациями и условиями, указанными в '
          'техническом приложении к настоящему договору.',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'Вторая сторона обязуется предоставлять согласованные консультационные '
          'услуги в соответствии со спецификациями и условиями, указанными в '
          'техническом приложении к настоящему договору.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'Настоящий договор составлен в электронном виде на платформе JoodCraft.',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'Настоящий договор составлен в электронном виде на платформе JoodCraft '
          '{{تاريخ_العقد}}',
};

const Map<String, String> _ruSamples = <String, String>{
  'اسم_المتدرب': 'Анна Кузнецова',
  'اسم_الدورة': 'Профессиональное управление проектами',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 января 2026 г.',
  'الجهة_المانحة': 'Академия JoodCraft',
  'المدرب': 'Д-р Сара Морозова',
  'مدة_الدورة': '40 часов обучения',
  'مستوى_الأداء': 'Первое место',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'ООО «Джуд Трейд»',
  'اسم_الطرف_الثاني': 'ООО «Горизонт Строй»',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 января 2026 г.',
  'تاريخ_البداية': '1 февраля 2026 г.',
  'تاريخ_النهاية': '1 декабря 2026 г.',
  'قيمة_العقد': '150 000 SAR',
  'طريقة_الدفع': 'Аванс 40 %, остаток при поставке.',
  'اسم_المنشأة': 'JoodCraft',
};

const Map<String, String> _zhTexts = <String, String>{
  // ---- 模板标题 ----
  'شهادة شكر وتقدير': '感谢状',
  'شهادة إتمام دورة تدريبية': '培训课程结业证书',
  'شهادة تفوق وتميّز': '优秀证书',
  'إفادة خبرة': '工作经历证明',
  'عقد عمل': '劳动合同',
  'عقد تقديم خدمات': '服务提供合同',
  'شهادة تقدير كلاسيكية': '经典感谢状',
  'شهادة إنجاز بارز': '突出成就证书',
  'شهادة حضور وتدريب': '出席与培训证书',
  'شهادة تقدّم علمي': '学业进步证书',
  'عقد عمل مؤقت': '定期劳动合同',
  'شهادة ملكية كحلية': '皇家深蓝证书',
  'شهادة الجدارة العنابية': '酒红功绩证书',
  'شهادة الاستحقاق الملكي': '帝国功绩证书',
  'شهادة عصرية هادئة': '简约柔和证书',
  'شهادة هندسية زرقاء': '蓝色几何证书',
  'شهادة التدرّج الناعم': '柔和渐变证书',
  'شهادة رسمية مؤسسية': '企业官方证书',
  'شهادة تنفيذية': '高管证书',
  'شهادة الاعتماد المهني': '专业认证证书',
  'شهادة أكاديمية بختم': '带印章的学术证书',
  'شهادة تقدير أنيقة': '优雅感谢状',
  'شهادة مرتبة الشرف': '荣誉证书',
  'شهادة أكاديمية': '学术证书',
  'شهادة إتمام': '结业证书',
  'شهادة إتمام معتمدة': '认证结业证书',
  'شهادة الجدارة والتميّز': '功绩与优秀证书',
  'شهادة تقدير ملكية': '皇家感谢状',
  'شهادة تنفيذية معتمدة': '认证高管证书',
  'شهادة معتمدة رسمياً': '官方认证证书',
  'عقد تقديم استشارات': '咨询服务合同',
  // ---- 模板中的拉丁标题 ----
  'ACADEMIC CERTIFICATE': '学术证书',
  'CERTIFICATE OF DISTINCTION': '杰出证书',
  'CERTIFIED COMPLETION': '认证结业',
  'HONORS CERTIFICATE': '荣誉证书',
  'IMPERIAL CERTIFICATE OF HONOR': '帝国荣誉证书',
  'OFFICIAL CERTIFICATE': '官方证书',
  'PROFESSIONAL ACCREDITATION': '专业认证',
  'ROYAL CERTIFICATE OF MERIT': '皇家功绩证书',
  'CERTIFICATE OF APPRECIATION': '感谢证书',
  'CERTIFICATE OF COMPLETION': '结业证书',
  'CERTIFICATE OF EXCELLENCE': '优秀证书',
  'CERTIFICATE OF ACHIEVEMENT': '成就证书',
  'CERTIFICATE OF ATTENDANCE': '出席证书',
  'CERTIFICATE OF PROGRESS': '进步证书',
  // ---- 证书正文 ----
  'تشهد إدارة {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} 管理层特此证明：',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} 特此证明：',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} 特此证明：',
  'الجهة المانحة': '颁发机构',
  'الرئيس التنفيذي': '首席执行官',
  'المدرب': '培训师',
  'المدرّب المعتمد': '认证培训师',
  'المدير الأكاديمي': '学术总监',
  'المدير التنفيذي': '执行总监',
  'المدير العام': '总经理',
  'الموارد البشرية': '人力资源部',
  'مدير الأكاديمية': '学院主管',
  'مدير المدرسة': '校长',
  'مدير البرنامج': '项目总监',
  'مدير البرنامج — {{الجهة_المانحة}}': '项目总监 — {{الجهة_المانحة}}',
  'مدير التحكيم': '评审团主席',
  'مدير المركز': '中心主任',
  'عميد الكلية': '学院院长',
  'عميد المعهد': '研究所所长',
  'التوقيع المعتمد': '授权签字',
  'التاريخ: {{التاريخ}}': '日期：{{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}': '执行总监 — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}': '执行总监 — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': '证书编号：{{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      '证书编号：{{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': '验证：{{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}': '如需验证此证书：{{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': '本研究所向以下人员致以祝贺：',
  'يُكرَّم المتدرب': '表彰学员',
  'تُمنح هذه الشهادة إلى': '本证书授予',
  'تُمنح بمرتبة الشرف إلى': '以荣誉名义授予',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      '本证书通过 JoodCraft 平台以电子方式签发。',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      '通过 JoodCraft 以电子方式签发 — {{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      '作出了杰出的努力和堪称楷模的表现，值得表彰与赞扬。祝愿其继续取得成功。',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      '已成功完成「{{اسم_الدورة}}」培训课程，为期 {{مدة_الدورة}}，由 {{المدرب}} 指导，'
          '展现了敬业精神与卓越表现。',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      '因在「{{اسم_الدورة}}」中取得 {{مستوى_الأداء}}，以表彰其勤奋、卓越与求知精神。',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '已成功完成「{{اسم_الدورة}}」，为期 {{مدة_الدورة}}，由 {{المدرب}} 指导。',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      '已成功完成「{{اسم_الدورة}}」，为期 {{مدة_الدورة}}，由 {{المدرب}} 指导，'
          '并获得 {{مستوى_الأداء}}。',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '已成功完成「{{اسم_الدورة}}」培训课程，为期 {{مدة_الدورة}}，由 {{المدرب}} 指导。',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      '已成功完成「{{اسم_الدورة}}」课程，为期 {{مدة_الدورة}}，展现了敬业精神与卓越表现。',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      '已出席并通过「{{اسم_الدورة}}」培训课程，为期 {{مدة_الدورة}}，由 {{المدرب}} '
          '指导，展现了出色的敬业精神与纪律性。',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      '已成功完成「{{اسم_الدورة}}」课程，并因取得 {{مستوى_الأداء}} 而受到表彰。',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      '已成功并出色地完成「{{اسم_الدورة}}」课程，并因取得 {{مستوى_الأداء}} 而受到表彰，'
          '以肯定其卓越的学术贡献。',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '以证明其完成「{{اسم_الدورة}}」，为期 {{مدة_الدورة}}，由 {{المدرب}} 指导。',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      '因在「{{اسم_الدورة}}」中取得 {{مستوى_الأداء}}，以表彰其卓越表现与不懈努力。',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      '因在「{{اسم_الدورة}}」中取得 {{مستوى_الأداء}}，以表彰其卓越、不懈努力与对卓越的追求。',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      '以表彰其卓越表现、成功完成「{{اسم_الدورة}}」以及取得 {{مستوى_الأداء}}。',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      '以表彰其勤奋、卓越与求知精神，以及在「{{اسم_الدورة}}」中取得 {{مستوى_الأداء}}。',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      '以表彰其展现的、值得肯定的敬业与精湛，以及在「{{اسم_الدورة}}」中取得 {{مستوى_الأداء}}。',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      '以表彰其杰出的努力与堪称楷模的表现。祝愿其继续取得成功。',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      '以表彰其杰出的努力与符合我们价值观的卓越表现。祝愿其继续取得成功。',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      '以表彰其杰出的努力与符合我们价值观的卓越表现，以及其在敬业与奉献方面的表率作用。'
          '祝愿其继续取得成功。',
  // ---- 工作经历证明 ----
  'إلى من يهمه الأمر،': '敬启者：',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      '兹证明 {{اسم_الطرف_الثاني}} 曾在 {{اسم_المنشأة}} 工作，自 {{تاريخ_البداية}} '
          '至 {{تاريخ_النهاية}}，在此期间表现出能力、纪律以及对所委派任务的完全投入。',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      '本证明系应其本人要求出具，以便在需要时提交给主管机关，本机构不承担任何责任。',
  'وتفضلوا بقبول فائق الاحترام والتقدير.': '此致敬礼，并致最崇高的敬意。',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      '本证明通过 JoodCraft 平台以电子方式签发。',
  // ---- 合同 ----
  'الرقم المرجعي: {{رقم_العقد}}': '参考编号：{{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      '于 {{تاريخ_البداية}}，双方经协商达成如下协议：',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      '于 {{تاريخ_العقد}}，双方经协商达成如下协议：',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}': '甲方（雇主）：{{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}': '乙方（雇员）：{{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': '甲方：{{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': '乙方：{{اسم_الطرف_الثاني}}',
  'الطرف الأول': '甲方',
  'الطرف الثاني': '乙方',
  'البند الأول: المدة': '第一条：期限',
  'البند الثاني: الأجر': '第二条：薪酬',
  'البند الثاني: المقابل المالي': '第二条：报酬',
  'البند الأول: نطاق العمل': '第一条：工作范围',
  'البند الثالث: الأحكام العامة': '第三条：一般条款',
  'البند الأول: مدة العقد': '第一条：合同期限',
  'البند الثاني: الأجر وطريقة الدفع': '第二条：薪酬与支付方式',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      '本合同期限自 {{تاريخ_البداية}} 起，至 {{تاريخ_النهاية}} 止，经双方书面协议可以续签。',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      '乙方有权获得薪酬 {{قيمة_العقد}}。{{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      '乙方就其服务有权获得报酬 {{قيمة_العقد}}。{{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      '乙方有权获得薪酬 {{قيمة_العقد}}，按照 {{طريقة_الدفع}} 定期支付',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      '乙方就其咨询服务有权获得报酬 {{قيمة_العقد}}。{{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      '本合同受沙特阿拉伯王国现行劳动法规管辖，由此产生的任何争议均提交主管机关处理。',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      '本合同受沙特阿拉伯王国法律管辖，由此产生的任何争议均提交主管司法机关处理。',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      '本合同受现行劳动法规管辖，由此产生的任何争议均按适用程序提交主管机关处理。',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      '本合同按特定期限订立，自 {{تاريخ_البداية}} 起至 {{تاريخ_النهاية}} 止，'
          '除经双方事先书面协议外不得延期。',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      '乙方承诺按照本合同技术附件所载的规格和条件提供约定服务。',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      '乙方承诺按照本合同所附技术附件所载的规格和条件提供约定的咨询服务。',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      '本合同通过 JoodCraft 平台以电子方式订立。',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      '本合同于 {{تاريخ_العقد}} 通过 JoodCraft 平台以电子方式订立',
};

const Map<String, String> _zhSamples = <String, String>{
  'اسم_المتدرب': '李思远',
  'اسم_الدورة': '专业项目管理',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '2026年1月15日',
  'الجهة_المانحة': 'JoodCraft 学院',
  'المدرب': '张伟博士',
  'مدة_الدورة': '40 学时',
  'مستوى_الأداء': '第一名',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': '吉祥贸易有限公司',
  'اسم_الطرف_الثاني': '地平线建筑工程有限公司',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '2026年1月15日',
  'تاريخ_البداية': '2026年2月1日',
  'تاريخ_النهاية': '2026年12月1日',
  'قيمة_العقد': '150,000 沙特里亚尔',
  'طريقة_الدفع': '预付40%，余款交货时支付。',
  'اسم_المنشأة': 'JoodCraft',
};

const Map<String, String> _urTexts = <String, String>{
  // ---- سند کے عنوانات ----
  'شهادة شكر وتقدير': 'تعریفی سند',
  'شهادة إتمام دورة تدريبية': 'کورس مکمل کرنے کی سند',
  'شهادة تفوق وتميّز': 'شاندار کارکردگی کی سند',
  'إفادة خبرة': 'تجربے کی سند',
  'عقد عمل': 'معاہدۂ ملازمت',
  'عقد تقديم خدمات': 'خدمات فراہمی کا معاہدہ',
  'شهادة تقدير كلاسيكية': 'کلاسیکی تعریفی سند',
  'شهادة إنجاز بارز': 'نمایاں کارنامے کی سند',
  'شهادة حضور وتدريب': 'حاضری اور تربیت کی سند',
  'شهادة تقدّم علمي': 'علمی ترقی کی سند',
  'عقد عمل مؤقت': 'عارضی معاہدۂ ملازمت',
  'شهادة ملكية كحلية': 'شاہی گہرے نیلے رنگ کی سند',
  'شهادة الجدارة العنابية': 'عنابی فضیلت کی سند',
  'شهادة الاستحقاق الملكي': 'شاہی فضیلت کی سند',
  'شهادة عصرية هادئة': 'سادہ پاسٹل سند',
  'شهادة هندسية زرقاء': 'نیلی ہندسی سند',
  'شهادة التدرّج الناعم': 'نرم گریڈیشن کی سند',
  'شهادة رسمية مؤسسية': 'سرکاری ادارہ جاتی سند',
  'شهادة تنفيذية': 'ایگزیکٹو سند',
  'شهادة الاعتماد المهني': 'پیشہ ورانہ منظوری کی سند',
  'شهادة أكاديمية بختم': 'مہر کے ساتھ تعلیمی سند',
  'شهادة تقدير أنيقة': 'خوبصورت تعریفی سند',
  'شهادة مرتبة الشرف': 'امتیازی سند',
  'شهادة أكاديمية': 'تعلیمی سند',
  'شهادة إتمام': 'تکمیل کی سند',
  'شهادة إتمام معتمدة': 'تصدیق شدہ تکمیل کی سند',
  'شهادة الجدارة والتميّز': 'فضیلت اور شاندار کارکردگی کی سند',
  'شهادة تقدير ملكية': 'شاہی تعریفی سند',
  'شهادة تنفيذية معتمدة': 'تصدیق شدہ ایگزیکٹو سند',
  'شهادة معتمدة رسمياً': 'سرکاری طور پر تصدیق شدہ سند',
  'عقد تقديم استشارات': 'مشاورتی خدمات کا معاہدہ',
  // ---- سندوں میں موجود لاطینی عنوانات ----
  'ACADEMIC CERTIFICATE': 'تعلیمی سند',
  'CERTIFICATE OF DISTINCTION': 'امتیاز کی سند',
  'CERTIFIED COMPLETION': 'تصدیق شدہ تکمیل',
  'HONORS CERTIFICATE': 'امتیازی سند',
  'IMPERIAL CERTIFICATE OF HONOR': 'شاہی اعزازی سند',
  'OFFICIAL CERTIFICATE': 'سرکاری سند',
  'PROFESSIONAL ACCREDITATION': 'پیشہ ورانہ منظوری',
  'ROYAL CERTIFICATE OF MERIT': 'شاہی فضیلت کی سند',
  'CERTIFICATE OF APPRECIATION': 'تعریفی سند',
  'CERTIFICATE OF COMPLETION': 'تکمیل کی سند',
  'CERTIFICATE OF EXCELLENCE': 'شاندار کارکردگی کی سند',
  'CERTIFICATE OF ACHIEVEMENT': 'کارنامے کی سند',
  'CERTIFICATE OF ATTENDANCE': 'حاضری کی سند',
  'CERTIFICATE OF PROGRESS': 'ترقی کی سند',
  // ---- سند کا متن ----
  'تشهد إدارة {{الجهة_المانحة}} بأن':
      '{{الجهة_المانحة}} کی انتظامیہ تصدیق کرتی ہے کہ',
  'تشهد {{الجهة_المانحة}} بأن': '{{الجهة_المانحة}} تصدیق کرتا ہے کہ',
  'تشهد {{الجهة_المانحة}} بأنّ': '{{الجهة_المانحة}} تصدیق کرتا ہے کہ',
  'الجهة المانحة': 'جاری کنندہ ادارہ',
  'الرئيس التنفيذي': 'چیف ایگزیکٹو آفیسر',
  'المدرب': 'ٹرینر',
  'المدرّب المعتمد': 'تصدیق شدہ ٹرینر',
  'المدير الأكاديمي': 'تعلیمی ڈائریکٹر',
  'المدير التنفيذي': 'ایگزیکٹو ڈائریکٹر',
  'المدير العام': 'جنرل مینیجر',
  'الموارد البشرية': 'انسانی وسائل',
  'مدير الأكاديمية': 'اکیڈمی ڈائریکٹر',
  'مدير المدرسة': 'اسکول پرنسپل',
  'مدير البرنامج': 'پروگرام ڈائریکٹر',
  'مدير البرنامج — {{الجهة_المانحة}}':
      'پروگرام ڈائریکٹر — {{الجهة_المانحة}}',
  'مدير التحكيم': 'منصفی کمیٹی کے سربراہ',
  'مدير المركز': 'مرکز ڈائریکٹر',
  'عميد الكلية': 'ڈین آف فیکلٹی',
  'عميد المعهد': 'ڈائریکٹر انسٹیٹیوٹ',
  'التوقيع المعتمد': 'مجاز دستخط',
  'التاريخ: {{التاريخ}}': 'تاریخ: {{التاريخ}}',
  '{{الجهة_المانحة}} — {{التاريخ}}': '{{الجهة_المانحة}} — {{التاريخ}}',
  'المدير التنفيذي — {{الجهة_المانحة}}':
      'ایگزیکٹو ڈائریکٹر — {{الجهة_المانحة}}',
  'المدير التنفيذي — {{اسم_المنشأة}}':
      'ایگزیکٹو ڈائریکٹر — {{اسم_المنشأة}}',
  'رقم الشهادة: {{رقم_الشهادة}}': 'سند نمبر: {{رقم_الشهادة}}',
  'رقم الشهادة: {{رقم_الشهادة}} — {{رابط_التحقق}}':
      'سند نمبر: {{رقم_الشهادة}} — {{رابط_التحقق}}',
  'للتحقق: {{رقم_الشهادة}}': 'تصدیق کے لیے: {{رقم_الشهادة}}',
  'للتحقق من صحة الشهادة: {{رقم_الشهادة}}':
      'اس سند کی تصدیق کے لیے: {{رقم_الشهادة}}',
  'يتقدّم المعهد بالتهنئة إلى': 'انسٹیٹیوٹ مبارکباد پیش کرتا ہے',
  'يُكرَّم المتدرب': 'تربیت یافتہ کو اعزاز دیا جاتا ہے',
  'تُمنح هذه الشهادة إلى': 'یہ سند عطا کی جاتی ہے',
  'تُمنح بمرتبة الشرف إلى': 'امتیاز کے ساتھ عطا کی جاتی ہے',
  'حُرّرت هذه الشهادة إلكترونياً عبر منصة جودكرافت.':
      'یہ سند جود کرافٹ پلیٹ فارم کے ذریعے برقی طور پر جاری کی گئی۔',
  'حُرّرت هذه الشهادة إلكترونياً — {{رقم_الشهادة}}':
      'جود کرافٹ کے ذریعے برقی طور پر جاری کی گئی — {{رقم_الشهادة}}',
  'قدّم جهوداً متميزة وأداءً مشرفاً يستحق التقدير والثناء، سائلين الله له دوام التوفيق والسداد.':
      'شاندار کوششیں اور مثالی کارکردگی کا مظاہرہ کیا ہے جو تعریف کے '
          'لائق ہے۔ ہم اس کی مسلسل کامیابی کی دعا کرتے ہیں۔',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وأظهر التزاماً وتميّزاً في الأداء.':
      'نے «{{اسم_الدورة}}» تربیتی پروگرام {{مدة_الدورة}} کی مدت میں '
          '{{المدرب}} کی زیر نگرانی کامیابی سے مکمل کیا اور عزم و شاندار '
          'کارکردگی کا مظاہرہ کیا۔',
  'لتحقيقه {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديراً لما أبداه من اجتهاد وتفوّق وحرص على التعلّم.':
      '«{{اسم_الدورة}}» میں {{مستوى_الأداء}} حاصل کرنے پر، ان کی محنت، '
          'برتری اور سیکھنے کے شوق کے اعتراف میں۔',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'نے «{{اسم_الدورة}}» {{مدة_الدورة}} کی مدت میں {{المدرب}} کی زیر '
          'نگرانی کامیابی سے مکمل کیا۔',
  'قد أتمّ بنجاح «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، وحصوله على {{مستوى_الأداء}}.':
      'نے «{{اسم_الدورة}}» {{مدة_الدورة}} کی مدت میں {{المدرب}} کی زیر '
          'نگرانی کامیابی سے مکمل کیا اور {{مستوى_الأداء}} حاصل کیا۔',
  'قد أتمّ بنجاح البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      'نے «{{اسم_الدورة}}» تربیتی پروگرام {{مدة_الدورة}} کی مدت میں '
          '{{المدرب}} کی زیر نگرانی کامیابی سے مکمل کیا۔',
  'قد أتمّ بنجاح برنامج «{{اسم_الدورة}}» بمدة {{مدة_الدورة}}، وأظهر التزاماً وتفوّقاً في الأداء.':
      'نے «{{اسم_الدورة}}» پروگرام {{مدة_الدورة}} کی مدت میں کامیابی سے '
          'مکمل کیا اور عزم و برتری کا مظاہرہ کیا۔',
  'قد حضر واجتاز البرنامج التدريبي «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}، مُظهرًا التزاماً وانضباطاً ممتازاً.':
      'نے «{{اسم_الدورة}}» تربیتی پروگرام {{مدة_الدورة}} کی مدت میں '
          '{{المدرب}} کی زیر نگرانی میں شرکت کی اور کامیابی سے پاس کیا، '
          'بہترین عزم و ضبط کا مظاہرہ کرتے ہوئے۔',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح، ويُكرَّم لحصوله على {{مستوى_الأداء}}.':
      'نے «{{اسم_الدورة}}» پروگرام کامیابی سے مکمل کیا اور {{مستوى_الأداء}} '
          'حاصل کرنے پر اعزاز دیا جاتا ہے۔',
  'قد أتمّ برنامج «{{اسم_الدورة}}» بنجاح وتميّز، ويُكرَّم لحصوله على {{مستوى_الأداء}} حفلاً لعطائه العلمي المتميّز.':
      'نے «{{اسم_الدورة}}» پروگرام کامیابی اور امتیاز کے ساتھ مکمل کیا '
          'اور {{مستوى_الأداء}} حاصل کرنے پر اعزاز دیا جاتا ہے، ان کی '
          'شاندار علمی خدمات کے اعتراف میں۔',
  'اعتماداً لإتمامه «{{اسم_الدورة}}» بمدة {{مدة_الدورة}} وبإشراف {{المدرب}}.':
      '«{{اسم_الدورة}}» {{مدة_الدورة}} کی مدت میں {{المدرب}} کی زیر نگرانی '
          'مکمل کرنے کی تصدیق میں۔',
  'لحصوله على {{مستوى_الأداء}} في «{{اسم_الدورة}}»، تقديراً لتفوّقه واجتهاده المستمر.':
      '«{{اسم_الدورة}}» میں {{مستوى_الأداء}} حاصل کرنے پر، ان کی برتری '
          'اور مسلسل محنت کے اعتراف میں۔',
  'لحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}، تقديرًا لتفوقه واجتهاده المستمر وحرصه على التميّز.':
      '«{{اسم_الدورة}}» میں {{مستوى_الأداء}} حاصل کرنے پر، ان کی برتری، '
          'مسلسل محنت اور برتری کے حصول کی کوشش کے اعتراف میں۔',
  'تقديرًا لأدائه المتميّز وإتمامه «{{اسم_الدورة}}» بنجاح، وحصوله على {{مستوى_الأداء}}.':
      'ان کی شاندار کارکردگی، «{{اسم_الدورة}}» کامیابی سے مکمل کرنے اور '
          '{{مستوى_الأداء}} حاصل کرنے کے اعتراف میں۔',
  'تقديرًا لما أبداه من اجتهاد وتفوّق وحرص على التعلّم، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'ان کی محنت، برتری اور سیکھنے کے شوق، اور «{{اسم_الدورة}}» میں '
          '{{مستوى_الأداء}} حاصل کرنے کے اعتراف میں۔',
  'لما أظهره من التزام وإتقان يستحق التقدير، وحصوله على {{مستوى_الأداء}} في {{اسم_الدورة}}.':
      'ان کے عزم و مہارت کے اعتراف میں جو تعریف کے لائق ہے، اور '
          '«{{اسم_الدورة}}» میں {{مستوى_الأداء}} حاصل کرنے پر۔',
  'تقديراً لجهوده المتميّزة وأدائه المشرف الذي يستحق الثناء، سائلين له دوام التوفيق والنجاح.':
      'ان کی شاندار کوششوں اور مثالی کارکردگی کے اعتراف میں۔ ہم ان کی '
          'مسلسل کامیابی کی دعا کرتے ہیں۔',
  'تقديرًا لجهوده المتميّزة وأدائه البارز الذي يليق بقيمنا، مع تمنياتنا له بدوام التوفيق والسداد.':
      'ان کی شاندار کوششوں اور ہماری اقدار کے مطابق نمایاں کارکردگی کے '
          'اعتراف میں۔ ہم ان کی مسلسل کامیابی کی دعا کرتے ہیں۔',
  'تقديرًا لجهوده المتميزة وأدائه البارز الذي يليق بقيمنا، واحتفاله قدوةً في الإتقان والالتزام، متمنين له دوام التوفيق.':
      'ان کی شاندار کوششوں اور ہماری اقدار کے مطابق نمایاں کارکردگی کے '
          'اعتراف میں، نیز مہارت اور عزم میں نمونہ ہونے پر۔ ہم ان کی مسلسل '
          'کامیابی کی دعا کرتے ہیں۔',
  // ---- تجربے کی سند ----
  'إلى من يهمه الأمر،': 'بخدمت متعلقہ صاحب،',
  'نشهد بأن السيد/ {{اسم_الطرف_الثاني}} قد عمل لدى {{اسم_المنشأة}} خلال الفترة من {{تاريخ_البداية}} إلى {{تاريخ_النهاية}}، وقد اتّسم خلالها بالكفاءة والانضباط والالتزام بأداء المهام الموكلة إليه على أكمل وجه.':
      'ہم تصدیق کرتے ہیں کہ {{اسم_الطرف_الثاني}} نے {{اسم_المنشأة}} میں '
          '{{تاريخ_البداية}} سے {{تاريخ_النهاية}} تک کام کیا، اور اس دوران '
          'اہلیت، نظم و ضبط اور تفویض کردہ ذمہ داریوں کی مکمل ادائیگی کا '
          'مظاہرہ کیا۔',
  'وقد أُعطيت له هذه الإفادة بناءً على طلبه لتقديمها إلى الجهات المختصة عند الحاجة، دون أدنى مسؤولية على المنشأة.':
      'یہ سند ان کی درخواست پر جاری کی گئی ہے تاکہ ضرورت پڑنے پر متعلقہ '
          'حکام کو پیش کی جا سکے، ادارے پر کوئی ذمہ داری عائد نہیں ہوتی۔',
  'وتفضلوا بقبول فائق الاحترام والتقدير.': 'ہم اپنی بھرپور عزت و احترام پیش کرتے ہیں۔',
  'صدرت هذه الإفادة إلكترونياً عبر منصة جودكرافت.':
      'یہ سند جود کرافٹ پلیٹ فارم کے ذریعے برقی طور پر جاری کی گئی۔',
  // ---- معاہدے ----
  'الرقم المرجعي: {{رقم_العقد}}': 'حوالہ نمبر: {{رقم_العقد}}',
  'إنه في يوم {{تاريخ_البداية}}، تم الاتفاق بين كل من:':
      '{{تاريخ_البداية}} کو درج ذیل فریقین کے درمیان معاہدہ طے پایا:',
  'إنه في يوم {{تاريخ_العقد}}، تم الاتفاق بين كل من:':
      '{{تاريخ_العقد}} کو درج ذیل فریقین کے درمیان معاہدہ طے پایا:',
  'الطرف الأول (صاحب العمل): {{اسم_المنشأة}}':
      'پہلا فریق (آجر): {{اسم_المنشأة}}',
  'الطرف الثاني (العامل): {{اسم_الطرف_الثاني}}':
      'دوسرا فریق (ملازم): {{اسم_الطرف_الثاني}}',
  'الطرف الأول: {{اسم_الطرف_الأول}}': 'پہلا فریق: {{اسم_الطرف_الأول}}',
  'الطرف الثاني: {{اسم_الطرف_الثاني}}': 'دوسرا فریق: {{اسم_الطرف_الثاني}}',
  'الطرف الأول': 'پہلا فریق',
  'الطرف الثاني': 'دوسرا فریق',
  'البند الأول: المدة': 'پہلی شق: مدت',
  'البند الثاني: الأجر': 'دوسری شق: اجرت',
  'البند الثاني: المقابل المالي': 'دوسری شق: معاوضہ',
  'البند الأول: نطاق العمل': 'پہلی شق: دائرۂ کار',
  'البند الثالث: الأحكام العامة': 'تیسری شق: عمومی دفعات',
  'البند الأول: مدة العقد': 'پہلی شق: معاہدے کی مدت',
  'البند الثاني: الأجر وطريقة الدفع': 'دوسری شق: اجرت اور ادائیگی کا طریقہ',
  'تبدأ مدة هذا العقد من تاريخ {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ويجوز تجديده باتفاق كتابي بين الطرفين.':
      'اس معاہدے کی مدت {{تاريخ_البداية}} سے شروع ہو کر {{تاريخ_النهاية}} کو '
          'ختم ہوتی ہے، اور فریقین کے تحریری معاہدے سے اس کی تجدید کی جا '
          'سکتی ہے۔',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'دوسرا فریق {{قيمة_العقد}} کی اجرت کا حقدار ہوگا۔ {{طريقة_الدفع}}',
  'يستحق الطرف الثاني مقابل خدماته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'دوسرا فریق اپنی خدمات کے بدلے {{قيمة_العقد}} کا حقدار ہوگا۔ '
          '{{طريقة_الدفع}}',
  'يستحق الطرف الثاني أجراً وقدره {{قيمة_العقد}}، تُصرف بانتظام وفق {{طريقة_الدفع}}':
      'دوسرا فریق {{قيمة_العقد}} کی اجرت کا حقدار ہوگا، جو {{طريقة_الدفع}} '
          'کے مطابق باقاعدگی سے ادا کی جائے گی',
  'يستحق الطرف الثاني مقابل استشاراته {{قيمة_العقد}}. و{{طريقة_الدفع}}':
      'دوسرا فریق اپنی مشاورتی خدمات کے بدلے {{قيمة_العقد}} کا حقدار '
          'ہوگا۔ {{طريقة_الدفع}}',
  'يخضع هذا العقد لأنظمة العمل السارية في المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة.':
      'یہ معاہدہ مملکت سعودی عرب میں نافذ مزدوری قوانین کے تابع ہے، اور اس '
          'سے پیدا ہونے والا کوئی بھی تنازعہ متعلقہ حکام کو بھیجا جائے گا۔',
  'يخضع هذا العقد لأنظمة المملكة العربية السعودية، وأي نزاع ينشأ عنه يُحال إلى الجهة القضائية المختصة.':
      'یہ معاہدہ مملکت سعودی عرب کے قوانین کے تابع ہے، اور اس سے پیدا ہونے '
          'والا کوئی بھی تنازعہ متعلقہ عدلیہ کو بھیجا جائے گا۔',
  'يخضع هذا العقد لأنظمة العمل السارية، وأي نزاع ينشأ عنه يُحال إلى الجهة المختصة وفق الإجراءات المعمول بها.':
      'یہ معاہدہ نافذ مزدوری قوانین کے تابع ہے، اور اس سے پیدا ہونے والا '
          'کوئی بھی تنازعہ رائج طریقہ کار کے مطابق متعلقہ حکام کو بھیجا جائے گا۔',
  'أُبرم هذا العقد لفترة مؤقتة تبدأ من {{تاريخ_البداية}} وتنتهي في {{تاريخ_النهاية}}، ولا يجوز تمديده إلا باتفاق مكتوب مسبق بين الطرفين.':
      'یہ معاہدہ ایک مقررہ مدت کے لیے کیا گیا ہے جو {{تاريخ_البداية}} سے '
          'شروع ہو کر {{تاريخ_النهاية}} کو ختم ہوتی ہے، اور فریقین کے پیشگی '
          'تحریری معاہدے کے بغیر اس میں توسیع نہیں کی جا سکتی۔',
  'يلتزم الطرف الثاني بتقديم الخدمات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني لهذا العقد.':
      'دوسرا فریق اس معاہدے کے فنی ضمیمے میں درج وضاحتوں اور شرائط کے '
          'مطابق طے شدہ خدمات فراہم کرنے کا پابند ہوگا۔',
  'يلتزم الطرف الثاني بتقديم الاستشارات المتفق عليها وفق المواصفات والشروط الواردة في الملحق الفني المرفق بهذا العقد.':
      'دوسرا فریق اس معاہدے کے ساتھ منسلک فنی ضمیمے میں درج وضاحتوں اور '
          'شرائط کے مطابق طے شدہ مشاورتی خدمات فراہم کرنے کا پابند ہوگا۔',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت.':
      'یہ معاہدہ جود کرافٹ پلیٹ فارم کے ذریعے برقی طور پر تیار کیا گیا۔',
  'حُرّر هذا العقد إلكترونياً عبر منصة جودكرافت بتاريخ {{تاريخ_العقد}}':
      'یہ معاہدہ {{تاريخ_العقد}} کو جود کرافٹ پلیٹ فارم کے ذریعے برقی طور '
          'پر تیار کیا گیا',
};

const Map<String, String> _urSamples = <String, String>{
  'اسم_المتدرب': 'احمد رضا خان',
  'اسم_الدورة': 'پیشہ ورانہ منصوبہ بندی',
  'رقم_الشهادة': 'JC-2026-000112',
  'التاريخ': '15 جنوری 2026',
  'الجهة_المانحة': 'جود کرافٹ اکیڈمی',
  'المدرب': 'ڈاکٹر سارہ خان',
  'مدة_الدورة': '40 گھنٹے تربیت',
  'مستوى_الأداء': 'پہلی پوزیشن',
  'رابط_التحقق': 'https://joodcraft.app/v/JC-2026-000112',
  'اسم_الطرف_الأول': 'جود ٹریڈنگ کمپنی',
  'اسم_الطرف_الثاني': 'افق کنسٹرکشن',
  'رقم_العقد': 'JC-C-2026-0044',
  'تاريخ_العقد': '15 جنوری 2026',
  'تاريخ_البداية': '1 فروری 2026',
  'تاريخ_النهاية': '1 دسمبر 2026',
  'قيمة_العقد': '150,000 سعودی ریال',
  'طريقة_الدفع': '%40 پیشگی ادائیگی، باقی ترسیل پر۔',
  'اسم_المنشأة': 'JoodCraft',
};
