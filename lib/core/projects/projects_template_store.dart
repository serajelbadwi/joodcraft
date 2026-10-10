import '../templates/local_template_store.dart';
import '../templates/template_record.dart';
import 'project_record.dart';
import 'projects_controller.dart';

/// محوّل [LocalTemplateStore] فوق جدول المشاريع المحلي.
///
/// المكتبة ومولّد الدفعات كانا يقرآن «القوالب المحلية» من `SharedPreferences`،
/// فأصبحا يقرآن **المشروع نفسه** من قاعدة المشاريع المحلية: مصدر واحد للحقيقة،
/// فما يحفظه المحرّر يظهر في المكتبة فوراً وبلا مزامنة.
class ProjectsTemplateStore implements LocalTemplateStore {
  ProjectsTemplateStore({ProjectsController? controller})
      : _projects = controller ?? ProjectsController.instance;

  final ProjectsController _projects;

  /// معرّفات اللقطة الأخيرة — أساس آمن للحذف عند [saveAll].
  Set<String> _snapshot = <String>{};

  /// هل تُحفظ فعلياً على القرص؟ (التراجع إلى الذاكرة يعني لا.)
  bool get isPersistent => _projects.isPersistent;

  @override
  Future<List<TemplateRecord>> loadAll() async {
    await _projects.restore();
    final List<ProjectRecord> rows = _projects.projects;
    _snapshot = <String>{for (final ProjectRecord record in rows) record.id};
    return <TemplateRecord>[
      for (final ProjectRecord record in rows) record.toTemplateRecord(),
    ];
  }

  @override
  Future<void> saveAll(List<TemplateRecord> records) async {
    await _projects.restore();
    final List<ProjectRecord> rows = <ProjectRecord>[
      for (final TemplateRecord record in records) _rowOf(record),
    ];
    final Set<String> incoming =
        <String>{for (final ProjectRecord row in rows) row.id};

    // الحذف مقصور على ما كان موجوداً في اللقطة السابقة ثم اختفى: صفٌّ أنشأه
    // المحرّر بعد اللقطة لا يُمحى بسبب قائمة قديمة في المكتبة.
    for (final String gone in _snapshot.difference(incoming)) {
      await _projects.remove(gone);
    }
    await _projects.upsertAll(rows);
    _snapshot = incoming;
  }

  /// صفّ مشروع من سجلّ قالب، مع الحفاظ على ما لا يحمله السجلّ (الصورة المصغّرة).
  ProjectRecord _rowOf(TemplateRecord record) {
    final ProjectRecord? existing = _projects.findById(record.id);
    return ProjectRecord.fromTemplateRecord(
      record,
      thumbnailPath: existing?.thumbnailPath,
    );
  }
}
