/// أدوات اسم ملف التصدير المدمج: التنقية، والامتداد، والاسم الافتراضي.
///
/// منطق خالص بلا واجهة، فيُستخدم في الشاشة (لعرض الاسم النهائي قبل الحفظ) وفي
/// `BulkGenerationService` (لحساب الاسم الذي يُحفظ به الملف) بلا تكرار.
abstract final class OutputFileName {
  const OutputFileName._();

  /// الاسم الاحتياطي حين يفرغ إدخال المستخدم بالكامل.
  static const String fallback = 'شهادات_المتدربين';

  /// الامتداد الافتراضي للملف المدمج.
  static const String defaultExtension = '.pdf';

  /// امتدادات لا نُكرّرها إن كتبها المستخدم بنفسه (‏PDF، صورة، أو أرشيف
  /// مضغوط) — فأي امتداد منها يُطرح كي لا يصير الملف `تقرير.png.pdf`.
  static const List<String> knownExtensions = <String>['.pdf', '.png', '.zip'];

  /// المحارف الممنوعة في أسماء الملفات على Windows (وهي ممنوعة أيضاً على
  /// macOS/Linux): `\ / : * ? " < > |`.
  static final RegExp invalidCharacters = RegExp(r'[\\/:*?"<>|]');

  /// محارف التحكّم غير المرئية — تُحذف أيضاً.
  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1F]');

  /// مسافات متكرّرة (ومسافات عربية) تُطوى إلى مسافة واحدة.
  static final RegExp _spaces = RegExp(r'\s+');

  /// ينقّي [raw] فيبقى اسماً صالحاً على كل الأنظمة.
  ///
  /// يحذف المحارف الممنوعة ومحارف التحكّم، ويطوي المسافات المتكرّرة، ويقلّم
  /// المسافات والنقاط الطرفية (يسمح بها النظام تقنياً لكنها تُربك المستخدم).
  static String sanitize(String raw) {
    final String cleaned = raw
        .replaceAll(invalidCharacters, '')
        .replaceAll(_controlCharacters, '')
        .replaceAll(_spaces, ' ')
        .trim();
    return cleaned.replaceAll(RegExp(r'^[.\s]+'), '').replaceAll(RegExp(r'[.\s]+$'), '');
  }

  /// اسم افتراضي ذكي مشتقّ من عنوان القالب النشط، أو [fallback] إن فرغ.
  static String defaultBaseName({String? templateTitle}) {
    final String title = sanitize(templateTitle ?? '');
    return title.isEmpty ? fallback : title;
  }

  /// اسم الأساس (بلا امتداد) من إدخال المستخدم: تنقية ← قصّ أي امتداد معروف ←
  /// احتياط إن فرغ.
  ///
  /// يُستخدم كاسم مجلد الوضع المنفصل (المجلد لا يحمل امتداد `.pdf`).
  static String baseName(String raw, {String fallbackName = fallback}) {
    final String cleaned = sanitize(raw);
    if (cleaned.isEmpty) return fallbackName;
    final String lower = cleaned.toLowerCase();
    for (final String known in knownExtensions) {
      if (lower.endsWith(known)) {
        final String stripped =
            sanitize(cleaned.substring(0, cleaned.length - known.length));
        return stripped.isEmpty ? fallbackName : stripped;
      }
    }
    return cleaned;
  }

  /// يضيف [extension] إن لم يكن الاسم يحمل امتداداً معروفاً مسبقاً.
  static String withExtension(
    String name, {
    String extension = defaultExtension,
  }) {
    final String lower = name.toLowerCase();
    for (final String known in knownExtensions) {
      if (lower.endsWith(known)) return name;
    }
    return '$name$extension';
  }

  /// يحوّل إدخال المستخدم إلى اسم ملف نهائي: تنقية ← احتياط ← امتداد.
  ///
  /// [extension] صيغة الخروج المختارة (`.pdf` هو الافتراضي، `.png` للصور) —
  /// والأمتدادات المعروفة في [knownExtensions] تُطرح من أي اسم كتبها المستخدم
  /// بنفسه فلا يتراكب امتدادان.
  static String resolve(
    String raw, {
    String fallbackName = fallback,
    String extension = defaultExtension,
  }) {
    final String cleaned = sanitize(raw);
    return withExtension(
      cleaned.isEmpty ? fallbackName : cleaned,
      extension: extension,
    );
  }
}
