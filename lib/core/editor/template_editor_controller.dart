import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../assets/asset_type_ui.dart';
import '../assets/assets_controller.dart';
import '../assets/user_asset.dart';
import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../models/text_flow.dart';
import '../pdf/pdf_font_catalog.dart';
import '../templates/template_record.dart';
import '../templates/template_repository.dart';
import 'canvas_geometry.dart';
import 'element_factory.dart';

/// حالة محرر القوالب: المستند + التحديد + عمليات التحرير + التراجع/الإعادة.
///
/// **لماذا في `core`?** لأن محرّر الشهادات ومحرّر العقود يستخدمان المتحكم نفسه
/// تماماً، والفارق بينهما هو التصنيف والاتجاه فقط. المتحكم لا يعرف شيئاً عن
/// الواجهة ولا عن Supabase إلا عبر واجهة [TemplateRepository] المحقونة.
///
/// قواعد التحرير:
/// * كل عملية تُسجَّل في مكدّس التراجع، لكن أثناء السحب تُسجَّل **مرة واحدة**
///   عبر [beginInteraction]/[endInteraction] حتى لا يمتلئ التاريخ بآلاف الحالات.
/// * التحديد لا يُسجَّل (ليس تغييراً في المستند).
class TemplateEditorController extends ChangeNotifier {
  TemplateEditorController({
    required TemplateDocument document,
    required this.category,
    TemplateRepository? repository,
    String title = 'قالب جديد',
    String? recordId,
  })  : _document = document,
        _repository = repository,
        _title = title,
        _recordId = recordId;

  /// أقصى عدد حالات محفوظة للتراجع.
  static const int _maxHistory = 60;

  /// أصغر عرض/ارتفاع مسموح به للعنصر (بوحدات التصميم).
  static const double minElementSize = 12;

  final TemplateCategory category;
  final TemplateRepository? _repository;

  TemplateDocument _document;
  String? _selectedId;

  /// كل العناصر المحددة (بترتيب التحديد). `_selectedId` هو "العنصر الأساسي"
  /// (آخر عنصر نُقر عليه) الذي تُبنى عليه أدوات الشريط النوعية.
  final Set<String> _selectedIds = <String>{};

  /// حافظة النسخ/القص (نسخ غير مرتبطة بالمستند — عناصر غير قابلة للتغيير).
  final List<TemplateElement> _clipboard = <TemplateElement>[];

  String _title;
  String? _recordId;

  final List<TemplateDocument> _undoStack = <TemplateDocument>[];
  final List<TemplateDocument> _redoStack = <TemplateDocument>[];

  bool _dirty = false;
  bool _saving = false;
  bool _loading = false;
  bool _interactionOpen = false;
  String? _statusMessage;

  // ==========================================================================
  //                              الحالة المقروءة
  // ==========================================================================

  TemplateDocument get document => _document;

  /// أبعاد مساحة التصميم (وحدات التصميم = بكسل عند 96dpi).
  Size get designSize =>
      Size(_document.designWidth, _document.designHeight);

  /// `null` يعني أن التطبيق غير مربوط بـ Supabase (الحفظ معطّل).
  TemplateRepository? get repository => _repository;

  bool get canPersist => _repository != null;

  String get title => _title;
  String? get recordId => _recordId;

  /// هل هناك تعديلات لم تُحفظ؟
  bool get hasUnsavedChanges => _dirty;

  bool get isSaving => _saving;
  bool get isLoading => _loading;

  /// رسالة نجاح/معلومة تُعرض مرة واحدة في الواجهة.
  String? get statusMessage => _statusMessage;

  String? get selectedId => _selectedId;

  /// معرّفات كل العناصر المحددة (بترتيب التحديد).
  List<String> get selectedIds => List<String>.unmodifiable(_selectedIds);

  /// عدد العناصر المحددة.
  int get selectionCount => _selectedIds.length;

  /// هل العنصر [id] ضمن التحديد الحالي؟
  bool isSelected(String id) => _selectedIds.contains(id);

  /// هل هناك أكثر من عنصر محدد؟
  bool get hasMultiSelection => _selectedIds.length > 1;

  /// العناصر المحددة بترتيب المستند (من الخلف إلى الأمام).
  List<TemplateElement> get selectedElements => _document.elements
      .where((TemplateElement element) => _selectedIds.contains(element.id))
      .toList(growable: false);

  /// هل توجد عناصر في الحافظة؟
  bool get hasClipboard => _clipboard.isNotEmpty;

  /// العنصر "الأساسي" المحدد (أو `null`) — آخر عنصر نُقر عليه.
  TemplateElement? get selected {
    final String? id = _selectedId;
    if (id == null) return null;
    for (final TemplateElement element in _document.elements) {
      if (element.id == id) return element;
    }
    return null;
  }

  bool get hasSelection => _selectedIds.isNotEmpty;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// هل يحتوي القالب على حقول ديناميكية؟
  bool get hasDynamicFields => _document.hasDynamicFields;

  /// تغيير عنوان القالب (يُثبَّت في قاعدة البيانات عند الحفظ التالي).
  void rename(String title) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty || trimmed == _title) return;
    _title = trimmed;
    _markDirty();
    notifyListeners();
  }

  void clearStatusMessage() {
    if (_statusMessage == null) return;
    _statusMessage = null;
    notifyListeners();
  }

  // ==========================================================================
  //                              التحديد
  // ==========================================================================

  void select(String? id) {
    // تجاهُل معرّفاً غير موجود حتى لا يبقى تحديد "معلّق" بعد الحذف.
    if (id != null && !_document.elements.any((TemplateElement e) => e.id == id)) {
      return;
    }
    if (id == null) {
      if (_selectedIds.isEmpty) return;
      _selectedIds.clear();
      _selectedId = null;
      notifyListeners();
      return;
    }
    if (_selectedIds.length == 1 && _selectedIds.contains(id)) return;
    _selectedIds
      ..clear()
      ..add(id);
    _selectedId = id;
    notifyListeners();
  }

  /// تبديل تحديد عنصر واحد (Ctrl/⌘ + نقر) — يُضيفه أو يُزيله.
  void toggleSelection(String id) {
    if (!_document.elements.any((TemplateElement e) => e.id == id)) return;
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedId == id) {
        _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
      }
    } else {
      _selectedIds.add(id);
      _selectedId = id;
    }
    notifyListeners();
  }

  /// تعيين مجموعة التحديد كاملةً.
  ///
  /// [additive] = true يُضيف إلى التحديد الحالي (Shift/Ctrl)، وإلا يستبدله.
  void selectMany(Iterable<String> ids, {bool additive = false}) {
    final List<String> valid = ids
        .where((String id) =>
            _document.elements.any((TemplateElement e) => e.id == id))
        .toList(growable: false);
    if (additive) {
      _selectedIds.addAll(valid);
    } else {
      _selectedIds
        ..clear()
        ..addAll(valid);
    }
    _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
    notifyListeners();
  }

  /// تحديد كل عناصر القالب (Ctrl+A).
  void selectAll() => selectMany(
        _document.elements.map((TemplateElement element) => element.id),
      );

  /// تحديد العناصر التي تتقاطع صناديقها مع مستطيل (بوحدات التصميم) — أداة السحب.
  void selectWithin(Rect region, {bool additive = false}) {
    final List<String> hits = _document.elements
        .where((TemplateElement element) =>
            _designRect(element).overlaps(region))
        .map((TemplateElement element) => element.id)
        .toList(growable: false);
    selectMany(hits, additive: additive);
  }

  void clearSelection() => select(null);

  // ==========================================================================
  //                              التراجع/الإعادة
  // ==========================================================================

  /// بدء تفاعل متصل (سحب/تحجيم/تدوير) — يُسجَّل التراجع مرة واحدة.
  void beginInteraction() {
    if (_interactionOpen) return;
    _interactionOpen = true;
    _pushHistory();
  }

  /// إنهاء التفاعل المتصل.
  void endInteraction() {
    if (!_interactionOpen) return;
    _interactionOpen = false;
    _markDirty();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final TemplateDocument previous = _undoStack.removeLast();
    _redoStack.add(_document);
    _document = previous;
    _reconcileSelection();
    _dirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final TemplateDocument next = _redoStack.removeLast();
    _undoStack.add(_document);
    _document = next;
    _reconcileSelection();
    _dirty = true;
    notifyListeners();
  }

  void _pushHistory() {
    _undoStack.add(_document);
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _markDirty() {
    _dirty = true;
    _statusMessage = null;
  }

  /// تنفيذ تعديل على المستند مع تسجيله في التاريخ.
  void _mutate(TemplateDocument next) {
    if (!_interactionOpen) _pushHistory();
    _document = next;
    _markDirty();
    notifyListeners();
  }

  /// إبقاء التحديد متسقاً بعد التراجع/الإعادة أو تغيير المستند.
  void _reconcileSelection() {
    _selectedIds.removeWhere((String id) =>
        !_document.elements.any((TemplateElement element) => element.id == id));
    if (_selectedId != null && !_selectedIds.contains(_selectedId)) {
      _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
    }
    if (_selectedId == null && _selectedIds.isNotEmpty) {
      _selectedId = _selectedIds.last;
    }
  }

  // ==========================================================================
  //                              تعديل العناصر
  // ==========================================================================

  /// استبدال عنصر بنسخة معدّلة (الأساس الذي تُبنى عليه كل أدوات الشريط).
  void replaceElement(TemplateElement updated) {
    final int index = _document.elements
        .indexWhere((TemplateElement element) => element.id == updated.id);
    if (index < 0) return;
    final List<TemplateElement> elements = <TemplateElement>[
      ..._document.elements,
    ];
    elements[index] = updated;
    _mutate(_document.copyWith(elements: elements));
  }

  /// تعديل العنصر المحدد دالةً بدالة (تُستخدم من شريط الخصائص).
  void updateSelected(TemplateElement Function(TemplateElement element) transform) {
    final TemplateElement? current = selected;
    if (current == null) return;
    replaceElement(transform(current));
  }

  /// إضافة عنصر جديد إلى اللوحة وتحديده.
  TemplateElement addElement(NewElementKind kind) {
    final TemplateElement element = ElementFactory.create(
      kind: kind,
      design: designSize,
      index: _document.elements.length,
    );
    addElementInstance(element);
    return element;
  }

  /// إضافة عنصر جاهز (يُستخدم في الاختبارات وفي إدراج الحقول الديناميكية).
  void addElementInstance(TemplateElement element) {
    _mutate(_document.copyWith(
      elements: <TemplateElement>[..._document.elements, element],
    ));
    _selectedIds
      ..clear()
      ..add(element.id);
    _selectedId = element.id;
    notifyListeners();
  }

  /// العنصر النصي المحدّد حالياً، أو `null` في غيره.
  TextElement? get selectedTextElement =>
      selected is TextElement ? selected as TextElement : null;

  /// تحويل عنصر نصي بالقيمة المفتاحية إلى حقل ديناميكي.
  ///
  /// يُغلف المحتوى بـ `{{...}}`، ويتحوّل النوع إلى حقل ديناميكي يربط بين
  /// المحرّر والتوليد الجماعي دون الحاجة لحذف النص وإعادة إنشائه.
  void convertTextToDynamicField(String fieldKey) {
    final TextElement? element = selectedTextElement;
    if (element == null) return;
    final String token = '{{${fieldKey.trim()}}}';
    updateSelected(
      (TemplateElement updated) => updated is TextElement
          ? TextElement(
              id: updated.id,
              box: updated.box,
              text: updated.text.isEmpty ? token : token,
              family: updated.family,
              weight: updated.weight,
              fontSize: updated.fontSize,
              colorHex: updated.colorHex,
              backgroundHex: updated.backgroundHex,
              align: updated.align,
              verticalAlign: updated.verticalAlign,
              direction: updated.direction,
              justifyMode: updated.justifyMode,
              lineHeight: updated.lineHeight,
              letterSpacing: updated.letterSpacing,
              maxLines: updated.maxLines,
              opacity: updated.opacity,
            )
          : updated,
    );
  }

  /// إدراج عنصر جاهز في ترتيب الرسم المطلوب مع تحديده.
  ///
  /// [index] = 0 يضعه في الخلف (خلفية/إطار المستند)، وأي قيمة خارج المدى
  /// تضيفه في المقدمة كبقية العناصر.
  void insertElement(TemplateElement element, {int index = -1}) {
    final List<TemplateElement> elements = <TemplateElement>[
      ..._document.elements,
    ];
    if (index < 0 || index > elements.length) {
      elements.add(element);
    } else {
      elements.insert(index, element);
    }
    _mutate(_document.copyWith(elements: elements));
    _selectedIds
      ..clear()
      ..add(element.id);
    _selectedId = element.id;
    notifyListeners();
  }

  /// حذف كل العناصر المحددة.
  void deleteSelected() {
    if (_selectedIds.isEmpty) return;
    _mutate(_document.copyWith(
      elements: _document.elements
          .where((TemplateElement element) => !_selectedIds.contains(element.id))
          .toList(growable: false),
    ));
    _selectedIds.clear();
    _selectedId = null;
    notifyListeners();
  }

  /// تكرار كل العناصر المحددة بإزاحة بسيطة، وتحديد النسخ الناتجة.
  void duplicateSelected() {
    final List<TemplateElement> chosen = selectedElements;
    if (chosen.isEmpty) return;

    final List<TemplateElement> copies = <TemplateElement>[];
    for (int i = 0; i < chosen.length; i++) {
      final TemplateElement copy = chosen[i]
          .moved(dx: 18, dy: 18)
          .withRotation(chosen[i].rotation);
      copies.add(_withId(
        copy,
        ElementFactory.nextId(_document.elements.length + i, 'copy'),
      ));
    }
    _mutate(_document.copyWith(
      elements: <TemplateElement>[..._document.elements, ...copies],
    ));
    _selectedIds
      ..clear()
      ..addAll(copies.map((TemplateElement element) => element.id));
    _selectedId = copies.last.id;
    notifyListeners();
  }

  // ==========================================================================
  //                          الحافظة (نسخ/قص/لصق)
  // ==========================================================================

  /// نسخ العناصر المحددة إلى الحافظة.
  void copySelection() {
    if (_selectedIds.isEmpty) return;
    _clipboard
      ..clear()
      ..addAll(selectedElements);
  }

  /// قص العناصر المحددة (نسخ + حذف).
  void cutSelection() {
    if (_selectedIds.isEmpty) return;
    copySelection();
    deleteSelected();
  }

  /// لصق محتوى الحافظة بإزاحة صغيرة، وتحديد النسخ الملصقة.
  void pasteClipboard() {
    if (_clipboard.isEmpty) return;
    final List<TemplateElement> copies = <TemplateElement>[];
    for (int i = 0; i < _clipboard.length; i++) {
      final TemplateElement shifted = _clipboard[i].moved(dx: 18, dy: 18);
      copies.add(_withId(
        shifted,
        ElementFactory.nextId(_document.elements.length + i, 'paste'),
      ));
    }
    _mutate(_document.copyWith(
      elements: <TemplateElement>[..._document.elements, ...copies],
    ));
    _selectedIds
      ..clear()
      ..addAll(copies.map((TemplateElement element) => element.id));
    _selectedId = copies.last.id;
    notifyListeners();
  }

  /// نقل العناصر المحددة بمقدار (dx, dy) بوحدات التصميم، مع الالتصاق الذكي.
  ///
  /// لعنصر واحد يحفظ سلوك الالتصاق بالحواف/المنتصف، وللمجموعة يتحرّك الكل
  /// بنفس الفرق ككتلة واحدة.
  void moveSelectedBy(double dx, double dy, {bool snap = true}) {
    if (_selectedIds.isEmpty) return;

    if (_selectedIds.length == 1) {
      final TemplateElement? current = selected;
      if (current == null) return;
      ElementBox box = current.box.translated(dx: dx, dy: dy);
      box = _clampToPage(box);
      if (snap) box = ElementSnapper.snap(box: box, design: designSize);
      replaceElement(current.withBox(box));
      return;
    }

    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) => _selectedIds.contains(element.id)
            ? element.withBox(
                _clampToPage(element.box.translated(dx: dx, dy: dy)))
            : element)
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// تعيين صندوق العنصر المحدد مباشرة (مقابس التحجيم).
  void setSelectedBox(ElementBox box, {bool snap = false, bool clamp = true}) {
    final TemplateElement? current = selected;
    if (current == null) return;
    ElementBox next = box;
    if (next.width > 0 && next.width < minElementSize) {
      next = next.copyWith(width: minElementSize);
    }
    if (next.height > 0 && next.height < minElementSize) {
      next = next.copyWith(height: minElementSize);
    }
    if (clamp) next = _clampToPage(next);
    if (snap) next = ElementSnapper.snap(box: next, design: designSize);
    replaceElement(current.withBox(next));
  }

  /// تعيين صناديق عدة عناصر معاً (سحب مجموعة) في نداء واحد.
  ///
  /// يُستخدم أثناء سحب المجموعة ككتلة واحدة (عكس نداءات متتالية تُعقّد
  /// سجل التراجع وتُظهر تأرجحاً).
  void setSelectionBoxes(
    Map<String, ElementBox> boxes, {
    bool snap = false,
    bool clamp = true,
  }) {
    if (boxes.isEmpty) return;
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) {
      ElementBox? next = boxes[element.id];
      if (next == null) return element;
      if (next.width > 0 && next.width < minElementSize) {
        next = next.copyWith(width: minElementSize);
      }
      if (next.height > 0 && next.height < minElementSize) {
        next = next.copyWith(height: minElementSize);
      }
      if (clamp) next = _clampToPage(next);
      if (snap) next = ElementSnapper.snap(box: next, design: designSize);
      return element.withBox(next);
    })
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// تدوير العناصر المحددة إلى زاوية مطلقة (داخل المدى ‎-180..180‎).
  void setSelectedRotation(double degrees) {
    if (_selectedIds.isEmpty) return;
    final double angle = _normalizeAngle(degrees);
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) => _selectedIds.contains(element.id)
            ? element.withRotation(angle)
            : element)
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// إزاحة العناصر المحددة بالدرجات (مقبض التدوير).
  void rotateSelectedBy(double deltaDegrees) {
    if (_selectedIds.isEmpty) return;
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) => _selectedIds.contains(element.id)
            ? element.withRotation(
                _normalizeAngle(element.rotation + deltaDegrees))
            : element)
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// تمرير العناصر المحددة خطوة إلى الأمام في ترتيب الرسم.
  void bringForward() => _reorderSelection(1);

  /// تمرير العناصر المحددة خطوة إلى الخلف في ترتيب الرسم.
  void sendBackward() => _reorderSelection(-1);

  /// نقل العناصر المحددة إلى أعلى الترتيب.
  void bringToFront() {
    if (_selectedIds.isEmpty) return;
    final List<TemplateElement> chosen = selectedElements;
    final List<TemplateElement> rest = _document.elements
        .where((TemplateElement element) => !_selectedIds.contains(element.id))
        .toList(growable: false);
    _setOrder(<TemplateElement>[...rest, ...chosen]);
  }

  /// نقل العناصر المحددة إلى أسفل الترتيب (خلف كل شيء).
  void sendToBack() {
    if (_selectedIds.isEmpty) return;
    final List<TemplateElement> chosen = selectedElements;
    final List<TemplateElement> rest = _document.elements
        .where((TemplateElement element) => !_selectedIds.contains(element.id))
        .toList(growable: false);
    _setOrder(<TemplateElement>[...chosen, ...rest]);
  }

  /// تمرير التحديد خطوة واحدة مع الحفاظ على الترتيب النسبي داخله.
  void _reorderSelection(int step) {
    if (_selectedIds.isEmpty) return;
    final List<TemplateElement> elements = <TemplateElement>[
      ..._document.elements,
    ];
    final List<int> indices = <int>[
      for (int i = 0; i < elements.length; i++)
        if (_selectedIds.contains(elements[i].id)) i,
    ];

    // نعالج الجهة القيادية أولاً حتى لا يزحم العنصر التالي جاره المحدد.
    final Iterable<int> ordered =
        step > 0 ? indices.reversed : indices;
    for (final int index in ordered) {
      final int target = index + step;
      if (target < 0 || target >= elements.length) continue;
      if (_selectedIds.contains(elements[target].id)) continue;
      final TemplateElement moved = elements.removeAt(index);
      elements.insert(target, moved);
    }
    _setOrder(elements);
  }

  /// تطبيق ترتيب جديد إن كان مختلفاً عن الحالي فعلاً (بلا سجل تراجع فارغ).
  void _setOrder(List<TemplateElement> next) {
    final List<TemplateElement> current = _document.elements;
    if (next.length == current.length) {
      bool same = true;
      for (int i = 0; i < next.length; i++) {
        if (next[i].id != current[i].id) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _mutate(_document.copyWith(elements: next));
  }

  // ==========================================================================
  //                        أدوات الشريط (خصائص النص/الأصول)
  // ==========================================================================

  /// تعديل نص العنصر المحدد.
  void updateText(String value) {
    updateSelected(
      (TemplateElement element) =>
          element is TextElement ? element.copyWith(text: value) : element,
    );
  }

  /// إدراج حقل ديناميكي `{{...}}` في نهاية نص العنصر المحدد.
  void insertFieldToken(String token) {
    final TemplateElement? current = selected;
    if (current is! TextElement) return;
    final String separator = current.text.isEmpty || current.text.endsWith(' ')
        ? ''
        : ' ';
    updateText('${current.text}$separator$token');
  }

  /// خصائص نمط النص مجتمعة في نداء واحد.
  void updateTextStyle({
    PdfFontFamily? family,
    Object? customFont = _unset,
    PdfFontWeight? weight,
    double? fontSize,
    String? colorHex,
    Object? backgroundHex = _unset,
    ElementTextAlign? align,
    ElementVerticalAlign? verticalAlign,
    ElementDirection? direction,
    JustifyMode? justifyMode,
    double? lineHeight,
    double? letterSpacing,
    double? opacity,
  }) {
    updateSelected((TemplateElement element) {
      if (element is! TextElement) return element;
      return element.copyWith(
        family: family,
        customFont: customFont,
        weight: weight,
        fontSize: fontSize,
        colorHex: colorHex,
        backgroundHex: backgroundHex,
        align: align,
        verticalAlign: verticalAlign,
        direction: direction,
        justifyMode: justifyMode,
        lineHeight: lineHeight,
        letterSpacing: letterSpacing,
        opacity: opacity,
      );
    });
  }

  /// تبديل اتجاه النص للعناصر المحددة (عربي ↔ لاتيني).
  ///
  /// يُطبَّق على **كل** عناصر النص في التحديد (كبقية أدوات الشريط)، ويُحسب
  /// الاتجاه الجديد من العنصر الأساسي: إن كان اتجاهه الفعلي عربيًا صار لاتينيًا
  /// والعكس. يعيد الاتجاه الذي طُبِّق، أو `null` إن لم يكن في التحديد نص.
  ///
  /// الاتجاه الفعلي يُحلّ بـ`TextFlow` نفسه الذي يستخدمه المحرر والـ PDF، ومنه
  /// يُستنتج المتجه الصحيح حتى لو كان العنصر على `auto`.
  ElementDirection? toggleSelectedTextDirection() {
    final List<TextElement> targets = _document.elements
        .whereType<TextElement>()
        .where((TextElement element) => _selectedIds.contains(element.id))
        .toList(growable: false);
    if (targets.isEmpty) return null;

    final TextElement primary = targets.firstWhere(
      (TextElement element) => element.id == _selectedId,
      orElse: () => targets.last,
    );
    final ElementDirection next =
        TextFlow.resolvesRtl(primary.direction, primary.text)
            ? ElementDirection.ltr
            : ElementDirection.rtl;

    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) =>
            element is TextElement && _selectedIds.contains(element.id)
                ? element.copyWith(direction: next)
                : element)
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
    return next;
  }

  /// شفافية العناصر المحددة (نص/صورة/ختم/شكل).
  void setSelectedOpacity(double opacity) {
    if (_selectedIds.isEmpty) return;
    final double safe = opacity.clamp(0.0, 1.0);
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) => !_selectedIds.contains(element.id)
            ? element
            : switch (element) {
                TextElement() => element.copyWith(opacity: safe),
                ShapeElement() => element.copyWith(opacity: safe),
                SealElement() => element.copyWith(opacity: safe),
                ImageElement() => element.copyWith(opacity: safe),
                _ => element,
              })
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// حلّ وضع (Fit) الصورة المحددة.
  void setSelectedImageFit(ImageFit fit) {
    updateSelected(
      (TemplateElement element) =>
          element is ImageElement ? element.copyWith(fit: fit) : element,
    );
  }

  /// مسار/مصدر الصورة المحددة.
  void setSelectedImagePath(
    String path, {
    ImageSourceKind kind = ImageSourceKind.asset,
  }) {
    updateSelected(
      (TemplateElement element) => element is ImageElement
          ? element.copyWith(path: path, sourceKind: kind)
          : element,
    );
  }

  /// ربط أصل من مكتبة أصولي بالعنصر المحدد مع تضمين نسخة Base64 احتياطية.
  ///
  /// النسخة المضمّنة تجعل القالب مكتفياً بذاته: يبقى الإطار/الشعار قابلاً
  /// للرسم في معاينة المحرر وفي ملف الـ PDF حتى لو حُذف الأصل من المكتبة
  /// لاحقاً — دون اعتماد حصري على المعرّف (`asset_id`).
  void assignSelectedUserAsset(UserAsset asset) {
    final String base64 = stripBase64DataUri(asset.base64Data);
    updateSelected(
      (TemplateElement element) => element is ImageElement
          ? element.copyWith(
              path: asset.id,
              sourceKind: ImageSourceKind.userAsset,
              fit: asset.type.defaultFit,
              data: base64.isEmpty ? null : base64,
            )
          : element,
    );
  }

  /// ألوان الختم المحدد.
  void setSelectedSealColors({
    String? fillHex,
    String? ringHex,
    String? starHex,
    double? starRatio,
  }) {
    updateSelected(
      (TemplateElement element) => element is SealElement
          ? element.copyWith(
              fillHex: fillHex,
              ringHex: ringHex,
              starHex: starHex,
              starRatio: starRatio,
            )
          : element,
    );
  }

  /// خصائص الشكل المحدد.
  void setSelectedShapeStyle({
    Object? fillHex = _unset,
    Object? strokeHex = _unset,
    double? strokeWidth,
    double? radius,
  }) {
    updateSelected(
      (TemplateElement element) => element is ShapeElement
          ? element.copyWith(
              fillHex: fillHex,
              strokeHex: strokeHex,
              strokeWidth: strokeWidth,
              radius: radius,
            )
          : element,
    );
  }

  /// بيانات رمز الـ QR المحدد.
  void setSelectedQrData(String data) {
    updateSelected(
      (TemplateElement element) =>
          element is QrElement ? element.copyWith(data: data) : element,
    );
  }

  // ==========================================================================
  //                              إعدادات الورقة
  // ==========================================================================

  void setPaperSize(PaperSize size) {
    if (size == _document.paperSize) return;
    _mutate(_document.copyWith(paperSize: size));
  }

  void setOrientation(PageOrientation orientation) {
    if (orientation == _document.orientation) return;
    _mutate(_document.copyWith(orientation: orientation));
  }

  /// الدخول المخصص (السماح للمستخدم بإدخال الأبعاد بالسم والمليمتر والبوصة).
  void setCustomPageSize(double width, double height, MeasurementUnit unit) {
    if (_document.customPageSize?.width == width &&
        _document.customPageSize?.height == height &&
        _document.customPageSize?.unit == unit) {
      return;
    }
    _mutate(_document.copyWith(customPageSize: CustomPageSize(
      width: width,
      height: height,
      unit: unit,
    )));
  }

  /// المقاس الاسمي المُعروض في شريط الأدوات.
  String get paperSizeLabel =>
      _document.customPageSize != null
          ? '${_document.customPageSize!.width.toStringAsFixed(2)} × '
              '${_document.customPageSize!.height.toStringAsFixed(2)} '
              '${_document.customPageSize!.unit.labelAr}'
          : _document.paperSize.descriptionAr;

  void setBackgroundHex(String hex) {
    if (hex == _document.backgroundHex) return;
    _mutate(_document.copyWith(backgroundHex: hex));
  }

  /// استبدال المستند كاملاً (فتح قالب محفوظ).
  ///
  /// [asClean] = true عندما يأتي المستند من قاعدة البيانات (لا تعديلات بعد).
  void loadDocument(
    TemplateDocument document, {
    bool asClean = true,
    String? recordId,
    String? title,
  }) {
    _pushHistory();
    _document = _withEmbeddedAssets(document);
    _selectedIds.clear();
    _selectedId = null;
    _dirty = !asClean;
    if (recordId != null) _recordId = recordId;
    if (title != null) _title = title;
    notifyListeners();
  }

  /// تحميل قالب من أصول التطبيق المحزومة (بلا شبكة).
  Future<void> loadTemplateAsset(
    String assetPath, {
    AssetBundle? bundle,
    bool asClean = false,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final String json = await (bundle ?? rootBundle).loadString(assetPath);
      loadDocument(TemplateDocument.fromJsonString(json), asClean: asClean);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ==========================================================================
  //                              الحفظ في Supabase
  // ==========================================================================

  /// حفظ القالب (إنشاء أو تحديث). يرمي [AppException] عند الفشل.
  ///
  /// `schema_version` يأتي تلقائياً داخل `layout_data` من
  /// [TemplateDocument.toJson] — وهو شرط إلزامي في قاعدة البيانات.
  Future<TemplateRecord> save({String? title, bool isPublic = false}) async {
    final TemplateRepository? repository = _repository;
    if (repository == null) {
      throw const AppException(AppErrorCode.notConfigured);
    }

    final String finalTitle = (title ?? _title).trim().isEmpty
        ? 'قالب بلا عنوان'
        : (title ?? _title).trim();
    final Map<String, dynamic> layout = _document.toJson();

    _saving = true;
    notifyListeners();
    try {
      final TemplateRecord saved;
      if (_recordId == null) {
        saved = await repository.create(
          title: finalTitle,
          category: category,
          orientation: _document.orientation,
          layoutData: layout,
          isPublic: isPublic,
        );
      } else {
        saved = await repository.update(
          id: _recordId!,
          title: finalTitle,
          category: category,
          orientation: _document.orientation,
          layoutData: layout,
          isPublic: isPublic,
        );
      }

      _recordId = saved.id;
      _title = saved.title;
      _dirty = false;
      // إعادة بناء المستند من المخزون تضمن أن ما حُفظ هو ما سيُعاد فتحه
      // (وبالتالي تكشف أي فقدان في الحقول فوراً بدل أن يظهر لاحقاً).
      _document = saved.toDocument();
      _reconcileSelection();
      _statusMessage = 'تم حفظ القالب «${saved.title}».';
      return saved;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// اعتماد سجل قادم من قاعدة البيانات بلا إعادة بناء.
  void adoptRecord(TemplateRecord record) {
    _recordId = record.id;
    _title = record.title;
    _dirty = false;
    notifyListeners();
  }

  // ==========================================================================
  //                              أدوات داخلية
  // ==========================================================================

  /// مستطيل العنصر بوحدات التصميم مع حلّ العرض/الارتفاع التلقائي.
  ///
  /// يُستخدم في التحديد الجماعي بالسحب (`selectWithin`).
  Rect _designRect(TemplateElement element) {
    final Size size = designSize;
    final double width = element.box.width > 0
        ? element.box.width
        : (size.width - element.box.x).clamp(0.0, size.width);
    final double height = element.box.height > 0
        ? element.box.height
        : (size.height - element.box.y).clamp(0.0, size.height);
    return Rect.fromLTWH(element.box.x, element.box.y, width, height);
  }

  /// إبقاء العنصر داخل حدود الورقة (مع السماح بالالتصاق بالحواف تماماً).
  ElementBox _clampToPage(ElementBox box) {
    final Size size = designSize;
    final double width = box.width;
    final double height = box.height;
    final double maxX = width > 0 ? size.width - width : size.width;
    final double maxY = height > 0 ? size.height - height : size.height;
    return box.copyWith(
      x: box.x.clamp(0.0, maxX < 0 ? 0.0 : maxX),
      y: box.y.clamp(0.0, maxY < 0 ? 0.0 : maxY),
    );
  }

  static double _normalizeAngle(double degrees) {
    double value = degrees % 360;
    if (value > 180) value -= 360;
    if (value < -180) value += 360;
    return value == -0.0 ? 0 : value;
  }

  /// يضمّن نسخة Base64 احتياطية داخل كل عنصر صورة يشير إلى أصل من المكتبة
  /// لكنه بلا بيانات مضمّنة (قوالب محفوظة قبل هذا التحديث) — حلّ جذري لمشكلة
  /// «أصل محذوف»: يبقى الإطار قابلاً للرسم حتى لو حُذف الأصل.
  TemplateDocument _withEmbeddedAssets(TemplateDocument document) {
    final AssetsController assets = AssetsController.instance;
    bool changed = false;
    final List<TemplateElement> elements = document.elements.map(
      (TemplateElement element) {
        if (element is! ImageElement) return element;
        if (element.sourceKind != ImageSourceKind.userAsset) return element;
        if (element.hasEmbeddedData) return element;
        final UserAsset? asset = assets.byId(element.path);
        final String base64 = stripBase64DataUri(asset?.base64Data ?? '');
        if (base64.isEmpty) return element;
        changed = true;
        return element.copyWith(data: base64);
      },
    ).toList(growable: false);
    return changed ? document.copyWith(elements: elements) : document;
  }

  /// إعادة تسمية عنصر بمعرّف جديد مع الحفاظ على نوعه.
  static TemplateElement _withId(TemplateElement element, String id) {
    return switch (element) {
      TextElement() => TextElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          text: element.text,
          family: element.family,
          weight: element.weight,
          fontSize: element.fontSize,
          colorHex: element.colorHex,
          backgroundHex: element.backgroundHex,
          align: element.align,
          verticalAlign: element.verticalAlign,
          direction: element.direction,
          lineHeight: element.lineHeight,
          letterSpacing: element.letterSpacing,
          maxLines: element.maxLines,
          opacity: element.opacity,
        ),
      ShapeElement() => ShapeElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          kind: element.kind,
          fillHex: element.fillHex,
          strokeHex: element.strokeHex,
          strokeWidth: element.strokeWidth,
          radius: element.radius,
          opacity: element.opacity,
        ),
      SealElement() => SealElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          fillHex: element.fillHex,
          ringHex: element.ringHex,
          starHex: element.starHex,
          starRatio: element.starRatio,
          opacity: element.opacity,
        ),
      ImageElement() => ImageElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          sourceKind: element.sourceKind,
          path: element.path,
          fit: element.fit,
          opacity: element.opacity,
          // الحفاظ على النسخة المضمّنة عند النسخ/التكرار — وإلا فقد الإطار
          // نسخته الاحتياطية وسقط عند حذف الأصل من المكتبة.
          data: element.data,
        ),
      QrElement() => QrElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          data: element.data,
          colorHex: element.colorHex,
          backgroundHex: element.backgroundHex,
        ),
      UnknownElement() => UnknownElement(
          id: id,
          box: element.box,
          raw: element.raw,
          rotation: element.rotation,
        ),
    };
  }
}

/// قيمة تفيد "لم يُمرَّر" لتمييزها عن "مُرِّرت كـ null" في التحديث الجزئي.
const Object _unset = Object();
