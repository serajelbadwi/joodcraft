/// تطبيع روابط Google Drive إلى صيغة صورة **مباشرة** قابلة لعرض في `Image.network`.
///
/// رابط المشاركة العادي لصورة على درايف هو **صفحة عرض** لا صورة:
/// `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
/// وحين يُخزَّن هكذا في `image_url` تُحمّل الشبكة صفحة HTML بدل الصورة
/// فتظهر أيقونة الصورة المكسورة. الحل: استخراج `FILE_ID` وتحويله إلى رابط
/// المُصغّرة المباشر:
/// `https://drive.google.com/thumbnail?id=FILE_ID&sz=w1000`
///
/// التطبيع يجري **عند الحفظ** (لكل ما يُكتب مستقبلاً) **وعند القراءة**
/// (للصفوف المخزّنة قديماً بالرابط القديم) فلا يحتاج أحد إلى تنظيف القاعدة
/// يدوياً، ويكون الرابط في القاعدة دائماً في صورته الجاهزة للعرض.
library;

/// حوّل رابط صورة Google Drive إلى صيغة مباشرة (`thumbnail…sz=w1000`).
///
/// الصيغ المقبولة عند المدخل (تُقبل كلها ويُستخرج منها نفس المعرّف):
/// * `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
/// * `https://drive.google.com/file/d/FILE_ID/view`
/// * `https://drive.google.com/open?id=FILE_ID`
/// * `https://drive.google.com/uc?export=view&id=FILE_ID`
/// * `https://drive.google.com/thumbnail?id=FILE_ID&sz=w400`
///
/// أي رابط **ليس** من Drive يعود كما هو دون تغيير (روابط الدلو العام
/// `village-ads` وغيرها تبقى سليمة)، والنصّ الفارغ يعود `null` ليُحفظ
/// الحقل فارغاً لا بسلسلة فارغة.
String? normalizeGoogleDriveUrl(String url) {
  final String raw = url.trim();
  if (raw.isEmpty) return null;

  String? id = _driveFileId(raw);
  if (id == null) return raw;

  return 'https://drive.google.com/thumbnail?id=$id&sz=w1000';
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
