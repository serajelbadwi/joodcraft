import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'asset_image_disk_cache.dart';
import 'user_asset.dart';

/// ذاكرة وسيطة لبيانات الصور المفكوكة من Base64 وموفّرات الرسم المشتقّة منها.
///
/// **المشكلة التي تحلّها:** `UserAsset.bytes` تفكّ ترميز Base64 في كل نداء، وكان
/// `ElementView` يبني `Image.memory(asset.bytes)` في كل `build`. وبما أن فكّ
/// الترميز يُنتج قائمة بايتات جديدة في كل مرة، يتغيّر مفتاح `MemoryImage` عند
/// فلاتر فتُمحى نتيجة `imageCache` وتُعاد رَستَرة صورة الإطار/الخلفية عالية
/// الدقة عشرات المرات في الثانية أثناء السحب — وهو السبب الرئيس لتجمّد المحرّر
/// عند الاستخدام المطوّل.
///
/// **الحل:** نحفظ نسخة واحدة من البايتات (وموفّر `MemoryImage` المبني عليها)
/// لكل أصل، فيثبت مفتاح `MemoryImage` ويُعاد استخدام الصورة المفكوكة من
/// `PaintingBinding.imageCache` بدل إعادة فكّها في كل إطار.
///
/// **الحدّ الأعلى (LRU):** الذاكرة عالمية، وبعض الصور (الإطارات/الخلفيات عالية
/// الدقة) ثقيلة. لمنع تضخّم الاستهلاك مع القوالب الكبيرة نُبقي أحدث
/// [maxEntries] عنصراً فقط ونُسقط الأقدم «الأقل استخداماً» تلقائياً — دون أي
/// أثر على العرض لأن الويدجت المعروض يملك مرجع موفّره أصلاً، وإعادة الطلب
/// اللاحقة تُعيد الفكّ والبناء تلقائياً.
///
/// **طبقة القرص:** هذه الذاكرة تضيع بإغلاق التطبيق، فتعيد الفتحة التالية فكّ
/// Base64 من جديد. لذلك تُساندها طبقة قرصية ([AssetImageDiskCache]) تحفظ
/// البايتات المفكوكة، ويسخّنها [preload] عند استعادة المكتبة فيصير فتح القالب
/// بعد إعادة التشغيل إعادة استخدام مباشرة للصورة بلا إعادة فكّها.
class AssetImageCache {
  AssetImageCache._({this.maxEntries = defaultMaxEntries})
      : assert(maxEntries > 0, 'maxEntries يجب أن يكون أكبر من صفر.');

  /// العدد الافتراضي الأقصى للعناصر المحفوظة (بايتات + موفّرات).
  static const int defaultMaxEntries = 64;

  static final AssetImageCache instance = AssetImageCache._();

  /// سقف عدد العناصر المحفوظة في كل خريطة.
  final int maxEntries;

  // `Map` في دارت يحفظ ترتيب الإدخال، فنستخدم أول مفتاح كـ«الأقدم».
  final Map<String, Uint8List> _bytes = <String, Uint8List>{};
  final Map<String, ImageProvider> _providers = <String, ImageProvider>{};

  /// عدد الأصول المخزّنة (للتشخيص والاختبارات).
  int get length => _bytes.length;

  /// عدد موفّرات الرسم المخزّنة (للتشخيص).
  int get providerCount => _providers.length;

  static String _keyForAsset(String id) => 'a:$id';

  /// إرجاع بايتات مفتاح — مع تحديث «حداثة» استخدامه، وإلا فكّها وتخزينها.
  ///
  /// `load` يرمي (مثل Base64 غير صالح) فلا يُخزَّن شيء.
  Uint8List _bytesFor(String key, Uint8List Function() load) {
    final Uint8List? existing = _bytes.remove(key);
    if (existing != null) {
      _bytes[key] = existing; // أعِده للمؤخّرة = «أحدث استخداماً».
      return existing;
    }
    final Uint8List value = load();
    _bytes[key] = value;
    _trim();
    return value;
  }

  /// تحديث حداثة مفتاح قائم دون تغيير قيمته.
  void _touchBytes(String key) {
    final Uint8List? existing = _bytes.remove(key);
    if (existing != null) _bytes[key] = existing;
  }

  /// إسقاط «الأقل استخداماً» حتى لا يتجاوز أي من المخزنين الحدّ الأعلى.
  void _trim() {
    while (_bytes.length > maxEntries) {
      final String oldest = _bytes.keys.first;
      _bytes.remove(oldest);
      _providers.remove(oldest);
    }
    while (_providers.length > maxEntries) {
      final String oldest = _providers.keys.first;
      _providers.remove(oldest);
      _bytes.remove(oldest);
    }
  }

  /// بايتات أصل المستخدم — تُفكّ مرة واحدة ثم تُخزّن.
  Uint8List bytesForAsset(UserAsset asset) =>
      _bytesFor(_keyForAsset(asset.id), () => asset.bytes);

  /// بايتات أصل مخزّنة مسبقاً (من رسم اللوحة) بلا الحاجة إلى كائن [UserAsset].
  ///
  /// تُستخدم كاحتياط في محرّك الـ PDF: إن تعذّر الوصول إلى الأصل من المتحكم
  /// لكنه رُسم على Canvas سابقاً، نُصدر البكسلات نفسها التي رآها المستخدم.
  Uint8List? cachedBytesForAsset(String id) {
    final String key = _keyForAsset(id);
    final Uint8List? cached = _bytes[key];
    if (cached == null) return null;
    _touchBytes(key);
    return cached;
  }

  /// بايتات صورة مضمّنة (Base64 بلا بادئة data URI) — تُفكّ مرة واحدة.
  ///
  /// يرمي إن كانت البيانات غير صالحة، ولا يُخزّن حينها شيئاً.
  Uint8List bytesForBase64(String base64Data) =>
      _bytesFor(base64Data, () => base64Decode(base64Data));

  /// موفّر رسم مشتق من بايتات أصل — يُبنى مرة واحدة ويُعاد استخدامه، فيتطابق
  /// مفتاحه مع `imageCache` عبر الإطارات.
  ImageProvider providerForAsset(UserAsset asset) {
    final String key = _keyForAsset(asset.id);
    final ImageProvider? cached = _providers[key];
    if (cached != null) {
      _touchBytes(key);
      return cached;
    }
    final ImageProvider provider = MemoryImage(bytesForAsset(asset));
    _providers[key] = provider;
    _trim();
    return provider;
  }

  /// موفّر رسم لصورة مضمّنة (Base64).
  ImageProvider providerForBase64(String base64Data) {
    final ImageProvider? cached = _providers[base64Data];
    if (cached != null) {
      _touchBytes(base64Data);
      return cached;
    }
    final ImageProvider provider =
        MemoryImage(bytesForBase64(base64Data));
    _providers[base64Data] = provider;
    _trim();
    return provider;
  }

  // ==========================================================================
  //  الطبقة القرصية (إعادة الاستخدام عبر إعادات التشغيل)
  // ==========================================================================

  /// يسخّن الذاكرة من الكاش القرصي عند استعادة مكتبة الأصول.
  ///
  /// لكل أصل غير موجود في الذاكرة: نجرّب قراءة البايتات المفكوكة من القرص (وهو
  /// ما يجعل فتح القالب بعد إعادة التشغيل يعيد استخدام الصورة بلا إعادة فكّ
  /// Base64)، وإن غابت نفكّها من Base64 ونحفظها للفتحات التالية.
  ///
  /// لا يرمي أبداً: أي فشل في أصل واحد لا يوقف البقية.
  Future<void> preload(Iterable<UserAsset> assets) async {
    for (final UserAsset asset in assets) {
      final String key = _keyForAsset(asset.id);
      if (_bytes.containsKey(key)) continue;

      Uint8List? fromDisk;
      try {
        fromDisk = await AssetImageDiskCache.instance.read(asset.id);
      } on Object catch (_) {
        fromDisk = null;
      }
      if (fromDisk != null && fromDisk.isNotEmpty) {
        _store(key, fromDisk);
        continue;
      }

      final Uint8List decoded;
      try {
        decoded = asset.bytes;
      } on Object catch (_) {
        continue; // محتوى تالف: نتجاهله بلا كسر الاستعادة.
      }
      _store(key, decoded);
      // كتابة غير حاجزة: التسخين لا يجوز أن يتوقّف على القرص.
      unawaited(AssetImageDiskCache.instance.write(asset.id, decoded));
    }
  }

  /// يخزّن بايتات أصل في الذاكرة ويجدول حفظها على القرص.
  ///
  /// يُستعمل عند إضافة أصل جديد كي يجدته الفتح التالي في الكاش القرصي. الذاكرة
  /// تُحدَّث فوراً، والكتابة القرصية غير حاجزة (تحسين خلفي لا يؤخّر الإضافة).
  Uint8List putAndPersist(UserAsset asset, Uint8List bytes) {
    _store(_keyForAsset(asset.id), bytes);
    unawaited(AssetImageDiskCache.instance.write(asset.id, bytes));
    return bytes;
  }

  void _store(String key, Uint8List value) {
    _bytes[key] = value;
    _trim();
  }

  /// إزالة أصل واحد (عند حذفه من المكتبة) حتى لا تبقى صورة ميتة في الذاكرة
  /// ولا نسخة يتيمة على القرص.
  void evictAsset(String id) {
    final String key = _keyForAsset(id);
    _bytes.remove(key);
    _providers.remove(key);
    unawaited(AssetImageDiskCache.instance.remove(id));
  }

  /// تفريغ الذاكرة كاملة (إغلاق المحرّر أو إعادة ضبط القالب).
  ///
  /// لا يمسّ الطبقة القرصية: هي الذاكرة الدائمة التي يُعاد الاستخدام منها في
  /// الفتحة التالية، وإنما نُفرّغ الذاكرة المؤقّتة فقط.
  void clear() {
    _bytes.clear();
    _providers.clear();
  }
}
