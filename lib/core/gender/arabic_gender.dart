/// محرّك التذكير والتأنيث والتصنيف الذكي (Gender Rules & Grammar Engine).
///
/// المكوّنات الثلاثة:
/// 1. [Gender] — الجنس النحوي (ذكر/أنثى) مع قراءة قيمته من نص (عمود Excel أو
///    إعداد واجهة).
/// 2. [GenderGrammar] — الصيغة الشرطية `{{الجنس: نص_الذكر | نص_الأنثى}}`:
///    بناؤها، كشفها، وحلّها جنساً واحداً.
/// 3. [ArabicGenderDetector] — كاشف جنس الاسم العربي الأول بلا شبكة ولا قاعدة
///    بيانات: قائمة أسماء أنثوية شائعة + قواعد صرفية + معالجة الألقاب والبادئات.
///
/// القاعدة الحاكمة في كل المحرّك: **الرجوع إلى المذكّر** كلما كان الحكم غامضاً،
/// فلا تخرج شهادة بصيغة أنثوية بالخطأ.
library;

/// الجنس النحوي المستخدم في صياغة النصوص العربية.
enum Gender {
  /// المذكّر — وهو الفرض الافتراضي عند غياب أي دليل.
  male('ذكر', 'm'),

  /// المؤنّث.
  female('أنثى', 'f');

  const Gender(this.labelAr, this.code);

  /// التسمية العربية كما تُعرض في الواجهة وجداول المراجعة.
  final String labelAr;

  /// رمز مختصر يُستخدم في حفظ التخطيطات والتصدير.
  final String code;

  bool get isFemale => this == Gender.female;
  bool get isMale => this == Gender.male;

  /// قراءة الجنس من قيمة نصّية (خلية Excel، إعداد واجهة).
  ///
  /// تُقبل الصيغ الشائعة: `ذكر/مذكر/male/m/1/ولد` و
  /// `أنثى/انثى/أنثي/مؤنث/female/f/2/بنت`. تُعيد `null` للقيم الغامضة حتى
  /// يقرّر المستدعي (كاشف الاسم) بدلاً من التخمين.
  static Gender? fromValue(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    if (value.isEmpty) return null;
    switch (value) {
      case 'ذكر':
      case 'مذكر':
      case 'ولد':
      case 'male':
      case 'm':
      case 'man':
      case 'boy':
      case '1':
        return Gender.male;
      case 'أنثى':
      case 'انثى':
      case 'أنثي':
      case 'انثي':
      case 'مؤنث':
      case 'مؤنثة':
      case 'بنت':
      case 'فتاة':
      case 'female':
      case 'f':
      case 'woman':
      case 'girl':
      case '2':
        return Gender.female;
    }
    return null;
  }

  /// المقابل الآخر (يُستخدم في مبدّل المعاينة الحيّة).
  Gender get opposite => this == Gender.male ? Gender.female : Gender.male;
}

/// صيغة شرطية واحدة مُستخرَجة من نص: الفرعان (ذكر/أنثى) ومداها في النص.
class GenderCondition {
  const GenderCondition({
    required this.male,
    required this.female,
    required this.start,
    required this.end,
  });

  /// النص البديل عند الذكورة.
  final String male;

  /// النص البديل عند الأنوثة.
  final String female;

  /// موضع بداية الصيغة في النص الأصلي.
  final int start;

  /// موضع نهاية الصيغة (غير شامل).
  final int end;

  /// هل الصيغة متساوية الفرعين (بلا أثر فعلي)؟
  bool get isNeutral => male.trim() == female.trim();

  @override
  String toString() => 'GenderCondition($male | $female)@$start-$end';
}

/// صيغة جاهزة شائعة تُدرَج بضغطة واحدة من لوحة الخصائص.
class GenderSnippetPreset {
  const GenderSnippetPreset({
    required this.labelKey,
    required this.male,
    required this.female,
  });

  /// مفتاح الترجمة لوصف الصيغة (النص المُدرَج يبقى عربياً).
  final String labelKey;

  /// نص فرع الذكر.
  final String male;

  /// نص فرع الأنثى.
  final String female;

  /// الصيغة الكاملة كما تُدرَج في النص.
  String get snippet => GenderGrammar.snippet(male, female);
}

/// الصيغة الشرطية `{{الجنس: ذكر | أنثى}}` — بناءً وكشفاً وحلّاً.
abstract final class GenderGrammar {
  const GenderGrammar._();

  /// المفتاح القياسي للجنس (وهو أيضاً اسم العمود الصريح المعتاد في Excel).
  static const String maleKey = 'الجنس';

  /// كل المفاتيح المقبولة للصيغة الشرطية (عربية وإنجليزية).
  static const Set<String> keys = <String>{
    'الجنس',
    'النوع',
    'الجندر',
    'gender',
    'sex',
  };

  /// الأنماط الشرطية داخل النص: `{{الجنس: A | B}}`.
  static final RegExp pattern = RegExp(
    r'\{\{\s*(الجنس|النوع|الجندر|gender|sex)\s*:\s*([^{}]*?)\s*\|\s*([^{}]*?)\s*\}\}',
    caseSensitive: false,
  );

  /// هل باطن قوسين `{{...}}` صيغة شرطية للجنس؟
  ///
  /// يُستخدم لاستثناء الصيغ من حقول القالب (`fieldKeys`) فلا تُطلب لها أعمدة
  /// Excel ولا تُعدّ حقلاً ناقصاً.
  static bool isConditionInner(String inner) {
    final String value = inner.trim();
    if (value.isEmpty || !value.contains('|')) return false;
    final int colon = value.indexOf(':');
    if (colon <= 0) return false;
    return keys.contains(value.substring(0, colon).trim().toLowerCase());
  }

  /// بناء صيغة شرطية من فرعَيها.
  static String snippet(String male, String female) =>
      '{{$maleKey: ${male.trim()} | ${female.trim()}}}';

  /// حلّ كل الصيغ الشرطية في النص بالجنس المعطى.
  ///
  /// [gender] = `null` يعني الرجوع إلى المذكّر (الفرع الأول) كما تنصّ القاعدة.
  static String apply(String raw, Gender? gender) {
    if (raw.isEmpty || !raw.contains('|')) return raw;
    final Gender resolved = gender ?? Gender.male;
    return raw.replaceAllMapped(
      pattern,
      (Match match) => resolved.isFemale ? match.group(3)! : match.group(2)!,
    );
  }

  /// كل الصيغ الشرطية في نص — تُستخدم لعرضها/إحصائها في الواجهة.
  static List<GenderCondition> conditionsIn(String raw) {
    if (raw.isEmpty) return const <GenderCondition>[];
    return pattern
        .allMatches(raw)
        .map((RegExpMatch match) => GenderCondition(
              male: match.group(2)?.trim() ?? '',
              female: match.group(3)?.trim() ?? '',
              start: match.start,
              end: match.end,
            ))
        .toList(growable: false);
  }

  /// هل يحتوي النص صيغة شرطية واحدة على الأقل؟
  static bool containsCondition(String raw) =>
      raw.isNotEmpty && raw.contains('|') && pattern.hasMatch(raw);

  /// الصيغ الجاهزة الشائعة في الشهادات والعقود.
  static const List<GenderSnippetPreset> presets = <GenderSnippetPreset>[
    GenderSnippetPreset(
      labelKey: 'genderPresetCompleted',
      male: 'أتمّ',
      female: 'أتمّت',
    ),
    GenderSnippetPreset(
      labelKey: 'genderPresetPassed',
      male: 'اجتاز',
      female: 'اجتازت',
    ),
    GenderSnippetPreset(
      labelKey: 'genderPresetForStudent',
      male: 'للطالب',
      female: 'للطالبة',
    ),
    GenderSnippetPreset(
      labelKey: 'genderPresetStudent',
      male: 'الطالب',
      female: 'الطالبة',
    ),
    GenderSnippetPreset(
      labelKey: 'genderPresetToHim',
      male: 'له',
      female: 'لها',
    ),
    GenderSnippetPreset(
      labelKey: 'genderPresetHonoring',
      male: 'المتدرب المتميّز',
      female: 'المتدربة المتميّزة',
    ),
  ];
}

/// استخراج الجنس من بيانات سجل/قالب بترتيب ثقة صارم.
abstract final class GenderResolver {
  const GenderResolver._();

  /// مفاتيح عمود الجنس الصريح (كما تنصّ المواصفة: الجنس / Gender / النوع).
  static const List<String> genderKeys = <String>[
    'الجنس',
    'النوع',
    'الجندر',
    'gender',
    'Gender',
    'sex',
    'Sex',
  ];

  /// مفاتيح حقول الاسم التي يُقاس عليها الجنس تلقائياً عند غياب عمود صريح.
  ///
  /// مرتّبة بالأولوية: اسم المتدرّب/الطالب ثم أطراف العقود ثم الاسم العام.
  static const List<String> nameKeys = <String>[
    'اسم_المتدرب',
    'اسم_الطالب',
    'اسم_المشارك',
    'student_name',
    'student',
    'اسم_الطرف_الثاني',
    'اسم_الطرف_الأول',
    'party_2',
    'party_1',
    'اسم_المنشأة',
    'اسم الموظف',
    'الاسم',
    'اسم',
    'name',
  ];

  /// الجنس الصريح في مجموعة بيانات، أو `null` إن لم يوجد/كان غامضاً.
  static Gender? explicitIn(Map<String, String>? data) {
    if (data == null) return null;
    for (final String key in genderKeys) {
      final Gender? gender = Gender.fromValue(data[key]);
      if (gender != null) return gender;
    }
    return null;
  }

  /// مفتاح أول حقل اسم يحمل قيمة صالحة في [data].
  static String? nameKeyIn(Map<String, String>? data) {
    if (data == null) return null;
    for (final String key in nameKeys) {
      final String value = (data[key] ?? '').trim();
      if (value.isNotEmpty && !value.contains('{{')) return key;
    }
    return null;
  }

  /// أول اسم صالح في مجموعة بيانات (لاستنتاج الجنس).
  static String? nameIn(Map<String, String>? data) {
    final String? key = nameKeyIn(data);
    return key == null ? null : (data![key] ?? '').trim();
  }

  /// نسخة من [data] بعد استبدال الاسم بقيمة المستخدم [name].
  ///
  /// يُستبدل أول حقل اسم موجود فعلاً، فتُعاد مطابقة الجنس والطباعة على ما كتبه
  /// المستخدم في جدول المراجعة لا على قيمة الملف الأصلية. فإن لم يكن في الربط
  /// أيّ حقل اسم أُضيف الاسم تحت [fallbackKey] حتى يبقى كشف الجنس متسقاً مع ما
  /// يراه المستخدم (والطباعة تتجاهله إن لم يستخدمه القالب). `null`/الفراغ يعيد
  /// [data] كما هي.
  static Map<String, String> withName(
    Map<String, String> data,
    String? name, {
    String fallbackKey = 'اسم_المتدرب',
  }) {
    final String trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return data;
    final String key = nameKeyIn(data) ?? fallbackKey;
    return <String, String>{...data, key: trimmed};
  }

  /// حلّ الجنس النهائي لسجل واحد.
  ///
  /// الترتيب: [override] (إعداد الواجهة/المعاينة الحيّة) ← عمود الجنس الصريح في
  /// [data] ثم [fallback] ← كشف الاسم في [data] ثم [fallback] ← **المذكّر**.
  static Gender resolve(
    Map<String, String>? data, {
    Gender? override,
    Map<String, String>? fallback,
  }) {
    if (override != null) return override;
    final Gender? explicit =
        explicitIn(data) ?? explicitIn(fallback);
    if (explicit != null) return explicit;
    final String? name = nameIn(data) ?? nameIn(fallback);
    if (name != null) return ArabicGenderDetector.detect(name);
    return Gender.male;
  }

  /// الجنس ليُحقن في بيانات كل صف قبل الطباعة.
  ///
  /// يُكتب بالقيمة العربية (`ذكر`/`أنثى`) تحت مفتاح [GenderGrammar.maleKey]
  /// فيستفيد منه `resolveFields` (كشف الجنس) وأي نص يستخدم `{{الجنس}}` معاً —
  /// ويعبر حدّ العزل (`Isolate`) بلا أي ترميز إضافي.
  static String labelFor(
    Map<String, String>? data, {
    Gender? override,
    Map<String, String>? fallback,
  }) =>
      resolve(data, override: override, fallback: fallback).labelAr;
}

/// كاشف جنس الاسم العربي الأول — محلّي بالكامل (بلا شبكة).
///
/// المنهجية: تُجرَّد الألقاب والبادئات، ثم يُقيَّم الرمز الاسمي الأول بقائمة
/// أسماء أنثوية شائعة، فإن لم يُطابق طُبِّقت القواعد الصرفية (تاء مربوطة،
/// ألف ممدودة، ألف مقصورة) مع قائمة استثناءات للمذكّر. الافتراض النهائي: ذكر.
abstract final class ArabicGenderDetector {
  const ArabicGenderDetector._();

  /// كشف جنس اسم كامل. الافتراض `Gender.male` عند أي غموض.
  static Gender detect(String? rawName) {
    final String cleaned = _stripDiacritics(rawName ?? '').trim();
    if (cleaned.isEmpty) return Gender.male;

    final List<String> tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((String token) => token.trim().isNotEmpty)
        .toList(growable: false);

    for (final String token in tokens) {
      final String norm = _normalize(token);
      if (norm.isEmpty) continue;

      // لقب مؤنّث صريح يحكم فوراً («الأستاذة سارة»، «د. هند»).
      if (_femaleHonorifics.contains(norm)) return Gender.female;
      // لقب مذكّر/محايد: يُجرَّد ويُتابع البحث في الرمز التالي.
      if (_maleHonorifics.contains(norm) || _neutralPrefixes.contains(norm)) {
        continue;
      }
      // بادئة مركّبة تحكم الجنس بنفسها.
      if (norm.startsWith('عبد') || _malePrefixes.contains(norm)) {
        return Gender.male;
      }
      if (_femalePrefixes.contains(norm)) return Gender.female;

      return _evaluateCore(norm);
    }
    return Gender.male;
  }

  /// تقييم الرمز الاسمي الأول (بعد تجريد الألقاب).
  static Gender _evaluateCore(String core) {
    if (_femaleNames.contains(core)) return Gender.female;
    if (_maleNamesWithFeminineForm.contains(core)) return Gender.male;
    // قواعد صرفية: تاء مربوطة أو ألف ممدودة أو ألف مقصورة ← أنثى.
    if (core.endsWith('ه') || core.endsWith('اء') || core.endsWith('ى')) {
      return Gender.female;
    }
    return Gender.male;
  }

  /// تجريد التشكيل والتطويل (يُبقي الحروف كما هي فلا يمسّ الصرف).
  static String _stripDiacritics(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in value.runes) {
      if (rune >= 0x064B && rune <= 0x0652) continue; // التشكيل.
      if (rune == 0x0640) continue; // التطويل.
      if (rune == 0x0670) continue; // الألف الخنجرية.
      buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  /// تطبيع للمقارنة: توحيد الهمزات، والتاء المربوطة ← هاء، وحذف الرموز.
  static String _normalize(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in _stripDiacritics(value).trim().toLowerCase().runes) {
      final String ch = String.fromCharCode(rune);
      switch (ch) {
        case 'أ':
        case 'إ':
        case 'آ':
        case 'ٱ':
          buffer.write('ا');
        case 'ة':
          buffer.write('ه');
        case 'ئ':
          buffer.write('ي');
        case 'ؤ':
          buffer.write('و');
        default:
          if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(ch)) {
            buffer.write(ch);
          }
      }
    }
    return buffer.toString();
  }

  /// ألقاب تدلّ على الأنوثة مباشرةً.
  static const Set<String> _femaleHonorifics = <String>{
    'استاذه',
    'دكتوره',
    'مهندسه',
    'سيده',
    'انسه',
    'شيخه',
    'معلمه',
    'باحثه',
    'طبيبه',
    'محاميه',
    'مدربه',
    'م',
  };

  /// ألقاب محايدة أو مذكّرة تُجرَّد قبل تقييم الاسم.
  static const Set<String> _maleHonorifics = <String>{
    'د',
    'اد',
    'استاذ',
    'استاد',
    'دكتور',
    'مهندس',
    'سيد',
    'شيخ',
    'معلم',
    'طبيب',
    'محامي',
    'مدرب',
    'بروفيسور',
    'برفيسور',
    'dr',
    'prof',
    'mr',
    'eng',
  };

  /// بادئات تُجرَّد بلا حكم («آل» = اسم عائلة).
  static const Set<String> _neutralPrefixes = <String>{'ال'};

  /// بادئات مركّبة تحكم الذكورة («عبد الله»، «أبو بكر»، «ابن سينا»).
  static const Set<String> _malePrefixes = <String>{'ابو', 'ابن', 'بن', 'بو'};

  /// بادئات مركّبة تحكم الأنوثة («أم كلثوم»، «بنت سعيد»).
  static const Set<String> _femalePrefixes = <String>{'ام', 'بنت', 'ابنه'};

  /// أسماء أنثوية شائعة (مطبَّعة: همزات موحّدة، تاء مربوطة ← هاء).
  static const Set<String> _femaleNames = <String>{
    // الأسماء الواردة في المواصفة وأوسع شعبية.
    'ساره', 'مريم', 'مريام', 'فاطمه', 'نوره', 'اروى', 'هند', 'ليلى', 'ليلي',
    'سلمى', 'هدى', 'منى', 'رنا', 'رانيا', 'دينا', 'ديانا', 'ايمان', 'امل',
    'امال', 'امنيه', 'بسمه', 'بشاير', 'تغريد', 'جواهر', 'حصه', 'حنان', 'خديجه',
    'رحمه', 'رغد', 'ريم', 'زينب', 'سعاد', 'سمر', 'سهام', 'شذى', 'شهد', 'صفاء',
    'ضحى', 'عايشه', 'عبير', 'غاده', 'غيداء', 'فاتن', 'فرح', 'فوزيه', 'لطيفه',
    'لمى', 'لمياء', 'مها', 'مروه', 'مشاعل', 'منال', 'مي', 'ميساء', 'ناديه',
    'نجلاء', 'ندى', 'نسرين', 'نهى', 'نوف', 'هبه', 'هيفاء', 'وفاء', 'ياسمين',
    'يسرى', 'اميره', 'ابتسام', 'اسماء', 'الاء', 'بشرى', 'بلقيس', 'جميله',
    'حياه', 'خلود', 'دعاء', 'رحاب', 'روان', 'رولا', 'ريما', 'زهراء', 'زهره',
    'ساجده', 'سحر', 'سلوى', 'سناء', 'شاهيناز', 'شروق', 'شيماء', 'صابرين',
    'صبا', 'عفاف', 'علياء', 'عهود', 'غزل', 'فايزه', 'فريده', 'قمر', 'كريمه',
    'لبنى', 'لورا', 'لينا', 'ليان', 'ماجده', 'ماريا', 'ملاك', 'منار', 'موده',
    'نرمين', 'نصره', 'نهال', 'نوال', 'هاجر', 'هاله', 'هيام', 'وداد', 'يارا',
    'يسرا', 'عاليه', 'جوريه', 'سارا', 'ديما', 'سما', 'اسيل', 'رتاج', 'رنيم',
    'ريماس', 'سديم', 'غاليه', 'نجود', 'نهاد', 'هنادي', 'وضحى', 'امنه', 'اسراء',
    'اخلاص', 'اعتدال', 'انعام', 'ايات', 'بثينه', 'براء', 'تقى', 'تهاني',
    'ثريا', 'جمانه', 'حوريه', 'حور', 'خوله', 'دلال', 'رابعه', 'رفيف', 'رهام',
    'زكيه', 'سلمي', 'شمس', 'صفيه', 'عتاب', 'عزيزه', 'غيدا', 'فردوس', 'لميس',
    'مروى', 'ملك', 'ميار', 'نائله', 'نبيله', 'نجاح', 'نعمه', 'هناء', 'هيفا',
    'وسام', 'يمنى', 'رقيه', 'سكينه', 'حبيبه', 'حميده', 'خيريه', 'زبيده',
    'زليخه', 'سعيده', 'شفيقه', 'صالحه', 'عابده', 'كفاح', 'كوثر', 'لولوه',
    'مزنه', 'مشيره', 'معصومه', 'نجيبه', 'نور', 'نواله', 'وفيه', 'ياقوت',
    'اقبال', 'انوار', 'بتول', 'بدور', 'جيهان', 'حليمه', 'رغده', 'ريام',
    'زينه', 'سنابل', 'شفاء', 'شهله', 'صفا', 'عاليا', 'عطور', 'غزيل', 'فتون',
    'فدوى', 'قصواء', 'نبراس', 'هيا', 'وجنات', 'روبي', 'غيد', 'اثير', 'اريج',
    'اسيا', 'بيسان', 'جوانا',
  };

  /// أسماء مذكّرة تنتهي بصيغة أنثوية (تاء مربوطة/ألف ممدودة/مقصورة) — استثناء
  /// لازم وإلا انقلب الجنس في أسماء شائعة مثل «حمزة» و«مصطفى».
  static const Set<String> _maleNamesWithFeminineForm = <String>{
    'حمزه',
    'اسامه',
    'معاويه',
    'طلحه',
    'عروه',
    'حذيفه',
    'قتيبه',
    'عبيده',
    'علاء',
    'بهاء',
    'ضياء',
    'مصطفى',
    'عيسى',
    'يحيى',
    'موسى',
    'مرتضى',
    'انور',
    'اسلام',
  };
}
