import 'sheet_data.dart';

/// ربط أعمدة ملف البيانات بالحقول الديناميكية في القالب.
///
/// المفتاح هو **فهرس العمود** لا عنوانه، لأن العناوين تتغيّر بين الملفات بينما
/// يبقى الترتيب مفهوماً. القيمة هي مفتاح الحقل كما يُكتب داخل `{{...}}`.
class ColumnMapping {
  const ColumnMapping(this.byColumn);

  static const ColumnMapping empty = ColumnMapping(<int, String>{});

  /// فهرس العمود ← مفتاح الحقل.
  final Map<int, String> byColumn;

  bool get isEmpty => byColumn.isEmpty;
  bool get isNotEmpty => byColumn.isNotEmpty;
  int get mappedCount => byColumn.length;

  String? fieldFor(int column) => byColumn[column];

  int? columnFor(String field) {
    for (final MapEntry<int, String> entry in byColumn.entries) {
      if (entry.value == field) return entry.key;
    }
    return null;
  }

  List<int> get mappedColumns => byColumn.keys.toList(growable: false);

  /// حقول مرتبطة بأكثر من عمود — تُمنع في الواجهة لأن نتيجتها غامضة.
  List<String> get duplicateFields {
    final Map<String, int> counts = <String, int>{};
    for (final String field in byColumn.values) {
      counts[field] = (counts[field] ?? 0) + 1;
    }
    return counts.entries
        .where((MapEntry<String, int> e) => e.value > 1)
        .map((MapEntry<String, int> e) => e.key)
        .toList(growable: false);
  }

  bool get hasDuplicates => duplicateFields.isNotEmpty;

  /// نسخة بعد ربط/فكّ ربط عمود. تمرير `null` للحقل يلغي الربط.
  ColumnMapping withColumn(int column, String? field) {
    final Map<int, String> next = Map<int, String>.from(byColumn);
    if (field == null || field.trim().isEmpty) {
      next.remove(column);
    } else {
      next[column] = field.trim();
    }
    return ColumnMapping(next);
  }

  ColumnMapping withoutColumns(Iterable<int> columns) {
    final Map<int, String> next = Map<int, String>.from(byColumn);
    for (final int column in columns) {
      next.remove(column);
    }
    return ColumnMapping(next);
  }

  /// بناء بيانات صف واحد: مفتاح الحقل ← قيمة الخلية.
  ///
  /// الخلايا الفارغة **تُدرَج** كقيم فارغة (`''`) حتى تستطيع سياسة المعالجة أن
  /// تقرّر: تُسقط الصف أم تستخدم القيمة التجريبية. حذفها هنا سيُخفي المعلومة.
  Map<String, String> apply(SheetRow row) {
    final Map<String, String> data = <String, String>{};
    for (final MapEntry<int, String> entry in byColumn.entries) {
      data[entry.value] = row.cellAt(entry.key).trim();
    }
    return data;
  }

  /// مفاتيح الحقول المرتبطة (بلا تكرار) بترتيب الأعمدة.
  List<String> get fields {
    final List<String> out = <String>[];
    for (final int column in byColumn.keys.toList()..sort()) {
      final String field = byColumn[column]!;
      if (!out.contains(field)) out.add(field);
    }
    return out;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'columns': <String, String>{
          for (final MapEntry<int, String> entry in byColumn.entries)
            '${entry.key}': entry.value,
        },
      };

  /// قراءة آمنة: أي مفتاح غير رقمي يُتجاهل بلا رمي.
  static ColumnMapping fromJson(Object? json) {
    if (json is! Map) return empty;
    final Object? columns = json['columns'];
    if (columns is! Map) return empty;
    final Map<int, String> parsed = <int, String>{};
    for (final MapEntry<Object?, Object?> entry in columns.entries) {
      final int? column = int.tryParse('${entry.key}');
      final String field = '${entry.value}'.trim();
      if (column == null || column < 0 || field.isEmpty) continue;
      parsed[column] = field;
    }
    return ColumnMapping(parsed);
  }

  // ==========================================================================
  //  الكشف التلقائي
  // ==========================================================================

  /// أقصى تشابه مقبول للربط التلقائي.
  static const int autoDetectThreshold = 500;

  /// ربط تلقائي ذكي: يطابق عناوين الأعمدة العربية مع الحقول الديناميكية.
  ///
  /// الخوارزمية: تُحسب درجة تشابه لكل (عمود، حقل) ثم يُختار الأعلى درجة بالتدريج
  /// (greedy) مع منع استخدام العمود أو الحقل أكثر من مرة — نتيجة حتمية ومفهومة،
  /// ويبقى للمستخدم تعديلها يدوياً.
  /// [aliases] تربط مفتاح الحقل بعناوين بديلة تُطابَق فقط ولا تُكتب في الربط
  /// (انظر `FieldAliases`): مفاتيح القالب تبقى هي المُسجَّلة حتى يستبدل محرّك
  /// الطباعة القيم فعلاً.
  /// [allowMatch] حاجز دلالي اختياري: أي زوج (عمود، حقل) يُرجع عنه `false`
  /// يُستبعد من الربط التلقائي بالكامل. يُستخدم لمنع الربط غير المنطقي — أبرزُه
  /// ربط عمود اسم (Name/الاسم) بحقل تاريخ أو رقم إشعار، وهو ما يطبع الاسم في
  /// مكان التاريخ. الحاجز لا يمسّ الربط اليدوي: المستخدم يستطيع دائماً فرض ما
  /// يريد من القائمة.
  static ColumnMapping autoDetect({
    required List<int> columns,
    required List<String> headers,
    required List<String> fieldKeys,
    Map<String, List<String>> aliases = const <String, List<String>>{},
    bool Function(int column, String field)? allowMatch,
  }) {
    final List<_Candidate> candidates = <_Candidate>[];
    final Set<String> seenHeaders = <String>{};
    for (final int column in columns) {
      final String header = column < headers.length ? headers[column] : '';
      // عنوان مكرّر لا يُربط تلقائياً أكثر من مرة: بدل تخمين عمود ثانٍ بحقل
      // مختلف، يُترك للمستخدم ويظهر بوضوح في الواجهة.
      if (!seenHeaders.add(normalize(header))) continue;
      for (final String field in fieldKeys) {
        if (allowMatch != null && !allowMatch(column, field)) continue;
        int score = similarity(header, field);
        for (final String alias in aliases[field] ?? const <String>[]) {
          final int aliasScore = similarity(header, alias);
          if (aliasScore > score) score = aliasScore;
        }
        if (score >= autoDetectThreshold) {
          candidates.add(_Candidate(column, field, score));
        }
      }
    }

    candidates.sort((_Candidate a, _Candidate b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      if (a.column != b.column) return a.column.compareTo(b.column);
      return a.field.compareTo(b.field);
    });

    final Map<int, String> mapping = <int, String>{};
    final Set<String> used = <String>{};
    for (final _Candidate candidate in candidates) {
      if (mapping.containsKey(candidate.column)) continue;
      if (used.contains(candidate.field)) continue;
      mapping[candidate.column] = candidate.field;
      used.add(candidate.field);
    }
    return ColumnMapping(mapping);
  }

  /// درجة التشابه بين رأس عمود ومفتاح حقل (0 = لا علاقة).
  static int similarity(String header, String fieldKey) {
    final String h = normalize(header);
    final String f = normalize(fieldKey);
    if (h.isEmpty || f.isEmpty) return 0;
    if (h == f) return 1000;

    final String hBare = stripArticle(h);
    final String fBare = stripArticle(f);
    if (hBare == fBare) return 900;

    final List<String> hTokens = tokenize(header);
    final List<String> fTokens = tokenize(fieldKey);
    if (hTokens.isEmpty || fTokens.isEmpty) return 0;

    final int matched =
        hTokens.where((String token) => fTokens.contains(token)).length;
    if (matched == 0) return 0;

    if (hTokens.length > 1) {
      // أي كلمة غريبة في رأس العمود تعني أنه ليس نفس الحقل.
      if (matched < hTokens.length) return 0;
      return 850 + matched * 10 + _averageLength(hTokens);
    }

    final String only = hTokens.single;
    if (fTokens.first == only) return 800 + only.length;
    if (fTokens.contains(only) && only.length >= 5) return 600 + only.length;
    return 0;
  }

  /// تقطيع النص إلى كلمات مطبَّعة بلا «ال» التعريف.
  static List<String> tokenize(String value) => value
      .split(RegExp(r'[\s_\-\u00B7\.\/\(\)\[\]\\:،,]+'))
      .map(normalize)
      .map(stripArticle)
      .where((String token) => token.length >= 2)
      .toList(growable: false);

  static int _averageLength(List<String> tokens) {
    if (tokens.isEmpty) return 0;
    final int total = tokens.fold<int>(0, (int sum, String t) => sum + t.length);
    return total ~/ tokens.length;
  }

  /// تطبيع عربي: توحيد الهمزات والتاء المربوطة وحذف التشكيل والرموز.
  static String normalize(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in value.trim().toLowerCase().runes) {
      // التشكيل العربي (U+064B..U+0652) والتطويل.
      if (rune >= 0x064B && rune <= 0x0652) continue;
      if (rune == 0x0640) continue;
      final String ch = String.fromCharCode(rune);
      switch (ch) {
        case 'أ':
        case 'إ':
        case 'آ':
        case 'ٱ':
          buffer.write('ا');
        case 'ة':
          buffer.write('ه');
        case 'ى':
          buffer.write('ي');
        case 'ئ':
          buffer.write('ي');
        case 'ؤ':
          buffer.write('و');
        case ' ':
        case '_':
        case '-':
        case '.':
        case '(':
        case ')':
        case '[':
        case ']':
        case '/':
        case '\\':
        case ':':
        case '،':
        case ',':
          break;
        default:
          if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(ch)) {
            buffer.write(ch);
          }
      }
    }
    return buffer.toString();
  }

  /// حذف «ال» التعريف من البداية للمقارنة (`الاسم` ← `اسم`).
  static String stripArticle(String value) =>
      value.length > 2 && value.startsWith('ال') ? value.substring(2) : value;

  @override
  String toString() => 'ColumnMapping($byColumn)';
}

/// مرشَّح ربط واحد أثناء الحساب.
class _Candidate {
  const _Candidate(this.column, this.field, this.score);

  final int column;
  final String field;
  final int score;
}
