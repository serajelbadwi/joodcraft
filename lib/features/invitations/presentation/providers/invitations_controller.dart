import 'package:flutter/foundation.dart';

import '../../../../core/constants/dynamic_fields.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/services/pdf_generator_service.dart';
import '../../../../core/templates/invitation_gallery.dart';
import '../../../../core/templates/invitation_group.dart';
import '../../../batch_processor/data/sheet_parse_isolate.dart';
import '../../../batch_processor/domain/column_mapping.dart';
import '../../../batch_processor/domain/field_aliases.dart';
import '../../../batch_processor/domain/sheet_data.dart';
import '../../../batch_processor/domain/sheet_reader.dart';
import '../../data/invitation_output_writer.dart';
import '../../domain/invitation_export_service.dart';
import '../../domain/invitation_name_file.dart';

/// حالة شاشة «الدعوات الشخصية الجماعية» كاملة في `ChangeNotifier` واحد.
///
/// الخطوات: اختيار قالب ← رفع ملف الأسماء ← ربط عمود الاسم ← معاينة 3 نسخ ←
/// توليد (PNG/PDF فردي باسم صاحبه) ← حفظ. كل نقلية حالة هنا قابلة للاختبار
/// بلا واجهة، والمخرجات تُبنى عبر [InvitationExportService] نفسه.
class InvitationsController extends ChangeNotifier {
  InvitationsController({
    PdfGeneratorService? generator,
    InvitationExportService? service,
    InvitationOutputWriter? writer,
    List<InvitationTemplate>? templates,
    this.parseInIsolate = true,
    this.isolateByteThreshold = defaultIsolateByteThreshold,
  })  : _generator = generator,
        _service = service,
        _writer = writer ?? createInvitationOutputWriter(),
        _templates = templates ?? InvitationTemplates.all;

  final PdfGeneratorService? _generator;
  InvitationExportService? _service;
  final InvitationOutputWriter _writer;
  final List<InvitationTemplate> _templates;

  /// هل يُفكَّك ملف Excel في isolate خلفي؟ (المصنّفات الكبيرة فقط.)
  static const int defaultIsolateByteThreshold = 48 * 1024;

  final bool parseInIsolate;

  final int isolateByteThreshold;

  bool _shouldUseIsolate(String fileName, Uint8List bytes) =>
      parseInIsolate &&
      !kIsWeb &&
      SheetReaders.isWorkbook(fileName) &&
      bytes.lengthInBytes >= isolateByteThreshold;

  // ==========================================================================
  //                                اختيار القالب
  // ==========================================================================

  InvitationGroup? _group;
  InvitationTemplate? _template;
  String _message = '';
  String? _errorAr;

  InvitationGroup? get groupFilter => _group;

  String? get errorAr => _errorAr;

  List<InvitationTemplate> get templates =>
      List<InvitationTemplate>.unmodifiable(_templates);

  List<InvitationTemplate> get visibleTemplates {
    final InvitationGroup? group = _group;
    if (group == null) return templates;
    return _templates
        .where((InvitationTemplate template) => template.group == group)
        .toList(growable: false);
  }

  InvitationTemplate? get template => _template;

  String get message => _message;

  void selectGroup(InvitationGroup? group) {
    if (_group == group) return;
    _group = group;
    notifyListeners();
  }

  void selectTemplate(InvitationTemplate template) {
    if (_template?.id == template.id) return;
    _template = template;
    _message = '';
    notifyListeners();
  }

  void setMessage(String value) {
    if (_message == value) return;
    _message = value;
    notifyListeners();
  }

  /// هل يحتوي القالب المختار على حقل `{{الاسم}}`؟ (المطلوب للتوليد الشخصي).
  bool get templateHasNameField =>
      document?.fieldKeys.contains(DynamicFields.nameKey) ?? false;

  /// المستند الجاهز للتوليد بمقاس القالب ونص الرسالة الحالي.
  TemplateDocument? get document {
    final InvitationTemplate? selected = _template;
    if (selected == null) return null;
    final String text = _message.trim().isEmpty ? selected.message : _message;
    return selected.withMessage(text);
  }

  // ==========================================================================
  //                              ملف الأسماء
  // ==========================================================================

  SheetData _sheet = SheetData.empty;
  String? _fileName;
  Uint8List? _sheetBytes;
  List<String> _sheetNames = const <String>[];
  String? _sheetName;
  bool _loadingFile = false;
  int? _nameColumn;

  SheetData get sheet => _sheet;

  String? get fileName => _fileName;

  List<String> get sheetNames => _sheetNames;

  String? get sheetName => _sheetName;

  bool get loadingFile => _loadingFile;

  bool get hasSheet => _sheet.isNotEmpty;

  int? get nameColumn => _nameColumn;

  String? get nameColumnHeader =>
      _nameColumn != null && _nameColumn! < _sheet.headers.length
          ? _sheet.headers[_nameColumn!]
          : null;

  /// أعمدة الملف المرشّحة للربط (التي تحوي بيانات فعلاً).
  List<int> get dataColumns => _sheet.dataColumns;

  /// عنوان عمود حسب فهرسه.
  String headerAt(int column) =>
      column >= 0 && column < _sheet.headers.length
          ? _sheet.headers[column]
          : '';

  Future<void> loadBytes({
    required String fileName,
    required Uint8List bytes,
    String? sheetName,
  }) async {
    _loadingFile = true;
    notifyListeners();
    try {
      final SheetReadResult result;
      if (_shouldUseIsolate(fileName, bytes)) {
        result = await parseSheetInBackground(
          SheetParseRequest(
            fileName: fileName,
            bytes: bytes,
            sheetName: sheetName,
          ),
        );
      } else {
        result = SheetReaders.readResult(
          bytes,
          fileName: fileName,
          sheetName: sheetName,
        );
      }
      _sheetBytes = bytes;
      _sheetNames = result.sheetNames;
      _sheetName = result.sheet.sheetName;
      _applySheet(result.sheet, fileName: fileName);
      _errorAr = null;
    } on Object catch (error) {
      _sheet = SheetData.empty;
      _sheetBytes = null;
      _sheetNames = const <String>[];
      _sheetName = null;
      _nameColumn = null;
      _errorAr = 'تعذّر قراءة الملف: $error';
    } finally {
      _loadingFile = false;
      notifyListeners();
    }
  }

  Future<void> selectSheet(String sheetName) async {
    final Uint8List? bytes = _sheetBytes;
    final String? name = _fileName;
    if (bytes == null || name == null) return;
    await loadBytes(fileName: name, bytes: bytes, sheetName: sheetName);
  }

  /// يطبّق الورقة ويكتشف عمود الاسم تلقائياً («الاسم»، «اسم»، «الاسم الكامل»…).
  void _applySheet(SheetData sheet, {required String fileName}) {
    _sheet = sheet;
    _fileName = fileName;
    final ColumnMapping mapping = ColumnMapping.autoDetect(
      columns: sheet.dataColumns,
      headers: sheet.headers,
      fieldKeys: fieldKeys,
      aliases: FieldAliases.byToken,
    );
    _nameColumn = mapping.columnFor(DynamicFields.nameKey);
    notifyListeners();
  }

  void setNameColumn(int? column) {
    if (_nameColumn == column) return;
    _nameColumn = column;
    notifyListeners();
  }

  void clearFile() {
    _sheet = SheetData.empty;
    _fileName = null;
    _sheetBytes = null;
    _sheetNames = const <String>[];
    _sheetName = null;
    _nameColumn = null;
    _errorAr = null;
    notifyListeners();
  }

  // ==========================================================================
  //                           فحص الأسماء والمعاينة
  // ==========================================================================

  /// حقول القالب المعروفة للنظام — عمود الاسم فقط في وضع الدعوات.
  static const List<String> fieldKeys = <String>[DynamicFields.nameKey];

  /// فحص الملف: خطة كل صف + عدد الفارغ + الأسماء المكررة.
  InvitationSheetAudit get audit {
    final int? column = _nameColumn;
    if (_sheet.isEmpty || column == null) return InvitationSheetAudit.empty;
    final List<String> names = <String>[];
    final List<int> rowNumbers = <int>[];
    for (final SheetRow row in _sheet.sheetRows) {
      if (row.isBlank) continue;
      names.add(row.cellAt(column));
      rowNumbers.add(row.displayNumber);
    }
    return InvitationSheetPlanner.plan(names: names, rowNumbers: rowNumbers);
  }

  List<InvitationRowPlan> get plans => audit.plans;

  List<InvitationRowPlan> get previewPlans =>
      plans.length <= 3 ? plans : plans.sublist(0, 3);

  int get emptyCount => audit.emptyCount;

  List<String> get duplicateNames => audit.duplicateNames;

  // ==========================================================================
  //                                 التوليد
  // ==========================================================================

  InvitationExportFormat _format = InvitationExportFormat.png;
  bool _zip = true;
  bool _csv = false;
  bool _busy = false;
  bool _paused = false;
  bool _cancelRequested = false;
  int _done = 0;
  int _total = 0;
  InvitationExportReport? _report;
  String? _savedDirectory;
  String? _savedZipPath;
  String? _savedCsvPath;

  InvitationExportFormat get format => _format;

  bool get zip => _zip;

  bool get csv => _csv;

  bool get busy => _busy;

  bool get paused => _paused;

  int get done => _done;

  int get total => _total;

  double get progress => _total == 0 ? 0 : _done / _total;

  InvitationExportReport? get report => _report;

  String? get savedDirectory => _savedDirectory;

  String? get savedZipPath => _savedZipPath;

  String? get savedCsvPath => _savedCsvPath;

  bool get canStartExport =>
      !_busy &&
      document != null &&
      templateHasNameField &&
      _nameColumn != null &&
      plans.isNotEmpty;

  void setFormat(InvitationExportFormat format) {
    if (_format == format) return;
    _format = format;
    notifyListeners();
  }

  void setZip(bool value) {
    if (_zip == value) return;
    _zip = value;
    notifyListeners();
  }

  void setCsv(bool value) {
    if (_csv == value) return;
    _csv = value;
    notifyListeners();
  }

  void togglePause() {
    if (!_busy) return;
    _paused = !_paused;
    notifyListeners();
  }

  void requestCancel() {
    _cancelRequested = true;
    notifyListeners();
  }

  Future<InvitationExportService> _ensureService() async {
    final InvitationExportService? existing = _service;
    if (existing != null) return existing;
    final PdfGeneratorService generator =
        _generator ?? await PdfGeneratorService.create();
    _service = InvitationExportService(generator: generator);
    return _service!;
  }

  /// يولّد ملفاً لكل اسم — بلا حفظ على القرص (يأتي لاحقاً عبر [saveReport]).
  Future<InvitationExportReport?> startExport() async {
    final TemplateDocument? doc = document;
    if (doc == null || !canStartExport) {
      _errorAr = 'اختر قالباً واربط عمود الأسماء أولاً.';
      notifyListeners();
      return null;
    }
    _busy = true;
    _paused = false;
    _cancelRequested = false;
    _done = 0;
    _report = null;
    _errorAr = null;
    notifyListeners();
    try {
      final InvitationExportService service = await _ensureService();
      final InvitationExportReport report = await service.run(
        document: doc,
        plans: plans,
        format: _format,
        emptyCount: audit.emptyCount,
        makeZip: _zip,
        makeCsv: _csv,
        onProgress: (int done, int total) {
          _done = done;
          _total = total;
          notifyListeners();
        },
        waitWhilePaused: () async {
          while (_paused && !_cancelRequested) {
            await Future<void>.delayed(const Duration(milliseconds: 60));
          }
        },
        isCancelled: () => _cancelRequested,
      );
      _report = report;
      return report;
    } on Object catch (error) {
      _errorAr = 'تعذّر توليد الدعوات: $error';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// يحفظ نتيجة التوليد في المجلد المختار (ويُعيد مساره).
  Future<String?> saveReport({InvitationExportReport? target}) async {
    final InvitationExportReport? report = target ?? _report;
    if (report == null || report.files.isEmpty) return null;
    String? directory = _savedDirectory ?? await _writer.pickDirectory();
    if (directory == null) return null;
    final String? saved =
        await _writer.saveFiles(directory: directory, files: report.files);
    if (saved == null) return null;
    directory = saved;
    _savedDirectory = directory;
    final String template = _template?.id ?? 'invitations';
    if (report.hasZip) {
      _savedZipPath = await _writer.saveBytes(
        directory: directory,
        fileName: '$template.zip',
        bytes: report.zipBytes!,
      );
    }
    if (report.hasCsv) {
      _savedCsvPath = await _writer.saveBytes(
        directory: directory,
        fileName: '$template.csv',
        bytes: report.csvBytes!,
      );
    }
    notifyListeners();
    return directory;
  }

  /// اسم مقترح لمجلد/أرشيف الإخراج.
  String get outputBaseName {
    final String? name = _fileName;
    final String base =
        name == null ? 'invitations' : name.replaceAll(RegExp(r'\.[^.]+$'), '');
    return base.isEmpty ? 'invitations' : base;
  }

  void reset() {
    clearFile();
    _template = null;
    _message = '';
    _busy = false;
    _paused = false;
    _cancelRequested = false;
    _done = 0;
    _total = 0;
    _report = null;
    _savedDirectory = null;
    _savedZipPath = null;
    _savedCsvPath = null;
    notifyListeners();
  }
}
