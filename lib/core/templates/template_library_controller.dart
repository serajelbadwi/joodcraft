import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import 'local_template_store.dart';
import 'preset_catalog.dart';
import 'preset_template.dart';
import 'template_library_entry.dart';
import 'template_record.dart';
import 'template_repository.dart';

/// متحكم مكتبة القوالب — يجمع ثلاثة مصادر في مساحة واحدة:
///
/// * **الجاهزة (Preset)**: محزومة في التطبيق، متاحة دائماً بلا شبكة.
/// * **المحلية (Local)**: محفوظة على الجهاز عبر [LocalTemplateStore]، تُستعاد
///   عند إعادة فتح التطبيق بلا شبكة.
/// * **السحابية (Cloud)**: قوالب المستخدم في Supabase عبر [TemplateRepository].
///
/// يعتمد على واجهات فقط، فيُشغَّل كاملاً في الاختبارات بمستودع ومخزن وهميين.
class TemplateLibraryController extends ChangeNotifier {
  TemplateLibraryController(
    this._repository, {
    LocalTemplateStore? localStore,
    List<PresetTemplate>? presets,
  })  : _localStore = localStore ?? SharedPreferencesLocalTemplateStore(),
        _presets = presets ?? PresetCatalog.all;

  /// `null` يعني أن التطبيق غير مربوط بـ Supabase بعد.
  final TemplateRepository? _repository;
  final LocalTemplateStore _localStore;
  final List<PresetTemplate> _presets;

  List<TemplateRecord> _cloudTemplates = const <TemplateRecord>[];
  List<TemplateRecord> _localTemplates = const <TemplateRecord>[];
  bool _busy = false;
  String? _errorMessage;

  /// هل القوالب السحابية متاحة (مرتبطة بـ Supabase)؟
  bool get isAvailable => _repository != null;

  bool get isCloudAvailable => _repository != null;

  /// القوالب الجاهزة المحزومة (أوفلاين دائماً).
  List<PresetTemplate> get presets => List<PresetTemplate>.unmodifiable(_presets);

  /// القوالب المحفوظة على هذا الجهاز.
  List<TemplateRecord> get localTemplates => _localTemplates;

  /// قوالب المستخدم السحابية (توافق مع الواجهات السابقة).
  List<TemplateRecord> get templates => _cloudTemplates;

  bool get isBusy => _busy;

  /// آخر رسالة خطأ عربية (خاصة بالسحابة — لا تمنع القوالب الجاهزة/المحلية).
  String? get errorMessage => _errorMessage;

  bool get isEmpty => !_busy && errorMessage == null && entries.isEmpty;

  /// عدد القوالب في كل مصدر (لشارات الترويسة).
  int get totalCount =>
      presets.length + _localTemplates.length + _cloudTemplates.length;

  /// المداخل الموحّدة: الجاهزة ← المحلية ← السحابية.
  List<TemplateLibraryEntry> get entries => <TemplateLibraryEntry>[
        for (final PresetTemplate preset in _presets)
          TemplateLibraryEntry(
            record: preset.toRecord(),
            source: TemplateSource.preset,
            collection: preset.collection,
            preset: preset,
          ),
        for (final TemplateRecord record in _localTemplates)
          TemplateLibraryEntry(
            record: record,
            source: TemplateSource.local,
          ),
        for (final TemplateRecord record in _cloudTemplates)
          TemplateLibraryEntry(
            record: record,
            source: TemplateSource.cloud,
          ),
      ];

  /// تحميل المصادر: المحلي دائماً، والسحابي إن كان متاحاً.
  ///
  /// لا يرمي: فشل السحابة يُعرض في [errorMessage] مع بقاء القوالب الجاهزة
  /// والمحلية متاحة، وهذا جوهر العمل أوفلاين.
  Future<void> refresh() async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // مهلة دفاعية: مخزن محلي معلَّق يجب ألّا يجمد واجهة المكتبة أو المحرّر.
      _localTemplates = await _localStore
          .loadAll()
          .timeout(const Duration(seconds: 3));
    } catch (error) {
      debugPrint('[مكتبة القوالب] تعذّرت قراءة القوالب المحلية: $error');
      _localTemplates = const <TemplateRecord>[];
    }

    final TemplateRepository? repository = _repository;
    if (repository == null) {
      _cloudTemplates = const <TemplateRecord>[];
    } else {
      try {
        _cloudTemplates = await repository.listMine();
      } on AppException catch (error) {
        _errorMessage = error.message;
      } on Object catch (error) {
        _errorMessage =
            AppException(AppErrorCode.unknown, cause: error).message;
      }
    }

    _busy = false;
    notifyListeners();
  }

  /// حفظ قالب في السحابة (إنشاء جديد أو تحديث قائم). يرمي [AppException] عند الفشل.
  Future<TemplateRecord> save({
    String? id,
    required String title,
    required TemplateCategory category,
    required PageOrientation orientation,
    required Map<String, dynamic> layoutData,
    bool isPublic = false,
  }) async {
    final TemplateRepository? repository = _repository;
    if (repository == null) {
      throw const AppException(AppErrorCode.notConfigured);
    }

    _busy = true;
    notifyListeners();
    try {
      final TemplateRecord record = id == null || id.isEmpty
          ? await repository.create(
              title: title,
              category: category,
              orientation: orientation,
              layoutData: layoutData,
              isPublic: isPublic,
            )
          : await repository.update(
              id: id,
              title: title,
              category: category,
              orientation: orientation,
              layoutData: layoutData,
              isPublic: isPublic,
            );

      // إبقاء القائمة متزامنة مع الخادم بلا طلب إضافي.
      final int index = _cloudTemplates
          .indexWhere((TemplateRecord item) => item.id == record.id);
      if (index >= 0) {
        _cloudTemplates = <TemplateRecord>[..._cloudTemplates]..[index] = record;
      } else {
        _cloudTemplates = <TemplateRecord>[record, ..._cloudTemplates];
      }
      _errorMessage = null;
      return record;
    } on AppException catch (error, stackTrace) {
      _errorMessage = error.message;
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// «حفظ كقالب مخصص» — يستورد القالب إلى السحابة تحت عنوان جديد.
  Future<TemplateRecord> saveAsCustom({
    required String title,
    required TemplateLibraryEntry entry,
  }) {
    return save(
      title: title,
      category: entry.category,
      orientation: entry.orientation,
      layoutData: entry.toDocument().toJson(),
    );
  }

  /// استيراد قالب جاهز إلى المكتبة المحلية (يعمل أوفلاين ويُستعاد لاحقاً).
  Future<TemplateRecord> importPreset(
    PresetTemplate preset, {
    String? title,
  }) async {
    final DateTime now = DateTime.now();
    final String clean = (title ?? '').trim();
    final TemplateRecord record = TemplateRecord(
      id: 'local_${now.microsecondsSinceEpoch}',
      userId: 'local',
      title: clean.isEmpty ? preset.titleAr : clean,
      category: preset.category,
      orientation: preset.orientation,
      layoutData: preset.document.toJson(),
      createdAt: now,
      updatedAt: now,
    );
    _localTemplates = <TemplateRecord>[record, ..._localTemplates];
    notifyListeners();
    await _persistLocal();
    return record;
  }

  /// حفظ مستند كقالب محلي (بلا شبكة) — يُستخدم لإنشاء نسخة محلية.
  Future<TemplateRecord> saveLocal({
    required String title,
    required TemplateCategory category,
    required PageOrientation orientation,
    required Map<String, dynamic> layoutData,
  }) async {
    final DateTime now = DateTime.now();
    final TemplateRecord record = TemplateRecord(
      id: 'local_${now.microsecondsSinceEpoch}',
      userId: 'local',
      title: title.trim().isEmpty ? 'قالب بلا عنوان' : title.trim(),
      category: category,
      orientation: orientation,
      layoutData: layoutData,
      createdAt: now,
      updatedAt: now,
    );
    _localTemplates = <TemplateRecord>[record, ..._localTemplates];
    notifyListeners();
    await _persistLocal();
    return record;
  }

  /// حذف قالب محلي. لا يرمي.
  Future<void> removeLocal(String id) async {
    _localTemplates = _localTemplates
        .where((TemplateRecord item) => item.id != id)
        .toList(growable: false);
    notifyListeners();
    await _persistLocal();
  }

  /// حذف قالب سحابي. يرمي [AppException] عند الفشل.
  Future<void> remove(String id) async {
    final TemplateRepository? repository = _repository;
    if (repository == null) {
      throw const AppException(AppErrorCode.notConfigured);
    }

    _busy = true;
    notifyListeners();
    try {
      await repository.delete(id);
      _cloudTemplates = _cloudTemplates
          .where((TemplateRecord item) => item.id != id)
          .toList(growable: false);
      _errorMessage = null;
    } on AppException catch (error, stackTrace) {
      _errorMessage = error.message;
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// جلب قالب واحد بالمعرّف — يبحث في السحابة ثم المحلي.
  Future<TemplateRecord?> findById(String id) async {
    for (final TemplateRecord record in _localTemplates) {
      if (record.id == id) return record;
    }
    final TemplateRepository? repository = _repository;
    if (repository == null) return null;
    return repository.findById(id);
  }

  Future<void> _persistLocal() async {
    try {
      await _localStore.saveAll(_localTemplates);
    } catch (error) {
      debugPrint('[مكتبة القوالب] تعذّر حفظ القوالب المحلية: $error');
    }
  }
}
