import '../constants/app_constants.dart';
import '../models/template_document.dart';

/// سجل قالب محفوظ في جدول `public.templates`.
///
/// هذا الكائن هو الحدّ بين قاعدة البيانات والمحرر: طبقة البيانات تُنتج
/// `TemplateRecord`، والمحرر يستهلك `layoutData` كـ [TemplateDocument] فقط.
class TemplateRecord {
  const TemplateRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.orientation,
    required this.layoutData,
    this.isPublic = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final TemplateCategory category;
  final PageOrientation orientation;

  /// هيكل القالب الكامل — يجب أن يحتوي `schema_version`.
  final Map<String, dynamic> layoutData;

  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// هل السجل يحتوي مخططاً صالحاً (إصدار مطابق للمدعوم)؟
  bool get hasLayout => layoutData.isNotEmpty;

  /// تحويل السجل إلى مستند قابل للتعديل/الطباعة.
  TemplateDocument toDocument() => TemplateDocument.fromJson(
        Map<String, dynamic>.from(layoutData),
      );

  /// بناءً على نتائج PostgREST (أسماء الأعمدة كما في قاعدة البيانات).
  ///
  /// القراءة **متسامحة** عمداً: أي حقل مفقود يأخذ قيمة افتراضية بدل أن يُسقِط
  /// القائمة كاملة — فسجل واحد تالف لا يجب أن يُخفي بقية القوالب.
  factory TemplateRecord.fromRow(Map<String, dynamic> row) {
    final Object? rawLayout = row['layout_data'];
    return TemplateRecord(
      id: '${row['id'] ?? ''}',
      userId: '${row['user_id'] ?? ''}',
      title: '${row['title'] ?? 'قالب بلا عنوان'}',
      category: TemplateCategory.fromDb(row['category'] as String?),
      orientation: PageOrientation.fromDb(row['orientation'] as String?),
      layoutData: rawLayout is Map
          ? Map<String, dynamic>.from(rawLayout)
          : <String, dynamic>{},
      isPublic: row['is_public'] == true,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  /// تسلسل السجل لحفظه محلياً (بلا شبكة) — يُستخدمه [LocalTemplateStore].
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category.dbValue,
        'orientation': orientation.dbValue,
        'layout_data': layoutData,
        'is_public': isPublic,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// قراءة سجل من JSON محلي — متسامحة كـ [fromRow] تماماً.
  factory TemplateRecord.fromJson(Map<String, dynamic> json) =>
      TemplateRecord.fromRow(json);

  /// بناء صف للإدخال/التحديث.
  Map<String, dynamic> toRow({
    required String userId,
    required Map<String, dynamic> layoutData,
    String? title,
    TemplateCategory? category,
    PageOrientation? orientation,
    bool? isPublic,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'title': title ?? this.title,
      'category': (category ?? this.category).dbValue,
      'orientation': (orientation ?? this.orientation).dbValue,
      'layout_data': layoutData,
      'is_public': isPublic ?? this.isPublic,
    };
  }

  TemplateRecord copyWith({
    String? title,
    TemplateCategory? category,
    PageOrientation? orientation,
    Map<String, dynamic>? layoutData,
    bool? isPublic,
    DateTime? updatedAt,
  }) {
    return TemplateRecord(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      orientation: orientation ?? this.orientation,
      layoutData: layoutData ?? this.layoutData,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
