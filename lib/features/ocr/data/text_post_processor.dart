/// تنظيف النص المستخرج من OCR قبل عرضه للمستخدم.
///
/// **المشكلة:** Tesseract يقرأ مستنداً عربياً فيه كلمات لاتينية فيُنتج رموزاً
/// لاتينية **وهمية** لا معنى لها (`by`, `so`, `ne`, `dal`, `cai`, `Land`…) —
/// هي أخطاء قراءة لحروف عربية، لا إنجليزية حقيقية. ويُنتج أيضاً أخطاء عربية
/// شائعة (`الالرحمن`، `وو`، مسافات مزدوجة، `....`، ازدواج الياء `التقويى`).
///
/// **المبدأ الحاكم:** لا نحذف إلا ما ثبت أنه وهمي، ونُبقي كل ما يحمل معنى:
///
/// | يُحذف | يُحفظ |
/// |---|---|
/// | لاتيني **ملتصق** بحروف عربي (`بby`) | جملة إنجليزية فيها مفردة تفهم (`CEO and Founder`) |
/// | كلمة/مجموعة لاتينية **وسط نص عربي** لا تفهم | اختصار كلّه أحرف كبيرة (`API`, `PDF`, `URL`, `US`) |
/// | الرموز المُبلَّغ عنها (`by`,`so`,`ne`,`dal`,`cai`,`land`) | كلمة إنجليزية معروفة (`hello`, `world`, `internet`…) |
/// | رمز داخل قوس مرجع (`[ق: AVA]` ← `[ق: ]`) | روابط وبريد (`example.com`, `user@host`) |
///
/// ## القواعد (أربع عشرة)
///
/// 1.  المحارف غير المرئية وTatweel
/// 2.  لاتيني ملتصق بالعربي
/// 3.  رموز وهمية وسط نصّ عربي (**بما فيها مجموعات كاملة لا تفهم**)
/// 4.  صلعم → ﷺ
/// 5.  الال → ال
/// 6.  وو → و
/// 7.  ازدواج الياء: التقويى → التقويي
/// 8.  !! → !  و .... → ...
/// 9.  الأرقام: `18` ← `١٨` في سياق عربي غالب
/// 10. قوس المرجع: `[ق: AVA]` ← `[ق: ]`
/// 11. الأقواس المزخرفة: `تعالى: …)` ← `تعالى: ﴿…﴾`
/// 12. المسافات
/// 13. حذف الفراغ في الطرفين
/// 14. **تصحيح الكلمة العربية بالقاموس** (مسافة تحرير 1، بلا التباس)
///
/// **حدود هذا المعالج:** تحسين تلقائيّ **لا بديل** عن المراجعة البشرية —
/// لذلك يبقى النصّ قابلاً للتحرير، وتُعرض ملاحظة `ocrCleanupNote` عند تغيّره.
library;

import 'arabic_word_list.dart';
import 'quran_word_list.dart';

class OcrTextPostProcessor {
  const OcrTextPostProcessor._();

  // ==========================================================================
  //  مفردات التحكّم (محارف هربة — لا محارف مرئية غير مرئية في المصدر!)
  // ==========================================================================

  /// نطاقات الحروف العربية (بما فيها علامات التشكيل).
  static const String _arabic = r'؀-ۿݐ-ݿ';

  /// المحارف غير المرئية التي يزيدها الاستخراج أحياناً
  /// (Zero-Width Space/Joiner، BOM، Soft Hyphen، Word Joiner،
  /// وكذلك **علامات الاتجاه** LRM/RLM).
  ///
  /// ⚠️ **لماذا أضيفت LRM/RLM؟** القياس بيّن أنّهما يظهران **داخل** الأرقام
  /// في المخرَج العربي (`١‏-`، `[ق: ١/ا].‏`) فيُحسبان حرفين في كل رقم.
  /// وهما علامتا تنسيق لا تحملان معنى — وسكربت القياس في المشروع
  /// (`run_tesseract.py`) يُسقطهما أصلاً في `_TASHKEEL`، فإبقاؤهما هنا
  /// يجعل النصّ المعروض أسوأ من النصّ المقيس.
  static final RegExp _invisible = RegExp(
    '[\u200B\u200C\u200D\uFEFF\u00AD\u2060\u200E\u200F]',
  );

  /// الرسم المتكرّر (Tatweel) — ضجيج بصري خالص لا معنى له.
  static final RegExp _tatweel = RegExp('ـ');

  /// رموز المسافة غير الاعتيادية → مسافة عادية
  /// (NBSP، مسافات رفيعة/ضيّقة، مسافةideographic).
  static final RegExp _oddSpace = RegExp('[\u00A0\u2007\u2008\u2009\u202F\u3000]');

  /// نصّ عربي في سطر ما (شرط الحذف كله: لا نلمس سطراً لاتينياً خالصاً).
  static final RegExp _hasArabic = RegExp('[$_arabic]');

  /// كلمة لاتينية «نواة»: تبدأ بحرف ولا تحوي `@` أو `.` (فيبقى البريد والروابط
  /// خارج كل معالجة — لا يمكن أن تُحذف).
  static final RegExp _latinCore = RegExp(r"^[A-Za-z][A-Za-z0-9'\-]*$");

  /// اختصارات حقيقية شائعة في المستندات — هي وحدها تُعفى من الحذف.
  ///
  /// ⚠️ **لماذا قائمة لا تعبيرٌ نمطي؟** كان الاعتماد على `^[A-Z]{2,6}$` يعتبر
  /// **كل** زمرة حروف كبيرة اختصاراً — فينجو `ABN` و`BI` و`AVA` وهي قراءات
  /// مشوّهة لأرقامٍ هندية ولم تُخترع كاختصارات أبداً، ويزيد الأمر أنّها كانت
  /// تجعل جاراتها «ذات معنى» فتُحفَظ معها. القائمة الصريحة تُنقذ `API`/`PDF`
  /// وتُلقي البقيّة.
  static const Set<String> _knownAcronyms = <String>{
    // أنظمة ووظائف
    'API', 'PDF', 'PNG', 'JPG', 'OCR', 'CSS', 'HTML', 'SQL', 'USB', 'SIM', 'URL',
    // دول وجهات
    'US', 'UK', 'UAE', 'KSA', 'EU', 'UN', 'HQ', 'PIN', 'VAT',
    // أدوار ومسمّيات
    'HR', 'PR', 'R&D', 'CEO', 'CFO', 'CTO', 'MBA', 'PhD', 'GPA',
    // أرقام ووحدات شائعة
    'TV', 'PC', 'AM', 'PM', 'ID', 'SMS', 'GSM', 'ICT', 'WC', 'AC', 'DC',
  };

  /// لاتيني **ملتصق** بحرف عربي من جهة أو من الجهتين.
  /// لتفادي `lookbehind` (غير مدعومة في `RegExp` بـDart) نلتقط الطرفين معاً.
  static final RegExp _gluedLatin = RegExp(
    '([$_arabic])([A-Za-z]{1,8})|([A-Za-z]{1,8})([$_arabic])',
  );

  /// تكرار حرف الواو/الفاء (`وو` → `و`) — أثر قراءة مضاعف.
  static final RegExp _doubledWawFaw = RegExp(r'[وف]{2,}');

  /// علامات ترقيم مكرّرة غير النقاط (`!!`، `،،`، `؟؟`).
  static final RegExp _repeatedPunct = RegExp(r'([!؟?،,;:])\1+');

  /// شريط النقاط (2 فأكثر) — يُعامَل بحسب طوله حفاظاً على القاطع `...`.
  static final RegExp _dotRun = RegExp(r'\.{2,}');

  /// مسافة قبل علامة ترقيم (خطأ شائع: `نص ، آخر`) — عدا النقطة، فمسافة
  /// قبل القاطع `...` صحيحة.
  static final RegExp _spaceBeforePunct = RegExp(' +([،؟!؛:,)])');

  /// مسافات متتالية → مسافة واحدة.
  static final RegExp _multiSpace = RegExp(' {2,}');

  // --------------------------------------------------------------------------
  //  مفردات المحتوى
  // --------------------------------------------------------------------------

  /// الرموز الوهمية الشائعة في المستندات العربية — قراءات خاطئة لحروف عربية.
  /// تُحذف **فقط** وسط نصّ عربي (انظر [_isFakeLatin]).
  static const Set<String> _alwaysFake = <String>{
    // المُبلَّغ عنها صراحةً في هذا المشروع.
    'by', 'so', 'ne', 'dal', 'cai', 'land',
    // قراءات خاطئة شائعة في OCR العربي (حقيقية لغوياً لكنها ليست هنا معنى).
    'ore', 'ire', 'lor', 'ver', 'tor', 'res', 'ere', 'der', 'ser',
    'one', 'two', 'are', 'con', 'int', 'out', 'the', 'and', 'for',
    'san', 'del', 'von', 'bin', 'ala', 'elh',
  };

  /// اختصارات/كلمات قصيرة حقيقية تبقى مهما وقع وسط عربي.
  static const Set<String> _keepShort = <String>{
    'no', 'ok', 'id', 'it', 'pc', 'tv', 'ad', 'pm', 'am', 'co', 'inc',
    'ltd', 'org', 'net', 'app', 'kit', 'pro', 'max', 'min', 'top', 'vip',
  };

  /// كلمات إنجليزية معروفة تبقى دائماً حتى وسط نصّ عربي — تحية ودول وشهور
  /// وأسماء ومصطلحات تقنية شائعة في المستندات العربية.
  static const Set<String> _knownEnglish = <String>{
    // تحية وعبارات الدعوات والشهادات
    'hello', 'world', 'welcome', 'thanks', 'thank', 'congratulations',
    'congratulation', 'best', 'wishes', 'regards', 'sincerely', 'dear',
    'happy', 'birthday', 'anniversary', 'wedding', 'invitation', 'invite',
    'rsvp', 'save', 'date', 'party', 'event', 'venue', 'address',
    // أشهر وتواريخ
    'january', 'february', 'march', 'april', 'may', 'june', 'july',
    'august', 'september', 'october', 'november', 'december',
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday',
    'sunday', 'today', 'tomorrow', 'week', 'month', 'year',
    // دول ومدن وجهات
    'saudi', 'arabia', 'riyadh', 'jeddah', 'makkah', 'madinah', 'dubai',
    'egypt', 'cairo', 'kuwait', 'qatar', 'bahrain', 'oman', 'jordan',
    'iraq', 'lebanon', 'syria', 'yemen', 'sudan', 'palestine', 'turkey',
    'usa', 'canada', 'london', 'paris', 'new', 'york', 'city',
    'university', 'college', 'school', 'hospital', 'ministry', 'company',
    'center', 'centre', 'department', 'management', 'office', 'street',
    'road', 'building', 'floor', 'gate', 'hall', 'garden', 'park',
    // تقنية وملفات
    'internet', 'windows', 'microsoft', 'google', 'android', 'iphone',
    'email', 'website', 'online', 'download', 'file', 'files', 'page',
    'pages', 'copy', 'copyright', 'rights', 'reserved', 'version',
    'update', 'upgrade', 'support', 'service', 'services', 'system',
    'password', 'username', 'account', 'number', 'code', 'serial',
    'size', 'color', 'black', 'white', 'red', 'green', 'blue', 'gold',
    // مفردات الشهادات والعقود
    'manager', 'director', 'head', 'staff', 'employee', 'student',
    'teacher', 'doctor', 'engineer', 'accountant', 'signature', 'stamp',
    'issued', 'issue', 'expiry', 'valid', 'certificate', 'degree',
    'bachelor', 'master', 'doctorate', 'grade', 'honors', 'gpa',
  };

  /// صيغ الشرف المشوّهة التي ينتجها Tesseract عن `ﷺ` و`ﷻ`.
  static const Map<String, String> _honorifics = <String,String>{
    'صلعم': 'ﷺ',
    'صلغم': 'ﷺ',
    'صلأعم': 'ﷺ',
    'صلمم': 'ﷺ',
    'صلنعم': 'ﷺ',
    'جلجلاله': 'ﷻ',
    'جلجللاله': 'ﷻ',
  };

  /// موضع الشرف المُنقَّط: اسم النبي (أو عبارة الصلاة عليه) ثم نقطتان
  /// ثم رقم عربي واحد.
  ///
  /// **المشكلة المقيسة:** `ﷺ` رمزٌ واحدٌ ذو محارف متصلة مركّبة، والمحرّك
  /// يقرأه غالباً **نقطتين ورقماً** (`النبي:١‏`) لأنه يفكّك التركيب.
  /// وهو أثر منتشر لا حالة شاذّة، فيُرجَع إلى رمزه الصحيح.
  ///
  /// النقطتان تُحفظان لأنهما في المتن العربي غالباً تأتيان **بعد** الشرف
  /// (`النبي ﷺ: قال…`) — فالمُرَجَّح أنّ المحرّك قرأهما لا أنّه ابتكرهما.
  ///
  /// **الأشكال الثلاثة المقيسة** للّبس، كلّها رمز `ﷺ` واحد يتفكّك:
  /// `النبي:١`، `النبي 1:`، `النبي 1؛`. والرقم يقتصرّ على `١` لأنّ الرمز
  /// يُقرأ واحداً لا غير؛ وشرط النقطة أو الفاصلة **واجب** — وإلّا التهمت
  /// القاعدة ترقيماً صحيحاً (`النبي ١` في أعداد الأحاديث).
  static final RegExp _misreadHonorific = RegExp(
    '(النبي|رسول الله|صلى الله عليه وسلم)'
    r'(\s*[:؛;]\s*[١1|]\s*[:؛;]?|\s*[١1|]\s*[:؛;])',
  );

  // --------------------------------------------------------------------------
  //  السياق العربي الإسلامي
  // --------------------------------------------------------------------------

  /// أرقام لاتينية وهندية للمقابلة (0..9) — الفهرس = القيمة.
  static const List<String> _arabicIndicDigits = <String>[
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
  ];

  /// رقم عربي واحد يلي مباشرةً (بلا فراغ) رقم عربي أو كلمة.
  static final RegExp _latinNumber = RegExp(r'[0-9]+');

  /// رقم هندي متبوع بفراغ ثم شَّرطة — يُلصَق بلا فراغ.
  ///
  /// اصطلاح الترقيم العربي أن الشَّرطة تلصق برقمها (`١-`)، وأي فراغ بينهما
  /// أثر قراءة لا أصل في المتن. ولذلك يُعاد اللصق تلقائياً — وهذا هو الشكل
  /// المتوقّع في كل مستند مرقّم عربي.
  ///
  /// فئة الأحرف تُبنى من قائمة الأرقام الهندية أعلاه (`join()` ←
  /// `٠١٢٣٤٥٦٧٨٩`) فلا تُعرَّف اثنتان على الاسم نفسه.
  static final RegExp _digitThenDash =
      RegExp('([${_arabicIndicDigits.join()}]) +([\\-–—])');

  /// عبارات تُنبئ بوقوع اقتباس قرآني أو حديثي.  ///
  /// على أثرها تُستعاد الأقواس المزخرفة `﴿ ﴾`: المحرّك يقرأ `﴾` قوساً
  /// لاتينياً `)` فيبقى الاقتباس **مفتوحاً** بلا مغلق.
  static const List<String> _quoteCues = <String>[
    'تعالى',
    'سبحانه',
    'جل جلاله',
    'صلى الله عليه',
    'رسول الله',
  ];

  /// نصّ عربي الغالب: حروفه العربية أكثر من لاتينيّه.
  ///
  /// شرط كل قواعد التطبيع الرقمي والأقواس: لا تُمسّ سطراً إنجليزياً خالصاً
  /// ولا مختلطاً يتساوى فيه الطرفان (تعداد إحصائي فيه لاتيني حقيقي).
  static bool _isArabicDominant(String line) {
    int arabic = 0;
    int latin = 0;
    for (final int rune in line.runes) {
      if (_arabicLetter.hasMatch(String.fromCharCode(rune))) {
        arabic++;
      } else if (_latinLetter.hasMatch(String.fromCharCode(rune))) {
        latin++;
      }
    }
    return arabic > 0 && arabic > latin;
  }

  /// حرف عربي مفرد (بما فيه التشكيل) — للعدّ فقط.
  static final RegExp _arabicLetter = RegExp('[$_arabic]');

  /// حرف لاتيني مفرد — للعدّ فقط.
  static final RegExp _latinLetter = RegExp(r'[A-Za-z]');

  /// محرف قبل موضع رقم لاتيني بشرطين، أو آخرهما.
  static bool _touchesSeparator(String line, int start, int end) {
    if (start > 0) {
      final String before = line[start - 1];
      if (before == '/' || before == '-') return true;
    }
    if (end < line.length) {
      final String after = line[end];
      if (after == '/' || after == '-') return true;
    }
    return false;
  }

  // ==========================================================================
  //  الواجهة
  // ==========================================================================

  /// ينظّف نصّ OCR ويُعيد النصّ المصحّح.
  ///
  /// تُطبَّق القواعد بالترتيب آمن: إزالة الضجيج ← فصل اللاتيني عن العربي
  /// ← التصحيحات الإسلامية والرقمية ← المسافات. النصّ الفارغ يُعاد كما هو.
  ///
  /// [useDictionary] يجعل القاموس العربي يعمل في تصحيح الكلمات (القاعدة 15).
  /// مفعّل افتراضياً؛ ويُطفأ في الاختبارات حين يُراد اختبار القواعد الأخرى
  /// بمعزل عن أثر القاموس.
  static String process(String raw, {bool useDictionary = true}) {
    if (raw.isEmpty) return raw;

    String text = raw;
    text = _stripInvisible(text); // 1) محارف غير مرئية + Tatweel
    text = _removeGluedLatin(text); // 2) لاتيني ملتصق بالعربي
    text = _removeIsolatedFakeLatin(text); // 3) رموز وهمية وسط نصّ عربي
    text = _normalizeHonorifics(text); // 4) صلعم → ﷺ
    text = _collapseArabicPrefixes(text); // 5) الال → ال
    text = _fixRepeatedWaw(text); // 6) وو → و
    text = _fixFinalYa(text); // 7) ازدواج الياء: التقويى → التقويي
    text = _collapsePunctuation(text); // 8) !! → ! و .... → ...
    text = _restoreMisreadOne(text); // 8ب) | → ١ (سياق عربي)
    text = _restoreIndicDigits(text); // 9) 18 → ١٨ (سياق عربي)
    text = _restoreHonorificGlyph(text); // 10) النبي:١‏ → النبي ﷺ
    text = _spaceBeforeQuote(text); // 10ب) ‏:« ← : «
    text = _reattachNumberDash(text); // 11) ١ - → ١-
    text = _cleanReferenceBrackets(text); // 12) [ق: AVA] → [ق: ]
    text = _restoreOrnateBrackets(text); // 13) ‏﴿‏…‏﴾‎
    text = _normalizeWhitespace(text); // 14) المسافات
    if (useDictionary) {
      text = _correctArabicWords(text); // 15) قاموس
    }
    return text.trim(); // 16) بلا مسافات في الطرفين
  }

  /// هل غيّر المعالج النصّ؟ (يُستخدم لعرض ملاحظة التنظيف في الواجهة).
  static bool changed(String raw, String cleaned) => raw != cleaned;

  // ==========================================================================
  //  القواعد
  // ==========================================================================

  /// **القاعدة 1** — إزالة المحارف غير المرئية و`ـ` (Tatweel).
  ///
  /// المحارف الصفرية العرض تُحذف **بلا مسافة** (لا تُقسّم كلمة)، أمّا رموز
  /// المسافة الشبيهة بـNBSP فتصير مسافة عادية.
  static String _stripInvisible(String text) => text
      .replaceAll(_invisible, '')
      .replaceAll(_tatweel, '')
      .replaceAll(_oddSpace, ' ');

  /// **القاعدة 2** — حذف النواة اللاتينية الملتصقة بحروف عربية
  /// (`بby` → `ب`، `Landع` → `ع`). الحروف العربية تبقى كما هي.
  static String _removeGluedLatin(String text) => text.replaceAllMapped(
    _gluedLatin,
    (Match match) {
      final String? before = match.group(1);
      if (before != null) return before; // عربي ← لاتيني: نُبقي العربي
      return match.group(4)!; // لاتيني ← عربي: نُبقي العربي
    },
  );

  /// **القاعدة 3** — حذف الكلمة اللاتينية المنفردة وسط نصّ عربي.
  ///
  /// ثلاثة أبواب بالترتيب، ولا يُحذف إلا ما عبرها كلّها:
  /// 1. **سياق عربي**: أحد الجارَين يحتوي حروفاً عربية.
  /// 2. ليست **رمزاً** كلّه أحرف كبيرة (`API`/`US`) ولا **معروفة**
  ///    (`hello`, `world`, `internet`).
  /// 3. ليست ضمن **جملة إنجليزية** (كلمتان لاتينيتان متتاليتان فأكثر).
  ///
  /// ⚠️ **الباب الثالث صُحّح:** كان يمُرّر **أيّ** كلمتين لاتينيتين متتاليتين
  /// بلا فحص — فنجا من الحذف زوج كلمات وهميتين خالصتين مثل `gle BI` و`AVA`.
  /// الصواب عكسه: الجملة الإنجليزية تُعرَف بأنّ فيها **مفردةً على الأقل**
  /// كلمة معروفة أو اختصاراً أو رمزاً قصيراً معروفاً. وما خلا ذلك — أي مجموعة
  /// كلّها مجهولة وسط عربي — قراءة مشوّهة لحروف عربية فتُحذف كاملةً.
  static String _removeIsolatedFakeLatin(String text) {
    final List<String> out = <String>[];
    for (final String line in text.split('\n')) {
      // سطر بلا حروف عربي خالص: لا نلمسه إطلاقاً.
      if (!_hasArabic.hasMatch(line)) {
        out.add(line);
        continue;
      }
      final List<String> tokens = line.split(' ');
      final List<bool> drop = List<bool>.filled(tokens.length, false);

      int i = 0;
      while (i < tokens.length) {
        if (!_isLatinCore(_coreOf(tokens[i]))) {
          i++;
          continue;
        }
        // جماعة الكلمات اللاتينية المتتالية (بلا كلمة لاتينية غيرها بينها).
        int j = i;
        while (j + 1 < tokens.length && _isLatinCore(_coreOf(tokens[j + 1]))) {
          j++;
        }
        // جملة إنجليزية: كلمتان فأكثر **ومعهما مفردة تفهم** ← تبقى كاملة.
        if (j > i) {
          if (!_runCarriesMeaning(tokens, i, j)) {
            for (int k = i; k <= j; k++) {
              // نحذف ما ليس له معنى فقط؛ البقية (معروفة/مختصرة) تبقى ويحذفها
              // الباب الأخير إن بقيت منفردة وسط عربي.
              if (_isFakeLatin(_coreOf(tokens[k]), tokens, k)) drop[k] = true;
            }
          }
          i = j + 1;
          continue;
        }
        if (_isFakeLatin(_coreOf(tokens[i]), tokens, i)) drop[i] = true;
        i++;
      }

      final List<String> kept = <String>[];
      for (int k = 0; k < tokens.length; k++) {
        if (!drop[k]) kept.add(tokens[k]);
      }
      out.add(kept.join(' '));
    }
    return out.join('\n');
  }

  /// هل في هذه المجموعة اللاتينية مفردة تفهم اللغة معناها؟
  ///
  /// هو شرط بقاء الجملة الإنجليزية وسط النصّ العربي: `CEO and Founder` فيها
  /// `and` فتفهم وتبقى، أمّا `gle BI` و`AVA` فكلّ كلماتها مجهولة ⇒ قراءات
  /// مشوّهة لحروف عربية فتُحذف.
  static bool _runCarriesMeaning(List<String> tokens, int from, int to) {
    for (int k = from; k <= to; k++) {
      final String core = _coreOf(tokens[k]);
      final String lower = core.toLowerCase();
      if (_isRealAcronym(core)) return true; // API, PDF
      if (_keepShort.contains(lower)) return true; // no, ok, org
      if (_knownEnglish.contains(lower)) return true; // hello, world
    }
    return false;
  }

  /// هل هو اختصار حقيقي معروف (لا مجموعة حروف كبيرة تشبهه)؟
  static bool _isRealAcronym(String core) => _knownAcronyms.contains(core);

  /// هل هذه الكلمة اللاتينية المنفردة رمز وهمي؟
  static bool _isFakeLatin(String core, List<String> tokens, int index) {
    if (core.isEmpty) return false;
    // الباب الأول: سياق عربي (لا نحذف في سطر لاتيني/رقمي خالص).
    if (!_neighborIsArabic(tokens, index)) return false;

    final String lower = core.toLowerCase();

    // الباب الثاني: رموز مُبلَّغ عنها تُحذف مهما كانت كلمات حقيقية لغوياً.
    if (_alwaysFake.contains(lower)) return true;

    // الباب الثالث: ما يحمل معنى يبقى.
    if (_isRealAcronym(core)) return false; // API, PDF, US
    if (_keepShort.contains(lower)) return false; // no, ok, org, pro
    if (_knownEnglish.contains(lower)) return false; // hello, world, ...

    // غير معروفة وسط عربي ⇒ رمز وهمي (طويلة كانت أم قصيرة). وهنا تطول
    // زُمر الحروف الكبيرة (`ABN`, `BI`, `AVA`) فتُحذف كذلك: قراءات مشوّهة
    // لأرقام هندية ولم تُخترع كاختصارات. راجع [_knownAcronyms].
    return true;
  }

  /// هل أحد الجارَين يحتوي حروفاً عربية؟
  static bool _neighborIsArabic(List<String> tokens, int index) {
    for (final int step in const <int>[-1, 1]) {
      final int at = index + step;
      if (at < 0 || at >= tokens.length) continue;
      final String core = _coreOf(tokens[at]);
      if (core.isNotEmpty && _hasArabic.hasMatch(core)) return true;
    }
    return false;
  }

  /// علامات الترقيم التي تسبق الكلمة (`«`، `(`، `{`، `"`، `[`، `‑`، `﴿`).
  ///
  /// الأقواس المزخرفة `﴿ ﴾` مضمومة إلى الكلمة فيخرجها المحرّك ملتصقة بها،
  /// فلا تُعدَّل كلمةٌ عليها قوس: النواة تُخلَّى منه كما تُخلّى من الفاصلة.
  static final RegExp _leadingPunct = RegExp(r'^[("\u00AB\[{\-\uFD3F]+');

  /// علامات الترقيم التي تلي الكلمة (`،`، `؟`، `»`، `)`، `]`، `}` … `﴾`).
  ///
  /// ⚠️ **لماذا وُجدت هنا أقواسُ الشرف تحديداً؟** لولاهما لدخل `﴾` في نواة
  /// الكلمة (`السيئة﴾`)، فغابت عن القاموس ثمّ وُجد على مسافة حذفٍ واحدة
  /// منها — فيحذفها المعالج **كأنها زائدة**. وهذا مقيس لا مُفترى: سطر
  /// `﴿آية﴾ [سورة: ١]` كان يخرج منه `﴿آية [سورة: ١]` بحذف المغلق.
  static final RegExp _trailingPunct = RegExp(
    r'[).,;:?!\u061F\u060C"\u00BB\]}\uFD3E]+$',
  );

  /// نواة الكلمة بلا علامات الترقيم المحيطة (`«نص،` → `نص`).
  static String _coreOf(String token) => token
      .replaceAll(_leadingPunct, '')
      .replaceAll(_trailingPunct, '');

  /// هل الكلمة نواة لاتينية صحيحة؟
  static bool _isLatinCore(String core) =>
      core.isNotEmpty && _latinCore.hasMatch(core);

  /// **القاعدة 4** — تطبيع صيغ الشرف المشوّهة (`صلعم` → `ﷺ`).
  static String _normalizeHonorifics(String text) {
    String out = text;
    _honorifics.forEach((String bad, String good) {
      out = out.replaceAll(bad, good);
    });
    return out;
  }

  /// **القاعدة 5** — دمج تكرار «ال» البادئ (`الالرحمن` → `الرحمن`).
  ///
  /// تكرار «ال» أثر قراءة مضاعفة، والصيغة السليمة «ال» واحدة قبل الجذر.
  static String _collapseArabicPrefixes(String text) {
    String out = text;
    while (out.contains('الال')) {
      out = out.replaceAll('الال', 'ال');
    }
    return out;
  }

  /// **القاعدة 6** — دمج الواو/الفاء المكرّرة (`وو` → `و`).
  static String _fixRepeatedWaw(String text) => text.replaceAllMapped(
    _doubledWawFaw,
    (Match match) => match.group(0)![0],
  );

  /// **القاعدة 7** — تصحيح ازدواج الياء في آخر الكلمة
  /// (`التقويى` → `التقويي`).
  ///
  /// **لماذا هذه الضيّقة لا القاعدة العامة (`ى` أخيرة → `ي`)?** القاعدة
  /// العامة **تفسد** كلمات كثيرة صحيحة تنتهي بـ`ى`: `على`، `الأولى`،
  /// `الدنيا`، `مصطفى`، `موسى`، `عيسى`… وحصرناها في الحالة التي لا شكّ فيها:
  /// **ازدواج الياء** (`يى`) أثر قراءة مضاعف، فلا كلمة عربية سليمة تنتهي
  /// بـ`يى`. وكلمة تنتهي بـ`ى` بلا ياء قبلها تبقى كما هي.
  static String _fixFinalYa(String text) => text.replaceAllMapped(
    RegExp('[$_arabic]*يى'),
    (Match match) {
      final String word = match.group(0)!;
      return '${word.substring(0, word.length - 1)}ي';
    },
  );

  /// **القاعدة 8** — دمج علامات الترقيم المكرّرة (`!!` → `!`، `،،` → `،`).
  /// القاطع `...` محفوظ لأنه علامة مشروعة؛ وما زاد عليها يعود `...`.
  static String _collapsePunctuation(String text) {
    String out = text.replaceAllMapped(
      _repeatedPunct,
      (Match match) => match.group(1)!,
    );
    out = out.replaceAllMapped(_dotRun, (Match match) {
      final int length = match.group(0)!.length;
      if (length == 3) return '...'; // القاطع المشروع
      if (length > 3) return '...'; // ضجيج ← قاطع
      return '.'; // نقطتان ← واحدة
    });
    return out;
  }

  /// **القاعدة 9** — المسافات: واحدة بين الكلمات، بلا مسافة قبل الترقيم،
  /// وبلا أكثر من سطرين متتاليين.
  ///
  /// `replaceAllMapped` لا `replaceAll(r'$1')`: `String.replaceAll` في Dart
  /// يضع نصّ الاستبدال **حرفيّاً** فلا تُحلّ `$1` مجموعة.
  static String _normalizeWhitespace(String text) => text
      .replaceAllMapped(
        _spaceBeforePunct,
        (Match match) => match.group(1)!,
      )
      .replaceAll(_multiSpace, ' ')
      .replaceAll(RegExp(' +\n'), '\n')
      .replaceAll(RegExp('\n{3,}'), '\n\n');

  // ==========================================================================
  //  قواعد السياق العربي الإسلامي
  // ==========================================================================

  /// **القاعدة 8ب** — إرجاع الرقم `١` حين يقرأه المحرّك **شَّرطة عمودية**.
  ///
  /// رمز `١` العربي رسمهُ يشبه `|` تماماً، فيقرأه المحرّك شَّرطة عمودية
  /// (`|- أذى` حيث الصواب `١- أذى`). والقيدان يمنعان مساس جداولٍ أو فواصل:
  ///
  /// 1. السطر عربي الغالب.
  /// 2. الشَّرطة **في موضع رقم**: ملاصقة لرقم أو لشَّرطة (`|- أذى`، `١|`،
  ///    `-|`)، أو في **أوّل السطر** (`| أذى`) — وجدولٌ لا يبدأ عمودَه الأول
  ///    بفاصل. فاصلٌ في وسط سطر تعداد (`الاسم | العنوان`) يقف بين مسافتين
  ///    ولا يليه رقم، فلا يُطابَق ولا يُمسّ.
  ///
  /// والقيود معاً هي ما يمنع مساس جدولٍ أو سطرٍ لاتينيّ.
  static String _restoreMisreadOne(String text) {
    final List<String> out = <String>[];
    for (final String line in text.split('\n')) {
      if (!_isArabicDominant(line) || !_misreadOneBar.hasMatch(line)) {
        out.add(line);
        continue;
      }
      out.add(line.replaceAllMapped(_misreadOneBar, (Match m) => '١'));
    }
    return out.join('\n');
  }

  /// شَّرطة عمودية في موضع رقم: مسبوقة أو متبوعة برقم هندي أو شَّرطة،
  /// أو واقفة في أوّل السطر.
  static final RegExp _misreadOneBar = RegExp(
    '(?<=[${_arabicIndicDigits.join()}\\-–—])\\|'
    '|\\|(?=[${_arabicIndicDigits.join()}\\-–—])'
    '|^\\s*\\|',
  );

  /// **القاعدة 9** — تحويل الأرقام اللاتينية إلى هندية في النصّ العربي الغالب.
  ///
  /// `eng.traineddata` حين يُفتح مع `ara` يقرأ رقم `١٨` لاتينياً (`18`)،
  /// فتبدو الحواشي والمراجع أجنبية في متن عربي. والتحويل **مقيّد** بثلاثة
  /// شروط كي لا يُفسد تاريخاً ولا ترقيباً:
  ///
  /// 1. السطر عربي الغالب (حروفه العربية أكثر من لاتينيّه).
  /// 2. الرقم ليس من أربع خانات — تلك سنة (`2014`).
  /// 3. الرقم غير متّصل بفاصل `/` أو `-` — ذلك تاريخ (`2014/04`) أو نطاق
  ///    (`10-12`) أو بند مرقّم (`1- نص`)، وتحويله يفسد المعنى.
  static String _restoreIndicDigits(String text) {
    final List<String> out = <String>[];
    for (final String line in text.split('\n')) {
      if (!_isArabicDominant(line) || !_latinNumber.hasMatch(line)) {
        out.add(line);
        continue;
      }
      out.add(
        line.replaceAllMapped(_latinNumber, (Match match) {
          final String digits = match.group(0)!;
          final int start = match.start;
          final int end = match.end;
          if (digits.length == 4) return digits; // سنة
          if (_touchesSeparator(line, start, end)) return digits; // تاريخ/نطاق
          return digits.replaceAllMapped(
            _latinDigitChar,
            (Match d) => _arabicIndicDigits[int.parse(d.group(0)!)],
          );
        }),
      );
    }
    return out.join('\n');
  }

  /// رقم لاتيني مفرد (خانة واحدة) — وحدة بناء التحويل.
  static final RegExp _latinDigitChar = RegExp(r'[0-9]');

  /// **القاعدة 10** — إرجاع رمز الشرف حين يقرأه المحرّك نقطتين ورقماً.
  ///
  /// راجع [_misreadHonorific]: الرمز `ﷺ` مركّب من محارف متصلة، فيفكّكه
  /// المحرّك إلى `:١`. والإرجاع هنا **ليس تخميناً** — فالسياق (اسم النبي)
  /// والبنية (نقطتان + رقم واحد) كلاهما أثرٌ مرئي في النصّ.
  static String _restoreHonorificGlyph(String text) => text.replaceAllMapped(
    _misreadHonorific,
    (Match match) => '${match.group(1)} ﷺ:',
  );

  /// **القاعدة 10ب** — مسافة بعد النقطتين قبل علامة الاقتباس (`:«` ← `: «`).
  ///
  /// المحرّك يقرأ رمز `ﷺ` ثم النقطتين ثم يلصق علامة الاقتباس بالصمت
  /// (`النبي ﷺ:«لا يدخل»`) لأنّ المسافة في الصورة ضيّقة. والنصّ العربي لا
  /// يُكتب اقتباساً ملتصقاً بالفاصلة قبله أبداً، فالمسافة أصلٌ لا تحسين.
  ///
  /// الإدراج **مقيّد بعلامة اقتباس مفتوحة** لا أيّ رمز: `[ق:١٨]` فيها
  /// نقطتان ثم رقم فلا تُمسّ، وكذلك `الإجابة: قال` فيها مسافة أصلاً.
  static String _spaceBeforeQuote(String text) => text.replaceAllMapped(
    _colonThenQuote,
    (Match match) => '${match.group(1)} ${match.group(2)}',
  );

  /// فاصلة (نقطتان/فاصلة منقوطة/فاصلة عربية) ملتصقة بعلامة اقتباس مفتوحة.
  static final RegExp _colonThenQuote = RegExp(
    r'([:؛;])([«﴿(])',
  );

  /// **القاعدة 11** — إلصاق الشَّرطة برقمها الهندي (`١ -` ← `١-`).
  ///
  /// اصطلاح الترقيم العربي أن تلصق الشَّرطة برقمها، والفراغ بينهما أثرُ
  /// قراءة (المحرّك يفصل بين «الرقم» و«الرمز» لأنهما نوعان عنده). والإلصاق
  /// يُعيد الشكل الاصطلاحي المتوقّع في كل مستند مرقّم عربي.
  static String _reattachNumberDash(String text) {
    // الرقم والشَّرطة يبقيان، والفراغ بينهما وحده هو ما يُحذف.
    String out = text.replaceAllMapped(_digitThenDash, (Match match) {
      return '${match.group(1)}${match.group(2)}';
    });
    // الاتجاه المعكوس: `‎-١` حيث الصواب `١-`. المحرّك يضع الشَّرطة قبل
    // الرقم حين يبدأ السطر بها، لأنّ علامة الاتجاه تقلب ترتيب العرض.
    // والشرط «شَّرطة **ملاصقة** لرقم» يميّزها عن شَّرطة الترقيم (`السؤال -`
    // أو `١-`) فلا تُقلَب.
    return out.replaceAllMapped(_dashThenDigit, (Match match) {
      return '${match.group(2)}${match.group(1)}';
    });
  }

  /// شَّرطة متبوعة مباشرةً برقم هندي (بلا فراغ) — ترتيبٌ معكوس يُردّ.
  ///
  /// ⚠️ الأقواس `[...]` هنا **فئة أحرف** لا مجموعة: كتابتها `(...)` كانت
  /// تعني تسلسل «٠ ثم ١ ثم ٢…» فلا يطابقها رقمٌ واحد أبداً، فكانت القاعدة
  /// صامتة تماماً (اكتُشف بالقياس: `-١` ظلّت كما هي).
  static final RegExp _dashThenDigit = RegExp(
    '([\\-–—])([${_arabicIndicDigits.join()}])',
  );

  /// **القاعدة 12** — تنقية ما بين قوسَي مرجع.
  ///
  /// المراجع الإسلامية تُكتب `[ق: ١٨]` و`[البقرة: ٢٥٥]`، ومحرّك الاستخراج
  /// يُخرج الرقم رمزاً لاتينياً (`AVA`, `BI`) لأنّ رقم `١٨` يُشبه حروفاً
  /// لاتينية. والقوس الفارغ `[ق: ]` أوضح للمراجعة البشرية من رمز لا معنى
  /// له — والمستخدم يملأ الرقم بنظره.
  ///
  /// يُعالج القوس المفتوح في آخر السطر أيضاً (`[ق: AVA` بلا `]`).
  static String _cleanReferenceBrackets(String text) {
    final List<String> out = <String>[];
    for (final String line in text.split('\n')) {
      if (!_hasArabic.hasMatch(line)) {
        out.add(line);
        continue;
      }
      // قوس مغلق: نُبقي داخلَه العربي والعلامات فقط.
      final RegExp closed = RegExp(r'\[([^\]\n]*)\]');
      // قوس مفتوح في آخر السطر.
      final RegExp openEnd = RegExp(r'\[([^\]\n]*)$');
      String cleaned = line.replaceAllMapped(closed, (Match m) {
        return '[${_keepOnlyMeaningfulInBracket(m.group(1)!)}]';
      });
      cleaned = cleaned.replaceAllMapped(openEnd, (Match m) {
        return '[${_keepOnlyMeaningfulInBracket(m.group(1)!)}]';
      });
      out.add(cleaned);
    }
    return out.join('\n');
  }

  /// يُخلي متن القوس من الرموز اللاتينية، ويُبقي العربي والأرقام والفواصل.
  static String _keepOnlyMeaningfulInBracket(String inner) {
    final List<String> tokens = inner.split(' ');
    final List<String> kept = <String>[];
    for (final String token in tokens) {
      final String core = _coreOf(token);
      if (core.isNotEmpty && _isLatinCore(core)) continue; // رمز وهمي
      kept.add(token);
    }
    // مسافة زائدة قبل النقطتين (`ق:` بعد إزالة رمز) — تُضمّ.
    final String joined = kept.join(' ').replaceAll(_multiSpace, ' ').trim();
    return joined.isEmpty ? '' : joined;
  }

  /// **القاعدة 11** — استعادة الأقواس المزخرفة `﴿ ﴾` حول الاقتباس الشرعي.
  ///
  /// المحرّك يقرأ `﴾` قوساً لاتينياً `)` ، فيبقى الاقتباس **مفتوحاً** بلا
  /// مغلق — وهو خطأ قراءة صارخ في النصّ القرآني. والعلامة التي تُنبئ به:
  /// عبارةٌ مثل `قال تعالى:` أو `قال رسول الله ﷺ` داخل السطر.
  ///
  /// الاستعادة مقصورة على ما له أثر مرئي:
  /// - يُدرَج `﴿` بعد العبارة (وبعد النقطتين إن وُجدتا).
  /// - يُحوَّل قوس `)` **غير المطابق** في السطر إلى `﴾`.
  /// ولا يُبتكر قوس من عدم — فما لا أثر له لا يُخمَّن.
  static String _restoreOrnateBrackets(String text) {
    final List<String> out = <String>[];
    for (final String line in text.split('\n')) {
      if (!_hasArabic.hasMatch(line) || !_hasQuoteCue(line)) {
        // لا عربي أو لا علامة اقتباس — لا مساس.
        out.add(line);
        continue;
      }
      if (line.contains('﴿')) {
        // المفتوح موجود — يُستعاد المغلق إن كان مفقوداً، إذ لا يُضاعَف
        // المفتوح لكنّ المغلق كثيراً ما يبتلعه المحرّك على الخطّ الصغير.
        out.add(_closeUnmatchedOrnate(line));
        continue;
      }
      final RegExp? cue = _firstCueIn(line);
      if (cue == null) {
        out.add(line);
        continue;
      }

      // (1) **زوج `(...)` متوازن وحيد** ⇒ المحرّك قرأ `﴿...﴾` قوساً لاتينياً.
      //
      // هذه الحالة هي الأكثر انتشاراً على الإطلاق: رمز `﴿` مركّب من محارف،
      // فيفكّكه المحرّك إلى `(` و`)` مطابقَين — فيبدو الاقتباس صحيحاً وهو
      // مفقود العلامتين. والدليل على أنّه اقتباس لا تعداد: علامة الاقتباس
      // (`تعالى`) في السطر، **وزوج واحد** لا أكثر، **وبلا قوس مزخرف** بعده.
      final String? converted = _convertBalancedParens(line);
      if (converted != null) {
        out.add(converted);
        continue;
      }

      // (2) لا قوس مغلق إطلاقاً ⇒ لا شيء يُستعاد، وإلّا وُضعت ﴿ يتيمة
      // بلا مقابل (مقيس: `قال رسول الله ﷺ: «…»` كان يخرج `رسول الله﴿ ﷺ:`).
      if (!line.contains(')')) {
        out.add(line);
        continue;
      }

      // (3) أقواس لاتينية بلا توازن بيّن ⇒ الغموض قائم ولا يُخترَق ﴿.
      if (line.contains('(')) {
        out.add(line);
        continue;
      }

      // ﴿ ملصوق بالنصّ نفسه — لا مسافة بعده (المسافة تُقرأ جزءاً من الكلمة).
      final String inserted = line.replaceFirstMapped(cue, (Match m) {
        final String whole = m.group(0)!;
        return '$whole﴿';
      });

      // ﴾ مكان `)` غير المطابق (لا `(` قبله في السطر).
      final String closed = inserted.contains('﴾')
          ? inserted
          : inserted.replaceFirst(')', '﴾');

      out.add(closed);
    }
    return out.join('\n');
  }

  /// يُغلق `﴿` يتيمة بـ`﴾` حين يبتلع المحرّك المغلق.
  ///
  /// لا يُبادر إلا بشرطين: قوس مفتوح **واحد** بالضبط، و**بلا** مغلق إطلاقاً؛
  /// وإلّا بقي السطر كما هو (الغموض لا يُخترَق بالتخمين).
  ///
  /// وموضع الإدراج **بنائيّ** لا اجتهادي، بترتيب الحتمية:
  /// 1. قبل مرجع الآية `[سورة: رقم]` إن وُجد بعد القوس.
  /// 2. قبل الترقيم الختامي (`.` أو `]` أو `)`).
  /// 3. نهاية السطر.
  ///
  /// ولا يُدرج القوس قبل مسافة: المسافة تُقرأ جزءاً من الكلمة التالية.
  static String _closeUnmatchedOrnate(String line) {
    if (line.contains('﴾')) return line; // مغلق موجود — لا مساس.
    if ('﴿'.allMatches(line).length != 1) return line; // أكثر من قوس — غموض.

    final int open = line.indexOf('﴿');

    // (1) مرجع الآية بعد القوس — القوس يُغلق قبل المسافة التي تسبق `[`.
    final int ref = line.indexOf(' [', open);
    if (ref > 0) return _insertAt(line, ref, '﴾');

    // (2) ترقيم ختامي: ﴾ قبله لا بعده.
    for (final String mark in <String>['.', ']', ')']) {
      final int at = line.indexOf(mark, open);
      if (at > 0) return _insertAt(line, at, '﴾');
    }

    // (3) نهاية السطر — بلا فراغات ختامية.
    return '${line.trimRight()}﴾';
  }

  /// يُدرج [what] قبل الموضع [at] من [line].
  static String _insertAt(String line, int at, String what) =>
      '${line.substring(0, at)}$what${line.substring(at)}';

  /// يُحوّل زوج `(...)` المتوازن الوحيد إلى `﴿...﴾`، أو يُعيد `null` إن لم
  /// يكن التحويل بيّناً.
  ///
  /// يُرفض الحالة حين:
  /// - يحوي السطر قوساً مزخرفاً أصلاً (`﴾`) — إذن الزوج ليس بديلاً عنه.
  /// - هناك **زوجان فأكثر** — لا يُعرف أيّهما الاقتباس.
  static String? _convertBalancedParens(String line) {
    if (line.contains('﴾')) return null;
    final List<RegExpMatch> pairs = _balancedParen
        .allMatches(line)
        .toList(growable: false);
    if (pairs.length != 1) return null;
    final RegExpMatch pair = pairs.first;
    final String inner = pair.group(1)!;
    if (inner.trim().isEmpty) return null; // قوس فارغ لا معنى له
    return '${line.substring(0, pair.start)}﴿$inner﴾${line.substring(pair.end)}';
  }

  /// زوج قوسَين لاتينيَين متوازنين لا يحويان قوساً آخر في داخلهما.
  static final RegExp _balancedParen = RegExp(r'\(([^()]+)\)');

  /// أوّل عبارة اقتباس واردة في السطر — أولويةً بترتيب [_quoteCues].
  static RegExp? _firstCueIn(String line) {
    for (final String phrase in _quoteCues) {
      final RegExp candidate = RegExp('$phrase(\\s*:\\s*)?');
      if (candidate.hasMatch(line)) return candidate;
    }
    return null;
  }

  /// هل في السطر عبارة تُنبئ باقتباس شرعي؟
  static bool _hasQuoteCue(String line) {
    for (final String cue in _quoteCues) {
      if (line.contains(cue)) return true;
    }
    return false;
  }

  // ==========================================================================
  //  القاموس العربي — تصحيح الكلمات بمسافة تحرير 1
  // ==========================================================================

  /// قاموس الكلمات مبنيّ مرّة واحدة: المفتاح مُطبَّع، والقيمة شكلها الأصلي.
  ///
  /// **مصدران مرتَّبان لا قائمة واحدة:**
  /// 1. [ArabicWordList] — تكرار الورود في نصوص ويب. ترتيبها **أوّليّة**:
  ///    ما تقدَّم فيها يبقى مرجعاً كما كان.
  /// 2. [QuranWordList] — جذور التنزيل التي تفقدها الأولى. تُملأ ما فقدها
  ///    القاموس ولا تزيح كلمةً قائمة عن مقعدها؛ فما تُضاف هنا إنّما يُضاف
  ///    من **العوز** لا من الاختلاف، والويب أقوى دليل في مجاله.
  ///
  /// ولولا الطبقة الثانية لكان القياسُ على التنزيل مفسوداً: `رحمن` و`رحيم`
  /// غائبتان عن العشرة آلاف، فتُعدّ مجهولةً ثمّ يُوجد لهما على مسافة تعديلٍ
  /// واحدة `رحمة` و`جحيم` — فتُبدَل الآيةُ الكريمَةُ بصنيع الوعاظ.
  static final Map<String, String> _dictionary = _buildDictionary();

  static Map<String, String> _buildDictionary() {
    final Map<String, String> map = <String, String>{};
    for (final String list in const <String>[
      ArabicWordList.raw,
      QuranWordList.raw,
    ]) {
      for (final String word in list.split('\n')) {
        if (word.isEmpty) continue;
        final String key = _lookupKey(word);
        if (key.length < 3) continue;
        // أوّل ظهور يفوز: القوائم مرتَّبة تكراراً، فالشكل الأكثر شيوعاً
        // هو ما يبقى مرجعاً للتصحيح.
        map.putIfAbsent(key, () => word);
      }
    }
    return map;
  }

  /// حروف التشكيل: تنقيتها الخمس، وحركة السكون والشدة ونحوهما — كلّها تُحذف
  /// من مفتاح المقارنة.
  ///
  /// 📐 **حذفها شرطٌ لا ترف:** القاموس بلا تشكيل، فكلّ كلمةٍ مُشكَّلة تغيب
  /// عنه حرفياً. وبدون هذا الحذف كان التصحيح يقع **على كلماتٍ صحيحة**: نصٌّ
  /// فيه `ثانٍ` (معرّفة بتنوين) يبحث عنه فلا يجده، ثمّ يجد `ثاني` على مسافة
  /// تبديلٍ واحدة فيُبدله بها — خطأٌ يولّده المعالج لا المحرّك.
  static final RegExp _diacritics = RegExp('[\u064B-\u0655\u0670]');

  /// المفتاح المُطبَّع لكلمة القاموس أو للنصّ المُقارَن.
  ///
  /// التطبيع للمقابلة **لا للإخراج** (`أإآ` ← `ا`، `ى` ← `ي`، وحذف
  /// التطويل): المحرّك قد يكتب `الأمان` حيث الصواب `الامان`، وتوحيتهما
  /// مختلفة شكلياً ومعناها واحد. والقيمة تبقى على شكل القاموس كي لا
  /// يُفرَض شكلٌ على المستخدم بلا داعٍ.
  static String _lookupKey(String word) => word
      .replaceAll(_diacritics, '')
      .replaceAll(_tatweel, '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي');

  /// حروف عربية تُبنى منها كل توليدات التعديل الواحد.
  static const String _arabicAlphabet =
      'ابتثجحخدذرزسشصضطظعغفقكلمنهويءآأإؤئاةىٱ';

  /// أقلّ طول لكلمة تُصحَّح. القِصَر هنا خطرٌ لا فائدة: كلمتان بثلاثة حروف
  /// بينهما تعديل واحد قد تُقلب معنى الجملة (`من` ← `فن`، `على` ← `علن`).
  static const int _minCorrectionLength = 4;

  /// **القاعدة 15** — تصحيح الكلمة العربية غير الموجودة في القاموس.
  ///
  /// **المنهج:** للكلمة المجهولة تُولَّد كل كلمات **مسافة التحرير 1**
  /// (تبديل حرف، حذفه، إضافته، أو عكس متجاورَين — طريقة Norvig)، ويُبحَث
  /// عن كلٍّ منها في القاموس. ويُرجَع التصحيح **فقط** إن كان هناك **مرشّحٌ
  /// واحد لا غير**:
  ///
  /// - **مرشّح واحد** ← التصحيح بيّن (`الكتااب` ← `الكتاب`).
  /// - **مرشّحان أو أكثر** ← التباسٌ: بعض المرشّحات هو الصواب وبعضها لا.
  ///   والاختيار هنا تخمينٌ بلا دليل، فيُترك النصّ كما هو — خطأٌ معروف
  ///   أسلم من «تصحيح» يزيد الخطأ.
  /// - **لا مرشّح** ← الكلمة غالباً صحيحة لكنها غائبة عن القاموس (اسم،
  ///   مصطلح، كلمة قرآنية). تُترك كما هي.
  ///
  /// ## الكلمة المقيَّدة لا تُصحَّح — ولو وُجد لها مرشّح
  ///
  /// أوّل سؤالٍ يُطرح عن **الكلمة كاملةً** لا عن جذعها العارى: إن كانت في
  /// القاموس فمعلومةٌ لا مجهولة، ولا يُبدَل المعلوم بالمخمَل. ولولا هذا
  /// الباب لكان المعجم يُفسد كلماتٍ وهو يظنّ أنه يصلحها، بمسلَّكٍ واحد
  /// يتكرّر: الجذع المفردَ يغيب عن القاموس والكلمة مقيَّدةٌ فيه، فيُعدّ
  /// الجذع مجهولًا ثمّ يُوجد له مرشّحٌ واحد فيُبدَل به الكلمة الصحيحة.
  ///
  /// وهذا **مقيس** لا مُفترى، وطرفاه معاً من قياسٍ واحد: `الحرمان` ←
  /// `الحرمنا` و`الخبيثة` ← `الخبيث`. وينطبق على المثال القديم
  /// `الحلام` ← `الحلال` أيضاً: كلاهما كلمةٌ في القاموس، والتبديل بين
  /// معروفَين لا دليل عليه — فصار يُترك كما استُخرج.
  ///
  /// ## لماذا نُقصِر الطبقة التنزيلية على كثيرة الورود؟
  ///
  /// لأنّ الإضافة إلى المعجم **ليست بلا كلفة**: كلّ مفردةٍ تُضاف تَصِحُّ
  /// لجارَيْها على مسافة تحريرٍ واحدة، فإن كان أحدُهما كلمةً واردةً
  /// **ومجهولةً عن المعجم** صار هذا المرشّح الجديد وحيداً فصُحِّح به وهو
  /// سليم. وهذا حدَث فعلاً حين دُرِجت مفرداتٌ نزيلية قليلة الورود:
  /// `حرمنا` ‏(‎6‎ مرات) صارت جارَ `حرمان` ‏(‎0‎) الوحيد فحُوِّل بها،
  /// و`خبيث` ‏(‎0‎) كذلك. و`الرحمن` ‏(‎45‎) و`رحيم` ‏(‎77‎) تمرّ بلا
  /// أذى. فالفصلَ بينهما **كثرةُ الورود** لا الاجتهاد.
  ///
  /// **حروف السوابق** (`و ف ب ل ك`) تُفصَل قبل البحث وتُعاد بعده — وإلا
  /// لاختلّت كل كلمة مسبوقة بسابق، وهي كثيرة جداً في العربية.
  static String _correctArabicWords(String text) {
    if (_dictionary.isEmpty) return text;
    final List<String> out = <String>[];
    for (final String line in text.split('\n')) {
      // سطر بلا عربي: لا معنى لتصحيح عربي.
      if (!_isArabicDominant(line)) {
        out.add(line);
        continue;
      }
      final List<String> tokens = line.split(' ');
      for (int i = 0; i < tokens.length; i++) {
        final String core = _coreOf(tokens[i]);
        if (core.length < _minCorrectionLength) continue;
        if (core.contains('.') || core.contains('@')) continue; // رابط/بريد
        final String? fixed = _correctCore(core);
        if (fixed == null || fixed == core) continue;
        tokens[i] = tokens[i].replaceFirst(core, fixed);
      }
      out.add(tokens.join(' '));
    }
    return out.join('\n');
  }

  /// يُصحّح نواةً واحدة، أو يُعيد `null` إن لم يكن التصحيح بيّناً.
  static String? _correctCore(String core) {
    // 📐 **السؤال عن الكلمة كاملةً أوّلاً — لا عن الجذع العاريّ.**
    //
    // والسبب أنّ الجذع مفرداً قد يغيب عن القاموس والكلمة مقيَّدةٌ فيه:
    // `الحرمان` في قائمة التكرار، لكنّ `حرمان` مفرداً ليس فيها، فتُعدّ
    // مجهولةً ثمّ يُوجد لها مرشّحٌ واحد (`حرمنا`) فيُبدَل بها الحسنُ
    // بالشنيع. ومسائلةُ الكلمةَ كاملةً تسدّ هذا الباب قبل أن يُفتَح.
    if (_dictionary.containsKey(_lookupKey(core))) return null;

    final String prefix = _cliticPrefix(core);
    final String stem = core.substring(prefix.length);
    if (stem.length < _minCorrectionLength) return null;

    final String key = _lookupKey(stem);
    if (_dictionary.containsKey(key)) return null; // موجودة — لا مساس

    final String? corrected = _uniqueEdit1(key);
    if (corrected == null) return null;
    // الشكل الأصلي من القاموس (لا المفتاح المطبَّع) + السابق المفصول.
    return '$prefix${_dictionary[corrected]}';
  }

  /// سابقة عربية ملتصقة أوّلها (حرف واحد أو اثنان: `و`، `وال`، `ال`، `لل`).
  ///
  /// **الترتيب ليس اعتباطياً:** `وال/فال/بال/كال` تسبق `ال`، وإلا اقتُطع أوّلها
  /// فبقي `وال` ثمّ بحث عن «كتاب» فلم يُوجد. و`ال` تسبق حروف الوصل المنفردة،
  /// لأنّ أصلها ألف اللام التعريف.
  static String _cliticPrefix(String word) {
    const List<String> prefixes = <String>[
      'وال',
      'فال',
      'بال',
      'كال',
      'لل',
      'ال',
      'و',
      'ف',
      'ب',
      'ل',
      'ك',
    ];
    for (final String prefix in prefixes) {
      if (word.length > prefix.length + 2 && word.startsWith(prefix)) {
        return prefix;
      }
    }
    return '';
  }

  /// المرشّح الوحيد في القاموس على مسافة تحرير 1 من [key] — أو `null`.
  static String? _uniqueEdit1(String key) {
    final Set<String> variants = _edit1Variants(key);
    String? found;
    for (final String variant in variants) {
      final String? hit = _dictionary[variant];
      if (hit == null) continue;
      if (found != null) return null; // مرشّحان ⇒ التباس
      found = variant;
    }
    return found;
  }

  /// كل توليدات مسافة التحرير 1 من [word] (طريقة Norvig).
  ///
  /// التوليد أسرع من البحث في القاموس كله بكثير: بضع مئات من المفاتيح
  /// بدل عشرة آلاف لكل كلمة — والفهرس `Map` يجعل كل اختبار O(1).
  static Set<String> _edit1Variants(String word) {
    final Set<String> out = <String>{};
    final List<String> letters = _arabicAlphabet.split('');
    final int n = word.length;

    // حذف حرف من كل موضع.
    for (int i = 0; i < n; i++) {
      out.add(word.substring(0, i) + word.substring(i + 1));
    }
    // عكس حرفَين متجاورَين.
    for (int i = 0; i < n - 1; i++) {
      out.add(
        '${word.substring(0, i)}${word[i + 1]}${word[i]}${word.substring(i + 2)}',
      );
    }
    // استبدال حرف في كل موضع، وإضافة حرف في كل موضع.
    for (int i = 0; i <= n; i++) {
      for (final String letter in letters) {
        if (i < n) {
          out.add('${word.substring(0, i)}$letter${word.substring(i + 1)}');
        }
        out.add('${word.substring(0, i)}$letter${word.substring(i)}');
      }
    }
    return out;
  }
}
