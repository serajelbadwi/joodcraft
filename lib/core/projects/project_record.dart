import 'dart:convert';

import '../constants/app_constants.dart';
import '../models/template_document.dart';
import '../templates/template_record.dart';

/// سجل مشروع في المخزن المحلي — جدول `projects`.
///
/// هذا هو الصفّ الواحد من «جدول المشاريع» المحلي، بأعمدة المواصفة حرفياً:
///
/// | العمود | النوع | المعنى |
/// | --- | --- | --- |
/// | `id` | TEXT PRIMARY KEY | معرّف المشروع |
/// | `title` | TEXT | اسم المشروع |
/// | `width` / `height` | REAL | أبعاد الصفحة بالنقطة الفاحصة (pt) |
/// | `layers_data` | TEXT (JSON) | شجرة العناصر والتنسيقات كاملة |
/// | `updated_at` | TEXT (ISO-8601) | آخر تعديل |
/// | `thumbnail_path` | TEXT | مسار الصورة المصغّرة محلياً (اختياري) |
///
/// وأعمدة مساعدة أُضيفت لأن شاشات المكتبة القائمة تفرّق بين الشهادات والعقود
/// (`category`) وتُرتّب بالأحدث وتفتح بالاتجاه الصحيح (`orientation`)، وكلها
/// قيم مستنبطة من المستند نفسه فلا تُخزَّن مرتين: `width/height` تكفي لاشتقاق
/// الاتجاه، لكن تخزينه صراحةً يجعل القراءة أسرع وبلا لبس.
class ProjectRecord {
  const ProjectRecord({
    required this.id,
    required this.title,
    required this.width,
    required this.height,
    required this.layersData,
    required this.updatedAt,
    this.thumbnailPath,
    this.category = TemplateCategory.certificate,
    this.orientation = PageOrientation.landscape,
    this.isPublic = false,
    this.createdAt,
  });

  /// اسم الجدول/المخزن — يُستخدم اسم صندوق Hive نفسه فيبقى الاسم واحداً في
  /// الكود وفي قاعدة البيانات.
  static const String tableName = 'projects';

  /// صاحب المشروع في المخزن المحلي — لا حسابات ولا خادم.
  static const String localUserId = 'local';

  /// مخطط SQL المرافق — للتنفيذات التي تختار SQLite (نفس الأعمدة بالحرف).
  /// الصفوف المخزَّنة الآن في [tableName] مطابقة لهذا المخطط تماماً، فالانتقال
  /// إلى SQLite لاحقاً لا يحتاج إلا كتابة محوّل واحد.
  static const String createTableSql = '''
CREATE TABLE IF NOT EXISTS projects (
  id             TEXT PRIMARY KEY,
  title          TEXT    NOT NULL,
  width          REAL    NOT NULL,
  height         REAL    NOT NULL,
  layers_data    TEXT    NOT NULL,
  updated_at     TEXT    NOT NULL,
  thumbnail_path TEXT,
  category       TEXT    NOT NULL DEFAULT 'certificate',
  orientation    TEXT    NOT NULL DEFAULT 'landscape',
  is_public      INTEGER NOT NULL DEFAULT 0,
  created_at     TEXT
);
CREATE INDEX IF NOT EXISTS projects_updated_at_idx
  ON projects (updated_at DESC);
''';

  final String id;
  final String title;

  /// عرض الصفحة بالنقطة الفاحصة (نفس وحدة المحرّك والطباعة).
  final double width;

  /// ارتفاع الصفحة بالنقطة الفاحصة.
  final double height;

  /// شجرة العناصر والتنسيقات كاملة كـ **نصّ JSON** (عمود `layers_data`).
  final String layersData;

  final DateTime updatedAt;

  /// مسار الصورة المصغّرة على القرص — `null` إن لم تُلتقط بعد.
  final String? thumbnailPath;

  final TemplateCategory category;
  final PageOrientation orientation;
  final bool isPublic;
  final DateTime? createdAt;

  bool get hasThumbnail => (thumbnailPath ?? '').trim().isNotEmpty;

  /// نسبة العرض إلى الارتفاع — يتخذها رسم أيقونة المشروع/الصفحة.
  double get aspectRatio => height <= 0 ? 1 : width / height;

  /// فكّ `layers_data` إلى خريطة. **لا يرمي**: نصّ تالف يُرجع خريطة فارغة.
  Map<String, dynamic> layersToJson() {
    final String raw = layersData.trim();
    if (raw.isEmpty) return <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// المستند القابل للتحرير/الطباعة من هذا الصفّ.
  TemplateDocument toDocument() =>
      TemplateDocument.fromJson(layersToJson());

  /// صفّ الجدول — أسماء الأعمدة كما في المواصفة (وحقول اختيارية تُحفظ بأمان).
  Map<String, dynamic> toRow() => <String, dynamic>{
        'id': id,
        'title': title,
        'width': width,
        'height': height,
        'layers_data': layersData,
        'updated_at': updatedAt.toIso8601String(),
        'thumbnail_path': thumbnailPath ?? '',
        'category': category.dbValue,
        'orientation': orientation.dbValue,
        'is_public': isPublic,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  /// قراءة صفّ من المخزن — **متسامحة** عمداً: صفّ تالف لا يُسقِط القائمة كلها،
  /// و`layers_data` تُقبل نصاً أو خريطة (فلا ينكسر تخزين قديم).
  factory ProjectRecord.fromRow(Map<dynamic, dynamic> row) {
    final Object? rawLayers = row['layers_data'];
    final String layers = switch (rawLayers) {
      String value => value,
      Map value => jsonEncode(value),
      _ => '',
    };
    return ProjectRecord(
      id: '${row['id'] ?? ''}',
      title: '${row['title'] ?? 'مشروع بلا عنوان'}',
      width: _toDouble(row['width']),
      height: _toDouble(row['height']),
      layersData: layers,
      updatedAt: _toDate(row['updated_at']) ?? DateTime.now(),
      thumbnailPath: _toText(row['thumbnail_path']),
      category: TemplateCategory.fromDb(_toText(row['category'])),
      orientation: PageOrientation.fromDb(_toText(row['orientation'])),
      isPublic: row['is_public'] == true || row['is_public'] == 1,
      createdAt: _toDate(row['created_at']),
    );
  }

  /// من سجلّ قالب/مشروع قائم إلى صفّ مشروع — يقيس الصفحة من المستند نفسه فلا
  /// تنفصل الأبعاد المخزَّنة عن التصميم أبداً.
  factory ProjectRecord.fromTemplateRecord(
    TemplateRecord record, {
    String? thumbnailPath,
    DateTime? updatedAt,
  }) {
    final TemplateDocument document = record.toDocument();
    final Map<String, dynamic> layers = record.layoutData.isEmpty
        ? <String, dynamic>{
            ...document.toJson(),
            'schema_version': AppConstants.layoutSchemaVersion,
          }
        : <String, dynamic>{
            ...record.layoutData,
            'schema_version': AppConstants.layoutSchemaVersion,
          };
    return ProjectRecord(
      id: record.id,
      title: record.title,
      width: document.pageWidthPt,
      height: document.pageHeightPt,
      layersData: jsonEncode(layers),
      updatedAt: updatedAt ?? record.updatedAt ?? DateTime.now(),
      thumbnailPath: thumbnailPath,
      category: record.category,
      orientation: record.orientation,
      isPublic: record.isPublic,
      createdAt: record.createdAt,
    );
  }

  /// تحويل الصفّ إلى سجلّ قالب — لتستمر كل الواجهات القائمة بلا تغيير.
  TemplateRecord toTemplateRecord() => TemplateRecord(
        id: id,
        userId: localUserId,
        title: title,
        category: category,
        orientation: orientation,
        layoutData: layersToJson(),
        isPublic: isPublic,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ProjectRecord copyWith({
    String? title,
    double? width,
    double? height,
    String? layersData,
    DateTime? updatedAt,
    String? thumbnailPath,
    TemplateCategory? category,
    PageOrientation? orientation,
    bool? isPublic,
    DateTime? createdAt,
  }) {
    return ProjectRecord(
      id: id,
      title: title ?? this.title,
      width: width ?? this.width,
      height: height ?? this.height,
      layersData: layersData ?? this.layersData,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      category: category ?? this.category,
      orientation: orientation ?? this.orientation,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _toText(Object? value) {
    final String text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _toDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
