import 'jood_writer_block.dart';
import 'writer_image.dart';
import 'writer_shape.dart';

/// محاذاة رقم الصفحة في تذييل الصفحة (يمين/وسط/يسار فعلياً).
enum PageNumberAlign {
  right('يمين', 'right'),
  center('وسط', 'center'),
  left('يسار', 'left');

  const PageNumberAlign(this.labelAr, this.jsonValue);
  final String labelAr;
  final String jsonValue;

  static PageNumberAlign fromJson(String? value) {
    for (final PageNumberAlign align in values) {
      if (align.jsonValue == value) return align;
    }
    return PageNumberAlign.center;
  }
}

/// نمط عرض رقم الصفحة.
enum PageNumberPattern {
  pageOfTotal('صفحة X من Y', 'pageOfTotal'),
  pageOnly('صفحة X', 'pageOnly'),
  plain('X فقط', 'plain'),
  slash('X / Y', 'slash');

  const PageNumberPattern(this.labelAr, this.jsonValue);
  final String labelAr;
  final String jsonValue;

  static PageNumberPattern fromJson(String? value) {
    for (final PageNumberPattern pattern in values) {
      if (pattern.jsonValue == value) return pattern;
    }
    return PageNumberPattern.pageOfTotal;
  }
}

class PageNumberingConfig {
  const PageNumberingConfig({
    this.enabled = true,
    this.startPage = 1,
    this.excludeFirstN = 0,
    this.fontSize = 10,
    this.color,
    this.align = PageNumberAlign.center,
    this.pattern = PageNumberPattern.pageOfTotal,
  });

  final bool enabled;

  /// رقم أول صفحة مرقّمة (لبدء الترقيم من رقم معيّن).
  final int startPage;

  /// عدد الصفحات الأولى المستثناة من الترقيم (غلاف أو مقدّمات).
  final int excludeFirstN;

  /// حجم خط الرقم (بكسل منطقي).
  final double fontSize;

  /// لون الرقم (ARGB)؛ `null` = الرمادي الافتراضي.
  final int? color;

  final PageNumberAlign align;
  final PageNumberPattern pattern;

  PageNumberingConfig copyWith({
    bool? enabled,
    int? startPage,
    int? excludeFirstN,
    double? fontSize,
    int? color,
    bool clearColor = false,
    PageNumberAlign? align,
    PageNumberPattern? pattern,
  }) {
    return PageNumberingConfig(
      enabled: enabled ?? this.enabled,
      startPage: startPage ?? this.startPage,
      excludeFirstN: excludeFirstN ?? this.excludeFirstN,
      fontSize: fontSize ?? this.fontSize,
      color: clearColor ? null : (color ?? this.color),
      align: align ?? this.align,
      pattern: pattern ?? this.pattern,
    );
  }

  /// هل تُرقَّم هذه الصفحة؟ (بفهرسها الابتدائي من الصفر)
  bool shouldNumberPage(int pageIndex) => enabled && pageIndex >= excludeFirstN;

  /// رقم الصفحة المعروض: يستأنف الترقيم بعد الصفحات المستثناة.
  int displayNumber(int pageIndex) => startPage + pageIndex - excludeFirstN;

  /// عدد الصفحات المرقّمة إجمالاً (الكلّ ناقص المستثناة).
  int numberedTotal(int totalPages) {
    final int total = totalPages - excludeFirstN;
    return total < 0 ? 0 : total;
  }

  /// نص التذييل حسب النمط المختار: «صفحة X من Y» أو «صفحة X» أو «X» أو «X / Y».
  String labelFor(int pageIndex, int totalPages) {
    final String x = '${displayNumber(pageIndex)}';
    final String y = '${numberedTotal(totalPages)}';
    switch (pattern) {
      case PageNumberPattern.pageOfTotal:
        return 'صفحة $x من $y';
      case PageNumberPattern.pageOnly:
        return 'صفحة $x';
      case PageNumberPattern.plain:
        return x;
      case PageNumberPattern.slash:
        return '$x / $y';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PageNumberingConfig &&
      other.enabled == enabled &&
      other.startPage == startPage &&
      other.excludeFirstN == excludeFirstN &&
      other.fontSize == fontSize &&
      other.color == color &&
      other.align == align &&
      other.pattern == pattern;

  @override
  int get hashCode => Object.hash(
    enabled,
    startPage,
    excludeFirstN,
    fontSize,
    color,
    align,
    pattern,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'startPage': startPage,
    'excludeFirstN': excludeFirstN,
    'fontSize': fontSize,
    if (color != null) 'color': color,
    'align': align.jsonValue,
    'pattern': pattern.jsonValue,
  };

  static PageNumberingConfig fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PageNumberingConfig();
    return PageNumberingConfig(
      enabled: json['enabled'] as bool? ?? true,
      startPage: json['startPage'] as int? ?? 1,
      excludeFirstN: json['excludeFirstN'] as int? ?? 0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 10,
      color: json['color'] is int ? json['color'] as int : null,
      align: PageNumberAlign.fromJson(json['align'] as String?),
      pattern: PageNumberPattern.fromJson(json['pattern'] as String?),
    );
  }
}

/// اتجاه الورقة.
enum WriterOrientation {
  portrait('رأسي', 'portrait'),
  landscape('أفقي', 'landscape');

  const WriterOrientation(this.labelAr, this.jsonValue);
  final String labelAr;
  final String jsonValue;

  static WriterOrientation fromJson(String? value) {
    if (value == 'landscape') return WriterOrientation.landscape;
    return WriterOrientation.portrait;
  }
}

/// تقسيم صفحة المحرّر إلى نصفين — «A4 → 2 × A5».
///
/// **الفكرة:** ورقة المحرّر المنطقية تتقلّص إلى نصف A4 (أي A5) فيتدفّق النصّ
/// من الصفحة الأولى إلى الثانية تلقائياً عبر [FlowPaginator]. وعند الطباعة
/// تُجمَع صفحتان متتاليتان على ورقة A4 واحدة (انظر [printImposition]).
///
/// | الوضع | صفحة المحرّر | ورقة الطباعة | الأثر |
/// |---|---|---|---|
/// | [single] | كما هي | A4 كما هو | عادي |
/// | [twoUpPortrait] | A5 (عرض A4 × نصف ارتفاعه) | A4 رأسية، نصفان فوق بعض | كتيّب يُطوى أفقياً |
/// | [twoUpLandscape] | A5 (نصف عرض A4 × ارتفاعه) | A4 عرضية، نصفان جنب بعض | كتيّب يُطوى عمودياً |
enum WriterPageLayout {
  /// صفحة واحدة كاملة بلا تقسيم.
  single('عادي (صفحة واحدة)', 'single'),

  /// A4 ← 2 × A5 طولي (كتيّب).
  twoUpPortrait('A4 → 2 × A5 طولي (كتيّب)', 'twoUpPortrait'),

  /// A4 ← 2 × A5 عرضي.
  twoUpLandscape('A4 → 2 × A5 عرضي', 'twoUpLandscape');

  const WriterPageLayout(this.labelAr, this.jsonValue);
  final String labelAr;

  /// القيمة المخزّنة في JSON (تظل ثابتة عبر الإصدارات).
  final String jsonValue;

  /// هل يُنتج هذا الوضع نصفَي صفحة بدل صفحة واحدة؟
  bool get splitsPage => this != WriterPageLayout.single;

  static WriterPageLayout fromJson(String? value) {
    for (final WriterPageLayout layout in values) {
      if (layout.jsonValue == value) return layout;
    }
    return WriterPageLayout.single;
  }
}

/// مقاس ورقة مستند «جود كاتب» (مليمتر) — A4 رأسي افتراضاً.
class JoodWriterPageSize {
  const JoodWriterPageSize({
    required this.widthMm,
    required this.heightMm,
    required this.label,
  });

  final double widthMm;
  final double heightMm;
  final String label;

  static const JoodWriterPageSize a4 = JoodWriterPageSize(
    widthMm: 210,
    heightMm: 297,
    label: 'A4',
  );
  static const JoodWriterPageSize a3 = JoodWriterPageSize(
    widthMm: 297,
    heightMm: 420,
    label: 'A3',
  );
  static const JoodWriterPageSize letter = JoodWriterPageSize(
    widthMm: 215.9,
    heightMm: 279.4,
    label: 'Letter',
  );
  static const JoodWriterPageSize legal = JoodWriterPageSize(
    widthMm: 215.9,
    heightMm: 355.6,
    label: 'Legal',
  );

  /// نصف A4 — الصفحة الواحدة عند تفعيل «A4 -> 2 x A5».
  ///
  /// النسبة من الورقة نفسها لا ثابت بصري: يضمن ان النصفين يعيدانان ابعاد
  /// الورقة بالضبط عند التجميع، فلا يبقى فراغ ولا يفيض المحتوى.
  ///
  /// كلا الوضعين يطبعان على ورقة **A4 رأسية** (210x297):
  /// * [WriterPageLayout.twoUpPortrait] — طيّ **افقي**: النصفان فوق بعض،
  ///   فالصفحة 210x148.5 (A5 افقي) — كتيّب يطوى ا水平ياً.
  /// * [WriterPageLayout.twoUpLandscape] — طيّ **عمودي**: النصفان جنب بعض،
  ///   فالصفحة 105x297 (A5 رأسي) — كتيّب يطوى عمودياً.
  static JoodWriterPageSize halfOf(
    JoodWriterPageSize page,
    WriterPageLayout layout,
  ) {
    if (!layout.splitsPage) return page;
    // الطولي: الشقّ افقي ⇒ الارتفاع نصفه.
    if (layout == WriterPageLayout.twoUpPortrait) {
      return JoodWriterPageSize(
        widthMm: page.widthMm,
        heightMm: page.heightMm / 2,
        label: '${page.label}1/2',
      );
    }
    // العرضي: الشقّ عمودي ⇒ العرض نصفه.
    return JoodWriterPageSize(
      widthMm: page.widthMm / 2,
      heightMm: page.heightMm,
      label: '${page.label}1/2',
    );
  }
  /// كل الأحجام المدعومة.
  static const List<JoodWriterPageSize> all = <JoodWriterPageSize>[
    a4,
    a3,
    letter,
    legal,
  ];

  /// يعيد الحجم مع تبديل العرض والارتفاع عند الاتجاه الأفقي.
  JoodWriterPageSize oriented(WriterOrientation orientation) {
    if (orientation == WriterOrientation.landscape) {
      return JoodWriterPageSize(
        widthMm: heightMm,
        heightMm: widthMm,
        label: label,
      );
    }
    return this;
  }

  double get aspectRatio => widthMm / heightMm;

  static JoodWriterPageSize fromLabel(String? label) {
    for (final JoodWriterPageSize size in all) {
      if (size.label == label) return size;
    }
    return a4;
  }
}

/// هوامش الصفحة (مليمتر).
class JoodWriterMargins {
  const JoodWriterMargins({
    this.top = 25,
    this.right = 20,
    this.bottom = 25,
    this.left = 20,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  /// ارتفاع منطقة المحتوى الفعلي داخل الورقة.
  double contentHeightMm(JoodWriterPageSize page) =>
      page.heightMm - top - bottom;

  /// عرض منطقة المحتوى الفعلي داخل الورقة.
  double contentWidthMm(JoodWriterPageSize page) => page.widthMm - left - right;

  JoodWriterMargins copyWith({
    double? top,
    double? right,
    double? bottom,
    double? left,
  }) => JoodWriterMargins(
    top: top ?? this.top,
    right: right ?? this.right,
    bottom: bottom ?? this.bottom,
    left: left ?? this.left,
  );

  static const JoodWriterMargins standard = JoodWriterMargins();
}

/// مستند «جود كاتب»: عنوان + كتل متتالية تُدفَّق على صفحات تلقائياً.
class JoodWriterDocument {
  const JoodWriterDocument({
    required this.title,
    required this.blocks,
    this.pageSize = JoodWriterPageSize.a4,
    this.orientation = WriterOrientation.portrait,
    this.margins = JoodWriterMargins.standard,
    this.pageNumbering = const PageNumberingConfig(),
    this.shapes = const <WriterShape>[],
    this.images = const <WriterImage>[],
    this.pageLayout = WriterPageLayout.single,
  });

  final String title;
  final List<JoodWriterBlock> blocks;
  final JoodWriterPageSize pageSize;
  final WriterOrientation orientation;
  final JoodWriterMargins margins;
  final PageNumberingConfig pageNumbering;
  final List<WriterShape> shapes;
  final List<WriterImage> images;

  /// تقسيم الصفحة — [single] يعني صفحة كاملة بلا تقسيم.
  final WriterPageLayout pageLayout;

  /// الحجم الفعلي بعد تطبيق الاتجاه.
  JoodWriterPageSize get effectivePageSize => pageSize.oriented(orientation);

  /// **مقاس صفحة المحرّر** بعد الاتجاه وبعد التقسيم.
  ///
  /// هنا تكمن الميزة: عند تفعيل «A4 → 2 × A5» يصبح مقاس الصفحة الواحدة نصف
  /// A4، فيتدفّق [FlowPaginator] النصّ من الأولى إلى الثانية تلقائياً —
  /// بلا أي تغيير في خوارزمية الترقيم نفسها، فهي تقبل أيّ ارتفاع محتوى.
  JoodWriterPageSize get editorPageSize =>
      JoodWriterPageSize.halfOf(effectivePageSize, pageLayout);

  /// مستند فارغ بابتدائي فقرة واحدة — لا يُفتح المحرّر بلا حقل كتابة.
  /// الفقرة تبدأ بمسافة سطر أول افتراضية لتنظيم بداية الأسطر.
  factory JoodWriterDocument.empty() => const JoodWriterDocument(
    title: 'مستند جديد',
    blocks: <JoodWriterBlock>[
      JoodWriterBlock(
        text: '',
        firstLineIndentCm: JoodWriterBlock.defaultFirstLineIndentCm,
      ),
    ],
  );

  /// مستند نموذجي يوضّح العناوين والفقرات والقوائم ويتجاوز صفحة واحدة.
  factory JoodWriterDocument.sample() => const JoodWriterDocument(
    title: 'تقرير تجريبي',
    blocks: <JoodWriterBlock>[
      JoodWriterBlock(
        text: 'تقرير الأداء الشهري',
        kind: JoodWriterBlockKind.heading1,
        align: JoodWriterAlign.center,
      ),
      JoodWriterBlock(text: 'مقدمة', kind: JoodWriterBlockKind.heading2),
      JoodWriterBlock(
        text:
            'يقدّم هذا المستند ملخّصاً للأداء خلال الشهر الماضي، مع '
            'الأرقام الرئيسية والملاحظات المهمة التي تخصّ فرق العمل '
            'والأقسام المختلفة. يُبنى هذا القسم من كتل نصّية قابلة للتحرير '
            'مباشرةً، ويمكن إضافة كتل جديدة أو تغيير أنواعها من شريط '
            'الأدوات أعلاه.',
      ),
      JoodWriterBlock(text: 'أبرز النتائج', kind: JoodWriterBlockKind.heading2),
      JoodWriterBlock(
        text: 'ارتفاع معدّل الإنجاز بنسبة ١٨٪ مقارنةً بالشهر السابق.',
        kind: JoodWriterBlockKind.bullet,
      ),
      JoodWriterBlock(
        text: 'انخفاض زمن المعالجة إلى ٣.٢ يوم عمل في المتوسط.',
        kind: JoodWriterBlockKind.bullet,
      ),
      JoodWriterBlock(
        text: 'اكتمال ترحيل ٤٢ ملفاً إلى النظام الجديد بلا أخطاء.',
        kind: JoodWriterBlockKind.bullet,
      ),
    ],
  );

  JoodWriterDocument copyWith({
    String? title,
    List<JoodWriterBlock>? blocks,
    JoodWriterPageSize? pageSize,
    WriterOrientation? orientation,
    JoodWriterMargins? margins,
    PageNumberingConfig? pageNumbering,
    List<WriterShape>? shapes,
    List<WriterImage>? images,
    WriterPageLayout? pageLayout,
  }) {
    return JoodWriterDocument(
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      margins: margins ?? this.margins,
      pageNumbering: pageNumbering ?? this.pageNumbering,
      shapes: shapes ?? this.shapes,
      images: images ?? this.images,
      pageLayout: pageLayout ?? this.pageLayout,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'pageSize': pageSize.label,
    'orientation': orientation.jsonValue,
    'pageLayout': pageLayout.jsonValue,
    'pageNumbering': pageNumbering.toJson(),
    'blocks': <dynamic>[for (final JoodWriterBlock b in blocks) b.toJson()],
    if (shapes.isNotEmpty)
      'shapes': <dynamic>[for (final WriterShape s in shapes) s.toJson()],
    if (images.isNotEmpty)
      'images': <dynamic>[for (final WriterImage img in images) img.toJson()],
  };

  static JoodWriterDocument fromJson(Map<String, dynamic> json) {
    final Object? rawBlocks = json['blocks'];
    final Object? rawShapes = json['shapes'];
    final Object? rawImages = json['images'];
    return JoodWriterDocument(
      title: json['title'] as String? ?? 'مستند',
      pageSize: JoodWriterPageSize.fromLabel(json['pageSize'] as String?),
      orientation: WriterOrientation.fromJson(json['orientation'] as String?),
      pageLayout: WriterPageLayout.fromJson(json['pageLayout'] as String?),
      pageNumbering: json['pageNumbering'] != null
          ? PageNumberingConfig.fromJson(
              Map<String, dynamic>.from(json['pageNumbering'] as Map),
            )
          : const PageNumberingConfig(),
      blocks: rawBlocks is List
          ? <JoodWriterBlock>[
              for (final Object? entry in rawBlocks)
                if (entry is Map)
                  JoodWriterBlock.fromJson(Map<String, dynamic>.from(entry)),
            ]
          : <JoodWriterBlock>[const JoodWriterBlock(text: '')],
      shapes: rawShapes is List
          ? <WriterShape>[
              for (final Object? entry in rawShapes)
                if (entry is Map)
                  WriterShape.fromJson(Map<String, dynamic>.from(entry)),
            ]
          : const <WriterShape>[],
      images: rawImages is List
          ? <WriterImage>[
              for (final Object? entry in rawImages)
                if (entry is Map)
                  WriterImage.fromJson(Map<String, dynamic>.from(entry)),
            ]
          : const <WriterImage>[],
    );
  }

  String encode() => JoodWriterBlock.encodeList(blocks);
}
