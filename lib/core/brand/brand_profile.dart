import 'package:flutter/foundation.dart' show immutable, listEquals, mapEquals;

/// توقيع معتمد محفوظ في هوية المؤسسة.
///
/// [imagePath] هو **معرّف أصل** في مكتبة الأصول (`AssetsController`)، لا مسار
/// ملف على القرص — فيبقى البروفايل ملفاً نصياً صغيراً تُخزَّن صوره مرّة واحدة
/// في مخزن الأصول، ولا تُكرَّر البايتات في كل حفظ للهوية.
@immutable
class BrandSignature {
  const BrandSignature({
    required this.id,
    required this.name,
    this.title = '',
    this.imagePath,
  });

  final String id;

  /// اسم صاحب التوقيع (مثال: «د. أحمد العلي»).
  final String name;

  /// الوظيفة/المسمّى (مثال: «المدير العام»).
  final String title;

  /// معرّف أصل صورة التوقيع، أو `null` إن كان توقيعاً نصياً فقط.
  final String? imagePath;

  BrandSignature copyWith({
    String? name,
    String? title,
    Object? imagePath = _unset,
  }) =>
      BrandSignature(
        id: id,
        name: name ?? this.name,
        title: title ?? this.title,
        imagePath: imagePath == _unset ? this.imagePath : imagePath as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        if (title.trim().isNotEmpty) 'title': title,
        if (imagePath != null && imagePath!.trim().isNotEmpty)
          'image_path': imagePath,
      };

  static BrandSignature? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final String id = '${raw['id'] ?? ''}'.trim();
    final String name = '${raw['name'] ?? ''}'.trim();
    if (id.isEmpty) return null;
    final Object? image = raw['image_path'] ?? raw['imagePath'] ?? raw['path'];
    final String imageText = '${image ?? ''}'.trim();
    return BrandSignature(
      id: id,
      name: name.isEmpty ? 'توقيع بلا اسم' : name,
      title: '${raw['title'] ?? ''}'.trim(),
      imagePath: imageText.isEmpty ? null : imageText,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BrandSignature &&
      other.id == id &&
      other.name == name &&
      other.title == title &&
      other.imagePath == imagePath;

  @override
  int get hashCode => Object.hash(id, name, title, imagePath);
}

/// هوية المؤسسة (البروفايل): الأصول البصرية + البيانات النصية + الألوان والخطوط.
///
/// **لماذا نموذج واحد؟** لأن الترويسة القياسية والتذييل والختم والتوقيع تُبنى من
/// عناصر مختلفة؛ فجمعها في مصدر واحد يجعل زرّ «إدراج الترويسة» يبني الكتلة كاملة
/// بلا أن يبحث المحرّر في أماكن متفرّقة.
@immutable
class BrandProfile {
  const BrandProfile({
    this.primaryLogoPath,
    this.watermarkLogoPath,
    this.officialSealPaths = const <String, String>{},
    this.signatures = const <BrandSignature>[],
    this.orgNameAr = '',
    this.orgNameEn = '',
    this.headerText = '',
    this.footerText = '',
    this.taxOrRegNumber = '',
    this.primaryColorHex = defaultPrimaryHex,
    this.secondaryColorHex = defaultSecondaryHex,
    this.accentColorHex = defaultAccentHex,
    this.defaultHeaderFontFamily,
    this.defaultBodyFontFamily,
  });

  // ألوان الهوية الافتراضية (الذهبي/الكحلي المعروف في التطبيق).
  static const String defaultPrimaryHex = '#1B2539';
  static const String defaultSecondaryHex = '#C7A26B';
  static const String defaultAccentHex = '#9E7B45';

  /// معرّف أصل الشعار الرئيسي (الترويسة).
  final String? primaryLogoPath;

  /// معرّف أصل شعار العلامة المائية (خلفية خفيفة).
  final String? watermarkLogoPath;

  /// ختم/أختام رسمية: اسم الختم ← معرّف أصل الصورة.
  final Map<String, String> officialSealPaths;

  /// التوقيعات المعتمدة (الاسم + المسمّى + الصورة).
  final List<BrandSignature> signatures;

  final String orgNameAr;
  final String orgNameEn;
  final String headerText;
  final String footerText;
  final String taxOrRegNumber;

  final String primaryColorHex;
  final String secondaryColorHex;
  final String accentColorHex;

  /// عائلة خط العناوين (`jsonValue` من `PdfFontFamily`)، أو `null` للافتراضي.
  final String? defaultHeaderFontFamily;

  /// عائلة خط المتن، أو `null` للافتراضي.
  final String? defaultBodyFontFamily;

  // --------------------------------------------------------------------------
  //  قراءات مساعدة
  // --------------------------------------------------------------------------

  bool get hasPrimaryLogo =>
      (primaryLogoPath ?? '').trim().isNotEmpty;

  bool get hasWatermark =>
      (watermarkLogoPath ?? '').trim().isNotEmpty;

  bool get hasSeals => officialSealPaths.isNotEmpty;

  bool get hasSignatures => signatures.isNotEmpty;

  /// أهم اسم للمؤسسة: العربي إن وُجد وإلا الإنجليزي.
  String get displayName =>
      orgNameAr.trim().isNotEmpty ? orgNameAr.trim() : orgNameEn.trim();

  /// هل البروفايل فارغ تماماً (لا شيء يُدرج ولا يُصدَّر)؟
  bool get isEmpty =>
      !hasPrimaryLogo &&
      !hasWatermark &&
      !hasSeals &&
      !hasSignatures &&
      displayName.isEmpty &&
      headerText.trim().isEmpty &&
      footerText.trim().isEmpty &&
      taxOrRegNumber.trim().isEmpty &&
      !hasCustomPalette;

  /// هل خرجت الألوان عن الافتراضي؟
  bool get hasCustomPalette =>
      primaryColorHex.toUpperCase() != defaultPrimaryHex ||
      secondaryColorHex.toUpperCase() != defaultSecondaryHex ||
      accentColorHex.toUpperCase() != defaultAccentHex;

  // --------------------------------------------------------------------------
  //  التعديل
  // --------------------------------------------------------------------------

  BrandProfile copyWith({
    Object? primaryLogoPath = _unset,
    Object? watermarkLogoPath = _unset,
    Map<String, String>? officialSealPaths,
    List<BrandSignature>? signatures,
    String? orgNameAr,
    String? orgNameEn,
    String? headerText,
    String? footerText,
    String? taxOrRegNumber,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? accentColorHex,
    Object? defaultHeaderFontFamily = _unset,
    Object? defaultBodyFontFamily = _unset,
  }) =>
      BrandProfile(
        primaryLogoPath: primaryLogoPath == _unset
            ? this.primaryLogoPath
            : primaryLogoPath as String?,
        watermarkLogoPath: watermarkLogoPath == _unset
            ? this.watermarkLogoPath
            : watermarkLogoPath as String?,
        officialSealPaths: officialSealPaths ?? this.officialSealPaths,
        signatures: signatures ?? this.signatures,
        orgNameAr: orgNameAr ?? this.orgNameAr,
        orgNameEn: orgNameEn ?? this.orgNameEn,
        headerText: headerText ?? this.headerText,
        footerText: footerText ?? this.footerText,
        taxOrRegNumber: taxOrRegNumber ?? this.taxOrRegNumber,
        primaryColorHex: primaryColorHex ?? this.primaryColorHex,
        secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
        accentColorHex: accentColorHex ?? this.accentColorHex,
        defaultHeaderFontFamily: defaultHeaderFontFamily == _unset
            ? this.defaultHeaderFontFamily
            : defaultHeaderFontFamily as String?,
        defaultBodyFontFamily: defaultBodyFontFamily == _unset
            ? this.defaultBodyFontFamily
            : defaultBodyFontFamily as String?,
      );

  /// بروفايل فارغ بألوان الهوية الافتراضية (لبّ زرّ «مسح الهوية»).
  BrandProfile cleared() => const BrandProfile();

  // --------------------------------------------------------------------------
  //  الترميز
  // --------------------------------------------------------------------------

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (hasPrimaryLogo) 'primary_logo': primaryLogoPath,
        if (hasWatermark) 'watermark_logo': watermarkLogoPath,
        if (officialSealPaths.isNotEmpty)
          'seals': <String, dynamic>{...officialSealPaths},
        if (signatures.isNotEmpty)
          'signatures': signatures
              .map((BrandSignature s) => s.toJson())
              .toList(growable: false),
        if (orgNameAr.trim().isNotEmpty) 'org_name_ar': orgNameAr,
        if (orgNameEn.trim().isNotEmpty) 'org_name_en': orgNameEn,
        if (headerText.trim().isNotEmpty) 'header_text': headerText,
        if (footerText.trim().isNotEmpty) 'footer_text': footerText,
        if (taxOrRegNumber.trim().isNotEmpty) 'reg_number': taxOrRegNumber,
        'primary_color': primaryColorHex,
        'secondary_color': secondaryColorHex,
        'accent_color': accentColorHex,
        if ((defaultHeaderFontFamily ?? '').trim().isNotEmpty)
          'header_font': defaultHeaderFontFamily,
        if ((defaultBodyFontFamily ?? '').trim().isNotEmpty)
          'body_font': defaultBodyFontFamily,
      };

  static BrandProfile fromJson(Object? raw) {
    if (raw is! Map) return const BrandProfile();
    final Map<String, String> seals = <String, String>{};
    final Object? rawSeals = raw['seals'] ?? raw['official_seal_paths'];
    if (rawSeals is Map) {
      rawSeals.forEach((Object? key, Object? value) {
        final String name = '${key ?? ''}'.trim();
        final String path = '${value ?? ''}'.trim();
        if (name.isNotEmpty && path.isNotEmpty) seals[name] = path;
      });
    }

    final List<BrandSignature> signatures = <BrandSignature>[];
    final Object? rawSignatures = raw['signatures'];
    if (rawSignatures is List) {
      for (final Object? item in rawSignatures) {
        final BrandSignature? signature = BrandSignature.fromJson(item);
        if (signature != null) signatures.add(signature);
      }
    }

    return BrandProfile(
      primaryLogoPath: _text(raw['primary_logo'] ?? raw['primaryLogoPath']),
      watermarkLogoPath:
          _text(raw['watermark_logo'] ?? raw['watermarkLogoPath']),
      officialSealPaths: seals,
      signatures: signatures,
      orgNameAr: '${raw['org_name_ar'] ?? raw['orgNameAr'] ?? ''}',
      orgNameEn: '${raw['org_name_en'] ?? raw['orgNameEn'] ?? ''}',
      headerText: '${raw['header_text'] ?? raw['headerText'] ?? ''}',
      footerText: '${raw['footer_text'] ?? raw['footerText'] ?? ''}',
      taxOrRegNumber: '${raw['reg_number'] ?? raw['taxOrRegNumber'] ?? ''}',
      primaryColorHex:
          '${raw['primary_color'] ?? defaultPrimaryHex}'.trim().isEmpty
              ? defaultPrimaryHex
              : '${raw['primary_color'] ?? defaultPrimaryHex}'.trim(),
      secondaryColorHex:
          '${raw['secondary_color'] ?? defaultSecondaryHex}'.trim().isEmpty
              ? defaultSecondaryHex
              : '${raw['secondary_color'] ?? defaultSecondaryHex}'.trim(),
      accentColorHex:
          '${raw['accent_color'] ?? defaultAccentHex}'.trim().isEmpty
              ? defaultAccentHex
              : '${raw['accent_color'] ?? defaultAccentHex}'.trim(),
      defaultHeaderFontFamily:
          _text(raw['header_font'] ?? raw['defaultHeaderFontFamily']),
      defaultBodyFontFamily:
          _text(raw['body_font'] ?? raw['defaultBodyFontFamily']),
    );
  }

  static String? _text(Object? value) {
    final String text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  @override
  bool operator ==(Object other) =>
      other is BrandProfile &&
      other.primaryLogoPath == primaryLogoPath &&
      other.watermarkLogoPath == watermarkLogoPath &&
      mapEquals(other.officialSealPaths, officialSealPaths) &&
      listEquals(other.signatures, signatures) &&
      other.orgNameAr == orgNameAr &&
      other.orgNameEn == orgNameEn &&
      other.headerText == headerText &&
      other.footerText == footerText &&
      other.taxOrRegNumber == taxOrRegNumber &&
      other.primaryColorHex == primaryColorHex &&
      other.secondaryColorHex == secondaryColorHex &&
      other.accentColorHex == accentColorHex &&
      other.defaultHeaderFontFamily == defaultHeaderFontFamily &&
      other.defaultBodyFontFamily == defaultBodyFontFamily;

  @override
  int get hashCode => Object.hash(
        primaryLogoPath,
        watermarkLogoPath,
        Object.hashAllUnordered(officialSealPaths.entries),
        Object.hashAll(signatures),
        orgNameAr,
        orgNameEn,
        headerText,
        footerText,
        taxOrRegNumber,
        primaryColorHex,
        secondaryColorHex,
        accentColorHex,
        defaultHeaderFontFamily,
        defaultBodyFontFamily,
      );
}

/// قيمة تفيد «لم يُمرَّر» لتمييزها عن «مُرِّرت كـ null» في التحديث الجزئي.
const Object _unset = Object();
