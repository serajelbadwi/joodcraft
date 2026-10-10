import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/jood_writer_block.dart';
import '../domain/jood_writer_document.dart';
import '../domain/writer_image.dart';
import '../domain/writer_shape.dart';

/// حقل كتابة يزامن تغييره مع كتلته عبر مالكه مباشرةً (هويته هي فهرسه)، فتبقى
/// الحقول موازية للكتل مهما نُشِطت أو أُزيلت وسط القائمة.
class WriterTextEditingController extends TextEditingController {
  WriterTextEditingController(this.owner, String text) : super(text: text) {
    addListener(_handleChanged);
  }

  final WriterDocumentController owner;

  void _handleChanged() => owner._onTextChanged(this);
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

  /// يستدعي [onEdited] مرة واحدة لكل موجة تعديلات، ويمنع التداخل اللانهائي
  /// حين يُنفِّذ المستمع نفسه تعديلاً جديداً (كالشطر الآلي نفسه).
  void _requestAutoSplit() {
    final VoidCallback? handler = onEdited;
    if (handler == null || _autoSplitting) return;
    _autoSplitting = true;
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
      notifyListeners();
    }
    // أي تعديل (نص أو تنسيق) قد يغيّر ارتفاع الكتلة ⇒ فحص الشطر الآلي فوراً.
    _requestAutoSplit();
    // وحفظ تلقائي مؤجّل بعد استقرار الكتابة.
    _scheduleAutosave();
  }

  @override
  void dispose() {
    _disposed = true;
    onEdited = null;
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
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
    _activeBlockIndex = _activeBlockIndex.clamp(0, _doc.blocks.length - 1);
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
  void _onTextChanged(WriterTextEditingController controller) {
    final int index = _controllers.indexOf(controller);
    if (index < 0 || index >= _doc.blocks.length) return;
    final String text = controller.text;
    if (_doc.blocks[index].text == text) return;
    _updateBlock(index, _doc.blocks[index].copyWith(text: text));
    _requestAutoSplit();
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
    _isDirty = false;
    _syncControllers();
    notifyListeners();
  }

  JoodWriterBlock? get activeBlock {
    if (_doc.blocks.isEmpty) return null;
    return _doc.blocks[_activeBlockIndex.clamp(0, _doc.blocks.length - 1)];
  }

  void setActiveBlock(int index) {
    if (_activeBlockIndex != index &&
        index >= 0 &&
        index < _doc.blocks.length) {
      _activeBlockIndex = index;
      notifyListeners();
    }
  }

  void _updateBlock(int index, JoodWriterBlock block, {bool notify = true}) {
    if (index < 0 || index >= _doc.blocks.length) return;
    final List<JoodWriterBlock> blocks = List<JoodWriterBlock>.of(_doc.blocks);
    blocks[index] = block;
    _doc = _doc.copyWith(blocks: blocks);
    _markDirty();
    if (notify) notifyListeners();
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

    notifyListeners();
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
    notifyListeners();
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

    notifyListeners();
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
    notifyListeners();
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

    notifyListeners();
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
