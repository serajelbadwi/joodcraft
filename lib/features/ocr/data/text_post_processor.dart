/// تنظيف النص المستخرج من OCR قبل عرضه للمستخدم.
///
/// **المشكلة:** Tesseract يقرأ مستنداً عربياً فيه كلمات لاتينية فيُنتج رموزاً
/// لاتينية **وهمية** لا معنى لها (`by`, `so`, `ne`, `dal`, `cai`, `Land`…) —
/// هي أخطاء قراءة لحروف عربية، لا إنجليزية حقيقية. ويُنتج أيضاً أخطاء عربية
/// شائعة (`الالرحمن`، `وو`، مسافات مزدوجة، `....`، `ى` في آخر الكلمة).
///
/// **المبدأ الحاكم:** لا نحذف إلا ما ثبت أنه وهمي، ونُبقي كل ما يحمل معنى:
///
/// | يُحذف | يُحفظ |
/// |---|---|
/// | لاتيني **ملتصق** بحروف عربية (`بby`) | جملة إنجليزية (كلمتان لاتينيتان متتاليتان فأكثر) |
/// | كلمة لاتينية **منفردة وسط نص عربي** غير معروفة | اختصار كلّه أحرف كبيرة (`API`, `PDF`, `URL`, `US`) |
/// | الرموز المُبلَّغ عنها (`by`,`so`,`ne`,`dal`,`cai`,`land`) | كلمة إنجليزية معروفة (`hello`, `world`, `internet`…) |
/// | — | روابط وبريد (`example.com`, `user@host`) |
///
/// **حدود هذا المعالج:** تحسين تلقائيّ **لا بديل** عن المراجعة البشرية —
/// لذلك يبقى النصّ قابلاً للتحرير، وتُعرض ملاحظة `ocrCleanupNote` عند تغيّره.
library;

class OcrTextPostProcessor {
  const OcrTextPostProcessor._();

  // ==========================================================================
  //  مفردات التحكّم (محارف هربة — لا محارف مرئية غير مرئية في المصدر!)
  // ==========================================================================

  /// نطاقات الحروف العربية (بما فيها علامات التشكيل).
  static const String _arabic = r'؀-ۿݐ-ݿ';

  /// المحارف غير المرئية التي يزيدها الاستخراج أحياناً
  /// (Zero-Width Space/Joiner، BOM، Soft Hyphen، Word Joiner).
  static final RegExp _invisible = RegExp(
    '[\u200B\u200C\u200D\uFEFF\u00AD\u2060]',
  );

  /// الرسم المتكرّر (Tatweel) — ضجيج بصري خالص لا معنى له.
  static final RegExp _tatweel = RegExp('ـ');

  /// رموز المسافة غير الاعتيادية → مسافة عادية
  /// (NBSP، مسافات رفيعة/ضيّقة، مسافةideographic).
  static final RegExp _oddSpace = RegExp('[\u00A0\u2007\u2008\u2009\u202F\u3000]');

  /// نصّ عربي في سطر ما (شرط الحذف كله: لا نلمس سطراً لاتينياً خالصاً).
  static final RegExp _hasArabic = RegExp('[$_arabic]');

  /// كل سلسلة حروف عربية (تُستخدم في تصحيح `ى`).
  static final RegExp _arabicWord = RegExp('[$_arabic]+');

  /// كلمة لاتينية «نواة»: تبدأ بحرف ولا تحوي `@` أو `.` (فيبقى البريد والروابط
  /// خارج كل معالجة — لا يمكن أن تُحذف).
  static final RegExp _latinCore = RegExp(r"^[A-Za-z][A-Za-z0-9'\-]*$");

  /// اختصار كلّه أحرف كبيرة (2–6): `API`, `PDF`, `URL`, `US`, `UK`, `OCR`.
  static final RegExp _acronym = RegExp(r'^[A-Z]{2,6}$');

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

  /// مسافة قبل علامة ترقيم (خطأ شائع: `نص ، آخر`).
  static final RegExp _spaceBeforePunct = RegExp(' +([،؟!؛:,.)])');

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

  /// كلمات عربية تُكتب صحيحة بـ`ى` في آخرها — لا تُحوَّل إلى `ي`.
  /// تُفحص بعد نزع السوابق (`والعلى` → `على`).
  static const Set<String> _finalYaKeep = <String>{
    // حروف وحروف وصل
    'على', 'الى', 'إلى', 'حتى', 'متى', 'ذى', 'لدى',
    // أسماء مشهورة تنتهي بـ`ى` صحيحة
    'موسى', 'عيسى', 'مصطفى', 'هدى', 'فدى', 'سعى', 'ولى', 'بقى',
    // «حىّ» (السكن) صحيحة بـ`ى` — والقراءة لا تفرّق، فنُبقيها.
    'حى',
  };

  /// سوابق الحروف تُنزع قبل فحص آخر الكلمة (بترتيب الطول).
  static const List<String> _prefixes = <String>['وال', 'بال', 'كال', 'فال'];

  /// حروف المفردة تُنزع أيضاً (`وموسى` → `موسى`).
  static const String _singlePrefixes = 'وفبلك';

  /// صيغ الشرف المشوّهة التي ينتجها Tesseract عن `ﷺ` و`ﷻ`.
  static const Map<String, String> _honorifics = <String, String>{
    'صلعم': 'ﷺ',
    'صلغم': 'ﷺ',
    'صلأعم': 'ﷺ',
    'صلمم': 'ﷺ',
    'صلنعم': 'ﷺ',
    'جلجلاله': 'ﷻ',
    'جلجللاله': 'ﷻ',
  };

  // ==========================================================================
  //  الواجهة
  // ==========================================================================

  /// ينظّف نصّ OCR ويُعيد النصّ المصحّح.
  ///
  /// تُطبَّق القواعد العشر بالترتيب آمن: إزالة الضجيج ← فصل اللاتيني عن
  /// العربي ← التصحيحات العربية ← المسافات. النصّ الفارغ يُعاد كما هو.
  static String process(String raw) {
    if (raw.isEmpty) return raw;

    String text = raw;
    text = _stripInvisible(text); // 1) محارف غير مرئية + Tatweel
    text = _removeGluedLatin(text); // 2) لاتيني ملتصق بالعربي
    text = _removeIsolatedFakeLatin(text); // 3) رموز وهمية وسط نصّ عربي
    text = _normalizeHonorifics(text); // 4) صلعم → ﷺ
    text = _collapseArabicPrefixes(text); // 5) الال → ال
    text = _fixRepeatedWaw(text); // 6) وو → و
    text = _fixFinalYa(text); // 7) ى → ي (مع استثناءات)
    text = _collapsePunctuation(text); // 8) !! → ! و .... → ...
    text = _normalizeWhitespace(text); // 9) المسافات
    return text.trim(); // 10) بلا مسافات في الطرفين
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
        // جملة إنجليزية (كلمتان فأكثر) ← تبقى كاملاً.
        if (j > i) {
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

  /// هل هذه الكلمة اللاتينية المنفردة رمز وهمي؟
  static bool _isFakeLatin(String core, List<String> tokens, int index) {
    if (core.isEmpty) return false;
    // الباب الأول: سياق عربي (لا نحذف في سطر لاتيني/رقمي خالص).
    if (!_neighborIsArabic(tokens, index)) return false;

    final String lower = core.toLowerCase();

    // الباب الثاني: رموز مُبلَّغ عنها تُحذف مهما كانت كلمات حقيقية لغوياً.
    if (_alwaysFake.contains(lower)) return true;

    // الباب الثالث: ما يحمل معنى يبقى.
    if (_acronym.hasMatch(core)) return false; // API, PDF, URL, US
    if (_keepShort.contains(lower)) return false; // no, ok, org, pro
    if (_knownEnglish.contains(lower)) return false; // hello, world, ...

    // غير معروفة وسط عربي ⇒ رمز وهمي (طويلة كانت أم قصيرة).
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

  /// علامات الترقيم التي تسبق الكلمة (`«`، `(`، `{`، `"`، `[`، `‑`).
  static final RegExp _leadingPunct = RegExp(r'^[("\u00AB\[{\-]+');

  /// علامات الترقيم التي تلي الكلمة (`،`، `؟`، `»`، `)`، `]`، `}` …).
  static final RegExp _trailingPunct = RegExp(
    r'[).,;:?!\u061F\u060C"\u00BB\]}]+$',
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

  /// **القاعدة 7** — تصحيح `ى` في آخر الكلمة إلى `ي`.
  ///
  /// في العربية لا تنتهي الكلمة بـ`ى` إلا كلمات معدودة (`على`، `حتى`،
  /// `موسى`…)؛ فأي `ى` أخرى أثر قراءة. الاستثناءات تُفحص بعد نزع السوابق.
  static String _fixFinalYa(String text) => text.replaceAllMapped(
    _arabicWord,
    (Match match) {
      final String word = match.group(0)!;
      if (!word.endsWith('ى')) return word;
      if (_finalYaKeep.contains(_bare(word))) return word;
      return '${word.substring(0, word.length - 1)}ي';
    },
  );

  /// نزع السوابق للcompare مع قائمة الاستثناءات (`والعلى` → `على`).
  static String _bare(String word) {
    String bare = word.replaceAll(RegExp('^[أإآٱ]'), '');
    for (final String prefix in _prefixes) {
      if (bare.length > 2 && bare.startsWith(prefix)) {
        bare = bare.substring(prefix.length);
        break;
      }
    }
    if (bare.length > 2 && _singlePrefixes.contains(bare[0])) {
      bare = bare.substring(1);
    }
    return bare;
  }

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
  static String _normalizeWhitespace(String text) => text
      .replaceAll(_spaceBeforePunct, r'$1')
      .replaceAll(_multiSpace, ' ')
      .replaceAll(RegExp(' +\n'), '\n')
      .replaceAll(RegExp('\n{3,}'), '\n\n');
}
