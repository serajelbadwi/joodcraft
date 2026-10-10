import 'dart:typed_data';

import '../../assets/assets_controller.dart';
import '../../assets/embedded_assets.dart';
import '../../assets/user_asset.dart';
import '../../constants/app_constants.dart';
import '../../fonts/custom_font_controller.dart';
import '../../fonts/custom_font_face.dart';
import '../../models/template_document.dart';
import 'jood_archive.dart';
import 'jood_project.dart';

/// كاتب ملفات ‎.jood‎ — يحوّل مستنداً حيّاً إلى **ملف واحد مستقلّ**.
///
/// الهيكل داخل الأرشيف:
/// ```
/// document.json      المخطّط: الصيغة + إصدارها + العنوان + المستند الكامل
/// assets/index.json  فهرس الأصول (بلا بايتات) + assets/<id>.<ext> لكل أصل
/// fonts/index.json   فهرس الخطوط + fonts/<family>.<ext> لكل وجه
/// thumbnail.png      صورة مصغّرة عالية الجودة (اختيارية)
/// ```
///
/// كل البايتات **مضمّنة**: لا مسار محلي مطلق ولا مرجع خارجي، فينتقل الملف بين
/// الأجهزة بلا روابط مفقودة. والكاتب **لا يلمس الشبكة** ولا يعتمد على الشاشة —
/// يمكن استدعاؤه من isolate خلفي لحفظ غير حاجز.
class JoodProjectExporter {
  const JoodProjectExporter();

  /// يبني بايتات ملف ‎.jood‎ من [document] وملحقاته المرتبطة فقط.
  ///
  /// [assets]/[fonts] اختياريان: عند غيابهما يُصدَّر المستند وحده (يُفيد
  /// الاختبارات وللتصدير المجرّد). الأصول/الخطوط التي يشير إليها المستند وتغيب
  /// عن المكتبة تُحفظ أسماؤها في `missing` داخل المخطّط بدل إسقاط التصدير.
  Uint8List export({
    required TemplateDocument document,
    required String title,
    AssetsController? assets,
    CustomFontController? fonts,
    Uint8List? thumbnailPng,
    DateTime? now,
  }) {
    final JoodArchive archive = JoodArchive();
    final DateTime stamp = now ?? DateTime.now();
    final String cleanTitle =
        title.trim().isEmpty ? 'مشروع بلا عنوان' : title.trim();

    final _AssetBundle assetBundle =
        _packAssets(archive, document, assets);
    final _FontBundle fontBundle = _packFonts(archive, document, fonts);

    if (thumbnailPng != null && thumbnailPng.isNotEmpty) {
      archive.add(JoodFormat.thumbnailFile, thumbnailPng);
    }

    archive.addJson(JoodFormat.documentFile, <String, dynamic>{
      'format': JoodFormat.formatKey,
      'format_version': JoodFormat.formatVersion,
      'schema_version': AppConstants.layoutSchemaVersion,
      'title': cleanTitle,
      'exported_at': stamp.toIso8601String(),
      'missing_assets': assetBundle.missing,
      'missing_fonts': fontBundle.missing,
      'document': document.toJson(),
    });

    return archive.encode();
  }

  _AssetBundle _packAssets(
    JoodArchive archive,
    TemplateDocument document,
    AssetsController? assets,
  ) {
    final List<Map<String, dynamic>> index = <Map<String, dynamic>>[];
    final List<String> missing = <String>[];
    for (final String id in referencedAssetIds(document)) {
      final UserAsset? asset = assets?.byId(id);
      if (asset == null) {
        missing.add(id);
        continue;
      }
      final String ext = _imageExtension(asset);
      final String path = '${JoodFormat.assetsPrefix}${_safeFile(asset.id)}$ext';
      archive.add(path, asset.bytes);
      index.add(<String, dynamic>{
        ...asset.toJson(),
        'file': path,
      }..remove('data'));
    }
    archive.addJson(
      JoodFormat.assetsIndexFile,
      <String, dynamic>{'items': index},
    );
    return _AssetBundle(missing: missing);
  }

  _FontBundle _packFonts(
    JoodArchive archive,
    TemplateDocument document,
    CustomFontController? fonts,
  ) {
    final List<Map<String, dynamic>> index = <Map<String, dynamic>>[];
    final List<String> missing = <String>[];
    for (final String family in referencedCustomFontFamilies(document)) {
      final List<CustomFontFace> faces = fonts?.faces
              .where((CustomFontFace f) => f.family == family)
              .toList(growable: false) ??
          const <CustomFontFace>[];
      if (faces.isEmpty) {
        missing.add(family);
        continue;
      }
      for (final CustomFontFace face in faces) {
        final String ext = _fontExtension(face.fileName);
        final String path =
            '${JoodFormat.fontsPrefix}${_safeFile(face.family)}-${face.weight}$ext';
        archive.add(path, face.bytes);
        index.add(<String, dynamic>{
          ...face.toJson(),
          'file': path,
        }..remove('data'));
      }
    }
    archive.addJson(
      JoodFormat.fontsIndexFile,
      <String, dynamic>{'items': index},
    );
    return _FontBundle(missing: missing);
  }

  static String _imageExtension(UserAsset asset) {
    final String ext = _extensionOf(asset.fileName);
    if (ext.isNotEmpty) return ext;
    return switch (asset.mime) {
      'image/jpeg' => '.jpg',
      'image/gif' => '.gif',
      'image/webp' => '.webp',
      'image/bmp' => '.bmp',
      _ => '.png',
    };
  }

  static String _fontExtension(String fileName) {
    final String ext = _extensionOf(fileName).toLowerCase();
    return ext == '.otf' ? '.otf' : '.ttf';
  }

  static String _extensionOf(String fileName) {
    final String base = fileName.replaceAll('\\', '/').split('/').last;
    final int dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(dot) : '';
  }

  /// يبني اسم ملف آمن داخل الأرشيف من معرّف قد يحمل محارف خاصة.
  static String _safeFile(String value) {
    final String clean = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    return clean.isEmpty ? 'item' : clean;
  }
}

class _AssetBundle {
  const _AssetBundle({required this.missing});

  final List<String> missing;
}

class _FontBundle {
  const _FontBundle({required this.missing});

  final List<String> missing;
}
