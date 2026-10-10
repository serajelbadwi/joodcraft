import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../assets/asset_type_ui.dart';
import '../assets/assets_controller.dart';
import '../assets/user_asset.dart';
import '../brand/brand_presets.dart';
import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../gender/arabic_gender.dart';
import '../models/decoration.dart';
import '../models/template_document.dart';
import '../models/template_element.dart';
import '../models/text_flow.dart';
import '../pdf/pdf_font_catalog.dart';
import '../projects/jood/jood_autosave_service.dart';
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

  /// خدمة الحفظ التلقائي (‎.jood‎) المرتبطة بهذا المحرّر — تُمرَّر من الشاشة
  /// المالكة فلا يعرف الموديل كيف يُبنى الأرشيف ولا إلى أين يُكتب.
  JoodAutosaveService? _autosave;

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

  /// خدمة الحفظ التلقائي المرتبطة (أو `null` إن كان الحفظ التلقائي معطّلاً).
  JoodAutosaveService? get autosave => _autosave;

  /// يربط خدمة الحفظ التلقائي بالمحرّر.
  ///
  /// **لا يجدول كتابة أولية عمداً:** جدولة كتابة قبل أول تعديل كانت تكتب
  /// مستنداً فارغاً فوق مسودّة سابقة قبل أن يقرّر المستخدم استعادتها أو
  /// إهمالها (فتضيع المسودة). الكتابة تبدأ مع أول تعديل عبر [_markDirty].
  void attachAutosave(JoodAutosaveService service) {
    _autosave = service;
  }

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

  // ==========================================================================
  //                       معاينة الخط الحية (مؤقتة)
  // ==========================================================================

  /// عائلة فلاتر تُعرض **مؤقتاً** على العنصر المحدد عند تمرير المؤشر فوق خيار
  /// خط في القوائم (الشريط العائم أو منتقي الشريط الجانبي) — تُرى بصريّة فقط
  /// ولا تُمسّ الوثيقة، فتزول بخروج المؤشر أو إغلاق القائمة أو اختيار خط.
  String? _fontPreviewUiFamily;

  String? get fontPreviewUiFamily => _fontPreviewUiFamily;

  void setFontPreview(String? uiFamily) {
    if (_fontPreviewUiFamily == uiFamily) return;
    _fontPreviewUiFamily = uiFamily;
    notifyListeners();
  }

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

  /// يستبدل العنوان الافتراضي بعنوان مترجم **بلا** وسم المستند كمتغيّر.
  ///
  /// يُستدعى من الواجهة بعد `initState` (حيث يتوفّر مندوبي الترجمة) وعندما
  /// يكون عنوان القالب لا يزال الافتراضي، فلا يُبطل حالة «بلا تعديلات» ولا
  /// يُلوّث عنوان قالب مُحمَّل.
  void localizeDefaultTitle(String localized, {required String defaultTitle}) {
    if (_title != defaultTitle) return;
    final String trimmed = localized.trim();
    if (trimmed.isEmpty) return;
    _title = trimmed;
  }

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
    // معاينة الخط الحية تزول بتبدّل التحديد.
    _fontPreviewUiFamily = null;
    if (id == null) {
      if (_selectedIds.isEmpty) return;
      _selectedIds.clear();
      _selectedId = null;
      notifyListeners();
      return;
    }
    if (_selectedIds.length == 1 && _selectedIds.contains(id)) return;
    // التحديد من اللوحة يحترم المجموعة المنطقية: نقر عنصر مُجمَّع يحدّد كل
    // أعضائه فوراً، فلا ينفصل عضو عن مجموعته بنقرة عابرة.
    final Set<String> target = <String>{id};
    _document.collectGroupMembers(id, target);
    _selectedIds
      ..clear()
      ..addAll(target);
    _selectedId = id;
    notifyListeners();
  }

  /// تبديل تحديد عنصر واحد (Ctrl/⌘ + نقر) — يُضيفه أو يُزيله (مع مجموعته).
  void toggleSelection(String id) {
    if (!_document.elements.any((TemplateElement e) => e.id == id)) return;
    final Set<String> group = <String>{};
    _document.collectGroupMembers(id, group);
    if (_selectedIds.contains(id)) {
      _selectedIds.removeAll(group);
    } else {
      _selectedIds.addAll(group);
      _selectedId = id;
    }
    if (_selectedId == null || !_selectedIds.contains(_selectedId)) {
      _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
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

  /// تحديد كل العناصر القابلة للتفاعل (Ctrl+A).
  ///
  /// المخفيّ والمقفل يُستبعدان: تحديدهما يعطي إحساساً بأن الاختصار «لا يعمل»
  /// لأن أدوات التحريك ترفضهما أصلاً.
  void selectAll() => selectMany(
        _document.elements
            .where(_document.isInteractive)
            .map((TemplateElement element) => element.id),
      );

  /// تحديد العناصر التي تتقاطع صناديقها مع مستطيل (بوحدات التصميم) — أداة السحب.
  ///
  /// يستبعد المخفيّ والمقفل، ويضمّ **كل** أعضاء مجموعة المنطقية إذا تقاطع أحدهم،
  /// فالسحب لا يفكّك المجموعات.
  void selectWithin(Rect region, {bool additive = false}) {
    final Set<String> hits = <String>{};
    for (final TemplateElement element in _document.elements) {
      if (!_document.isInteractive(element)) continue;
      if (_designRect(element).overlaps(region)) {
        _document.collectGroupMembers(element.id, hits);
      }
    }
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
    // كل تعديل يجدول مسودّة ‎.jood‎ مؤجّلة (Debounce) خلفياً: لا يعطّل الواجهة
    // ولا يكتب عند كل حركة، ويكفي للتعافي من إغلاق مفاجئ.
    _autosave?.schedule();
  }

  @override
  void dispose() {
    _autosave?.dispose();
    super.dispose();
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
    // تحويل أعاد العنصر نفسه ⇒ لا تغيير فعلي، فلا نُسجّل خطوة تراجع ولا
    // نُوسم المستند «مُعدَّلاً» (يحدث مع ضبط قيمة تساوي القيمة الحالية).
    if (identical(_document.elements[index], updated)) return;
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

  // ==========================================================================
  //                        الهوية الجاهزة (Brand Presets)
  // ==========================================================================

  /// إدراج كتلة هوية (ترويسة/تذييل) دفعةً واحدة وربط عناصرها كمجموعة.
  ///
  /// عملية واحدة = خطوة تراجع واحدة، والكتلة تُحدَّد كاملةً فوراً ليحرّكها
  /// المستخدم ويرى أنها كتلة واحدة لا عناصر متفرّقة.
  void insertBrandBlock(BrandBlock block) {
    if (block.isEmpty) return;
    final List<TemplateElement> elements = <TemplateElement>[
      ..._document.elements,
      ...block.elements,
    ];
    final Set<String> ids = block.elements
        .map((TemplateElement element) => element.id)
        .toSet();
    final TemplateDocument next = _document
        .copyWith(elements: elements)
        .withLayers(ids, (ElementLayerState s) => s.copyWith(groupId: block.groupId));
    _mutate(next);
    _selectedIds
      ..clear()
      ..addAll(ids);
    _selectedId = block.elements.last.id;
    notifyListeners();
  }

  /// تطبيق ألوان الهوية (الأساسي/الثانوي) على التحديد إن وُجد، وإلا على
  /// المستند كله — بلا أي تغيير في المواضع أو الأحجام.
  void applyBrandPalette({
    required String primaryHex,
    required String secondaryHex,
    bool selectionOnly = true,
  }) {
    final Set<String>? only =
        selectionOnly && _selectedIds.isNotEmpty ? _selectedIds : null;
    final List<TemplateElement> updated = BrandPresets.applyPalette(
      _document.elements,
      primaryHex: primaryHex,
      secondaryHex: secondaryHex,
      onlyIds: only,
    );
    bool changed = false;
    for (int i = 0; i < updated.length; i++) {
      if (!identical(updated[i], _document.elements[i])) {
        changed = true;
        break;
      }
    }
    if (!changed) return;
    _mutate(_document.copyWith(elements: updated));
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

  /// تحجيم العناصر المحددة حول مركزها بمعامل واحد (‎1 = بلا تغيير).
  ///
  /// يُحجَّم الصندوق (عرضاً وارتفاعاً) بالنسبة نفسها، وتُحجَّم معه الأدوات
  /// المرتبطة بالحجم (حجم خط النص، سماكة/استدارة الشكل) فتبقى النِسب البصرية
  /// ثابتة، ثم يُقصّ الصندوق على حدود الورقة.
  void scaleSelected(double factor) {
    if (factor <= 0 || factor == 1 || _selectedIds.isEmpty) return;
    final List<TemplateElement> elements = _document.elements.map(
      (TemplateElement element) {
        if (!_selectedIds.contains(element.id)) return element;
        final ElementBox box = element.box;
        final double width = box.width > 0 ? box.width * factor : box.width;
        final double height = box.height > 0 ? box.height * factor : box.height;
        // التحجيم حول المركز: يُزاح الركن الأيسر العلوي بنصف النمو.
        ElementBox next = box.copyWith(
          x: box.x + (box.width - width) / 2,
          y: box.y + (box.height - height) / 2,
          width: width,
          height: height,
        );
        next = _clampToPage(next);
        final TemplateElement scaled = element.withBox(next);
        if (scaled is TextElement) {
          return scaled.copyWith(
            fontSize: (scaled.fontSize * factor).clamp(1, 400).toDouble(),
          );
        }
        if (scaled is ShapeElement) {
          return scaled.copyWith(
            strokeWidth: scaled.strokeWidth * factor,
            radius: scaled.radius * factor,
            cornerRadii: scaled.cornerRadii == null
                ? null
                : <double>[
                    for (final double r in scaled.cornerRadii!) r * factor,
                  ],
            // أجزاء الشكل المركّب تتحجّم معه حتى لا تبقى ثابتة الحجم.
            booleanParts: scaled.isCompound
                ? <ShapeElement>[
                    for (final ShapeElement part in scaled.booleanParts)
                      part.copyWith(
                        box: ElementBox(
                          x: part.box.x * factor,
                          y: part.box.y * factor,
                          width: part.box.width * factor,
                          height: part.box.height * factor,
                        ),
                      ),
                  ]
                : scaled.booleanParts,
          );
        }
        return scaled;
      },
    ).toList(growable: false);
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
  //                          لوحة الطبقات (الظهور/القفل/الترتيب)
  // ==========================================================================

  /// ترتيب الطبقات المعروض في اللوحة: من **الأعلى** إلى الأسفل (عكس ترتيب
  /// الرسم) ليطابق ما يراه المستخدم على الورقة.
  List<TemplateElement> get layerOrder =>
      _document.elements.reversed.toList(growable: false);

  /// هل العنصر [id] مخفيّ على اللوحة وفي الطباعة؟
  bool isElementHidden(String id) => _document.isHidden(id);

  /// هل العنصر [id] مقفل (يُرسم لكن لا يُحدَّد ولا يُحرَّك)؟
  bool isElementLocked(String id) => _document.isLocked(id);

  /// إظهار/إخفاء عنصر — الإخفاء يُخرجه من اللوحة والـ PDF معاً.
  void setElementHidden(String id, bool hidden) {
    if (!_document.elements.any((TemplateElement e) => e.id == id)) return;
    if (_document.isHidden(id) == hidden) return;
    if (hidden) {
      // لا نُبقي عنصراً مخفياً محدداً: أدواته تكون بلا معنى.
      _selectedIds.remove(id);
      if (_selectedId == id) {
        _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
      }
    }
    _mutate(_document.withLayer(id, (ElementLayerState s) => s.copyWith(hidden: hidden)));
  }

  /// عكس ظهور العنصر.
  void toggleElementVisibility(String id) =>
      setElementHidden(id, !_document.isHidden(id));

  /// قفل/فك قفل عنصر — المقفل يبقى مرئياً لكنه لا يستقبل النقرات.
  void setElementLocked(String id, bool locked) {
    if (!_document.elements.any((TemplateElement e) => e.id == id)) return;
    if (_document.isLocked(id) == locked) return;
    if (locked) {
      _selectedIds.remove(id);
      if (_selectedId == id) {
        _selectedId = _selectedIds.isEmpty ? null : _selectedIds.last;
      }
    }
    _mutate(_document.withLayer(id, (ElementLayerState s) => s.copyWith(locked: locked)));
  }

  /// عكس قفل العنصر.
  void toggleElementLock(String id) =>
      setElementLocked(id, !_document.isLocked(id));

  /// نقل عنصر إلى موضع جديد في ترتيب الرسم (سحب في لوحة الطبقات).
  ///
  /// [newIndex] فهرس في ترتيب الرسم (0 = الخلف)، فيُحوّله الواجهة من الترتيب
  /// المعروض. عملية واحدة تُحفظ كخطوة تراجع واحدة.
  void moveElementTo(String id, int newIndex) {
    final List<TemplateElement> elements = <TemplateElement>[
      ..._document.elements,
    ];
    final int from = elements.indexWhere((TemplateElement e) => e.id == id);
    if (from < 0) return;
    final int to = newIndex.clamp(0, elements.length - 1);
    if (from == to) return;
    final TemplateElement moved = elements.removeAt(from);
    elements.insert(to, moved);
    _setOrder(elements);
  }

  /// تحديد عنصر من قائمة الطبقات (يتجاوز تداخل النقر على اللوحة).
  void selectFromLayer(String id, {bool additive = false}) {
    if (additive) {
      toggleSelection(id);
    } else {
      select(id);
    }
  }

  // ==========================================================================
  //                          المحاذاة والمجموعات
  // ==========================================================================

  /// هل التحديد الحالي مجموعة منطقية متكاملة؟
  bool get selectionIsGrouped {
    if (_selectedIds.length < 2) return false;
    final String? group = _document.groupIdOf(_selectedId ?? _selectedIds.first);
    if (group == null) return false;
    return _selectedIds
        .every((String id) => _document.groupIdOf(id) == group);
  }

  /// جمع العناصر المحددة في مجموعة منطقية واحدة (تتحرّك وتُحدَّد كوحدة).
  void groupSelection() {
    if (_selectedIds.length < 2) return;
    if (selectionIsGrouped) return;
    final String group = TemplateElement.newGroupId();
    _mutate(_document.withLayers(
      _selectedIds,
      (ElementLayerState s) => s.copyWith(groupId: group),
    ));
  }

  /// فكّ مجموعة التحديد الحالي (تُبقى العناصر محددة بلا ارتباط).
  void ungroupSelection() {
    if (_selectedIds.isEmpty) return;
    bool any = false;
    for (final String id in _selectedIds) {
      if (_document.groupIdOf(id) != null) {
        any = true;
        break;
      }
    }
    if (!any) return;
    _mutate(_document.withLayers(
      _selectedIds,
      (ElementLayerState s) => s.copyWith(groupId: null),
    ));
  }

  /// محاذاة كل العناصر المحددة على حافة/محور الحدّ الجامع لتحديدها.
  ///
  /// العنصر الأساسي لا يُحرّك (مرجع)، والبقية تنتقل إليه دفعياً — بلا أي
  /// تغيير في الأحجام، فالتصميم يبقى كما هو ويرتّب نفسه فقط.
  void alignSelection(LayerAlign align) {
    if (_selectedIds.length < 2) return;
    final List<TemplateElement> chosen = selectedElements;
    if (chosen.length < 2) return;

    final List<Rect> rects = chosen.map(_designRect).toList(growable: false);
    final Rect bounds = rects.reduce((Rect a, Rect b) => a.expandToInclude(b));

    final List<TemplateElement> elements = <TemplateElement>[
      ..._document.elements,
    ];
    for (final TemplateElement element in chosen) {
      final Rect rect = _designRect(element);
      final double dx = switch (align) {
        LayerAlign.left => bounds.left - rect.left,
        LayerAlign.centerH => bounds.center.dx - rect.center.dx,
        LayerAlign.right => bounds.right - rect.right,
        _ => 0,
      };
      final double dy = switch (align) {
        LayerAlign.top => bounds.top - rect.top,
        LayerAlign.centerV => bounds.center.dy - rect.center.dy,
        LayerAlign.bottom => bounds.bottom - rect.bottom,
        _ => 0,
      };
      if (dx == 0 && dy == 0) continue;
      final int index = elements.indexWhere((TemplateElement e) => e.id == element.id);
      if (index < 0) continue;
      elements[index] = element.withBox(element.box.copyWith(
        x: element.box.x + dx,
        y: element.box.y + dy,
      ));
    }
    _mutate(_document.copyWith(elements: elements));
  }

  // ==========================================================================
  //                        أدوات الشريط (خصائص النص/الأصول)
  // ==========================================================================

  // --------------------------------------------------------------------------
  //  جنس المعاينة الحيّة (التذكير/التأنيث)
  // --------------------------------------------------------------------------

  Gender? _previewGender;

  /// جنس المعاينة الحيّة للصيغ الشرطية `{{الجنس: ذكر | أنثى}}`.
  ///
  /// `null` = استنتاج تلقائي من الاسم/البيانات (الوضع الافتراضي)، وذكر/أنثى =
  /// فرض المعاينة على اللوحة فقط بلا أي تغيير في المستند أو الطباعة.
  Gender? get previewGender => _previewGender;

  /// تغيير جنس المعاينة الحيّة (`null` للعودة إلى التلقائي).
  void setPreviewGender(Gender? gender) {
    if (_previewGender == gender) return;
    _previewGender = gender;
    notifyListeners();
  }

  /// تبديل جنس المعاينة بين ذكر وأنثى (مبدّل الشريط العلوي).
  void togglePreviewGender() => setPreviewGender(
        _previewGender == Gender.female ? Gender.male : Gender.female,
      );

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
    Object? shadow = _unset,
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
        shadow: shadow,
      );
    });
  }

  /// إضافة ظل نص/تعديله/إزالته.
  ///
  /// `null` يُزيل الظل نهائياً. يُطبَّق على **كل** عناصر النص في التحديد
  /// (لا العنصر الأساسي وحده) بخطوة تراجع **واحدة** — فمجموعة نصوص/حقول
  /// ديناميكية تُظلّل دفعةً واحدة كما في `setSelectedOpacity`.
  void setSelectedTextShadow(TextShadow? shadow) {
    if (_selectedIds.isEmpty) return;
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) =>
            _selectedIds.contains(element.id) && element is TextElement
                ? element.copyWith(shadow: shadow)
                : element)
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
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
            ? element              : switch (element) {
                TextElement() => element.copyWith(opacity: safe),
                ShapeElement() => element.copyWith(opacity: safe),
                SealElement() => element.copyWith(opacity: safe),
                ImageElement() => element.copyWith(opacity: safe),
                DecorationElement() => element.copyWith(opacity: safe),
                SignatureElement() => element.copyWith(opacity: safe),
                _ => element,
              })
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// تلوين الصورة المحددة (`#RRGGBB`) — يُرسم بـ`BlendMode.srcIn` في اللوحة
  /// وفي الـ PDF معاً: تتغيّر البكسلات المرسومة ويبقى شفافُ الخلفية شفافاً.
  void setSelectedImageTint(String hex) {
    final String clean = hex.trim();
    if (clean.isEmpty) {
      clearSelectedImageTint();
      return;
    }
    updateSelected(
      (TemplateElement element) => element is ImageElement &&
              element.tintHex != clean
          ? element.copyWith(tintHex: clean)
          : element,
    );
  }

  /// إزالة تلوين الصورة المحددة — تعود بكسلات الصورة الأصلية كما هي.
  void clearSelectedImageTint() {
    updateSelected(
      (TemplateElement element) => element is ImageElement && element.hasTint
          ? element.copyWith(tintHex: null)
          : element,
    );
  }

  /// تلوين **كل** عناصر الصور المحددة معاً (`#RRGGBB`).
  ///
  /// عملية واحدة تُحفظ كخطوة تراجع واحدة (لا خطوة لكل عنصر)، فمجموعة إطارات/
  /// أختام تُلوّن بلون الهوية دفعةً واحدة كما في برامج التصميم.
  void setSelectionImageTint(String hex) {
    final String clean = hex.trim();
    if (clean.isEmpty) {
      clearSelectionImageTint();
      return;
    }
    _applyTintToSelection(clean);
  }

  /// إزالة التلوين عن كل عناصر الصور المحددة معاً.
  void clearSelectionImageTint() => _applyTintToSelection(null);

  /// هل يضمّ التحديد الحالي عنصر صورة واحداً على الأقلّ؟
  bool get hasSelectedImage => selectedElements.any(
        (TemplateElement element) => element is ImageElement,
      );

  /// تطبيق لون تلوين (أو إزالته بـ`null`) على كل صور التحديد دفعةً واحدة.
  void _applyTintToSelection(String? hex) {
    if (_selectedIds.isEmpty) return;
    bool changed = false;
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) {
      if (!_selectedIds.contains(element.id)) return element;
      if (element is! ImageElement) return element;
      if (element.tintHex == hex) return element;
      changed = true;
      return element.copyWith(tintHex: hex);
    })
        .toList(growable: false);
    if (!changed) return;
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
  /// وصف الزخرفة المتجهية المحددة (النوع والألوان والطبقات).
  void setSelectedDecorSpec(DecorSpec spec) {
    updateSelected(
      (TemplateElement element) =>
          element is DecorationElement ? element.copyWith(spec: spec) : element,
    );
  }

  /// عدد خانات عنصر التوقيعات المحدد (1..3).
  void setSelectedSignatureSlotCount(int count) {
    updateSelected(
      (TemplateElement element) => element is SignatureElement
          ? element.withSlotCount(count)
          : element,
    );
  }

  /// تعديل خانة توقيع واحدة في العنصر المحدد.
  void updateSelectedSignatureSlot(int index, SignatureSlot slot) {
    updateSelected(
      (TemplateElement element) => element is SignatureElement
          ? element.withSlot(index, slot)
          : element,
    );
  }

  /// خصائص عرض كتلة التوقيعات (الخطوط والألوان والتباعد).
  void setSelectedSignatureStyle({
    double? roleFontSize,
    double? nameFontSize,
    String? roleColorHex,
    String? nameColorHex,
    PdfFontFamily? family,
    Object? customFont = _unset,
    double? spacing,
    double? imageScale,
    SignatureAlign? align,
    bool? showDivider,
    ElementDirection? direction,
  }) {
    updateSelected(
      (TemplateElement element) => element is SignatureElement
          ? element.copyWith(
              roleFontSize: roleFontSize,
              nameFontSize: nameFontSize,
              roleColorHex: roleColorHex,
              nameColorHex: nameColorHex,
              family: family,
              customFont: customFont,
              spacing: spacing,
              imageScale: imageScale,
              align: align,
              showDivider: showDivider,
              direction: direction,
            )
          : element,
    );
  }

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

  /// خصائص الشكل المحدد (تعبئة/تدرّج/إطار/شرطات/زوايا/نجمة/ظل).
  void setSelectedShapeStyle({
    Object? fillHex = _unset,
    Object? strokeHex = _unset,
    double? strokeWidth,
    double? radius,
    double? fillOpacity,
    Object? cornerRadii = _unset,
    int? points,
    double? innerRadius,
    Object? gradient = _unset,
    Object? shadow = _unset,
    Object? dashPattern = _unset,
    bool? flipH,
    bool? flipV,
    Object? outerGlow = _unset,
    Object? innerGlow = _unset,
  }) {
    updateSelected(
      (TemplateElement element) => element is ShapeElement
          ? element.copyWith(
              fillHex: fillHex,
              strokeHex: strokeHex,
              strokeWidth: strokeWidth,
              radius: radius,
              fillOpacity: fillOpacity,
              cornerRadii: cornerRadii,
              points: points,
              innerRadius: innerRadius,
              gradient: gradient,
              shadow: shadow,
              dashPattern: dashPattern,
              flipH: flipH,
              flipV: flipV,
              outerGlow: outerGlow,
              innerGlow: innerGlow,
            )
          : element,
    );
  }

  // ==========================================================================
  //  التأثيرات (توهّج/ضبط لوني)
  // ==========================================================================

  /// توهّج خارجي و/أو داخلي للعناصر المحددة.
  ///
  /// `null` يُزيل التوهّج، وعدم تمرير الحقل يعني «اتركه كما هو» (نفس دلالة
  /// `_unset` في بقية أدوات الشريط) — فتعديل التوهّج الخارجي وحده لا يمسّ
  /// الداخلي. يُطبَّق على كل أنواع العناصر التي تدعم التوهّج في التحديد بخطوة
  /// تراجع واحدة.
  void setSelectedGlow({
    Object? outerGlow = _unset,
    Object? innerGlow = _unset,
  }) {
    if (_selectedIds.isEmpty) return;
    final List<TemplateElement> elements = _document.elements
        .map((TemplateElement element) => switch (element) {
              TextElement() =>
                element.copyWith(outerGlow: outerGlow, innerGlow: innerGlow),
              ShapeElement() =>
                element.copyWith(outerGlow: outerGlow, innerGlow: innerGlow),
              // الصور تدعم التوهّج الخارجي وحده (التوهّج الداخلي يحتاج قصّاً
              // داخل بكسلات الصورة وهو عمل بكسلي خارج نطاق اللوحة الحيّة).
              ImageElement() => element.copyWith(outerGlow: outerGlow),
              _ => element,
            })
        .toList(growable: false);
    _mutate(_document.copyWith(elements: elements));
  }

  /// ظل الصورة المحددة (Drop Shadow) — `null` يُزيله.
  void setSelectedImageShadow(ShapeShadow? shadow) {
    updateSelected(
      (TemplateElement element) => element is ImageElement
          ? element.copyWith(shadow: shadow)
          : element,
    );
  }

  /// الضبط اللوني للصورة المحددة (سطوع/تباين/تدوير لوني/تشبّع).
  ///
  /// `null` أو ضبط مكافئ للحياد يُزيل الحقل تماماً — فلا يُحفظ ضبط بلا أثر
  /// ولا تُعالَج بكسلات الصورة في الطباعة بلا داعٍ.
  void setSelectedImageAdjustments(ElementAdjustments? adjustments) {
    final ElementAdjustments? next =
        (adjustments == null || adjustments.isIdentity) ? null : adjustments;
    updateSelected(
      (TemplateElement element) => element is ImageElement
          ? element.copyWith(adjustments: next)
          : element,
    );
  }

  /// إزالة الضبط اللوني عن الصورة المحددة (تعود بكسلاتها الأصلية).
  void clearSelectedImageAdjustments() => setSelectedImageAdjustments(null);

  /// قلب أفقي/رأسي لكل الأشكال المحددة حول مركزها.
  void flipSelectedHorizontal() => _flipSelectedShapes(horizontal: true);
  void flipSelectedVertical() => _flipSelectedShapes(horizontal: false);

  void _flipSelectedShapes({required bool horizontal}) {
    if (_selectedIds.isEmpty) return;
    bool changed = false;
    final List<TemplateElement> elements = _document.elements.map(
      (TemplateElement element) {
        if (element is! ShapeElement) return element;
        if (!_selectedIds.contains(element.id)) return element;
        changed = true;
        return horizontal
            ? element.copyWith(flipH: !element.flipH)
            : element.copyWith(flipV: !element.flipV);
      },
    ).toList(growable: false);
    if (!changed) return;
    _mutate(_document.copyWith(elements: elements));
  }

  /// هل يمكن تطبيق عملية دمج منطقي على التحديد الحالي؟
  ///
  /// يتطلّب **شكلين بسيطين على الأقل** (غير مركّبين) — فالشكل المركّب نتيجة
  /// سابقة لا تُعاد دمجها هنا (تُفصل ثم تُدمج من جديد).
  bool get canApplyShapeBoolean => selectedElements
          .whereType<ShapeElement>()
          .where((ShapeElement shape) => !shape.isCompound)
          .length >
      1;

  /// هل في التحديد شكل مركّب (ناتج عملية دمج) يمكن فصله؟
  bool get hasCompoundSelection => selectedElements
      .whereType<ShapeElement>()
      .any((ShapeElement shape) => shape.isCompound);

  /// دمج الأشكال المحددة في شكل مركّب بعملية منطقية ([op]).
  ///
  /// يتطلّب تحديد شكلين على الأقل. يُصبح الشكل السفلي (الأول في ترتيب الرسم)
  /// هو الأساس الذي يُحتفظ بتعبئته، وتُخزَّن الأشكال كأجزاء نسبية داخله.
  void applyShapeBoolean(ShapeBooleanOp op) {
    final List<ShapeElement> parts = selectedElements
        .whereType<ShapeElement>()
        .where((ShapeElement shape) => !shape.isCompound)
        .toList(growable: false);
    if (parts.length < 2) return;

    double minX = parts.first.box.x;
    double minY = parts.first.box.y;
    double maxX = parts.first.box.x + parts.first.box.width;
    double maxY = parts.first.box.y + parts.first.box.height;
    for (final ShapeElement part in parts) {
      minX = math.min(minX, part.box.x);
      minY = math.min(minY, part.box.y);
      maxX = math.max(maxX, part.box.x + part.box.width);
      maxY = math.max(maxY, part.box.y + part.box.height);
    }

    final ShapeElement base = parts.first;
    final List<ShapeElement> localParts = <ShapeElement>[
      for (final ShapeElement part in parts)
        part.copyWith(
          box: part.box.copyWith(
            x: part.box.x - minX,
            y: part.box.y - minY,
          ),
        ),
    ];
    final ShapeElement compound = ShapeElement(
      id: base.id,
      box: ElementBox(
        x: minX,
        y: minY,
        width: math.max(1, maxX - minX),
        height: math.max(1, maxY - minY),
      ),
      kind: base.kind,
      fillHex: base.fillHex,
      strokeHex: base.strokeHex,
      strokeWidth: base.strokeWidth,
      radius: base.radius,
      cornerRadii: base.cornerRadii,
      gradient: base.gradient,
      shadow: base.shadow,
      dashPattern: base.dashPattern,
      fillOpacity: base.fillOpacity,
      opacity: base.opacity,
      booleanOp: op,
      booleanParts: localParts,
    );

    final Set<String> partIds = <String>{
      for (final ShapeElement part in parts) part.id,
    };
    final List<TemplateElement> elements = <TemplateElement>[];
    bool inserted = false;
    for (final TemplateElement element in _document.elements) {
      if (partIds.contains(element.id)) {
        if (!inserted) {
          elements.add(compound);
          inserted = true;
        }
        continue;
      }
      elements.add(element);
    }
    _mutate(_templateDocumentWith(elements));
    _selectedIds
      ..clear()
      ..add(compound.id);
    _selectedId = compound.id;
    notifyListeners();
  }

  /// فصل الشكل المركّب إلى أشكاله المكوّنة وإعادة تحديدها.
  void ungroupShapeBoolean() {
    final ShapeElement? compound = selected is ShapeElement
        ? selected as ShapeElement
        : null;
    if (compound == null || !compound.isCompound) return;

    final List<TemplateElement> elements = <TemplateElement>[];
    final List<String> newIds = <String>[];
    for (final TemplateElement element in _document.elements) {
      if (element is! ShapeElement || element.id != compound.id) {
        elements.add(element);
        continue;
      }
      final List<ShapeElement> parts = element.booleanParts;
      for (int i = 0; i < parts.length; i++) {
        final ShapeElement part = parts[i].copyWith(
          box: parts[i].box.copyWith(
            x: parts[i].box.x + element.box.x,
            y: parts[i].box.y + element.box.y,
          ),
          booleanOp: null,
          booleanParts: const <ShapeElement>[],
        );
        final ShapeElement released = ShapeElement(
          id: '${element.id}_s$i',
          box: part.box,
          kind: part.kind,
          rotation: part.rotation,
          fillHex: part.fillHex,
          strokeHex: part.strokeHex,
          strokeWidth: part.strokeWidth,
          radius: part.radius,
          cornerRadii: part.cornerRadii,
          points: part.points,
          innerRadius: part.innerRadius,
          gradient: part.gradient,
          shadow: part.shadow,
          dashPattern: part.dashPattern,
          flipH: part.flipH,
          flipV: part.flipV,
          opacity: part.opacity,
          fillOpacity: part.fillOpacity,
        );
        elements.add(released);
        newIds.add(released.id);
      }
    }
    _mutate(_templateDocumentWith(elements));
    _selectedIds
      ..clear()
      ..addAll(newIds);
    _selectedId = newIds.isEmpty ? null : newIds.last;
    notifyListeners();
  }

  /// نسخة من المستند بعناصر جديدة (مساعدة داخلية لعمليات الأشكال).
  TemplateDocument _templateDocumentWith(List<TemplateElement> elements) =>
      _document.copyWith(elements: elements);

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

  /// تغيير مقاس الورق مع **إعادة تخطيط تلقائي** للعناصر لتملأ المقاس الجديد.
  void setPaperSize(PaperSize size) {
    if (size == _document.paperSize) return;
    _mutate(_document.refit(paperSize: size));
  }

  /// تبديل الاتجاه (عرضي↔طولي) مع إعادة تخطيط العناصر تلقائياً للنسبة الجديدة.
  void setOrientation(PageOrientation orientation) {
    if (orientation == _document.orientation) return;
    _mutate(_document.refit(orientation: orientation));
  }

  /// الدخول المخصص (السماح للمستخدم بإدخال الأبعاد بالسم والمليمتر والبوصة).
  void setCustomPageSize(double width, double height, MeasurementUnit unit) {
    if (_document.customPageSize?.width == width &&
        _document.customPageSize?.height == height &&
        _document.customPageSize?.unit == unit) {
      return;
    }
    _mutate(_document.refit(customPageSize: CustomPageSize(
      width: width,
      height: height,
      unit: unit,
    )));
  }

  /// تفعيل المقاس المخصّص من مقاس قياسي — يبدأ من أبعاد الورقة الحالية
  /// محوّلةً إلى سنتيمتر، فلا يقفز التصميم إلى مقاس مفاجئ بل يبقى كما هو
  /// ويصير قابلاً للتعديل الحُرّ بالسنتيمتر/البوصة.
  void enableCustomPageSize() {
    if (_document.customPageSize != null) return;
    // في الوضع الأفقي يتُبادل دور العرض/الارتفاع، فنعود إلى الأبعاد الأصلية
    // للورقة حتى يبقى الشكل البصري ثابتاً لحظة التفعيل.
    final double baseWidth =
        _document.isLandscape ? _document.pageHeightPt : _document.pageWidthPt;
    final double baseHeight =
        _document.isLandscape ? _document.pageWidthPt : _document.pageHeightPt;
    _mutate(_document.refit(
      customPageSize: CustomPageSize(
        width: _round2(MeasurementUnit.cm.fromPoints(baseWidth)),
        height: _round2(MeasurementUnit.cm.fromPoints(baseHeight)),
        unit: MeasurementUnit.cm,
      ),
    ));
  }

  /// العودة إلى المقاسات القياسية (A4/A5) من المقاس المخصّص مع إعادة تخطيط.
  void clearCustomPageSize() {
    if (_document.customPageSize == null) return;
    _mutate(_document.refit(customPageSize: null));
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;

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

  /// تعيين تدرّج خلفية المستند (لونان + اتجاه) — يتقدّم على اللون المفرد.
  void setBackgroundGradient(BackgroundGradient gradient) {
    if (_document.backgroundGradient == gradient) return;
    _mutate(_document.copyWith(backgroundGradient: gradient));
  }

  /// إزالة التدرّج والعودة إلى اللون المفرد للمستند.
  void clearBackgroundGradient() {
    if (_document.backgroundGradient == null) return;
    _mutate(_document.copyWith(backgroundGradient: null));
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
        if (element is ImageElement) {
          if (element.sourceKind != ImageSourceKind.userAsset) return element;
          if (element.hasEmbeddedData) return element;
          final UserAsset? asset = assets.byId(element.path);
          final String base64 = stripBase64DataUri(asset?.base64Data ?? '');
          if (base64.isEmpty) return element;
          changed = true;
          return element.copyWith(data: base64);
        }
        // صور خانات التوقيع تحتاج النسخة المضمّنة نفسها — وإلا ابيضّ التوقيع
        // في الـ PDF لو حُذف الأصل من المكتبة لاحقاً.
        if (element is SignatureElement) {
          bool slotChanged = false;
          final List<SignatureSlot> slots = element.slots.map(
            (SignatureSlot slot) {
              if (slot.imageSource != ImageSourceKind.userAsset) return slot;
              if (slot.imageData != null && slot.imageData!.trim().isNotEmpty) {
                return slot;
              }
              final UserAsset? asset = assets.byId(slot.imagePath);
              final String base64 =
                  stripBase64DataUri(asset?.base64Data ?? '');
              if (base64.isEmpty) return slot;
              slotChanged = true;
              return slot.copyWith(imageData: base64);
            },
          ).toList(growable: false);
          if (!slotChanged) return element;
          changed = true;
          return element.copyWith(slots: slots);
        }
        return element;
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
          // الخط المخصص وطريقة الضبط والظل تُنقل كما هي — وإلا فُقدت عند
          // التكرار/النسخ (فالنسخة عنصر جديد يُبنى حقلاً حقلاً).
          customFont: element.customFont,
          weight: element.weight,
          fontSize: element.fontSize,
          colorHex: element.colorHex,
          backgroundHex: element.backgroundHex,
          align: element.align,
          verticalAlign: element.verticalAlign,
          direction: element.direction,
          justifyMode: element.justifyMode,
          lineHeight: element.lineHeight,
          letterSpacing: element.letterSpacing,
          maxLines: element.maxLines,
          opacity: element.opacity,
          shadow: element.shadow,
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
          cornerRadii: element.cornerRadii,
          points: element.points,
          innerRadius: element.innerRadius,
          gradient: element.gradient,
          shadow: element.shadow,
          dashPattern: element.dashPattern,
          flipH: element.flipH,
          flipV: element.flipV,
          booleanOp: element.booleanOp,
          booleanParts: element.booleanParts,
          opacity: element.opacity,
          fillOpacity: element.fillOpacity,
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
          // يُحفظ التلوين مع النسخة، وإلا فقد التكرار لون العنصر الأصلي.
          tintHex: element.tintHex,
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
      DecorationElement() => DecorationElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          spec: element.spec,
          opacity: element.opacity,
        ),
      SignatureElement() => SignatureElement(
          id: id,
          box: element.box,
          rotation: element.rotation,
          slots: element.slots,
          slotCount: element.slotCount,
          roleFontSize: element.roleFontSize,
          nameFontSize: element.nameFontSize,
          roleColorHex: element.roleColorHex,
          nameColorHex: element.nameColorHex,
          family: element.family,
          customFont: element.customFont,
          spacing: element.spacing,
          imageScale: element.imageScale,
          align: element.align,
          showDivider: element.showDivider,
          direction: element.direction,
          opacity: element.opacity,
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

/// محاور محاذاة التحديد المتعدد داخل حدّه الجامع.
enum LayerAlign {
  left,
  centerH,
  right,
  top,
  centerV,
  bottom;
}
