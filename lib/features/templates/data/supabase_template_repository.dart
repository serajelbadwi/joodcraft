import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/templates/template_record.dart';
import '../../../core/templates/template_repository.dart';

/// تنفيذ [TemplateRepository] فوق جدول `public.templates`.
///
/// هذا هو المكان الوحيد في التطبيق الذي يعرف شكل الجدول وأسماء أعمدته؛ كل ما
/// فوقه (المحرر، مكتبة القوالب، الشاشات) يتعامل مع [TemplateRecord] فقط.
///
/// الأمان ليس هنا: `user_id` يُملأ من الجلسة لخدمة الـ RLS، أما العزل الفعلي
/// فتفرضه سياسات قاعدة البيانات (`auth.uid() = user_id`).
class SupabaseTemplateRepository implements TemplateRepository {
  SupabaseTemplateRepository(this._client);

  final SupabaseClient _client;

  /// عمود الأحدث تعديلاً — يطابق ما يحدّثه الـ Trigger في قاعدة البيانات.
  static const String _orderColumn = 'updated_at';

  String get _userId {
    final String? id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(AppErrorCode.notAuthenticated);
    }
    return id;
  }

  @override
  Future<List<TemplateRecord>> listMine() async {
    try {
      final List<Map<String, dynamic>> rows = await _client
          .from(AppConstants.templatesTable)
          .select()
          .eq('user_id', _userId)
          .order(_orderColumn, ascending: false);

      return rows
          .map((Map<String, dynamic> row) => TemplateRecord.fromRow(row))
          .toList(growable: false);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<TemplateRecord?> findById(String id) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(AppConstants.templatesTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : TemplateRecord.fromRow(row);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<TemplateRecord> create({
    required String title,
    required TemplateCategory category,
    required PageOrientation orientation,
    required Map<String, dynamic> layoutData,
    bool isPublic = false,
  }) async {
    try {
      final Map<String, dynamic> row = await _client
          .from(AppConstants.templatesTable)
          .insert(<String, dynamic>{
            'user_id': _userId,
            'title': title,
            'category': category.dbValue,
            'orientation': orientation.dbValue,
            'layout_data': _sanitizeLayout(layoutData),
            'is_public': isPublic,
          })
          .select()
          .single();

      return TemplateRecord.fromRow(row);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<TemplateRecord> update({
    required String id,
    String? title,
    TemplateCategory? category,
    PageOrientation? orientation,
    Map<String, dynamic>? layoutData,
    bool? isPublic,
  }) async {
    try {
      final Map<String, dynamic> payload = <String, dynamic>{
        'title': ?title,
        if (category != null) 'category': category.dbValue,
        if (orientation != null) 'orientation': orientation.dbValue,
        if (layoutData != null) 'layout_data': _sanitizeLayout(layoutData),
        'is_public': ?isPublic,
      };

      final Map<String, dynamic> row = await _client
          .from(AppConstants.templatesTable)
          .update(payload)
          .eq('id', id)
          .select()
          .single();

      return TemplateRecord.fromRow(row);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from(AppConstants.templatesTable).delete().eq('id', id);
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  /// ضمان وجود `schema_version` قبل الإرسال.
  ///
  /// قاعدة البيانات ترفض أي `layout_data` بلا إصدار مخطط (قيد CHECK)، وهذا
  /// يحوّل خطأً غامضاً من الخادم إلى قيمة صحيحة دائماً.
  static Map<String, dynamic> _sanitizeLayout(Map<String, dynamic> layout) {
    return <String, dynamic>{
      ...layout,
      // يُكتب أخيراً ليضمن أن نسخة المخطط المخزنة هي نسخة المحرك الحالية.
      'schema_version': AppConstants.layoutSchemaVersion,
    };
  }
}
