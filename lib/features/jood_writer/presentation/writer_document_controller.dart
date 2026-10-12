import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/jood_writer_block.dart';
import '../domain/jood_writer_document.dart';
import '../domain/writer_image.dart';
import '../domain/writer_shape.dart';
import 'jood_writer_text_styles.dart';

/// حقل كتابة يزامن تغييره مع كتلته عبر مالكه مباشرةً (هويته هي فهرسه)، فتبقى
/// الحقول موازية للكتل مهما نُشِطت أو أُزيلت وسط القائمة.
class WriterTextEditingController extends TextEditingController {
  WriterTextEditingController(this.owner, String text) : super(text: text) {
    addListener(_handleChanged);
  }

  final WriterDocumentController owner;

  void _handleChanged() => owner._onTextChanged(this);

  /// موضع هذه الكتلة داخل المستند (هوية الحقل من خلال مالكه).
  int get _blockIndex => owner.indexOfController(this);

  /// يبني نصّ الحقل مضيفاً **إزاحة السطر الأول** إلى تدفّقه.
  ///
  /// لماذا هنا لا في `InputDecoration.prefix`؟ لأن `prefix` يُرسم **مرة واحدة
  /// قبل منطقة النص كلها**، فيُضيّق نطاق الالتفاف أبداً: كل الأسطر تبدأ من
  /// الحافة نفسها، فتبدو كلها مُزاحة لا أولها. أمّا `WidgetSpan` فهو جزء من
  /// تدفّق النص، فيشغل السطر الأول وحده وتطول الأسطر التالية على كامل العرض.
  ///
  /// نُبقي على ما تُعيده `super` بلا مساس (بما فيه تقسيم منطقة التركيب) فلا
  /// تتأثّر مواضع المؤشّر ولا التحديد.
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final TextSpan base = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );

    final int index = _blockIndex;
    if (index < 0 || index >= owner.document.blocks.length) return base;

    final double indent = JoodWriterTextStyles.firstLineIndentPx(
      owner.document.blocks[index],
    );
    if (indent <= 0) return base;

    return TextSpan(
      style: style,
      children: <InlineSpan>[
        WidgetSpan(child: SizedBox(width: indent)),
        base,
      ],
    );
  }
}

/// المتحكّم الرئيسي بـ «جود كاتب»، يحمل المستند وقائمة حقول الكتابة، ويدير
/// التكبير والتصغير وتنسيق الكتل وتعديلات الصفحات.
class WriterDocumentController extends ChangeNotifier {
  WriterDocumentController({JoodWriterDocument? initialDocument})
    : _doc = initialDocument ?? JoodWriterDocument.empty() {
    _syncControllers();
  }

  JoodWriterDocument _doc;
  JoodWriterDocument get document => _doc;

  final List<WriterTextEditingController> _controllers =
      <WriterTextEditingController>[];
  final List<FocusNode> _focusNodes = <FocusNode>[];

  List<TextEditingController> get controllers => _controllers;
  List<FocusNode> get focusNodes => _focusNodes;

  int _activeBlockIndex = 0;
  int get activeBlockIndex => _activeBlockIndex;

  /// إشارة تغيّر **الكتلة النشطة فقط** — يقرأها رسم الكتل وحده.
  ///
  /// لماذا إشارة منفصلة؟ لأنّ التركيز على نصّ (أو مغادرته) يغيّر الكتلة
  /// النشطة، وإشعار المتحكّم العام كان يُعيد بناء اللوحة كلها — بما فيها
  /// ترقيم الصفحات — فيبدو النصّ وكأنّه يُعاد بناؤه. بهذه الإشارة يُعاد
  /// بناء الكتلة التي تكتسب التركيز وحدها (والتي تفقده)، ولا شيء سواها.
  final ValueNotifier<int> _activeBlockSignal = ValueNotifier<int>(0);

  ValueListenable<int> get activeBlockSignal => _activeBlockSignal;

  double _zoomLevel = 1.0;
  double get zoomLevel => _zoomLevel;

  bool _isDirty = false;
  bool get isDirty => _isDirty;

  String? _documentId;
  String? get documentId => _documentId;

  /// المسافة البادئة الافتراضية للسطر الأول في الفقرات الجديدة (سنتيمتر).
  static const double defaultFirstLineIndentCm =
      JoodWriterBlock.defaultFirstLineIndentCm;

  /// نقطة الشطر الآلي: تُسجّله طبقة العرض (WriterCanvas) فتُستدعى فوراً بعد
  /// **كل** تعديل نصّي أو تنسيقي، فتُقطَع الكتلة الزائدة قبل رسم الصفحة.
  VoidCallback? onEdited;

  bool _autoSplitting = false;

  /// أُغلق المتحكّم: لا حقل بعده، فلا تُنفَّذ أي دولة مؤجّلة بعد الإطار.
  bool _disposed = false;

  /// عدّاد يزيد **فقط** عند تغيّر نصّ أي كتلة.
  ///
  /// لماذا؟ الطبقة الرسومية تريد الشطر الآلي عند الكتابة واللصق، لا عند
  /// التنقّل أو التكبير أو تبديل العرض. لو اعتمدت على `notifyListeners()`
  /// عامّةً لأعادت ترقيم الصفحات عند كل نقرة، فتتبدّل محتويات البطاقة
  /// المفتوحة أمام المستخدم (يبدو المحتوى «مختفياً»). هذا العدّاد يفصل
  /// «تغيّر المحتوى» عن «تغيّر طريقة العرض» بدقّة.
  int _textRevision = 0;

  int get textRevision => _textRevision;

  /// يُستدعى بعد أي تعديل نصّي (كتابة/لصق/مسح) — يزيد [textRevision].
  void _bumpTextRevision() {
    _textRevision++;
  }

  /// آخر مراجعة نصّية فُحص فيها الشطر الآلي **فعلاً** (قبل الرسم).
  ///
  /// الطبقة الرسومية تستعملها لتعرف أنّ الشطر قد جرى مع التعديل نفسه فلا
  /// تُعيده ثانيةً عند الإشعار — فكل ضغطة حرف كانت تُشغّل التدفّق الكامل
  /// مرّتين.
  int get autoSplitRevision => _autoSplitRevision;

  int _autoSplitRevision = 0;

  // ───────────────────────────────────────────────────────────────────────────
  //  تثبيت الكتابة: تحديثٌ واحد لكل موجة ضغطات
  // ───────────────────────────────────────────────────────────────────────────

  /// إشعار مؤجَّل بانتظار التصرّف — يُذعَن مرّةً واحدة لموجة الضغطات كلّها.
  bool _uiUpdateScheduled = false;

  /// يذيع إشعاراً واحداً لكل ما يُعَدَّل داخل اللحظة نفسها.
  ///
  /// ضغطة المفتاح الواحدة كانت تُنتج: إشعار `_markDirty` + إشعار
  /// `_updateBlock` + إشعار `splitBlockAt` ⇒ ثلاث إعادات بناء لمساحة العمل
  /// في الإطار ذاته، وكلّها ترسم الصفحات من جديد. هنا تُدمج في إشعار واحد
  /// **بعد** أن يستقرّ كلّ شيء (الشطر الآلي وإنشاء الصفحة الجديدة)، فاللقطة
  /// التي يراها المستخدم تُبنى مرّةً واحدة من الحالة النهائية.
  ///
  /// `scheduleMicrotask` لا `Future`/`Timer`: تُصرَّف قبل الإطار التالي مباشرةً
  /// — بلا تأخير مرئي، وقبل أي لقطة غير مكتملة.
  void _scheduleUiUpdate() {
    if (_uiUpdateScheduled || _disposed) return;
    _uiUpdateScheduled = true;
    scheduleMicrotask(_flushUiUpdate);
  }

  void _flushUiUpdate() {
    _uiUpdateScheduled = false;
    if (_disposed) return;
    notifyListeners();
  }

  /// يستدعي [onEdited] مرة واحدة لكل موجة تعديلات، ويمنع التداخل اللانهائي
  /// حين يُنفِّذ المستمع نفسه تعديلاً جديداً (كالشطر الآلي نفسه).
  void _requestAutoSplit() {
    final VoidCallback? handler = onEdited;
    if (handler == null || _autoSplitting) return;
    _autoSplitting = true;
    _autoSplitRevision = _textRevision;
    try {
      handler();
    } finally {
      _autoSplitting = false;
    }
  }

  // ------------------------------ الحفظ المحلي والحفظ التلقائي ------------------------------

  /// مفتاح تخزين جسم المستند في التفضيلات.
  static String _docKey(String id) => 'jood_writer_$id';

  /// مفتاح بيانات وصف المستند (العنوان وآخر تعديل).
  static String _metaKey(String id) => 'jood_writer_meta_$id';

  /// مفتاح آخر مستند مفتوح — لاستئناف الجلسة عند تشغيل المحرّر.
  static const String _lastDocKey = 'jood_writer_last_document';

  /// مهلة الحفظ التلقائي بعد آخر تعديل (تُعاد مع كل تعديل).
  static const Duration autosaveDelay = Duration(milliseconds: 800);

  Timer? _autosaveTimer;
  bool _autosaveEnabled = true;
  bool get autosaveEnabled => _autosaveEnabled;

  /// يجدول حفظاً تلقائياً مؤجّلاً؛ يُعاد جدولته مع كل تعديل فلا يُحفظ المستند
  /// إلا بعد استقرار الكتابة بلحظة واحدة، ولا يُغرق التخزين بعمليات كثيرة.
  void _scheduleAutosave() {
    if (!_autosaveEnabled || _disposed) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDelay, () {
      _autosaveTimer = null;
      if (_disposed || !_isDirty) return;
      unawaited(saveDocument());
    });
  }

  /// تفعيل/تعطيل الحفظ التلقائي (يُحفظ يدوياً عند طلب المستخدم).
  void setAutosaveEnabled(bool enabled) {
    if (_autosaveEnabled == enabled) return;
    _autosaveEnabled = enabled;
    if (enabled) {
      _scheduleAutosave();
    } else {
      _autosaveTimer?.cancel();
      _autosaveTimer = null;
    }
    notifyListeners();
  }

  /// تسلسل يمنع تصادم معرّفات المستندات المولَّدة في الليلة نفسها.
  static int _documentSequence = 0;

  /// ختم زمني متزايد صارماً: الحفظات المتتالية لا تتشارك زمناً واحداً حتى لو
  /// تجمّد عدّاد الإطار الوهمي، فيبقى ترتيب «الأحدث أولاً» صحيحاً.
  static int _lastSaveStamp = 0;

  /// حفظ فوري للمستند في التخزين المحلي، مع توثيق آخر مستند مفتوح.
  Future<void> saveDocument() async {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _documentId ??=
        'doc_${DateTime.now().microsecondsSinceEpoch}_${_documentSequence++}';
    final String id = _documentId!;
    final String jsonString = jsonEncode(_doc.toJson());
    final int now = DateTime.now().microsecondsSinceEpoch;
    _lastSaveStamp = now > _lastSaveStamp ? now : _lastSaveStamp + 1;
    final String metaJson = jsonEncode(<String, dynamic>{
      'title': _doc.title,
      'updatedAt': _lastSaveStamp,
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_docKey(id), jsonString);
    await prefs.setString(_metaKey(id), metaJson);
    await prefs.setString(_lastDocKey, id);
    if (_disposed) return;
    _isDirty = false;
    notifyListeners();
  }

  /// يفتح مستنداً محفوظاً بمقتبله [docId] ويستأنف عليه الكتابة.
  Future<bool> loadSavedDocument(String docId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_docKey(docId));
    if (jsonString == null) return false;
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final doc = JoodWriterDocument.fromJson(decoded);
      if (_disposed) return false;
      _documentId = docId;
      loadDocument(doc);
      await prefs.setString(_lastDocKey, docId);
      return true;
    } catch (e) {
      debugPrint('Error loading document: $e');
      return false;
    }
  }

  /// يستأنب آخر مستند كان مفتوحاً — يُستدعى عند إقلاع شاشة المحرّر.
  Future<bool> restoreLastDocument() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? id = prefs.getString(_lastDocKey);
      if (id == null) return false;
      return await loadSavedDocument(id);
    } on Object {
      return false;
    }
  }

  /// مستند جديد فارغ: لا يمحو المحفوظ، ويبدأ معرّفاً جديداً عند الحفظ.
  void createNewDocument() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _documentId = null;
    loadDocument(JoodWriterDocument.empty());
  }

  /// إعادة تسمية المستند الحالي — تدخل في الحفظ التلقائي تلقائياً.
  void renameDocument(String title) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty || trimmed == _doc.title) return;
    _doc = _doc.copyWith(title: trimmed);
    _markDirty();
    notifyListeners();
  }

  /// قائمة المستندات المحفوظة (الأحدث تعديلاً أولاً).
  Future<List<WriterDocumentSummary>> listSavedDocuments() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    const String prefix = 'jood_writer_meta_';
    final List<WriterDocumentSummary> items = <WriterDocumentSummary>[];
    for (final String key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final Object? raw = prefs.get(key);
      if (raw is! String) continue;
      try {
        final Map<String, dynamic> meta = Map<String, dynamic>.from(
          jsonDecode(raw) as Map,
        );
        items.add(
          WriterDocumentSummary(
            id: key.substring(prefix.length),
            title: meta['title'] as String? ?? 'مستند',
            updatedAtUs: meta['updatedAt'] as int? ?? 0,
          ),
        );
      } on Object {
        // وصف تالف يُتجنّب ولا يُسقط القائمة كلها.
      }
    }
    items.sort((a, b) => b.updatedAtUs.compareTo(a.updatedAtUs));
    return items;
  }

  /// حذف مستند محفوظ نهائياً من التخزين المحلي.
  Future<void> deleteSavedDocument(String docId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_docKey(docId));
    await prefs.remove(_metaKey(docId));
    // إن كان المحفوف هو «آخر مستند مفتوح» نُزيل المؤشّر حتى لا يُستأنف حيّفاً.
    if (prefs.getString(_lastDocKey) == docId) {
      await prefs.remove(_lastDocKey);
    }
    if (_documentId == docId) {
      // المستند المحذوف هو المفتوح الآن: بقي في الذاكرة كمسودّة غير محفوظة.
      _documentId = null;
      if (!_disposed) notifyListeners();
    }
  }

  void _markDirty() {
    if (!_isDirty) {
      _isDirty = true;
    }
    // أي تعديل (نص أو تنسيق) قد يغيّر ارتفاع الكتلة ⇒ فحص الشطر الآلي فوراً.
    _requestAutoSplit();
    // وحفظ تلقائي مؤجّل بعد استقرار الكتابة.
    _scheduleAutosave();
    // إشعار واحد لموجة التعديلات كلّها (انظر [_scheduleUiUpdate]).
    _scheduleUiUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    onEdited = null;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    _activeBlockSignal.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final WriterTextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode n in _focusNodes) {
      n.dispose();
    }
  }

  // -------------------------------- مزامنة حقول الكتابة --------------------------------

  WriterTextEditingController _newTextController(int blockIndex) =>
      WriterTextEditingController(this, _doc.blocks[blockIndex].text);

  FocusNode _newFocusNode(int blockIndex) {
    final FocusNode node = FocusNode(debugLabel: 'writer-block-$blockIndex');
    node.addListener(() {
      // التركيز فقط: مغادرة النصّ (Blur) لا تُعيد بناء شيء — لا إشعار ولا
      // انتقال نشاط — فالنصّ يبقى كما هو حرفاً حرفاً وموضعاً موضعاً.
      if (node.hasFocus) {
        // الفهرس يُقرأ من مكانه الحالي في القائمة؛ فالحقول تُدرج وتُزال في
        // منتصفها مع كل شطر أو دمج.
        final int index = _focusNodes.indexOf(node);
        if (index >= 0) setActiveBlock(index);
      }
    });
    return node;
  }

  /// تُطيل القائمة فقط (المستند الجديد/المحمّل)؛ أما الإدراج في المنتصف
  /// فيُنفَّذ عبر [_insertControllerAt] ليبقى الحقل موازياً لكتلته بالضبط.
  void _syncControllers() {
    while (_controllers.length > _doc.blocks.length) {
      _retire(_controllers.removeLast());
      _retire(_focusNodes.removeLast());
    }
    while (_controllers.length < _doc.blocks.length) {
      final int index = _controllers.length;
      _controllers.add(_newTextController(index));
      _focusNodes.add(_newFocusNode(index));
    }
    // مستند بلا كتلة: لا يوجد مدى صالح (`clamp(0, -1)` يرمي `ArgumentError`
    // لأن الحدّ الأدنى يفوق الأقصى) فنثبّت المؤشّر عند الصفر؛ و[`activeBlock`]
    // يحمي الوصول بمفرده حين تكون القائمة فارغة.
    _activeBlockIndex = _doc.blocks.isEmpty
        ? 0
        : _activeBlockIndex.clamp(0, _doc.blocks.length - 1);
  }

  void _insertControllerAt(int index, String text) {
    _controllers.insert(index, WriterTextEditingController(this, text));
    _focusNodes.insert(index, _newFocusNode(index));
  }

  void _removeControllerAt(int index) {
    if (index < 0 || index >= _controllers.length) return;
    _retire(_controllers.removeAt(index));
    _retire(_focusNodes.removeAt(index));
  }

  /// لا نرمِ حلاً ما زال بين يدي `EditableText`؛ نؤجّل الإتلاف لبعد إطار
  /// الرسم حتى يتحرّر منه أولاً.
  void _retire(Listenable target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (target is TextEditingController) {
        target.dispose();
      } else if (target is FocusNode) {
        target.dispose();
      }
    });
  }

  /// موضع حقل كتابة داخل قائمته — يُقرأ بهوية الحقل لا بفهرس إنشائه.
  int indexOfController(TextEditingController controller) =>
      _controllers.indexWhere((c) => identical(c, controller));

  /// **مستمع تغيير النص**: يزامن نص الحقل مع كتلته ثم يفعّل الشطر الآلي
  /// مباشرةً (قبل الرسم) حتى لا تتجاوز الكتلة صفحتها.
  ///
  /// كلّ ما يقع هنا يُدمج في **إشعار واحد** مؤجَّل حتى نهاية الموجة: ضغطةٌ
  /// واحدة كانت تُنتج ثلاثة إشعارات (الكتلة + الشطر + الصفحة الجديدة) ⇒
  /// ثلاث إعادات بناء لمساحة العمل في الإطار نفسه، وكلّها تُعيد تدفّق
  /// المستند وقياسه. والآن: القياس والشطر يقعان فعلاً (قبل الرسم)، والإشعار
  /// يقع مرّةً واحدة على الحالة المستقرّة.
  void _onTextChanged(WriterTextEditingController controller) {
    final int index = _controllers.indexOf(controller);
    if (index < 0 || index >= _doc.blocks.length) return;
    final String text = controller.text;
    if (_doc.blocks[index].text == text) return;
    // تغيّر نصّي حقيقي (كتابة أو لصق): يُعلَم حتى يشطر المحرّك تلقائياً.
    _bumpTextRevision();
    _isDirty = true;
    _updateBlock(
      index,
      _doc.blocks[index].copyWith(text: text),
      notify: false,
      autoSplit: false,
    );
    _requestAutoSplit();
    _scheduleAutosave();
    _scheduleUiUpdate();
  }

  void loadDocument(JoodWriterDocument document) {
    // لا نرمي حقولاً ما زالت بين يدي EditableText؛ نؤجّل إتلافها بعد الإطار.
    for (final WriterTextEditingController c in _controllers) {
      _retire(c);
    }
    for (final FocusNode n in _focusNodes) {
      _retire(n);
    }
    _controllers.clear();
    _focusNodes.clear();
    _doc = document;
    _activeBlockIndex = 0;
    _activeBlockSignal.value = 0;
    _isDirty = false;
    _syncControllers();
    notifyListeners();
  }

  JoodWriterBlock? get activeBlock {
    if (_doc.blocks.isEmpty) return null;
    return _doc.blocks[_activeBlockIndex.clamp(0, _doc.blocks.length - 1)];
  }

  /// ينقل النشاط إلى الكتلة [index] — ويُشعل إشارة النشاط وحدها.
  ///
  /// الإشعار العام يبقى للشريط الجانبي وشريط الأدوات (يقرآن خصائص الكتلة
  /// النشطة)، بينما رسم الكتل يقرأ [_activeBlockSignal] فلا يُعاد بناء
  /// الصفحات عند التركيز أو عند مغادرته.
  void setActiveBlock(int index) {
    if (_activeBlockIndex != index &&
        index >= 0 &&
        index < _doc.blocks.length) {
      _activeBlockIndex = index;
      _activeBlockSignal.value = index;
      // مؤجَّل: تبديل النشاط يقع أثناء الكتابة (شطر/دمج) فلا يُضاعف إعادات
      // البناء في الإطار نفسه — الإشارة النشطة تبقى فورية للرسم.
      _scheduleUiUpdate();
    }
  }

  /// يطلب تركيز حقل الكتلة [index] **بعد** الإطار الذي يُركَّب فيه.
  ///
  /// الحقل يُبنى في الإطار التالي لتنشيط الكتلة، وطلب التركيز قبل أن تتصل
  /// عقدته بأي ودجة يُهمَل بصمت — فيبدو النقر على النصّ بلا أثر. التأجيل
  /// لإطار واحد يجعل النقر على نصٍّ ثابتاً يُظهر الحقل القابل للتحرير
  /// ومؤشّره فوراً.
  void requestBlockFocus(int index) {
    if (_disposed || index < 0 || index >= _focusNodes.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || index >= _focusNodes.length) return;
      _focusNodes[index].requestFocus();
    });
  }

  void _updateBlock(
    int index,
    JoodWriterBlock block, {
    bool notify = true,
    bool autoSplit = true,
  }) {
    if (index < 0 || index >= _doc.blocks.length) return;
    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);
    blocks[index] = block;
    _doc = _doc.copyWith(blocks: blocks);
    _isDirty = true;
    // الشطر الآلي: فوريٌّ في مسار الكتابة (قبل الرسم)، ومؤجَّلٌ إلى إشعار
    // الموجة في بقيّة المسارات (شطر/دمج/كتابة برمجية) فلا يتوالى تدفّقان
    // في الإطار ذاته.
    if (autoSplit) {
      _markDirty();
      if (notify) _scheduleUiUpdate();
      return;
    }
    if (notify) _scheduleUiUpdate();
  }

  void updateActiveBlock(JoodWriterBlock block) {
    _updateBlock(_activeBlockIndex, block);
  }

  // -------------------------------- التنسيق --------------------------------

  void setBlockKind(JoodWriterBlockKind kind) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null && block.kind != kind) {
      updateActiveBlock(block.copyWith(kind: kind));
    }
  }

  void setBlockAlign(JoodWriterAlign align) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null && block.align != align) {
      updateActiveBlock(block.copyWith(align: align));
    }
  }

  void toggleBold() {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(block.copyWith(isBold: !block.isBold));
    }
  }

  void toggleItalic() {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(block.copyWith(isItalic: !block.isItalic));
    }
  }

  void setFirstLineIndent(double cm) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(block.copyWith(firstLineIndentCm: cm));
    }
  }

  void toggleUnderline() {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(block.copyWith(isUnderline: !block.isUnderline));
    }
  }

  void setFontFamily(String? family) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(
        block.copyWith(fontFamily: family, clearFontFamily: family == null),
      );
    }
  }

  void setFontSize(double? size) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(
        block.copyWith(fontSize: size, clearFontSize: size == null),
      );
    }
  }

  void setFontColor(Color? color) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(
        block.copyWith(fontColor: color, clearFontColor: color == null),
      );
    }
  }

  void setHighlightColor(Color? color) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(
        block.copyWith(highlightColor: color, clearHighlight: color == null),
      );
    }
  }

  void toggleStrikethrough() {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(
        block.copyWith(isStrikethrough: !block.isStrikethrough),
      );
    }
  }

  /// إزالة كل التنسيق من الكتلة النشطة (كزر «مسح التنسيق» في وورد):
  /// الخط والحجم واللون والتمييز والشطب والمسافات — كلّها تعود افتراضية.
  void clearFormatting() {
    final JoodWriterBlock? block = activeBlock;
    if (block == null) return;
    updateActiveBlock(
      block.copyWith(
        clearFontFamily: true,
        clearFontSize: true,
        clearFontColor: true,
        clearHighlight: true,
        isBold: false,
        isItalic: false,
        isUnderline: false,
        isStrikethrough: false,
        lineSpacing: 1.5,
        spaceBefore: 0.0,
        spaceAfter: 8.0,
        indentCm: 0.0,
        firstLineIndentCm: 0.0,
      ),
    );
  }

  void setLineSpacing(double spacing) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(block.copyWith(lineSpacing: spacing));
    }
  }

  void setParagraphSpacing({double? before, double? after}) {
    final JoodWriterBlock? block = activeBlock;
    if (block == null) return;
    updateActiveBlock(
      block.copyWith(spaceBefore: before, spaceAfter: after),
    );
  }

  void setIndentCm(double cm) {
    final JoodWriterBlock? block = activeBlock;
    if (block != null) {
      updateActiveBlock(block.copyWith(indentCm: cm.clamp(0.0, 10.0)));
    }
  }

  // ------------------------- خصائص الصفحة (الشريط) -------------------------

  /// لون ورق الصفحة — `null` يُرجع الورقة بيضاء كما كانت.
  void setPageColor(Color? color) {
    _doc = _doc.copyWith(
      pageColor: color?.toARGB32(),
      clearPageColor: color == null,
    );
    _markDirty();
    notifyListeners();
  }

  /// العلامة المائية (نصّ خلفي شفّاف) — `null` أو فراغ يزيلها.
  void setWatermark(String? text) {
    final String? trimmed = text?.trim();
    _doc = _doc.copyWith(
      watermark: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      clearWatermark: trimmed == null || trimmed.isEmpty,
    );
    _markDirty();
    notifyListeners();
  }

  void setPageBorder(bool enabled) {
    if (_doc.pageBorder != enabled) {
      _doc = _doc.copyWith(pageBorder: enabled);
      _markDirty();
      notifyListeners();
    }
  }

  // -------------------------------- إضافة/حذف الكتل --------------------------------

  void addBlockAfterActive() {
    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);
    final int insertIndex = _activeBlockIndex + 1;
    // التنسيق يورث من الكتلة الحالية لتسهيل الاستمرار
    final JoodWriterBlock? current = activeBlock;
    final JoodWriterBlockKind kind = current?.kind.isHeading == true
        ? JoodWriterBlockKind.paragraph
        : (current?.kind ?? JoodWriterBlockKind.paragraph);

    blocks.insert(
      insertIndex,
      JoodWriterBlock(
        text: '',
        kind: kind,
        align: current?.align ?? JoodWriterAlign.start,
        fontFamily: current?.fontFamily,
        fontSize: current?.fontSize,
        fontColor: current?.fontColor,
        indentCm: current?.indentCm ?? 0,
        // الفقرة الجديدة تبدأ بمسافة سطر أول افتراضية (أو الموروثة).
        firstLineIndentCm:
            current?.firstLineIndentCm ??
            (kind == JoodWriterBlockKind.paragraph
                ? defaultFirstLineIndentCm
                : 0.0),
        // لا نورث التمييز
      ),
    );

    _doc = _doc.copyWith(blocks: blocks);
    _insertControllerAt(insertIndex, '');
    setActiveBlock(insertIndex);
    _markDirty();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      if (_focusNodes.length > insertIndex) {
        _focusNodes[insertIndex].requestFocus();
      }
    });

    // إشعار واحد مؤجَّل لموجة الكتلة الجديدة (المؤشّر + الشطر + البناء).
    _scheduleUiUpdate();
  }

  void deleteActiveBlock() {
    if (_doc.blocks.length <= 1) return;

    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);
    final int removedIndex = _activeBlockIndex;
    blocks.removeAt(removedIndex);

    _doc = _doc.copyWith(blocks: blocks);
    _removeControllerAt(removedIndex);
    _markDirty();

    final int newActive = removedIndex >= blocks.length
        ? blocks.length - 1
        : removedIndex;
    setActiveBlock(newActive);
    _scheduleUiUpdate();
  }

  // -------------------------------- Auto-Split & Merge --------------------------------

  /// يقسّم كتلة عند نقطة معينة: النص الأول يبقى في الكتلة الأصلية، والباقي
  /// ينتقل لكتلة جديدة بعدها مباشرة **أسفل الصفحة**، ويُرسَل المؤشر معه.
  /// يُستدعى من محرك التقسيم الآلي.
  ///
  /// [caretAtStartOfAfter] يضع المؤشر عند مطلع الجزء المنقول بدل نهايته —
  /// يُستخدم لفاصل الصفحات اليدوي حيث تبدأ الكتابة صفحةً جديدة مباشرة.
  void splitBlockAt(
    int blockIndex,
    String textBefore,
    String textAfter, {
    bool caretAtStartOfAfter = false,
  }) {
    if (blockIndex < 0 || blockIndex >= _doc.blocks.length) return;

    final JoodWriterBlock original = _doc.blocks[blockIndex];
    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);

    // تحديث الكتلة الأصلية بالنص المقطوع
    blocks[blockIndex] = original.copyWith(text: textBefore);

    // إنشاء كتلة جديدة بالنص المتبقي (ترث التنسيق)
    blocks.insert(
      blockIndex + 1,
      JoodWriterBlock(
        text: textAfter,
        kind: original.kind,
        align: original.align,
        fontFamily: original.fontFamily,
        fontSize: original.fontSize,
        fontColor: original.fontColor,
        isBold: original.isBold,
        isItalic: original.isItalic,
        isUnderline: original.isUnderline,
        highlightColor: original.highlightColor,
        lineSpacing: original.lineSpacing,
        spaceBefore: 0, // لا مسافة قبل الجزء المنقسم
        spaceAfter: original.spaceAfter,
        indentCm: original.indentCm,
        firstLineIndentCm: 0, // الجزء المكمّل لا يأخذ إزاحة السطر الأول
      ),
    );

    _doc = _doc.copyWith(blocks: blocks);

    // مزامنة الحقول في مواضعها: نُحدّث حقل الجزء الأول ونُدرج حقل الجزء
    // الثاني — بلا إتلاف أي حقل ما زال بين يدي EditableText.
    _controllers[blockIndex].value = TextEditingValue(
      text: textBefore,
      selection: TextSelection.collapsed(offset: textBefore.length),
    );
    _insertControllerAt(blockIndex + 1, textAfter);

    // المؤشر فوراً وبلا انتظار إطار: الجزء المنقول هو الذي يستقبل الكتابة
    // مباشرةً، ولا معنى لتأجيل موضعه إلى ما بعد الرسم (وكان التأجيل يُسقطه
    // كلّما لم يكن إطار مجدول فيستقبل الإشعار المؤجَّل قبل أن يُنفَّذ الإطار).
    final WriterTextEditingController next = _controllers[blockIndex + 1];
    next.selection = TextSelection.collapsed(
      offset: caretAtStartOfAfter ? 0 : next.text.length,
    );

    // نقل التركيز والمؤشر للكتلة الجديدة في صفحتها الجديدة.
    _activeBlockIndex = blockIndex + 1;
    _markDirty();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || blockIndex + 1 >= _focusNodes.length) return;
      _focusNodes[blockIndex + 1].requestFocus();
      final WriterTextEditingController next = _controllers[blockIndex + 1];
      // المؤشر عند نهاية الجزء المنقول (استكمال الكتابة) أو عند مطلعه
      // (فاصل صفحات يدوي: الكتابة تبدأ صفحةً جديدة مباشرة).
      next.selection = TextSelection.collapsed(
        offset: caretAtStartOfAfter ? 0 : next.text.length,
      );
    });

    // إشعار واحد لموجة الشطر: الكتلة الجديدة + المؤشّر + إعادة التدفّق —
    // لا إعادةٌ لبناء مساحة العمل قبل أن تستقرّ كلّها.
    _scheduleUiUpdate();
  }

  /// يُدرج فاصل صفحات يدوياً عند موضع المؤشر: النص اللاحق يبدأ صفحةً جديدة
  /// **دائماً** مهما بقي مساحة في الصفحة الحالية، ويستقر المؤشر عند مطلعه.
  void insertPageBreakAtCaret() {
    final int index = _activeBlockIndex;
    if (index < 0 || index >= _controllers.length) return;

    final WriterTextEditingController tc = _controllers[index];
    int caret = tc.selection.isValid ? tc.selection.baseOffset : tc.text.length;
    if (caret < 0 || caret > tc.text.length) caret = tc.text.length;

    final String before = tc.text.substring(0, caret);
    final String after = tc.text.substring(caret);
    splitBlockAt(index, before, after, caretAtStartOfAfter: true);

    // الجزء اللاحق يحمل فاصل الصفحات: صفحته الجديدة ثابتة لا يزاحها امتلاء
    // الصفحة السابقة، ولا يُلغيه شطرٌ آلي لاحق.
    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);
    blocks[index + 1] = blocks[index + 1].copyWith(pageBreakBefore: true);
    _doc = _doc.copyWith(blocks: blocks);
    _scheduleUiUpdate();
  }

  /// يدمج كتلة مع الكتلة السابقة (Backspace في بداية كتلة).
  void mergeWithPreviousBlock(int blockIndex) {
    if (blockIndex <= 0 || blockIndex >= _doc.blocks.length) return;

    final JoodWriterBlock current = _doc.blocks[blockIndex];
    final JoodWriterBlock previous = _doc.blocks[blockIndex - 1];

    final int cursorPosition = previous.text.length;
    final String mergedText = previous.text + current.text;

    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);
    blocks[blockIndex - 1] = previous.copyWith(text: mergedText);
    blocks.removeAt(blockIndex);

    _doc = _doc.copyWith(blocks: blocks);

    // إزالة الحقل الزائد ثم مزامنة حقل الدمج في مكانه.
    _removeControllerAt(blockIndex);
    _controllers[blockIndex - 1].value = TextEditingValue(
      text: mergedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );

    _activeBlockIndex = blockIndex - 1;
    _markDirty();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || blockIndex - 1 >= _focusNodes.length) return;
      _focusNodes[blockIndex - 1].requestFocus();
    });

    // [_markDirty] أعلاه ذاع إشعار الموجة واحداً — لا إشعار ثانٍ للدمج.
  }

  // -------------------------------- إعدادات الصفحة والتكبير --------------------------------

  void setZoom(double zoom) {
    final double newZoom = zoom.clamp(0.5, 3.0);
    if (_zoomLevel != newZoom) {
      _zoomLevel = newZoom;
      notifyListeners();
    }
  }

  void zoomIn() => setZoom(_zoomLevel + 0.1);
  void zoomOut() => setZoom(_zoomLevel - 0.1);

  // -------------------------------- وضع العرض --------------------------------

  WriterViewMode _viewMode = WriterViewMode.single;

  /// وضع العرض الحالي: صفحة مفردة أو صفحتين متقابلتين (طي الكتاب).
  WriterViewMode get viewMode => _viewMode;

  void setViewMode(WriterViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
  }

  /// يبدّل بين الصفحة المفردة والصفحتين المتقابلتين.
  void toggleViewMode() => setViewMode(
    _viewMode == WriterViewMode.single
        ? WriterViewMode.spread
        : WriterViewMode.single,
  );

  void setPageSize(JoodWriterPageSize size) {
    if (_doc.pageSize != size) {
      _doc = _doc.copyWith(pageSize: size);
      _markDirty();
      notifyListeners();
    }
  }

  void setOrientation(WriterOrientation orientation) {
    if (_doc.orientation != orientation) {
      _doc = _doc.copyWith(orientation: orientation);
      _markDirty();
      notifyListeners();
    }
  }

  void setMargins(JoodWriterMargins margins) {
    _doc = _doc.copyWith(margins: margins);
    _markDirty();
    notifyListeners();
  }

  /// يفعل تقسيم الصفحة (A4 → 2 × A5).
  ///
  /// #[WriterPageLayout.splitsPage] يصغّر صفحة المحرّر إلى نصف الورقة، فيتدفّق
  /// [FlowPaginator] النصّ من الصفحة الأولى إلى الثانية تلقائياً — بلا أي
  /// تغيير في خوارزمية الترقيم نفسها.
  ///
  /// ويرافق التقسيم عرض صفحتين متقابلتين (طي الكتاب) لأنه يوافق شكل الكتيّب
  /// المطبوع؛ والعودة إلى «عادي» تُرجع الوضع المفرد.
  void setPageLayout(WriterPageLayout layout) {
    if (_doc.pageLayout == layout) return;
    _doc = _doc.copyWith(pageLayout: layout);
    _viewMode = layout.splitsPage
        ? WriterViewMode.spread
        : WriterViewMode.single;
    _markDirty();
    notifyListeners();
  }

  // -------------------------------- ترقيم الصفحات --------------------------------

  /// تفعيل/تعطيل الترقيم الآلي في تذييل الصفحات.
  void setPageNumberingEnabled(bool enabled) {
    final PageNumberingConfig config = _doc.pageNumbering;
    if (config.enabled == enabled) return;
    setPageNumbering(config.copyWith(enabled: enabled));
  }

  /// عدد الصفحات الأولى المستثناة من الترقيم (الغلاف أو المقدّمات).
  void setPageNumberingExcludeFirst(int count) {
    final int clamped = count.clamp(0, 20);
    final PageNumberingConfig config = _doc.pageNumbering;
    if (config.excludeFirstN == clamped) return;
    setPageNumbering(config.copyWith(excludeFirstN: clamped));
  }

  /// استبدال إعدادات الترقيم كاملةً.
  void setPageNumbering(PageNumberingConfig config) {
    if (_doc.pageNumbering == config) return;
    _doc = _doc.copyWith(pageNumbering: config);
    _markDirty();
    notifyListeners();
  }

  // -------------------------------- الأشكال والصور --------------------------------

  void addShape(WriterShape shape) {
    final List<WriterShape> shapes = List<WriterShape>.of(_doc.shapes)
      ..add(shape);
    _doc = _doc.copyWith(shapes: shapes);
    _markDirty();
    notifyListeners();
  }

  void updateShape(int index, WriterShape shape) {
    if (index >= 0 && index < _doc.shapes.length) {
      final List<WriterShape> shapes = List<WriterShape>.of(_doc.shapes);
      shapes[index] = shape;
      _doc = _doc.copyWith(shapes: shapes);
      _markDirty();
      notifyListeners();
    }
  }

  void removeShape(int index) {
    if (index >= 0 && index < _doc.shapes.length) {
      final List<WriterShape> shapes = List<WriterShape>.of(_doc.shapes)
        ..removeAt(index);
      _doc = _doc.copyWith(shapes: shapes);
      _markDirty();
      notifyListeners();
    }
  }

  void addImage(WriterImage image) {
    final List<WriterImage> images = List<WriterImage>.of(_doc.images)
      ..add(image);
    _doc = _doc.copyWith(images: images);
    _markDirty();
    notifyListeners();
  }

  void updateImage(int index, WriterImage image) {
    if (index >= 0 && index < _doc.images.length) {
      final List<WriterImage> images = List<WriterImage>.of(_doc.images);
      images[index] = image;
      _doc = _doc.copyWith(images: images);
      _markDirty();
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _doc.images.length) {
      final List<WriterImage> images = List<WriterImage>.of(_doc.images)
        ..removeAt(index);
      _doc = _doc.copyWith(images: images);
      _markDirty();
      notifyListeners();
    }
  }
}

/// وضع عرض صفحات «جود كاتب»: صفحة مفردة أو صفحتين متقابلتين (طي الكتاب).
enum WriterViewMode { single, spread }

/// موجز مستند محفوظ — لقائمة «المستندات» في اللوحة الجانبية.
class WriterDocumentSummary {
  const WriterDocumentSummary({
    required this.id,
    required this.title,
    required this.updatedAtUs,
  });

  final String id;
  final String title;

  /// آخر تعديل بالميكروثانية منذ العصر.
  final int updatedAtUs;

  DateTime get updatedAt => DateTime.fromMicrosecondsSinceEpoch(updatedAtUs);
}
