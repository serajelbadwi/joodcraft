import 'dart:convert';
import 'dart:typed_data';

import '../../assets/assets_controller.dart';
import '../../assets/user_asset.dart';
import '../../fonts/custom_font_controller.dart';
import '../../fonts/custom_font_face.dart';
import '../../models/template_document.dart';
import 'jood_archive.dart';
import 'jood_project.dart';

/// قارئ ملفات ‎.jood‎ — يفكّ الأرشيف ويعيد [JoodProject] كاملاً.
///
/// **متسامح عمداً:** ملحق تالف أو فهرسه غائب لا يُسقط الملف كله؛ يُتجاهل السجل
/// ويُسجَّل معرّفه ضمن `missing`، فيبقى المستند قابلاً للفتح. أما مستند تالف أو
/// بصمة صيغة خاطئة فيُرمى [JoodArchiveException] برسالة عربية واضحة.
class JoodProjectImporter {
  const JoodProjectImporter();

  /// يقرأ بايتات الملف ويعيد المشروع. يرمي [JoodArchiveException] على ملف غير
  /// صالح أو ليس من JoodCraft.
  JoodProject read(List<int> bytes) {
    final JoodArchive archive = JoodArchive.decode(bytes);

    final Map<String, dynamic>? manifest =
        archive.jsonOf(JoodFormat.documentFile);
    if (manifest == null) {
      throw const JoodArchiveException(
        'ملف المشروع لا يحوي مستنداً صالحاً (document.json مفقود أو تالف).',
      );
    }
    if ('${manifest['format'] ?? ''}' != JoodFormat.formatKey) {
      throw const JoodArchiveException(
        'هذا الملف ليس ملف مشروع JoodCraft.',
      );
    }

    final Object? rawDocument = manifest['document'];
    if (rawDocument is! Map) {
      throw const JoodArchiveException('مستند المشروع تالف.');
    }
    final TemplateDocument document =
        TemplateDocument.fromJson(Map<String, dynamic>.from(rawDocument));

    final List<UserAsset> assets = _readAssets(archive);
    final List<CustomFontFace> fonts = _readFonts(archive);

    final Uint8List? thumbnail = archive.bytesOf(JoodFormat.thumbnailFile);

    return JoodProject(
      document: document,
      title: '${manifest['title'] ?? 'مشروع مستورد'}',
      exportedAt:
          DateTime.tryParse('${manifest['exported_at']}') ?? DateTime.now(),
      schemaVersion: (manifest['schema_version'] as num?)?.toInt(),
      thumbnailPng: (thumbnail == null || thumbnail.isEmpty) ? null : thumbnail,
      assets: assets,
      fonts: fonts,
      missingAssetIds: _stringList(manifest['missing_assets']),
      missingFontFamilies: _stringList(manifest['missing_fonts']),
    );
  }

  /// يقرأ الملف ثم **يسجّل ملحقاته** في مكتبتي الأصول والخطوط المحليتين.
  ///
  /// الأصول/الخطوط تُدمج بمعرّفاتها الأصلية (تجاوز السجل الموجود بنفس المعرّف)
  /// فتظل مراجع المستند صالحة بلا إعادة تعيين يدوية. يعيد المشروع المقروء.
  Future<JoodProject> readAndRestore(
    List<int> bytes, {
    AssetsController? assets,
    CustomFontController? fonts,
  }) async {
    final JoodProject project = read(bytes);
    if (assets != null && project.assets.isNotEmpty) {
      await assets.importAll(project.assets);
    }
    if (fonts != null && project.fonts.isNotEmpty) {
      await fonts.importAll(project.fonts);
    }
    return project;
  }

  List<UserAsset> _readAssets(JoodArchive archive) {
    final Map<String, dynamic>? index =
        archive.jsonOf(JoodFormat.assetsIndexFile);
    final Object? items = index?['items'];
    if (items is! List) return const <UserAsset>[];
    final List<UserAsset> result = <UserAsset>[];
    for (final Object? item in items) {
      if (item is! Map) continue;
      final Map<String, dynamic> entry = Map<String, dynamic>.from(item);
      final String? file = _fileOf(entry);
      if (file == null) continue;
      final Uint8List? data = archive.bytesOf(file);
      if (data == null || data.isEmpty) continue;
      // نُعيد البايتات إلى حقل `data` بصيغة Base64 كما يتوقّعها [UserAsset].
      entry['data'] = base64Encode(data);
      final UserAsset? asset = UserAsset.fromJson(entry);
      if (asset != null) result.add(asset);
    }
    return result;
  }

  List<CustomFontFace> _readFonts(JoodArchive archive) {
    final Map<String, dynamic>? index =
        archive.jsonOf(JoodFormat.fontsIndexFile);
    final Object? items = index?['items'];
    if (items is! List) return const <CustomFontFace>[];
    final List<CustomFontFace> result = <CustomFontFace>[];
    for (final Object? item in items) {
      if (item is! Map) continue;
      final Map<String, dynamic> entry = Map<String, dynamic>.from(item);
      final String? file = _fileOf(entry);
      if (file == null) continue;
      final Uint8List? data = archive.bytesOf(file);
      if (data == null || data.isEmpty) continue;
      entry['data'] = base64Encode(data);
      final CustomFontFace? face = CustomFontFace.fromJson(entry);
      if (face != null) result.add(face);
    }
    return result;
  }

  static String? _fileOf(Map<String, dynamic> entry) {
    final String file = '${entry['file'] ?? ''}'.trim();
    return file.isEmpty ? null : file;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return <String>[
      for (final Object? item in raw)
        if ('$item'.trim().isNotEmpty) '$item'.trim(),
    ];
  }
}
