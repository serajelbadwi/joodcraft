import 'jood_writer_block.dart';

/// يقيس كتلة عند عرض محتوى معيّن: أسطرها بعد الالتفاف، وارتفاع سطرها،
/// والمسافات قبلها/بعدها.
///
/// **فصل القياس عن التدفّق مقصود**: التدفّق خوارزمية خالصة قابلة للاختبار بلا
/// خطوط ولا واجهة، والطبقة الرسومية تمرّر [TextPainterBlockMeasurer] الذي
/// يقيس بـ`TextPainter`. وفي الاختبارات يُحقن مُقاس ثابت فتُختبر الحدود والفيض
/// بدقّة حتمية.
abstract interface class BlockMeasurer {
  /// أسطر الكتلة كما ستُرسم (سطر واحد على الأقل، ولو فارغة).
  List<String> linesOf(JoodWriterBlock block);

  /// ارتفاع السطر الواحد لهذه الكتلة.
  double lineHeightOf(JoodWriterBlock block);

  /// مسافة تُضاف قبل الكتلة (لا تُحتسب في رأس الصفحة).
  double spacingBeforeOf(JoodWriterBlock block);

  /// مسافة تُضاف بعد الكتلة.
  double spacingAfterOf(JoodWriterBlock block);
}

/// مقطع من كتلة وقع على صفحة: الأسطر `[lineStart, lineEnd)` من `block`.
class JoodPageSlice {
  // ملاحظة: ليس `const` عن قصد — [_lineTotal] يُضبط عبر [of] بعد البناء.
  JoodPageSlice({
    required this.blockIndex,
    required this.block,
    required this.lineStart,
    required this.lineEnd,
  });

  final int blockIndex;
  final JoodWriterBlock block;
  final int lineStart;
  final int lineEnd;

  /// عدد الأسطر في المقطع.
  int get lineCount => lineEnd - lineStart;

  /// هل يبدأ المقطع الكتلة من أولها؟ (يُقرأ لعرض النقاط/العناوين مرة واحدة)
  bool get isBlockStart => lineStart == 0;

  /// هل ينهي المقطع الكتلة عند آخر سطر منها؟
  bool get isBlockEnd => lineEnd >= _lineTotal;

  // يُضبط عند البناء؛ صفر يعني «غير معروف» فيُعتبر نهايةً.
  int _lineTotal = 0;

  /// ينشئ مقطعاً مع معرفة إجمالي أسطر الكتلة (لحساب [isLast]).
  static JoodPageSlice of({
    required int blockIndex,
    required JoodWriterBlock block,
    required int lineStart,
    required int lineEnd,
    required int lineTotal,
  }) {
    final JoodPageSlice slice = JoodPageSlice(
      blockIndex: blockIndex,
      block: block,
      lineStart: lineStart,
      lineEnd: lineEnd,
    );
    slice._lineTotal = lineTotal;
    return slice;
  }
}

/// صفحة واحدة بعد التدفّق: مقاطع مرتّبة كما تُرسم من أعلى لأسفل.
class JoodPage {
  JoodPage(this.slices);

  final List<JoodPageSlice> slices;

  bool get isEmpty => slices.isEmpty;

  /// الأرقام التسلسلية للكتل التي بدأت على هذه الصفحة (لتصحيح الترقيم).
  Iterable<int> get blockIndexes =>
      slices.map((JoodPageSlice s) => s.blockIndex);
}

/// محرّك تدفّق الصفحات: يوزّع كتل المستند على صفحات بارتفاع محتوى ثابت،
/// ويولّد صفحة جديدة تلقائياً عند فيض الأسطر.
abstract final class FlowPaginator {
  /// يدفّق [blocks] على صفحات ارتفاع منطقة محتواها [contentHeight].
  ///
  /// * إن لم تتّسع الكتلة كاملةً، تُشطر أسطرها ويُكمَل الباقي في صفحة تالية.
  /// * إن لم يتّسع سطر واحد في صفحة فارغة (ارتفاع أصغر من سطر)، يوضع السطر
  ///   على الصفحة على أي حال حتى لا يدور التدفّق بلا نهاية.
  /// * المسافة قبل الكتلة تُهمَل في رأس الصفحة؛ والمسافة بعدها تُخصم بعد آخر سطر.
  static List<JoodPage> paginate({
    required List<JoodWriterBlock> blocks,
    required double contentHeight,
    required BlockMeasurer measurer,
    double topPaddingBuffer = 10.0,
    double bottomPaddingBuffer = 20.0, // لحماية التذييل وترقيم الصفحات
  }) {
    final List<JoodPage> pages = <JoodPage>[];
    List<JoodPageSlice> current = <JoodPageSlice>[];
    final double safeContentHeight =
        contentHeight - topPaddingBuffer - bottomPaddingBuffer;
    double remaining = safeContentHeight;

    void flush() {
      if (current.isNotEmpty) pages.add(JoodPage(current));
      current = <JoodPageSlice>[];
      remaining = safeContentHeight;
    }

    for (int index = 0; index < blocks.length; index++) {
      final JoodWriterBlock block = blocks[index];
      // فاصل صفحات يدوي: تبدأ هذه الكتلة صفحة جديدة دائماً مهما بقي مساحة
      // في الصفحة السابقة (زر «فاصل صفحات»).
      if (index > 0 && block.pageBreakBefore) flush();
      final List<String> lines = measurer.linesOf(block);
      final List<String> safeLines = lines.isEmpty ? const <String>[''] : lines;
      final double lineHeight = measurer.lineHeightOf(block);
      final double safeLineHeight = lineHeight <= 0 ? 1 : lineHeight;
      final double before = measurer.spacingBeforeOf(block);
      final double after = measurer.spacingAfterOf(block);

      int cursor = 0;
      // المسافة قبل الكتلة: تُحتسب فقط إن كانت الصفحة تحمل محتوىً بالفعل.
      if (current.isNotEmpty) remaining -= before;

      while (cursor < safeLines.length) {
        // لا يتّسع سطر في صفحة فيها محتوى ⇒ صفحة جديدة قبل المتابعة.
        if (remaining < safeLineHeight && current.isNotEmpty) {
          flush();
          continue;
        }

        // ضمان عدم قطع أسطر بنصفين (Strict Page Boundary).
        // السطر الذي لا يتسع كاملاً، يرحل للصفحة التالية بالكامل.
        int fit = (remaining / safeLineHeight).floor();

        // إذا كان السطر لا يتسع في هذه المساحة والصفحة تحمل محتوى، نرّحله.
        if (fit < 1 && current.isNotEmpty) {
          flush();
          continue;
        } else if (fit < 1) {
          // في حال كانت الصفحة فارغة جداً والسطر أطول منها أصلاً نمرره لكي نمنع الحلقة اللانهائية
          fit = 1;
        }
        final int count = (cursor + fit > safeLines.length)
            ? safeLines.length - cursor
            : fit;

        current.add(
          JoodPageSlice.of(
            blockIndex: index,
            block: block,
            lineStart: cursor,
            lineEnd: cursor + count,
            lineTotal: safeLines.length,
          ),
        );
        remaining -= count * safeLineHeight;
        cursor += count;

        // بقي من الكتلة أسطر ⇒ الفيض إلى صفحة جديدة.
        if (cursor < safeLines.length) flush();
      }

      remaining -= after;
      // مسافة بعد الكتلة قد تستهلك آخر الصفحة تماماً ⇒ صفحة تالية نظيفة.
      if (remaining <= 0 && index < blocks.length - 1) flush();
    }

    flush();
    if (pages.isEmpty) pages.add(JoodPage(<JoodPageSlice>[]));
    return pages;
  }
}
