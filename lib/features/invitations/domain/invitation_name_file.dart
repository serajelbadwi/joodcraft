/// أقصى طول لاسم الملف (بعد التعقيم).
const int invitationFileNameMaxLength = 60;

/// قاموس نقل حرفي للأسماء العربية الشائعة — يعطي نطقاً معروفاً بدل النقل الحرفي
/// الحرف-بحرف (`أحمد` ⇒ `ahmed` لا `ahmd`). الهدف أسماء مقروءة يثق بها المستخدم.
const Map<String, String> _commonNames = <String, String>{
  'أحمد': 'ahmed',
  'احمد': 'ahmed',
  'محمد': 'mohamed',
  'محمّد': 'mohamed',
  'عبدالله': 'abdullah',
  'عبد الله': 'abdullah',
  'عبدالرحمن': 'abdulrahman',
  'عبد الرحمن': 'abdulrahman',
  'عبدالعزيز': 'abdulaziz',
  'عبد العزيز': 'abdulaziz',
  'إبراهيم': 'ibrahim',
  'ابراهيم': 'ibrahim',
  'إسماعيل': 'ismail',
  'اسماعيل': 'ismail',
  'إسماعيل': 'ismail',
  'يوسف': 'youssef',
  'يوسف': 'youssef',
  'خالد': 'khaled',
  'سلمان': 'salman',
  'فهد': 'fahad',
  'سلطان': 'sultan',
  'تركي': 'turki',
  'عمر': 'omar',
  'علي': 'ali',
  'حسن': 'hassan',
  'حسين': 'hussein',
  'مصطفى': 'mostafa',
  'مصطفي': 'mostafa',
  'مهدي': 'mahdi',
  'كريم': 'karim',
  'طارق': 'tarek',
  'رامي': 'rami',
  'سامي': 'sami',
  'زياد': 'ziyad',
  'بدر': 'badr',
  'نواف': 'nawaf',
  'ماجد': 'majed',
  'فيصل': 'faisal',
  'سعد': 'saad',
  'سعود': 'saud',
  'راشد': 'rashed',
  'منصور': 'mansour',
  'وليد': 'waleed',
  'أسماء': 'asmaa',
  'اسماء': 'asmaa',
  'فاطمة': 'fatima',
  'فاطمه': 'fatima',
  'مريم': 'maryam',
  'خديجة': 'khadija',
  'خديجه': 'khadija',
  'عائشة': 'aisha',
  'عائشه': 'aisha',
  'زينب': 'zainab',
  'سارة': 'sara',
  'ساره': 'sara',
  'هند': 'hind',
  'نورة': 'noura',
  'نوره': 'noura',
  'لمى': 'lama',
  'لينا': 'lina',
  'رنا': 'rana',
  'رانية': 'rania',
  'رانيه': 'rania',
  'دانة': 'dana',
  'دانّه': 'dana',
  'جود': 'jood',
  'هدى': 'huda',
  'هدي': 'huda',
  'ليلى': 'layla',
  'ليلي': 'layla',
  'سلمى': 'salma',
  'سلمي': 'salma',
  'منى': 'mona',
  'مني': 'mona',
  'إيمان': 'iman',
  'ايمان': 'iman',
  'أمل': 'amal',
  'امل': 'amal',
  'شهد': 'shahad',
  'بطاقات': 'cards',
};

/// نقل الحروف العربية إلى أحرف لاتينية (احتياطي حين لا يوجد الاسم في القاموس).
const Map<String, String> _arabicLetters = <String, String>{
  'ا': 'a',
  'أ': 'a',
  'إ': 'a',
  'آ': 'a',
  'ٱ': 'a',
  'ب': 'b',
  'ت': 't',
  'ث': 'th',
  'ج': 'j',
  'ح': 'h',
  'خ': 'kh',
  'د': 'd',
  'ذ': 'dh',
  'ر': 'r',
  'ز': 'z',
  'س': 's',
  'ش': 'sh',
  'ص': 's',
  'ض': 'd',
  'ط': 't',
  'ظ': 'z',
  'ع': 'a',
  'غ': 'gh',
  'ف': 'f',
  'ق': 'q',
  'ك': 'k',
  'ل': 'l',
  'م': 'm',
  'ن': 'n',
  'ه': 'h',
  'و': 'w',
  'ؤ': 'w',
  'ي': 'y',
  'ى': 'y',
  'ئ': 'y',
  'ة': 'h',
};

/// الرموز الممنوعة في أسماء الملفات على ويندوز/ماك/لينكس.
final RegExp _invalidFileChars = RegExp(r'[\\/:*?"<>|\x00-\x1F]');

final RegExp _separators = RegExp(r'[\s._-]+');

final RegExp _diacritics = RegExp('[\u064B-\u0652\u0670\u0640]');

/// تعقيم اسم مدعو إلى قاعدة اسم ملف لاتينية آمنة.
abstract final class InvitationFileName {
  const InvitationFileName._();

  /// يحوّل «أحمد محمد» إلى `ahmed_mohamed`.
  ///
  /// الترتيب: تطبيع التشكيل ← تقسيم إلى كلمات ← نقل كل كلمة (قاموس الأسماء
  /// الشائعة أولاً ثم النقل الحرفي) ← تعقيم الرموز وربطها بشرطة سفلية.
  static String baseName(String rawName) {
    final String normalized = _normalize(rawName);
    if (normalized.isEmpty) return '';
    final List<String> words = normalized
        .split(_separators)
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
    final List<String> parts = <String>[];
    for (final String word in words) {
      final String latin = _transliterate(word);
      if (latin.isNotEmpty) parts.add(latin);
    }
    if (parts.isEmpty) return '';
    String base = parts.join('_').toLowerCase();
    base = base.replaceAll(_invalidFileChars, '_');
    base = base.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    base = base.replaceAll(RegExp(r'_+'), '_');
    base = base.replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.length > invitationFileNameMaxLength) {
      base = String.fromCharCodes(base.runes.take(invitationFileNameMaxLength))
          .replaceAll(RegExp(r'_+$'), '');
    }
    return base;
  }

  /// الاسم الكامل بعد التعقيم — يظهر في المعاينة وفهرس CSV.
  static String fullName(String rawName) => _normalize(rawName);

  static String _normalize(String value) {
    String text = value.trim();
    text = text.replaceAll(_diacritics, '');
    text = text.replaceAll('ـ', ''); // التطويل
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  static String _transliterate(String word) {
    // ابحث عن أطول أثر للاسم في القاموس (كلمتان متتاليتان ثم كلمة واحدة).
    final String compact = word.replaceAll(' ', '');
    if (_commonNames.containsKey(word)) return _commonNames[word]!;
    if (_commonNames.containsKey(compact)) return _commonNames[compact]!;
    final StringBuffer buffer = StringBuffer();
    for (final int rune in word.runes) {
      final String letter = String.fromCharCode(rune);
      final String? mapped = _arabicLetters[letter];
      if (mapped != null) {
        buffer.write(mapped);
      } else if (RegExp(r'[A-Za-z0-9]').hasMatch(letter)) {
        buffer.write(letter.toLowerCase());
      }
      // حروف أخرى (ترقيم، رموز) تُهمل — التعقيم اللاحق يكفي
    }
    return buffer.toString();
  }
}

/// صف واحد من ملف الأسماء بعد التحقق.
class InvitationRowPlan {
  const InvitationRowPlan({
    required this.rowNumber,
    required this.name,
    required this.fileNameBase,
    this.isDuplicate = false,
  });

  /// رقم الصف كما يراه المستخدم في Excel.
  final int rowNumber;

  /// الاسم الكامل كما ورد في الملف.
  final String name;

  /// قاعدة اسم الملف بعد التعقيم (بلا لاحقة).
  final String fileNameBase;

  /// هل الاسم مكرر في الملف؟ (يُولَّد له ملف مستقل باسم مرقّم).
  final bool isDuplicate;
}

/// نتيجة فحص ملف الأسماء: الخطة + تحذيرات الجاهزية.
class InvitationSheetAudit {
  const InvitationSheetAudit({
    required this.plans,
    required this.emptyCount,
    required this.duplicateNames,
  });

  static const InvitationSheetAudit empty = InvitationSheetAudit(
    plans: <InvitationRowPlan>[],
    emptyCount: 0,
    duplicateNames: <String>[],
  );

  /// الصفوف التي ستُولَّد لها دعوات (الخلايا الفارغة مستثناة).
  final List<InvitationRowPlan> plans;

  /// عدد الخلايا الفارغة في عمود الاسم — تُتخطّى.
  final int emptyCount;

  /// الأسماء المكررة (لكل منها أكثر من صف).
  final List<String> duplicateNames;

  int get plannedCount => plans.length;

  bool get isEmpty => plans.isEmpty;

  bool get hasDuplicates => duplicateNames.isNotEmpty;
}

/// يبني خطة التوليد من ورقة Excel وعمود الاسم المختار.
///
/// * الخلايا الفارغة تُتخطّى وتُحصى في [InvitationSheetAudit.emptyCount].
/// * الأسماء المكررة تُولَّد كلها (بأسماء ملفات مرقّمة) ويُنبَّه المستخدم.
/// * الأسماء الغريبة الرموز تُعقَّم تلقائياً في اسم الملف دون فقدان الصف.
abstract final class InvitationSheetPlanner {
  const InvitationSheetPlanner._();

  static InvitationSheetAudit plan({
    required List<String> names,
    required List<int> rowNumbers,
  }) {
    if (names.length != rowNumbers.length) {
      throw ArgumentError('طول قائمة الأسماء يجب أن يطابق أرقام الصفوف');
    }
    final Map<String, int> occurrences = <String, int>{};
    final List<InvitationRowPlan> plans = <InvitationRowPlan>[];
    final List<String> duplicates = <String>[];
    int emptyCount = 0;
    final Set<String> usedBases = <String>{};

    for (int i = 0; i < names.length; i++) {
      final String name = names[i].trim();
      if (name.isEmpty) {
        emptyCount++;
        continue;
      }
      final int seen = (occurrences[name] ?? 0) + 1;
      occurrences[name] = seen;
      if (seen == 2) duplicates.add(name);

      String base = InvitationFileName.baseName(name);
      if (base.isEmpty) base = 'دعوة${rowNumbers[i]}';
      String fileNameBase = base;
      if (usedBases.contains(fileNameBase)) {
        int copy = 2;
        while (usedBases.contains('${base}_$copy')) {
          copy++;
        }
        fileNameBase = '${base}_$copy';
      }
      usedBases.add(fileNameBase);

      plans.add(InvitationRowPlan(
        rowNumber: rowNumbers[i],
        name: name,
        fileNameBase: fileNameBase,
        isDuplicate: seen > 1,
      ));
    }

    return InvitationSheetAudit(
      plans: plans,
      emptyCount: emptyCount,
      duplicateNames: duplicates,
    );
  }
}
