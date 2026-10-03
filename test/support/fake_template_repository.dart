import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/templates/template_record.dart';
import 'package:joodcraft/core/templates/template_repository.dart';

/// مستودع قوالب يعمل في الذاكرة — يُمكّن اختبار الحفظ والاسترجاع بلا شبكة.
class FakeTemplateRepository implements TemplateRepository {
  FakeTemplateRepository({this.userId = 'user-1'});

  final String userId;

  /// القوالب المخزّنة بالترتيب الذي أُضيفت به.
  final List<TemplateRecord> records = <TemplateRecord>[];

  /// عدد نداءات كل عملية (للتحقق من سلوك الواجهة).
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int listCalls = 0;

  /// عند `true` ترمي كل العمليات خطأ عربياً — لاختبار مسارات الفشل.
  AppErrorCode? failWith;

  int _sequence = 0;

  void _maybeFail() {
    final AppErrorCode? code = failWith;
    if (code != null) throw AppException(code);
  }

  @override
  Future<List<TemplateRecord>> listMine() async {
    listCalls++;
    _maybeFail();
    return List<TemplateRecord>.unmodifiable(records.reversed);
  }

  @override
  Future<TemplateRecord?> findById(String id) async {
    _maybeFail();
    for (final TemplateRecord record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  @override
  Future<TemplateRecord> create({
    required String title,
    required TemplateCategory category,
    required PageOrientation orientation,
    required Map<String, dynamic> layoutData,
    bool isPublic = false,
  }) async {
    createCalls++;
    _maybeFail();
    _sequence++;
    final TemplateRecord record = TemplateRecord(
      id: 'template-$_sequence',
      userId: userId,
      title: title,
      category: category,
      orientation: orientation,
      layoutData: layoutData,
      isPublic: isPublic,
      createdAt: DateTime(2026, 1, _sequence),
      updatedAt: DateTime(2026, 1, _sequence),
    );
    records.add(record);
    return record;
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
    updateCalls++;
    _maybeFail();
    final int index = records.indexWhere((TemplateRecord item) => item.id == id);
    if (index < 0) throw const AppException(AppErrorCode.notFound);

    final TemplateRecord updated = records[index].copyWith(
      title: title,
      category: category,
      orientation: orientation,
      layoutData: layoutData,
      isPublic: isPublic,
      updatedAt: DateTime(2026, 2, 1),
    );
    records[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    _maybeFail();
    records.removeWhere((TemplateRecord item) => item.id == id);
  }
}
