import '../constants/app_constants.dart';
import '../errors/app_error_code.dart';
import '../errors/app_exception.dart';
import '../models/template_document.dart';
import '../templates/template_record.dart';
import '../templates/template_repository.dart';
import 'project_record.dart';
import 'projects_controller.dart';

/// تنفيذ [TemplateRepository] فوق **المخزن المحلي** وحده (جدول `projects`).
///
/// هذا التنفيذ يحلّ محلّ المستودع السحابي في التطبيق كله: المحرّر ومكتبة
/// القوالب ومولّد الدفعات يتعاملون مع `TemplateRepository` كما كانوا، لكن كل
/// عملية كتابة تنتهي في صفّ محلي واحد على قرص المستخدم — بلا أي رفع أو حفظ على
/// سيرفر خارجي، ويعمل بلا إنترنت بالكامل.
class LocalProjectRepository implements TemplateRepository {
  LocalProjectRepository({ProjectsController? controller})
      : _projects = controller ?? ProjectsController.instance;

  final ProjectsController _projects;

  @override
  Future<List<TemplateRecord>> listMine() async {
    await _projects.restore();
    return <TemplateRecord>[
      for (final ProjectRecord record in _projects.projects)
        record.toTemplateRecord(),
    ];
  }

  @override
  Future<TemplateRecord?> findById(String id) async {
    await _projects.restore();
    return _projects.findById(id)?.toTemplateRecord();
  }

  @override
  Future<TemplateRecord> create({
    required String title,
    required TemplateCategory category,
    required PageOrientation orientation,
    required Map<String, dynamic> layoutData,
    bool isPublic = false,
  }) async {
    await _projects.restore();
    final TemplateDocument document = _documentOf(layoutData, orientation);
    final ProjectRecord record = await _projects.save(
      title: title,
      document: document,
      category: category,
      isPublic: isPublic,
    );
    return record.toTemplateRecord();
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
    await _projects.restore();
    final ProjectRecord? existing = _projects.findById(id);
    if (existing == null) throw const AppException(AppErrorCode.notFound);

    final Map<String, dynamic> layers =
        layoutData ?? existing.layersToJson();
    final TemplateDocument document = _documentOf(
      layers,
      orientation ?? existing.orientation,
    );
    final ProjectRecord record = await _projects.save(
      id: id,
      title: title ?? existing.title,
      document: document,
      category: category ?? existing.category,
      isPublic: isPublic ?? existing.isPublic,
    );
    return record.toTemplateRecord();
  }

  @override
  Future<void> delete(String id) => _projects.remove(id);

  /// يحوّل `layout_data` إلى مستند **ويثبّت الاتجاه المطلوب** — فالاتجاه جزء من
  /// هوية المشروع لا من تفاصيل الرسم، ولا يجوز أن يختلف عمّا اختاره المستخدم.
  static TemplateDocument _documentOf(
    Map<String, dynamic> layout,
    PageOrientation orientation,
  ) {
    final TemplateDocument document = TemplateDocument.fromJson(
      Map<String, dynamic>.from(layout),
    );
    return document.orientation == orientation
        ? document
        : document.copyWith(orientation: orientation);
  }
}
