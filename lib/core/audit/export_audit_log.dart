import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نوع المستند الذي صدر في ملف الـ PDF.
enum ExportKind {
  certificate('شهادة', 'certificate'),
  contract('عقد', 'contract'),
  batch('دفعة شهادات', 'batch'),
  project('مشروع/ملف Jood', 'project'),
  preview('معاينة/طباعة', 'preview');

  const ExportKind(this.labelAr, this.dbValue);

  final String labelAr;
  final String dbValue;

  static ExportKind fromDb(String? value) {
    for (final ExportKind kind in ExportKind.values) {
      if (kind.dbValue == value) return kind;
    }
    return ExportKind.certificate;
  }
}

/// سطر واحد في **سجل التصدير**: ما صدر، ومتى، ومن أصدره، وبأي ملف.
///
/// الغرض تدقيقي محلي: من فتح التطبيق على جهاز يريد أن يعرف أي شهادة صدرت
/// ومَن صدرها، بلا سيرفر ولا مزامنة. لا يحمل أي محتوى مستند — بيانات وصفية فقط.
class ExportAuditEntry {
  const ExportAuditEntry({
    required this.id,
    required this.at,
    required this.documentTitle,
    required this.kind,
    this.templateId,
    this.fileName,
    this.pageCount = 1,
    this.adminId,
    this.adminEmail,
    this.adminName,
    this.recipient,
  });

  final String id;
  final DateTime at;

  /// عنوان المستند/القالب المصدر (كما يراه المستخدم في المكتبة).
  final String documentTitle;
  final ExportKind kind;

  /// معرّف القالب/المشروع — يربط السجل بمصدره المحلي إن بقي موجوداً.
  final String? templateId;

  /// اسم الملف الناتج على القرص (إن حُفظ بملف).
  final String? fileName;

  /// عدد الصفحات المولَّدة (صفوف الدفعة مثلاً).
  final int pageCount;

  final String? adminId;
  final String? adminEmail;
  final String? adminName;

  /// الجهة/المستلم في مستندات الشهادات (اختياري — بيانات وصفية).
  final String? recipient;

  /// اسم المدير المعروض، أو «محلي» إن لم تكن هناك جلسة.
  String get adminLabel {
    final String? name = adminName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final String? mail = adminEmail?.trim();
    if (mail != null && mail.isNotEmpty) return mail;
    return 'محلي';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'at': at.toIso8601String(),
        'title': documentTitle,
        'kind': kind.dbValue,
        'templateId': templateId,
        'fileName': fileName,
        'pageCount': pageCount,
        'adminId': adminId,
        'adminEmail': adminEmail,
        'adminName': adminName,
        'recipient': recipient,
      };

  static ExportAuditEntry? fromJson(Map<String, dynamic> json) {
    final Object? at = json['at'];
    final Object? id = json['id'];
    if (id is! String || at is! String) return null;
    final DateTime? parsed = DateTime.tryParse(at);
    if (parsed == null) return null;
    return ExportAuditEntry(
      id: id,
      at: parsed,
      documentTitle: (json['title'] as String?) ?? 'مستند بلا عنوان',
      kind: ExportKind.fromDb(json['kind'] as String?),
      templateId: json['templateId'] as String?,
      fileName: json['fileName'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 1,
      adminId: json['adminId'] as String?,
      adminEmail: json['adminEmail'] as String?,
      adminName: json['adminName'] as String?,
      recipient: json['recipient'] as String?,
    );
  }
}

/// مخزن السجل — واجهة تسمح بمخزن ذاكري في الاختبارات.
abstract interface class ExportAuditStore {
  Future<List<ExportAuditEntry>> load();
  Future<void> save(List<ExportAuditEntry> entries);
}

/// المخزن الحقيقي على الجهاز (تفضيلات مشتركة، مفتاح واحد).
class SharedPreferencesExportAuditStore implements ExportAuditStore {
  const SharedPreferencesExportAuditStore();

  static const String key = 'joodcraft.export_audit.v1';

  @override
  Future<List<ExportAuditEntry>> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(key);
      if (raw == null) return <ExportAuditEntry>[];
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <ExportAuditEntry>[];
      return <ExportAuditEntry>[
        for (final Object? item in decoded)
          if (item is Map)
            ?ExportAuditEntry.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return <ExportAuditEntry>[];
    }
  }

  @override
  Future<void> save(List<ExportAuditEntry> entries) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode(<Map<String, dynamic>>[
          for (final ExportAuditEntry entry in entries) entry.toJson(),
        ]),
      );
    } catch (_) {
      // فشل الأرشفة لا يجب أن يُفشل تصديراً تمّ بنجاح.
    }
  }
}

/// مخزن ذاكري (للاختبارات).
class InMemoryExportAuditStore implements ExportAuditStore {
  InMemoryExportAuditStore([List<ExportAuditEntry>? seed])
      : _entries = <ExportAuditEntry>[...?seed];

  List<ExportAuditEntry> _entries;

  @override
  Future<List<ExportAuditEntry>> load() async =>
      List<ExportAuditEntry>.unmodifiable(_entries);

  @override
  Future<void> save(List<ExportAuditEntry> entries) async {
    _entries = <ExportAuditEntry>[...entries];
  }
}

/// **سجل الشهادات الصادرة** — محلي بالكامل، يُقرأ من الذاكرة بعد الإقلاع.
///
/// يُسجَّل السطر **بعد نجاح** توليد الملف وكتابته فعلاً، فلا يُدخل السجل
/// محاولة فاشلة على أنها إصدار. الحدّ الأقصى يحمي الملف من النموّ الأبدي.
class ExportAuditLog extends ChangeNotifier {
  ExportAuditLog({ExportAuditStore? store})
      : _store = store ?? const SharedPreferencesExportAuditStore();

  /// النسخة العامة — قابلة للاستبدال في الاختبارات (مثل بقية المحرّكات).
  static ExportAuditLog instance = ExportAuditLog();

  /// يُربط **مرّة واحدة عند الإقلاع** بمزوّد الحساب الحالي، فيعرف السجل من
  /// أصدر الملف بلا أن يعتمد `core` على الواجهة ولا على `AuthProvider`.
  /// صيغة قياسية (record) تقطع الاعتماد في الاتجاه الخاطئ.
  static ({String? id, String? email, String? name}) Function()? currentAdmin;

  /// أقصى عدد سطور محفوظة (الأحدث يُبقى).
  static const int maxEntries = 1000;

  final ExportAuditStore _store;

  List<ExportAuditEntry> _entries = <ExportAuditEntry>[];
  bool _loaded = false;

  /// السجل مرتّباً من الأحدث إلى الأقدم.
  List<ExportAuditEntry> get entries =>
      List<ExportAuditEntry>.unmodifiable(_entries);

  bool get isLoaded => _loaded;
  bool get isEmpty => _entries.isEmpty;

  /// يُقرأ مرّة واحدة عند الإقلاع (أو أول عرض للشاشة).
  Future<void> restore() async {
    _entries = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  /// يُضيف سطر تصدير. يُعيد السطر المضاف.
  Future<ExportAuditEntry> record({
    required String documentTitle,
    required ExportKind kind,
    String? templateId,
    String? fileName,
    int pageCount = 1,
    String? adminId,
    String? adminEmail,
    String? adminName,
    String? recipient,
    DateTime? at,
  }) async {
    final DateTime now = at ?? DateTime.now();
    // المدير من الربط العام إن لم يُمرَّر صراحةً (مسار التصدير لا يعرف الواجهة).
    final bool hasExplicitAdmin =
        adminId != null || adminEmail != null || adminName != null;
    final ({String? id, String? email, String? name})? actor =
        hasExplicitAdmin ? null : currentAdmin?.call();
    final ExportAuditEntry entry = ExportAuditEntry(
      id: 'exp_${now.microsecondsSinceEpoch}',
      at: now,
      documentTitle:
          documentTitle.trim().isEmpty ? 'مستند بلا عنوان' : documentTitle.trim(),
      kind: kind,
      templateId: templateId,
      fileName: fileName,
      pageCount: pageCount,
      adminId: adminId ?? actor?.id,
      adminEmail: adminEmail ?? actor?.email,
      adminName: adminName ?? actor?.name,
      recipient: recipient,
    );

    _entries = <ExportAuditEntry>[entry, ..._entries];
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    _loaded = true;
    notifyListeners();
    await _store.save(_entries);
    return entry;
  }

  /// يُفرّغ السجل بالكامل.
  Future<void> clear() async {
    _entries = <ExportAuditEntry>[];
    _loaded = true;
    notifyListeners();
    await _store.save(_entries);
  }
}
