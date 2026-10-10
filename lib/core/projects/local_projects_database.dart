import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'project_record.dart';

/// قاعدة البيانات المحلية للمشاريع — «جدول `projects`» بلا أي خادم.
///
/// الواجهة تفصل الشاشات عن وسيط التخزين: التنفيذ الافتراضي [HiveProjectsDatabase]
/// (ملف على القرص على سطح المكتب، وIndexedDB على الويب)، و[InMemoryProjectsDatabase]
/// للاختبارات وللتراجع الآمن إن تعذّر فتح المخزن على منصة ما.
///
/// **المشروع لا يُرفع إلى أي سيرفر**: كل ما في هذه القاعدة محلي، ونسخة احتياطية
/// منها هي نسخة ملف واحد في مجلد بيانات التطبيق.
abstract interface class LocalProjectsDatabase {
  /// يهيّئ المقبض (فتح الملف/الصندوق). آمن للاستدعاء أكثر من مرة.
  Future<void> initialize();

  /// كل المشاريع مرتّبة بالأحدث تعديلاً.
  Future<List<ProjectRecord>> selectAll();

  /// مشروع واحد بالمعرّف.
  Future<ProjectRecord?> selectById(String id);

  /// إدراج أو تحديث صفّ واحد.
  Future<void> upsert(ProjectRecord record);

  /// إدراج/تحديث دفعة صفوف.
  Future<void> upsertAll(Iterable<ProjectRecord> records);

  /// حذف صفّ بالمعرّف. لا يرمي إن كان غير موجود.
  Future<void> delete(String id);

  /// حذف كل الصفوف (يُستخدم في «تفريغ المكتبة المحلية»).
  Future<void> clear();
}

/// تنفيذ [LocalProjectsDatabase] فوق صندوق Hive واحد اسمه `projects`.
///
/// كل صفّ يُخزَّن كخريطة بمفاتيح الأعمدة نفسها (`id`, `title`, `width`,
/// `height`, `layers_data`, `updated_at`, `thumbnail_path`) — فما على القرص هو
/// الجدول كما هو، بلا تحويل غامض بين الطبقتين.
class HiveProjectsDatabase implements LocalProjectsDatabase {
  HiveProjectsDatabase({this.boxName = ProjectRecord.tableName});

  final String boxName;

  static bool _hiveReady = false;

  Box<Map>? _box;

  /// يفتح الصندوق — ويهيّئ Hive مرة واحدة للتطبيق كله.
  @override
  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;
    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box<Map>(boxName);
      return;
    }
    if (!_hiveReady) {
      // يحدّد مجلد بيانات التطبيق (ويستعمل IndexedDB على الويب تلقائياً).
      await Hive.initFlutter();
      _hiveReady = true;
    }
    _box = await Hive.openBox<Map>(boxName);
  }

  Box<Map> get _openBox {
    final Box<Map>? box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('صندوق «$boxName» غير مفتوح — استدعِ initialize() أولاً.');
    }
    return box;
  }

  @override
  Future<List<ProjectRecord>> selectAll() async {
    await initialize();
    final List<ProjectRecord> records = <ProjectRecord>[
      for (final Map row in _openBox.values) ProjectRecord.fromRow(row),
    ];
    _sortByUpdated(records);
    return records;
  }

  @override
  Future<ProjectRecord?> selectById(String id) async {
    await initialize();
    final Map? row = _openBox.get(id);
    return row == null ? null : ProjectRecord.fromRow(row);
  }

  @override
  Future<void> upsert(ProjectRecord record) async {
    await initialize();
    await _openBox.put(record.id, record.toRow());
  }

  @override
  Future<void> upsertAll(Iterable<ProjectRecord> records) async {
    await initialize();
    await _openBox.putAll(<String, Map<String, dynamic>>{
      for (final ProjectRecord record in records)
        record.id: record.toRow(),
    });
  }

  @override
  Future<void> delete(String id) async {
    await initialize();
    await _openBox.delete(id);
  }

  @override
  Future<void> clear() async {
    await initialize();
    await _openBox.clear();
  }

  /// يغلق الصندوق ويمسح الكتابة المؤجّلة على القرص — يُستدعى عند إنهاء التطبيق
  /// وفي نهاية الاختبارات.
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

/// مخزن في الذاكرة — للاختبارات وللمعاينة، وللتراجع الآمن على منصة لا تدعم
/// فتح الصندوق (فلا يتعطّل التطبيق أبداً بسبب التخزين).
class InMemoryProjectsDatabase implements LocalProjectsDatabase {
  InMemoryProjectsDatabase([Iterable<ProjectRecord>? initial])
      : _rows = <String, ProjectRecord>{
          for (final ProjectRecord record in initial ?? <ProjectRecord>[])
            record.id: record,
        };

  Map<String, ProjectRecord> _rows;
  bool _initialized = false;

  /// كل الصفوف كما هي مخزَّنة (مفيدة في التحقّق من الاختبارات).
  List<ProjectRecord> get rows {
    final List<ProjectRecord> records = _rows.values.toList();
    _sortByUpdated(records);
    return List<ProjectRecord>.unmodifiable(records);
  }

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  @override
  Future<List<ProjectRecord>> selectAll() async {
    await initialize();
    return rows;
  }

  @override
  Future<ProjectRecord?> selectById(String id) async {
    await initialize();
    return _rows[id];
  }

  @override
  Future<void> upsert(ProjectRecord record) async {
    await initialize();
    _rows[record.id] = record;
  }

  @override
  Future<void> upsertAll(Iterable<ProjectRecord> records) async {
    await initialize();
    _rows = <String, ProjectRecord>{
      ..._rows,
      for (final ProjectRecord record in records) record.id: record,
    };
  }

  @override
  Future<void> delete(String id) async {
    await initialize();
    _rows.remove(id);
  }

  @override
  Future<void> clear() async {
    await initialize();
    _rows = <String, ProjectRecord>{};
  }
}

/// ترتيب موحّد: الأحدث تعديلاً أولاً، والمعرّف يفصل عند تساوي الوقت فيبقى
/// الترتيب ثابتاً بين قراءتين.
void _sortByUpdated(List<ProjectRecord> records) {
  records.sort((ProjectRecord a, ProjectRecord b) {
    final int byTime = b.updatedAt.compareTo(a.updatedAt);
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  });
}
