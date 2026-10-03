import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'template_record.dart';

/// مخزن القوالب المحلية — يحفظ القوالب على جهاز المستخدم بلا أي شبكة.
///
/// التنفيذ الافتراضي يستخدم `SharedPreferences` (ملف JSON في مجلد بيانات
/// التطبيق على سطح المكتب، و`localStorage` على الويب)، والواجهة قابلة للحقن
/// حتى تُختبر الاستعادة أوفلاين بلا منصة.
abstract interface class LocalTemplateStore {
  Future<List<TemplateRecord>> loadAll();

  Future<void> saveAll(List<TemplateRecord> records);
}

/// تخزين دائم عبر `SharedPreferences`.
class SharedPreferencesLocalTemplateStore implements LocalTemplateStore {
  SharedPreferencesLocalTemplateStore({this.key = defaultKey});

  /// المفتاح يحمل إصداراً حتى يمكن تغيير الشكل لاحقاً بلا كسر مكتبة قديمة.
  static const String defaultKey = 'joodcraft.local_templates.v1';

  final String key;

  @override
  Future<List<TemplateRecord>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <TemplateRecord>[];
    return decodeTemplates(raw);
  }

  @override
  Future<void> saveAll(List<TemplateRecord> records) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (records.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, encodeTemplates(records));
  }

  /// فك ترميز القوالب — مشترك مع الاختبارات، ولا يرمي على سجل تالف.
  static List<TemplateRecord> decodeTemplates(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return <TemplateRecord>[];
    }
    if (decoded is! List) return <TemplateRecord>[];
    return decoded
        .whereType<Map>()
        .map((Map<dynamic, dynamic> row) =>
            TemplateRecord.fromJson(Map<String, dynamic>.from(row)))
        .where((TemplateRecord record) => record.id.isNotEmpty)
        .toList(growable: false);
  }

  static String encodeTemplates(List<TemplateRecord> records) =>
      jsonEncode(records.map((TemplateRecord r) => r.toJson()).toList());
}

/// تخزين في الذاكرة — للاختبارات وللمعاينة السريعة.
class InMemoryLocalTemplateStore implements LocalTemplateStore {
  InMemoryLocalTemplateStore([List<TemplateRecord>? initial])
      : _records = <TemplateRecord>[...?initial];

  List<TemplateRecord> _records;

  List<TemplateRecord> get records => List<TemplateRecord>.unmodifiable(_records);

  @override
  Future<List<TemplateRecord>> loadAll() async =>
      List<TemplateRecord>.from(_records);

  @override
  Future<void> saveAll(List<TemplateRecord> records) async {
    _records = <TemplateRecord>[...records];
  }
}
