/// ورقة بيانات مقروءة محلياً من ملف `.xlsx` أو `.csv`.
///
/// التمثيل متعمَّد البساطة: **نصوص فقط**. لا أنواع ولا تواريخ ولا صيغ، لأن كل
/// ما يحتاجه مولّد الشهادات هو قيمة نصية تُكتب في مكان `{{الحقل}}`. أي تحويل
/// (تاريخ، رقم، نسبة) يجري في القارئ نفسه مرة واحدة.
class SheetData {
  const SheetData({
    required this.headers,
    required this.rows,
    this.sourceName = '',
    this.sheetName = '',
    this.notes = const <String>[],
    this.headerRowIndex = 0,
    this.rowSamples = const <List<String>>[],
  });

  /// أقصى عدد من الصفوف الأولية يُحتفظ بها لعرض منتقي «صف العناوين» في الواجهة.
  static const int sampleRowLimit = 15;

  /// ورقة فارغة — تُستخدم كحالة ابتدائية قبل اختيار ملف.
  static const SheetData empty = SheetData(
    headers: <String>[],
    rows: <List<String>>[],
  );

  /// عناوين الأعمدة كما وردت في الصف الأول (بعد التطبيع).
  final List<String> headers;

  /// صفوف البيانات (بلا صف العناوين)، كل صف بعرض [headers] بالضبط.
  final List<List<String>> rows;

  /// اسم الملف الذي قُرئت منه (يُعرض في الواجهة).
  final String sourceName;

  /// اسم الورقة داخل ملف Excel (فارغ في CSV).
  final String sheetName;

  /// ملاحظات الاستيراد: صفوف فارغة أُسقطت، عناوين ناقصة أُعيدت تسميتها…
  /// تُعرض للمستخدم حتى يفهم لماذا اختلف عدد الصفوف عمّا في ملفه.
  final List<String> notes;

  /// فهرس الصف الذي اعتُبر صف العناوين داخل المصفوفة الأصلية (يبدأ من صفر).
  ///
  /// `0` يعني «الصف الأول»، و`2` يعني «الصف الثالث» كما يراه المستخدم في Excel
  /// (أي أن رقم الصف في Excel = القيمة + 1). يُستخدم لترقيم الصفوف بدقة ولإظهار
  /// الصف المُكتشف تلقائياً في الواجهة.
  final int headerRowIndex;

  /// الصفوف الأولية الخام (قبل تحديد العناوين) لعرضها في منتقي صف العناوين.
  ///
  /// مقتطعة عند [sampleRowLimit] صفاً؛ كل صف نصوص مقصوصة بلا تطبيع للعرض فقط.
  final List<List<String>> rowSamples;

  /// بناء ورقة من مصفوفة خام مع **تطبيع كامل**:
  /// * أول صف غير فارغ هو العناوين (الصفوف الفارغة قبله تُسقط).
  /// * العناوين الفارغة تُسمّى `عمود N` حتى تبقى قابلة للربط.
  /// * عناوين مكرّرة تُلحَق برقم لتبقى فريدة (شرط لربط العمود بحقل).
  /// * كل صف يُطبَّع إلى عرض العناوين بالضبط، والصفوف الفارغة تماماً تُسقط.
  factory SheetData.fromMatrix(
    List<List<String>> matrix, {
    String sourceName = '',
    String sheetName = '',
    int? headerRowIndex,
  }) {
    final List<String> notes = <String>[];

    final List<List<String>> trimmed = matrix
        .map((List<String> row) =>
            row.map((String cell) => cell.trim()).toList(growable: false))
        .toList(growable: false);

    // عيّنة الصفوف الأولية للمنتقي: تُبنى من المصفوفة كاملة قبل أي اقتطاع حتى
    // يبقى فهرسها مطابقاً لرقم الصف الحقيقي في الملف.
    final List<List<String>> samples = trimmed
        .take(sampleRowLimit)
        .map(List<String>.unmodifiable)
        .toList(growable: false);

    // أول صف غير فارغ — يُستخدم كافتراض عندما لا يختار المستخدم صفاً بعينه.
    final int firstFilled = trimmed.indexWhere(
      (List<String> row) => row.any((String cell) => cell.isNotEmpty),
    );
    if (firstFilled < 0) {
      return SheetData(
        headers: const <String>[],
        rows: const <List<String>>[],
        sourceName: sourceName,
        sheetName: sheetName,
        notes: const <String>['الملف لا يحتوي أي بيانات.'],
        rowSamples: samples,
      );
    }

    // الصف الفعلي للعناوين: اختيار المستخدم إن وُجد (مقيّداً بحدود المصفوفة)،
    // وإلا أول صف غير فارغ (السلوك التلقائي السابق).
    final int headerIndex = headerRowIndex == null
        ? firstFilled
        : headerRowIndex.clamp(0, trimmed.length - 1);
    if (headerRowIndex != null && headerIndex > 0) {
      notes.add('اعتُبر الصف ${headerIndex + 1} صفَ العناوين بناءً على اختيارك؛ '
          'أُهمل ما قبله.');
    } else if (headerRowIndex == null && firstFilled > 0) {
      notes.add('أُسقطت $firstFilled صف/صفوف فارغة قبل العناوين.');
    }
    final List<List<String>> body = trimmed.sublist(headerIndex);

    final List<String> headers = _normalizeHeaders(body.first, notes);
    final int width = headers.length;

    final List<List<String>> rows = <List<String>>[];
    int droppedBlank = 0;
    for (final List<String> raw in body.skip(1)) {
      if (raw.every((String cell) => cell.isEmpty)) {
        droppedBlank++;
        continue;
      }
      rows.add(_fit(raw, width));
    }
    if (droppedBlank > 0) {
      notes.add('أُسقط $droppedBlank صف/صفوف فارغة تماماً.');
    }
    if (rows.isEmpty) {
      notes.add('لا توجد صفوف بيانات بعد صف العناوين.');
    }

    return SheetData(
      headers: headers,
      rows: rows,
      sourceName: sourceName,
      sheetName: sheetName,
      notes: notes,
      headerRowIndex: headerIndex,
      rowSamples: samples,
    );
  }

  static List<String> _normalizeHeaders(List<String> raw, List<String> notes) {
    int lastFilled = -1;
    for (int i = 0; i < raw.length; i++) {
      if (raw[i].isNotEmpty) lastFilled = i;
    }
    if (lastFilled < 0) return const <String>[];

    final List<String> out = <String>[];
    final Map<String, int> seen = <String, int>{};
    int renamed = 0;
    for (int i = 0; i <= lastFilled; i++) {
      String name = raw[i];
      if (name.isEmpty) {
        name = 'عمود ${i + 1}';
        renamed++;
      }
      final int count = seen[name] ?? 0;
      seen[name] = count + 1;
      if (count > 0) {
        name = '$name ($count)';
      }
      out.add(name);
    }
    if (renamed > 0) {
      notes.add('أُعيدت تسمية $renamed عمود/أعمدة بلا عنوان '
          'بصيغة «عمود رقم».');
    }
    return out;
  }

  static List<String> _fit(List<String> row, int width) {
    if (row.length == width) return List<String>.unmodifiable(row);
    if (row.length > width) {
      return List<String>.unmodifiable(row.sublist(0, width));
    }
    return List<String>.unmodifiable(<String>[
      ...row,
      ...List<String>.filled(width - row.length, ''),
    ]);
  }

  bool get isEmpty => headers.isEmpty;
  bool get isNotEmpty => !isEmpty;

  int get rowCount => rows.length;
  int get columnCount => headers.length;

  SheetRow rowAt(int index) => SheetRow(
        index: index,
        headers: headers,
        cells: rows[index],
        headerRowNumber: headerRowIndex + 1,
      );

  Iterable<SheetRow> get sheetRows sync* {
    for (int i = 0; i < rows.length; i++) {
      yield rowAt(i);
    }
  }

  /// الأعمدة التي تحمل بيانات فعلية في صف واحد على الأقل.
  ///
  /// تُستخدم لإخفاء أعمدة Excel الفارغة (المستوردة من تنسيقات سابقة) عن واجهة
  /// الربط فلا تُشوّش على المستخدم.
  List<int> get dataColumns {
    final List<int> columns = <int>[];
    for (int c = 0; c < columnCount; c++) {
      final bool hasData = rows.any((List<String> row) => row[c].isNotEmpty);
      if (hasData) columns.add(c);
    }
    return columns;
  }

  /// نسخة بعناوين مختلفة (لتعديل عنوان عمود من الواجهة).
  SheetData withHeaders(List<String> newHeaders) => SheetData(
        headers: List<String>.unmodifiable(newHeaders),
        rows: rows,
        sourceName: sourceName,
        sheetName: sheetName,
        notes: notes,
        headerRowIndex: headerRowIndex,
        rowSamples: rowSamples,
      );
}

/// صف واحد من الورقة — واجهة مريحة للقراءة بالعمود أو بالعنوان.
class SheetRow {
  const SheetRow({
    required this.index,
    required this.headers,
    required this.cells,
    this.headerRowNumber = 1,
  });

  /// فهرس الصف داخل [SheetData.rows] (يبدأ من صفر).
  final int index;

  final List<String> headers;
  final List<String> cells;

  /// رقم صف العناوين في Excel (يبدأ من 1). يكون `1` عندما تبدأ العناوين من
  /// الصف الأول، و`3` إذا اختار المستخدم أن تبدأ من الصف الثالث مثلاً.
  final int headerRowNumber;

  /// رقم الصف كما يراه المستخدم في Excel: يبدأ بعد صف العناوين مباشرةً
  /// (‏+1 للصف نفسه و+1 بسبب أن الفهرس يبدأ من صفر).
  int get displayNumber => index + headerRowNumber + 1;

  int get columnCount => cells.length;

  String cellAt(int column) =>
      column >= 0 && column < cells.length ? cells[column] : '';

  /// قيمة العمود بعنوانه، أو `''` إن لم يوجد العمود.
  String cell(String header) {
    final int column = headers.indexOf(header);
    return column < 0 ? '' : cellAt(column);
  }

  bool get isBlank => cells.every((String cell) => cell.isEmpty);

  int get filledCount =>
      cells.where((String cell) => cell.isNotEmpty).length;

  /// فهارس الأعمدة الفارغة في هذا الصف.
  List<int> get blankColumns => <int>[
        for (int i = 0; i < cells.length; i++)
          if (cells[i].isEmpty) i,
      ];

  Map<String, String> toMap({bool skipEmpty = false}) {
    final Map<String, String> map = <String, String>{};
    for (int i = 0; i < headers.length && i < cells.length; i++) {
      final String header = headers[i];
      if (header.isEmpty) continue;
      if (skipEmpty && cells[i].isEmpty) continue;
      map[header] = cells[i];
    }
    return map;
  }

  @override
  String toString() =>
      'SheetRow($displayNumber, ${cells.join(' | ')})';
}
