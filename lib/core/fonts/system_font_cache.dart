import 'dart:collection';

/// كاش كسول عام لقيم خطوط النظام.
///
/// **المشكلة التي يحلّها:** كان فحص خطوط النظام يقرأ مجلدات النظام والسجل من
/// الصفر في كل مرة يُختار فيها خط نظامي، وكانت بايتات ملف الخط تُقرأ من القرص
/// في كل طلب. الآن يُحسب كل مفتاح **مرة واحدة** ويُحفظ (الوعد الجاري ثم القيمة
/// الجاهزة)، فلا يتكرر الفحص ولا إعادة قراءة الملفات عند فتح منتقي الخطوط أو
/// تبديل الخط.
///
/// **التزامن:** إن تسابق طلبان على المفتاح نفسه اشتركا في الوعد الجاري، فيجري
/// الحساب مرّة واحدة فقط. ونتيجة حساب قديم أُطلق قبل استبداله عبر [get] بـ
/// [force] لا تُكتب فوق الأحدث (حماية من السباق).
///
/// **الحدّ الأعلى (LRU):** بعض الخطوط ثقيلة (ميجابايتات)، فمع [maxEntries] أكبر
/// من صفر نُبقي أحدث عدد محدود من المفاتيح ونُسقط الأقدم؛ وإعادة الطلب اللاحقة
/// تُقرأ من المصدر من جديد بلا أي خطأ. القيمة صفر تعني «بلا حدّ أعلى» (مناسب
/// لنتيجة الفحص الصغيرة).
class SystemFontCache<V> {
  SystemFontCache({this.maxEntries = 0})
      : assert(maxEntries >= 0, 'maxEntries لا يكون سالباً.');

  /// أقصى عدد مفاتيح محفوظة، أو `0` لبلا حدّ أعلى.
  final int maxEntries;

  // `LinkedHashMap` يحفظ ترتيب الإدخال، فأول مفتاح هو «الأقدم استخداماً».
  final LinkedHashMap<String, Future<V>> _entries =
      LinkedHashMap<String, Future<V>>();
  final Map<String, V> _values = <String, V>{};

  int _hits = 0;
  int _misses = 0;

  /// عدد المفاتيح المخزّنة حالياً (وعداً جارياً أو قيمة جاهزة).
  int get length => _entries.length;

  /// عدد مرات إصابة الكاش (إعادة قيمة محفوظة).
  int get hits => _hits;

  /// عدد مرات إخفاقه (تشغيل [load]).
  int get misses => _misses;

  /// هل للمفتاح مدخل مخزّن؟
  bool containsKey(String key) => _entries.containsKey(key);

  /// القيمة الجاهزة إن اكتمل حسابها، وإلا `null`.
  ///
  /// استخدم [containsKey] للتفريق بين «قيمة `null` محفوظة» و«لا مدخل».
  V? valueOf(String key) => _values[key];

  /// يعيد قيمة [key]: تُحسب بـ [load] مرة واحدة، ثم يُعاد المخزّن.
  ///
  /// * [force] = true يعيد الحساب ويستبدل المخزّن (لأداة «تحديث» مثلاً).
  Future<V> get(String key, Future<V> Function() load, {bool force = false}) {
    if (!force) {
      final Future<V>? cached = _entries.remove(key);
      if (cached != null) {
        _entries[key] = cached; // أعِده في المؤخّرة = «أحدث استخداماً».
        _hits++;
        return cached;
      }
    }
    _misses++;
    final Future<V> fresh = load();
    _entries[key] = fresh;
    _trim();
    // نسجّل القيمة الجاهزة للتشخيص، لكن فقط إن بقيت هذه هي النسخة الحالية
    // (لم يستبدلها force أو يُسقطها LRU في الأثناء).
    fresh.then(
      (V value) {
        if (identical(_entries[key], fresh)) _values[key] = value;
      },
      onError: (Object _) {
        // الخطأ يُعاد للمستدعي عبر `fresh` نفسه؛ هنا نتجاهله فقط لئلا يُعدّ
        // خطأً غير مُلتقَط.
      },
    );
    return fresh;
  }

  /// إسقاط «الأقل استخداماً» حتى لا يتجاوز المخزّن الحدّ الأعلى.
  void _trim() {
    if (maxEntries <= 0) return;
    while (_entries.length > maxEntries) {
      final String oldest = _entries.keys.first;
      _entries.remove(oldest);
      _values.remove(oldest);
    }
  }

  /// إزالة مفتاح واحد (عند طلب إعادة قراءة مصدره).
  void remove(String key) {
    _entries.remove(key);
    _values.remove(key);
  }

  /// تفريغ الكاش كله (في الاختبارات أو عند إعادة ضبط كامل) مع تصفير العدّادات.
  void clear() {
    _entries.clear();
    _values.clear();
    _hits = 0;
    _misses = 0;
  }
}
