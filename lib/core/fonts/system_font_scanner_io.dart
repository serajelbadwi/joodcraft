import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'system_font_disk_cache.dart';
import 'system_font_models.dart';

/// الدليل الرئيسي لخطوط النظام على Windows.
const String _defaultFontsDir = r'C:\Windows\Fonts';

/// مفتاح السجل الذي يسرد كل الخطوط المثبتة مع اسم عائلتها وملفها.
const String _registryFontsKey =
    r'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts';

/// امتدادات ملفات الخطوط المقبولة.
const List<String> _fontExtensions = <String>['.ttf', '.otf', '.ttc'];

/// كاش القرص المشترك لبايتات خطوط النظام (يُبطل تلقائياً عند تغيّر الملف).
final SystemFontDiskCache _diskCache = SystemFontDiskCache();

/// يفحص خطوط النظام المثبتة على Windows ويُرجعها مجمّعة بالعائلة.
///
/// المصادر بالترتيب: مجلد `C:\Windows\Fonts`، ثم
/// `%LOCALAPPDATA%\Microsoft\Windows\Fonts`، ثم سجل Windows (لتسمية العائلات
/// الحقيقية بدل أسماء الملفات). على الأنظمة غير Windows يُرجع فراغاً فوراً.
Future<WindowsFontDiscoveryResult> discoverSystemFonts({
  String? platform,
  void Function(String source, String error)? onError,
}) async {
  final String os = (platform ?? Platform.operatingSystem).toLowerCase();
  if (!os.contains('windows')) {
    debugPrint(
      '[WindowsSystemFontService] منصة غير Windows — تخطّي فحص الخطوط '
      '(تهدئة سليمة).',
    );
    return const WindowsFontDiscoveryResult(
      families: <WindowsSystemFontFamily>[],
      scannedDirs: <String>[],
      error: null,
    );
  }

  final List<String> scannedDirs = <String>[];
  final Map<String, String> filesByBaseName = <String, String>{};
  final Map<String, List<String>> pathsByFamily = <String, List<String>>{};

  final List<String> dirs = <String>[
    _defaultFontsDir,
    _localAppDataFontsDir(),
  ];
  for (final String dir in dirs) {
    if (dir.isEmpty) continue;
    try {
      final Directory directory = Directory(dir);
      if (!await directory.exists()) continue;
      scannedDirs.add(dir);
      await for (final FileSystemEntity entity in directory.list()) {
        if (entity is! File) continue;
        if (!_isFontFile(entity.path)) continue;
        filesByBaseName[_baseName(entity.path)] = entity.path;
      }
    } on Object catch (error) {
      // صلاحيات مقيدة أو ملف قيد الاستخدام: نتجاهل المصدر ونكمل.
      debugPrint('[WindowsSystemFontService] تعذّر قراءة $dir: $error');
      onError?.call(dir, '$error');
    }
  }

  // السجل يعطي أسماء العائلات الحقيقية (مثل «Arial» بدل «arial»).
  try {
    final Map<String, String> registry = await _readRegistryFonts();
    for (final MapEntry<String, String> entry in registry.entries) {
      final String? family = _familyFromRegistryName(entry.key);
      if (family == null) continue;
      final String? path =
          filesByBaseName[_baseName(entry.value)] ?? _absoluteOrNull(entry.value);
      if (path == null) continue;
      pathsByFamily.putIfAbsent(family, () => <String>[]).add(path);
      // لا نكرّر ربط الملف نفسه باسم عائلة مشتق من اسمه.
      filesByBaseName.remove(_baseName(path));
    }
  } on Object catch (error) {
    debugPrint('[WindowsSystemFontService] تعذّر قراءة السجل: $error');
    onError?.call('registry', '$error');
  }

  // ما تبقّى من الملفات (غير المذكورة في السجل) يُنسب إلى اسم ملفه.
  for (final MapEntry<String, String> entry in filesByBaseName.entries) {
    final String family = _familyFromFileName(entry.key);
    if (family.isEmpty) continue;
    pathsByFamily.putIfAbsent(family, () => <String>[]).add(entry.value);
  }

  final List<WindowsSystemFontFamily> families = pathsByFamily.entries
      .map(
        (MapEntry<String, List<String>> entry) => WindowsSystemFontFamily(
          displayName: entry.key,
          filePaths: List<String>.unmodifiable(entry.value),
        ),
      )
      .toList()
    ..sort((WindowsSystemFontFamily a, WindowsSystemFontFamily b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  debugPrint(
    '[WindowsSystemFontService] اكتُشفت ${families.length} عائلة من '
    '${scannedDirs.length} مجلد.',
  );

  return WindowsFontDiscoveryResult(
    families: families,
    scannedDirs: List<String>.unmodifiable(scannedDirs),
    error: null,
  );
}

/// يقرأ بايتات ملف خط من القرص، أو `null` إن تعذّر (صلاحيات/غياب).
///
/// لا يرمي أبداً: خطوط النظام قد تكون محميّة، والتعذّر يجب أن يُتجاهل بهدوء.
Future<ByteData?> readSystemFontBytes(String path) async {
  try {
    // الكاش القرصي أولاً: فتح لاحق يقرأ من الـSSD بلا مسح القرص الأصلي.
    final Uint8List? cached = await _diskCache.read(path);
    if (cached != null) return ByteData.sublistView(cached);

    final File file = File(path);
    if (!await file.exists()) return null;
    final Uint8List bytes = await file.readAsBytes();
    // حفظ غير حاجز: لا نؤخّر إرجاع البايتات على كتابة الكاش.
    unawaited(_diskCache.write(path, bytes));
    return ByteData.sublistView(bytes);
  } on Object catch (error) {
    // نتجاهل أخطاء الصلاحيات بصمت كما هو مطلوب لخطوط النظام.
    debugPrint('[WindowsSystemFontService] تعذّر قراءة $path: $error');
    return null;
  }
}

/// مجلد خطوط المستخدم المحلية (`%LOCALAPPDATA%\Microsoft\Windows\Fonts`).
String _localAppDataFontsDir() {
  final String? localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData != null && localAppData.isNotEmpty) {
    // الشرطة المائلة للأمام مقبولة على Windows وتجنّب هروب المحارف.
    return '$localAppData/Microsoft/Windows/Fonts';
  }
  final String? userProfile = Platform.environment['USERPROFILE'];
  if (userProfile != null && userProfile.isNotEmpty) {
    return '$userProfile/AppData/Local/Microsoft/Windows/Fonts';
  }
  return '';
}

/// يقرأ جدول الخطوط من سجل Windows. المفتاح ← الملف (اسم ملف أو مسار كامل).
Future<Map<String, String>> _readRegistryFonts() async {
  final Map<String, String> result = <String, String>{};
  final ProcessResult reg = await Process.run('reg', <String>[
    'query',
    _registryFontsKey,
  ]);
  if (reg.exitCode != 0) return result;

  final RegExp linePattern = RegExp(r'^\s*(.+?)\s+REG_SZ\s+(.+?)\s*$');
  for (final String line in reg.stdout.toString().split('\n')) {
    final RegExpMatch? match = linePattern.firstMatch(line);
    if (match == null) continue;
    result[match.group(1)!] = match.group(2)!;
  }
  return result;
}

/// يستخرج اسم العائلة من مفتاح السجل، مثل «Arial (TrueType)» ← «Arial».
String? _familyFromRegistryName(String raw) {
  String name = raw.trim();
  final int paren = name.indexOf('(');
  if (paren > 0) name = name.substring(0, paren).trim();
  // أسماء ملفات قصيرة بلا عائلة واضحة (مثل «Segoe UI Bold Italic» تبقى كما هي).
  if (name.isEmpty) return null;
  return name;
}

/// يشتق اسماً معقولاً للعائلة من اسم ملف الخط.
String _familyFromFileName(String fileName) {
  String name = fileName;
  final int dot = name.lastIndexOf('.');
  if (dot > 0) name = name.substring(0, dot);
  return name.trim();
}

/// المسار المطلق إن كان الإدخال كذلك فعلاً، وإلا `null`.
String? _absoluteOrNull(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.contains('\\') && !trimmed.contains('/')) return null;
  if (File(trimmed).isAbsolute) return trimmed;
  return null;
}

/// اسم الملف بلا مسار (بحروف صغيرة للمطابقة غير الحساسة لحالة الأحرف).
String _baseName(String path) {
  final String normalized = path.replaceAll('\\', '/');
  final int slash = normalized.lastIndexOf('/');
  final String name = slash >= 0 ? normalized.substring(slash + 1) : normalized;
  return name.toLowerCase();
}

/// هل المسار يشير إلى ملف خط قابل للاستخدام؟
bool _isFontFile(String path) {
  final String lower = path.toLowerCase();
  return _fontExtensions.any(lower.endsWith);
}
