import 'package:flutter/foundation.dart' show immutable;

/// مقاس ورقة الطباعة المستهدفة (بالمليمتر).
///
/// الأبعاد مخزّنة **بالطول** (العرض الأصغر أولاً) كما تُوصف الأوراق تجارياً،
/// ويُقلب الاتجاه عند الطلب عبر `sheetLandscape` في [ImpositionCalculator].
enum ImpositionSheet {
  /// A4 — 210×297 ملم.
  a4('A4', 210, 297),

  /// A3 — 297×420 ملم.
  a3('A3', 297, 420),

  /// ربع فرخ — 350×500 ملم.
  quarter('ربع فرخ', 350, 500);

  const ImpositionSheet(this.labelAr, this.widthMm, this.heightMm);

  final String labelAr;

  /// العرض بالطول (المليمتر).
  final double widthMm;

  /// الارتفاع بالطول (المليمتر).
  final double heightMm;

  /// المساحة الكلية للورقة (ملم²).
  double get areaMm2 => widthMm * heightMm;
}

/// نسخة واحدة من العنصر بعد حصرها على الورقة.
///
/// الإحداثيات **من الزاوية العليا اليسرى للورقة** وبالمليمتر، و[widthMm]/
/// [heightMm] هي أبعاد النسخة **كما ستُرسم** (أي بعد أي تدوير 90°).
@immutable
class ImpositionPlacement {
  const ImpositionPlacement({
    required this.index,
    required this.row,
    required this.column,
    required this.leftMm,
    required this.topMm,
    required this.widthMm,
    required this.heightMm,
    required this.rotated,
  });

  /// ترتيب النسخة (من 0) بترتيب الصفوف ثم الأعمدة.
  final int index;

  /// الصف (0 = الأعلى).
  final int row;

  /// العمود (0 = الأيسر).
  final int column;

  /// إحداثي X للزاوية العليا اليسرى.
  final double leftMm;

  /// إحداثي Y للزاوية العليا اليسرى.
  final double topMm;

  /// عرض النسخة كما ستُرسم.
  final double widthMm;

  /// ارتفاع النسخة كما ستُرسم.
  final double heightMm;

  /// هل دُوّرت هذه النسخة 90° عن أبعادها الأصلية؟
  final bool rotated;

  double get rightMm => leftMm + widthMm;
  double get bottomMm => topMm + heightMm;

  @override
  String toString() => 'ImpositionPlacement(#$index r$row c$column '
      '@(${leftMm.toStringAsFixed(2)}, ${topMm.toStringAsFixed(2)}) '
      '${widthMm.toStringAsFixed(2)}×${heightMm.toStringAsFixed(2)}'
      '${rotated ? ' ↻' : ''})';
}

/// نتيجة الحصر الكاملة لورقة واحدة.
@immutable
class ImpositionResult {
  const ImpositionResult({
    required this.sheet,
    required this.sheetLandscape,
    required this.itemWidthMm,
    required this.itemHeightMm,
    required this.gutterXMm,
    required this.gutterYMm,
    required this.marginMm,
    required this.bleedMm,
    required this.columns,
    required this.rows,
    required this.rotated,
    required this.placements,
  });

  final ImpositionSheet sheet;

  /// هل قُلبت الورقة (استُخدم ارتفاعها عرضاً)؟
  final bool sheetLandscape;

  /// أبعاد العنصر الأصلية كما أُدخلت.
  final double itemWidthMm;
  final double itemHeightMm;

  final double gutterXMm;
  final double gutterYMm;

  /// هامش الورقة من كل حافة.
  final double marginMm;

  /// احتياط النزف (bleed) المضاف إلى الهامش من كل حافة.
  final double bleedMm;

  /// أقصى عدد أعمدة في الشبكة.
  final int columns;

  /// أقصى عدد صفوف في الشبكة.
  final int rows;

  /// هل اختير تدوير العناصر 90°؟ (لأنه يستوعب نسخاً أكثر)
  final bool rotated;

  /// النسخ مرتّبة صفاً صفاً — كل عنصر بإحداثياته وصندوقه.
  final List<ImpositionPlacement> placements;

  /// أقصى عدد نسخ تُطبع على الورقة الواحدة.
  int get count => placements.length;

  bool get isEmpty => placements.isEmpty;

  /// عرض الورقة الفعّال بعد مراعاة `sheetLandscape`.
  double get sheetWidthMm => sheetLandscape ? sheet.heightMm : sheet.widthMm;

  /// ارتفاع الورقة الفعّال بعد مراعاة `sheetLandscape`.
  double get sheetHeightMm => sheetLandscape ? sheet.widthMm : sheet.heightMm;

  /// إجمالي المسافة المُستقطعة من كل حافة (الهامش + الاحتياط).
  double get insetMm => marginMm + bleedMm;

  /// المساحة الصالحة للطباعة داخل الهامش والاحتياط.
  double get usableWidthMm => sheetWidthMm - 2 * insetMm;

  /// المساحة الصالحة للطباعة داخل الهامش والاحتياط.
  double get usableHeightMm => sheetHeightMm - 2 * insetMm;

  /// عرض الخلية الواحدة بعد أي تدوير.
  double get cellWidthMm => rotated ? itemHeightMm : itemWidthMm;

  /// ارتفاع الخلية الواحدة بعد أي تدوير.
  double get cellHeightMm => rotated ? itemWidthMm : itemHeightMm;

  /// عرض الشبكة الفعلي المستخدم (بلا الهامش) شامل الفواصل الداخلية.
  double get usedWidthMm => columns == 0
      ? 0
      : columns * cellWidthMm + (columns - 1) * gutterXMm;

  /// ارتفاع الشبكة الفعلي المستخدم (بلا الهامش) شامل الفواصل الداخلية.
  double get usedHeightMm =>
      rows == 0 ? 0 : rows * cellHeightMm + (rows - 1) * gutterYMm;

  /// ما يتبقّى من عرض الورقة الصالح بعد الشبكة (للتوسيط أو التحقّق).
  double get surplusWidthMm => usableWidthMm - usedWidthMm;

  /// ما يتبقّى من ارتفاع الورقة الصالح بعد الشبكة.
  double get surplusHeightMm => usableHeightMm - usedHeightMm;

  /// نسبة استغلال الورقة = مساحة العناصر المطبوعة ÷ مساحة الورقة الكاملة.
  double get coverage {
    final double area = sheetWidthMm * sheetHeightMm;
    if (area <= 0) return 0;
    return count * itemWidthMm * itemHeightMm / area;
  }

  /// أقصى إحداثي أفقي تصل إليه أي نسخة.
  double get maxRightMm => placements.isEmpty
      ? 0
      : placements
          .map((ImpositionPlacement p) => p.rightMm)
          .reduce((double a, double b) => a > b ? a : b);

  /// أقصى إحداثي رأسي تصل إليه أي نسخة.
  double get maxBottomMm => placements.isEmpty
      ? 0
      : placements
          .map((ImpositionPlacement p) => p.bottomMm)
          .reduce((double a, double b) => a > b ? a : b);
}

/// محرّك الحصر الرياضي (Imposition) — يحوّل مقاس عنصر واحد إلى شبكة كاملة
/// على ورقة الطباعة.
///
/// **المدخلات:** أبعاد العنصر، مقاس الورقة، الفواصل الأفقية/الرأسية بين
/// النسخ، وهامش الورقة مع احتياط النزف (bleed).
///
/// **الحساب:** يُستقطع `(الهامش + الاحتياط)` من كل حافة، ثم يُحسب أقصى عدد
/// أعمدة وصفوف تنطبق بالكامل داخل المساحة الصالحة:
///
/// ```text
/// الأعمدة = ⌊(العرض الصالح + الفاصل الأفقي) ÷ (عرض العنصر + الفاصل الأفقي)⌋
/// الصفوف  = ⌊(الارتفاع الصالح + الفاصل الرأسي) ÷ (ارتفاع العنصر + الفاصل الرأسي)⌋
/// ```
///
/// الصيغة `(الصالح + الفاصل) ÷ (العنصر + الفاصل)` هي صيغة التوزيع القياسية:
/// تتحوّل إلى `⌊الصالح ÷ العنصر⌋` عند غياب الفاصل، وتصلح للفواصل الموجبة.
///
/// **التدوير التلقائي:** تُحسب الشبكة مرّتين — بأبعاد العنصر كما هي، وبأبعاده
/// مدوّرة 90° — ويُختار التوزيع الأكثر استيعاباً للنسخ (والأصل عند التعادل،
/// فيبقى الناتج ثابتاً وقابلاً للاختبار).
///
/// **المخرجات:** [ImpositionResult] تحمل عدد الأعمدة والصفوف وهل دُوّرت
/// النسخ، وقائمة [ImpositionPlacement] بإحداثي X/Y الدقيق لكل نسخة وصندوقها.
abstract final class ImpositionCalculator {
  const ImpositionCalculator._();

  /// هامش أمان ضدّ خطأ الفاصلة العائمة عند المطابقة التامة
  /// (‏`floor` لنتيجة ‎197/98.5‎ يجب أن تعطي 2 لا 1).
  static const double _epsilon = 1e-9;

  static ImpositionResult calculate({
    required double itemWidthMm,
    required double itemHeightMm,
    required ImpositionSheet sheet,
    double gutterXMm = 0,
    double gutterYMm = 0,
    double marginMm = 0,
    double bleedMm = 0,
    bool allowRotation = true,
    bool sheetLandscape = false,
  }) {
    if (itemWidthMm <= 0 || itemHeightMm <= 0) {
      throw ArgumentError.value(
        'الأبعاد',
        'itemWidthMm/itemHeightMm',
        'أبعاد العنصر يجب أن تكون موجبة (وُجد: $itemWidthMm×$itemHeightMm).',
      );
    }
    if (gutterXMm < 0 || gutterYMm < 0) {
      throw ArgumentError.value(
        'الفواصل',
        'gutterXMm/gutterYMm',
        'الفواصل لا يمكن أن تكون سالبة.',
      );
    }
    if (marginMm < 0 || bleedMm < 0) {
      throw ArgumentError.value(
        'الهامش/الاحتياط',
        'marginMm/bleedMm',
        'الهامش والاحتياط لا يمكن أن يكونا سالبين.',
      );
    }

    final double sheetWidth = sheetLandscape ? sheet.heightMm : sheet.widthMm;
    final double sheetHeight = sheetLandscape ? sheet.widthMm : sheet.heightMm;
    final double inset = marginMm + bleedMm;
    final double usableWidth = sheetWidth - 2 * inset;
    final double usableHeight = sheetHeight - 2 * inset;

    final _Grid straight = _fit(
      cellWidth: itemWidthMm,
      cellHeight: itemHeightMm,
      usableWidth: usableWidth,
      usableHeight: usableHeight,
      gutterX: gutterXMm,
      gutterY: gutterYMm,
    );
    final _Grid turned = allowRotation
        ? _fit(
            cellWidth: itemHeightMm,
            cellHeight: itemWidthMm,
            usableWidth: usableWidth,
            usableHeight: usableHeight,
            gutterX: gutterXMm,
            gutterY: gutterYMm,
          )
        : const _Grid(columns: 0, rows: 0, cellWidth: 0, cellHeight: 0);

    // التدوير يُختار فقط إن زاد النسخ فعلاً؛ التعادل يبقي الأصل.
    final bool rotated = turned.count > straight.count;
    final _Grid grid = rotated ? turned : straight;

    final List<ImpositionPlacement> placements = <ImpositionPlacement>[];
    for (int row = 0; row < grid.rows; row++) {
      for (int column = 0; column < grid.columns; column++) {
        placements.add(
          ImpositionPlacement(
            index: row * grid.columns + column,
            row: row,
            column: column,
            leftMm: inset + column * (grid.cellWidth + gutterXMm),
            topMm: inset + row * (grid.cellHeight + gutterYMm),
            widthMm: grid.cellWidth,
            heightMm: grid.cellHeight,
            rotated: rotated,
          ),
        );
      }
    }

    return ImpositionResult(
      sheet: sheet,
      sheetLandscape: sheetLandscape,
      itemWidthMm: itemWidthMm,
      itemHeightMm: itemHeightMm,
      gutterXMm: gutterXMm,
      gutterYMm: gutterYMm,
      marginMm: marginMm,
      bleedMm: bleedMm,
      columns: grid.columns,
      rows: grid.rows,
      rotated: rotated,
      placements: List<ImpositionPlacement>.unmodifiable(placements),
    );
  }

  /// يحسب شبكة واحدة بأبعاد خلية محدّدة (بلا تدوير).
  static _Grid _fit({
    required double cellWidth,
    required double cellHeight,
    required double usableWidth,
    required double usableHeight,
    required double gutterX,
    required double gutterY,
  }) {
    if (cellWidth <= 0 ||
        cellHeight <= 0 ||
        usableWidth <= 0 ||
        usableHeight <= 0) {
      return const _Grid(columns: 0, rows: 0, cellWidth: 0, cellHeight: 0);
    }
    final int columns = _axisCount(usableWidth, cellWidth, gutterX);
    final int rows = _axisCount(usableHeight, cellHeight, gutterY);
    // لا شبكة إن لم ينطبق عنصر واحد على أحد المحورين: لو أُبقي المحور الثاني
    // وحده (‎0×1‎) لظهر صفّ «شبحي» يُظهر `usedHeightMm` موجباً مع `count = 0`.
    if (columns == 0 || rows == 0) {
      return const _Grid(columns: 0, rows: 0, cellWidth: 0, cellHeight: 0);
    }
    return _Grid(
      columns: columns,
      rows: rows,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
    );
  }

  /// عدد الوحدات التي تنطبق على محور واحد: `⌊(الصالح + الفاصل) ÷ (الوحدة + الفاصل)⌋`.
  static int _axisCount(double usable, double cell, double gutter) {
    final double step = cell + gutter;
    if (step <= 0) return 0;
    final int count = ((usable + gutter) / step + _epsilon).floor();
    return count < 0 ? 0 : count;
  }
}

/// شبكة محسوبة على محورين (نتيجة وسيطة داخلية).
@immutable
class _Grid {
  const _Grid({
    required this.columns,
    required this.rows,
    required this.cellWidth,
    required this.cellHeight,
  });

  final int columns;
  final int rows;
  final double cellWidth;
  final double cellHeight;

  int get count => columns * rows;
}
