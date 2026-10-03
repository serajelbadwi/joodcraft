import '../constants/app_constants.dart';
import 'template_record.dart';

/// واجهة مستودع القوالب.
///
/// موجودة في `core` عمداً: كل شاشات التحرير (الشهادات والعقود) تعتمد عليها
/// **دون** أن تستورد ميزة أخرى، والتنفيذ الفعلي (Supabase) يبقى معزولاً في
/// `features/templates/data`.
abstract interface class TemplateRepository {
  /// قوالب المستخدم الحالي مرتّبة بالأحدث تعديلاً.
  Future<List<TemplateRecord>> listMine();

  /// جلب قالب واحد بالمعرّف.
  Future<TemplateRecord?> findById(String id);

  /// إنشاء قالب جديد (يُملأ `user_id` من الجلسة تلقائياً في التنفيذ).
  Future<TemplateRecord> create({
    required String title,
    required TemplateCategory category,
    required PageOrientation orientation,
    required Map<String, dynamic> layoutData,
    bool isPublic = false,
  });

  /// تحديث قالب قائم.
  Future<TemplateRecord> update({
    required String id,
    String? title,
    TemplateCategory? category,
    PageOrientation? orientation,
    Map<String, dynamic>? layoutData,
    bool? isPublic,
  });

  /// حذف قالب.
  Future<void> delete(String id);
}
