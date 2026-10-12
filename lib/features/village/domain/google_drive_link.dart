/// تطبيع روابط Google Drive إلى صيغة صورة **مباشرة** قابلة لعرض في `Image.network`.
///
/// رابط المشاركة العادي لصورة على درايف هو **صفحة عرض** لا صورة:
/// `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
/// وحين يُخزَّن هكذا في `image_url` تُحمّل الشبكة صفحة HTML بدل الصورة
/// فتظهر أيقونة الصورة المكسورة.
///
/// **ولماذا لا نستخدم رابط المُصغّرة `drive.google.com/thumbnail?id=…`؟**
/// لأنّه يحوّل (redirect) إلى `lh3.googleusercontent.com`، وهذا التحويل
/// **يفشل في طلبات CORS** — وFlutter على الويب يحمّل كل الصور بوضع CORS
/// (ليرسمها على كانفس WebGL) فالنتيجة: صورة سليمة في المتصفّح لا يراها
/// التطبيق أبداً. لذا نُطبِّع **مباشرة** إلى `lh3.googleusercontent.com`
/// الذي يخدم الصورة بترخيص `Access-Control-Allow-Origin: *` بلا أي
/// تحويل — فيعمل على الويب والموبايل والاختبارات بلا استثناء.
///
/// التطبيع يجري **عند الحفظ** (لكل ما يُكتب مستقبلاً) **وعند القراءة**
/// (للصفوف المخزّنة قديماً بأي صيغة — بما فيها صيغة `thumbnail?id=…`
/// القديمة) فلا يحتاج أحد إلى تنظيف القاعدة يدوياً، ويكون الرابط في
/// القاعدة دائماً في صورته الجاهزة للعرض.
library;

/// حوّل رابط صورة Google Drive إلى صيغة مباشرة (`lh3…/d/FILE_ID=w1000`).
///
/// الصيغ المقبولة عند المدخل (تُقبل كلها ويُستخرج منها نفس المعرّف):
/// * `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
/// * `https://drive.google.com/file/d/FILE_ID/view`
/// * `https://drive.google.com/open?id=FILE_ID`
/// * `https://drive.google.com/uc?export=view&id=FILE_ID`
/// * `https://drive.google.com/thumbnail?id=FILE_ID&sz=w400` (الصيغة القديمة)
///
/// أي رابط **ليس** من Drive يعود كما هو دون تغيير (روابط الدلو العام
/// `village-ads` وغيرها تبقى سليمة)، والرابط المباشر نفسه يعود كما هو،
/// والنصّ الفارغ يعود `null` ليُحفظ الحقل فارغاً لا بسلسلة فارغة.
///
/// **روابط المجلدات** (`/drive/folders/ID`) تعود `null` بدل حفظها: مجلد
/// ليس صورة ولا توجد صيغة تُصيِّره صورة، وحفظه يعني HTML يفشل عرضه كأنه
/// صورة — فالحقّ يبقى فارغاً فتظهر بطاقة الإعلان بلا صورة كما ينبغي.
String? normalizeGoogleDriveUrl(String url) {
  final String raw = url.trim();
  if (raw.isEmpty) return null;
  if (isGoogleDriveFolderUrl(raw)) return null;

  String? id = _driveFileId(raw);
  if (id == null) return raw;

  return 'https://lh3.googleusercontent.com/d/$id=w1000';
}

/// هل هذا الرابط **مجلداً** على Google Drive (`…/drive/folders/ID`)؟
///
/// يرفضه نموذج اللوحة برسالة توضيحية قبل الحفظ فلا يُخزَّن رابط ميت في
/// `image_url` أصلاً (يُستخدم نفسه في التطبيع أعلاه لحماية الصفوف القديمة).
bool isGoogleDriveFolderUrl(String url) {
  final String raw = url.trim();
  if (raw.isEmpty) return false;
  final Uri? uri = Uri.tryParse(raw);
  final String host = uri?.host.toLowerCase() ?? '';
  if (host != 'drive.google.com' && !host.endsWith('.drive.google.com')) {
    return false;
  }
  return uri!.path.contains('/folders/');
}

/// معرّف الملف داخل رابط Drive — `null` إن لم يكن الرابط من Drive.
///
/// المسار `/file/d/ID` مميّز لدرجة أنّ مطابقته كافية أينما وُجد، أمّا معامل
/// `id=` فيُطلب معه أن يكون المضيف `drive.google.com` حتى لا يخطف معرّفات
/// روابط أخرى (`…?id=123` على أي موقع).
String? _driveFileId(String raw) {
  final String? fromPath =
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(raw)?.group(1);
  if (fromPath != null) return fromPath;

  final Uri? uri = Uri.tryParse(raw);
  final String host = uri?.host.toLowerCase() ?? '';
  if (host != 'drive.google.com' && !host.endsWith('.drive.google.com')) {
    return null;
  }
  final String? fromQuery = uri!.queryParameters['id'];
  if (fromQuery == null || fromQuery.isEmpty) return null;
  return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(fromQuery) ? fromQuery : null;
}
