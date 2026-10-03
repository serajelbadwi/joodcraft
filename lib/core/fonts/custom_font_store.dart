import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'custom_font_face.dart';

/// مخزن الخطوط المخصصة محلياً — لا يمر أي بايت عبر الشبكة.
///
/// التنفيذ الافتراضي يستخدم `SharedPreferences` لأنه يعمل على ويندوز وويب
/// ولينكس/ماك بلا أي إعداد إضافي: على سطح المكتب يُكتب ملف JSON في مجلد
/// بيانات التطبيق، وعلى الويب في `localStorage`. الواجهة قابلة للحقن حتى
/// تُختبر منطقية الإضافة/الحذف بلا أي منصة.
abstract interface class CustomFontStore {
  Future<List<CustomFontFace>> loadAll();

  Future<void> saveAll(List<CustomFontFace> faces);
}

/// تخزين دائم عبر `SharedPreferences`.
class SharedPreferencesCustomFontStore implements CustomFontStore {
  SharedPreferencesCustomFontStore({this.key = defaultKey});

  /// المفتاح يحمل إصداراً حتى يمكن تغيير الشكل لاحقاً بلا كسر مكتبة قديمة.
  static const String defaultKey = 'joodcraft.custom_fonts.v1';

  final String key;

  @override
  Future<List<CustomFontFace>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <CustomFontFace>[];
    return decodeFaces(raw);
  }

  @override
  Future<void> saveAll(List<CustomFontFace> faces) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (faces.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, encodeFaces(faces));
  }

  /// فك ترميز قائمة الخطوط — مشترك مع الاختبارات، ولا يرمي على محتوى تالف.
  static List<CustomFontFace> decodeFaces(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return <CustomFontFace>[];
    }
    if (decoded is! List) return <CustomFontFace>[];
    return decoded
        .map(CustomFontFace.fromJson)
        .whereType<CustomFontFace>()
        .toList(growable: false);
  }

  static String encodeFaces(List<CustomFontFace> faces) =>
      jsonEncode(faces.map((CustomFontFace f) => f.toJson()).toList());
}

/// تخزين في الذاكرة — للاختبارات وللمعاينة السريعة.
class InMemoryCustomFontStore implements CustomFontStore {
  InMemoryCustomFontStore([List<CustomFontFace>? initial])
      : _faces = <CustomFontFace>[...?initial];

  List<CustomFontFace> _faces;

  List<CustomFontFace> get faces => List<CustomFontFace>.unmodifiable(_faces);

  @override
  Future<List<CustomFontFace>> loadAll() async =>
      List<CustomFontFace>.from(_faces);

  @override
  Future<void> saveAll(List<CustomFontFace> faces) async {
    _faces = <CustomFontFace>[...faces];
  }
}
