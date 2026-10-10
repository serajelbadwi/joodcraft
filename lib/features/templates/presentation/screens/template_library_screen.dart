import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/assets/embedded_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/editor/widgets/editor_controls.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/locale/locale_controller.dart';
import '../../../../core/templates/local_template_store.dart';
import '../../../../core/templates/template_localization.dart';
import '../../../../core/templates/preset_template.dart';
import '../../../../core/templates/template_library_controller.dart';
import '../../../../core/templates/template_library_entry.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/models/template_document.dart';
import '../../../../core/templates/template_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/pdf_template_preview.dart';
import '../widgets/template_thumbnail.dart';

/// ترتيب عرض القوالب في المكتبة.
enum TemplateLibrarySort {
  recentlyUpdated('الأحدث تعديلاً'),
  titleAsc('الاسم (أ - ي)'),
  collection('المجموعة'),
  source('المصدر');

  const TemplateLibrarySort(this.labelAr);

  final String labelAr;
}

/// مكتبة القوالب (المرحلة 5).
///
/// مساحة واحدة تجمع ثلاثة مصادر: **الجاهزة** المحزومة (أوفلاين دائماً)،
/// و**المحلية** المحفوظة على الجهاز، و**السحابية** المرتبطة بـ Supabase. مع
/// بحث وتصفية وترتيب وإجراءات كاملة (معاينة، فتح في المحرّر، استيراد محلي،
/// حفظ كقالب مخصص، استخدام في التوليد الجماعي، حذف).
class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({
    super.key,
    this.repository,
    this.localStore,
    this.controller,
    this.warmImageCache,
  });

  /// مستودع القوالب السحابية (يُحقن من الموجّه) — `null` إن لم يُربط Supabase.
  final TemplateRepository? repository;

  /// مخزن القوالب المحلية — يُحقن في الاختبارات (مخزن في الذاكرة).
  final LocalTemplateStore? localStore;

  /// متحكّم جاهز (للاختبارات) — يتقدّم على الحقن الافتراضي.
  final TemplateLibraryController? controller;

  /// مُسخِّن ذاكرة الصور عند فتح المكتبة — يُحقن في الاختبارات (لتفادي قرص
  /// حقيقي داخل منطقة `testWidgets` الزمنية المزيّفة). الافتراضي هو
  /// [warmDocumentsImageCache] على مستندات كل القوالب.
  final Future<void> Function(List<TemplateDocument> documents)?
      warmImageCache;

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  late final TemplateLibraryController _controller = widget.controller ??
      TemplateLibraryController(
        widget.repository,
        localStore: widget.localStore,
      );
  final TextEditingController _search = TextEditingController();

  TemplateSource? _source;
  TemplateCollection? _collection;
  PageOrientation? _orientation;
  TemplateLibrarySort _sort = TemplateLibrarySort.recentlyUpdated;

  /// معرّفات القوالب المفضّلة (محلياً في الجلسة — تُرتَّب أولاً في كل قسم).
  final Set<String> _favorites = <String>{};

  /// مفاتيح الأقسام المفتوحة حالياً. الافتراضي: **كل الأقسام مطويّة** عند
  /// فتح المكتبة، فيبدأ المستخدم ببصرٍ نظيف على بانرات التصنيفات ثم يفتح ما
  /// يريده فقط — بلا صفحة طويلة لا نهاية لها.
  final Set<String> _expanded = <String>{};

  /// ذاكرة مستندات القوالب (بالمعرّف) — تُحلّ من JSON مرة واحدة للصورة
  /// المصغّرة بدل إعادة تحليلها في كل إعادة بناء أثناء الكتابة في البحث.
  final Map<String, TemplateDocument> _documents =
      <String, TemplateDocument>{};

  @override
  void initState() {
    super.initState();
    unawaited(_refreshAndWarm());
  }

  /// يحمّل القوالب ثم يسخّن ذاكرة صور معايناتها في الخلفية.
  ///
  /// **لماذا عند الفتح؟** بطاقات المكتبة ومعايناتها ترسم صور أصول المستخدم
  /// (الإطار/الخلفية/التوقيع)، وهي بلا تسخين تُفكّ من Base64 عند أول رسم. قراءة
  /// نسخ القرص المحفوظة — أو فكّها وحفظها مرة واحدة — تجعلها جاهزة فوراً،
  /// وبلا تأخير للواجهة: كله غير حاجز بعد انتهاء تحميل القوالب.
  Future<void> _refreshAndWarm() async {
    await _controller.refresh();
    _documents.clear();
    if (!mounted || _controller.entries.isEmpty) return;
    final List<TemplateDocument> documents = <TemplateDocument>[
      for (final TemplateLibraryEntry entry in _controller.entries)
        entry.toDocument(),
    ];
    final Future<void> Function(List<TemplateDocument>)? warm =
        widget.warmImageCache;
    await (warm ?? warmDocumentsImageCache)(documents);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  /// مستند قالب — مذكورى بالمعرّف لتفادي إعادة التحليل في كل بناء.
  TemplateDocument _documentOf(TemplateLibraryEntry entry) =>
      _documents.putIfAbsent(entry.id, entry.toDocument);

  void _toggleFavorite(TemplateLibraryEntry entry) {
    setState(() {
      if (!_favorites.remove(entry.id)) _favorites.add(entry.id);
    });
  }

  void _toggleGroup(String key) {
    setState(() {
      if (!_expanded.remove(key)) _expanded.add(key);
    });
  }

  /// يفتح كل الأقسام المعروضة أو يطويها — زرّا «توسيع/طي الكل».
  void _setAllSections(bool expanded) {
    final Set<String> keys = <String>{
      for (final TemplateLibraryEntry entry in _visibleEntries())
        _groupKeyOf(entry),
    };
    setState(() {
      if (expanded) {
        _expanded.addAll(keys);
      } else {
        _expanded.removeAll(keys);
      }
    });
  }

  // ==========================================================================
  //  البناء
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context),
            Expanded(child: _body(context)),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.collections_bookmark_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(context.l10n?.destTemplates ?? 'مكتبة القوالب',
                        style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n?.tplSubtitle ??
                          'قوالب جاهزة احترافية + قوالبك المحفوظة — بحث وتصفية '
                              'وفتح واستيراد، أوفلاين بالكامل.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!_controller.isBusy) _CountChip(count: _controller.totalCount),
              const SizedBox(width: AppTheme.space8),
              IconAction(
                icon: Icons.unfold_more_rounded,
                tooltip: 'توسيع الكل',
                onPressed: () => _setAllSections(true),
              ),
              IconAction(
                icon: Icons.unfold_less_rounded,
                tooltip: 'طي الكل',
                onPressed: () => _setAllSections(false),
              ),
              const SizedBox(width: AppTheme.space8),
              IconAction(
                icon: Icons.refresh_rounded,
                tooltip: context.l10n?.tplRefreshTooltip ?? 'تحديث القائمة',
                onPressed: _controller.isBusy
                    ? null
                    : () => unawaited(_controller.refresh()),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    hintText: context.l10n?.tplSearchHint ?? 'بحث في القوالب…',
                    hintStyle: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              DropdownField<TemplateSource?>(
                label: context.l10n?.editorSource ?? 'المصدر',
                value: _source,
                items: <TemplateSource?>[null, ...TemplateSource.values],
                labelOf: (TemplateSource? value) => value == null
                    ? (context.l10n?.alpFilterAll ?? 'الكل')
                    : value.labelAr,
                width: 150,
                onChanged: (TemplateSource? value) =>
                    setState(() => _source = value),
              ),
              DropdownField<TemplateCollection?>(
                label: context.l10n?.editorGroup ?? 'المجموعة',
                value: _collection,
                items: <TemplateCollection?>[null, ...TemplateCollection.values],
                labelOf: (TemplateCollection? value) =>
                    value?.labelAr ?? context.l10n?.alpFilterAll ?? 'الكل',
                width: 180,
                onChanged: (TemplateCollection? value) =>
                    setState(() => _collection = value),
              ),
              DropdownField<TemplateLibrarySort>(
                label: context.l10n?.tplSortLabel ?? 'الترتيب',
                value: _sort,
                items: TemplateLibrarySort.values,
                labelOf: (TemplateLibrarySort value) => switch (value) {
                  TemplateLibrarySort.recentlyUpdated =>
                    context.l10n?.tplSortRecentlyUpdated ?? value.labelAr,
                  TemplateLibrarySort.titleAsc =>
                    context.l10n?.tplSortTitleAsc ?? value.labelAr,
                  TemplateLibrarySort.collection =>
                    context.l10n?.editorGroup ?? value.labelAr,
                  TemplateLibrarySort.source =>
                    context.l10n?.editorSource ?? value.labelAr,
                },
                width: 170,
                onChanged: (TemplateLibrarySort value) =>
                    setState(() => _sort = value),
              ),
              DropdownField<PageOrientation?>(
                label: 'الاتجاه',
                value: _orientation,
                items: <PageOrientation?>[null, ...PageOrientation.values],
                labelOf: (PageOrientation? value) => value == null
                    ? (context.l10n?.alpFilterAll ?? 'الكل')
                    : value.labelAr,
                width: 150,
                onChanged: (PageOrientation? value) =>
                    setState(() => _orientation = value),
              ),
            ],
          ),
          if (_controller.errorMessage != null) ...<Widget>[
            const SizedBox(height: AppTheme.space8),
            _SyncNote(message: _controller.errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_controller.isBusy && _controller.totalCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<TemplateLibraryEntry> visible = _visibleEntries();
    if (visible.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: _NoticeCard(
            icon: Icons.search_off_rounded,
            title: context.l10n?.tplNoResultsTitle ?? 'لا نتائج مطابقة',
            message: context.l10n?.tplNoResultsMessage ??
                'جرّب كلمة بحث أخرى أو أعد ضبط عامل التصفية.',
          ),
        ),
      );
    }

    // المكتبة أكورديون أقسام مجمّعة بالتصنيف/المجموعة. الكتالوج محزوم محدود
    // الحجم (عشرات القوالب لا آلاف)، فنبني الأقسام وكل بطاقاتها دفعةً واحدة
    // بدل بناء كسول: فيبقى كل قالب موجوداً في الشجرة فوراً — قابلاً للبحث
    // والاختيار والتنقل بلا أن يتأثّر توفّره بالتمرير.
    // لغة محتوى القوالب (أسماء وصيغ البلد) — تُمرَّر للبطاقات والمعاينة.
    final String contentLanguage = templateContentLanguageOf(context);
    final List<_LibraryGroup> groups = _groupEntries(visible);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final _LibraryGroup group in groups) ...<Widget>[
            _CollapsibleSection(
              key: ValueKey<String>('library-section-${group.key}'),
              group: group,
              expanded: _expanded.contains(group.key),
              onToggle: () => _toggleGroup(group.key),
              languageCode: contentLanguage,
              cloudAvailable: _controller.isCloudAvailable,
              documentOf: _documentOf,
              favorites: _favorites,
              onFavorite: _toggleFavorite,
              onOpen: _open,
              onPreview: _preview,
              onUseInBatch: _useInBatch,
              onImportLocal: _importLocal,
              onSaveCloud: _saveCloud,
              onRename: _rename,
              onDuplicate: _duplicate,
              onTogglePublic: _togglePublic,
              onDeleteCloud: _deleteCloud,
              onDeleteLocal: _deleteLocal,
            ),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  /// القوالب بعد تطبيق البحث والتصفية والترتيب (المفضّلة أولاً في كل قسم).
  List<TemplateLibraryEntry> _visibleEntries() {
    final List<TemplateLibraryEntry> items = _controller.entries
        .where(
          (TemplateLibraryEntry entry) =>
              (_source == null || entry.source == _source) &&
              (_orientation == null ||
                  entry.orientation == _orientation) &&
              entry.matchesCollection(_collection) &&
              entry.matchesQuery(_search.text),
        )
        .toList();

    items.sort((TemplateLibraryEntry a, TemplateLibraryEntry b) {
      final bool favoriteA = _favorites.contains(a.id);
      final bool favoriteB = _favorites.contains(b.id);
      if (favoriteA != favoriteB) return favoriteA ? -1 : 1;
      return _compare(a, b);
    });
    return items;
  }

  // ==========================================================================
  //  التجميع في أقسام
  // ==========================================================================

  /// مفتاح قسم "قوالبي المحفوظة" (المحلي والسحابي معاً).
  static const String _savedGroupKey = 'saved';

  /// مفتاح قسم العقود الموحّد (عقود العمل والخدمات في بانر واحد
  /// «عقود وتعهّدات»).
  static const String _contractsGroupKey = 'contracts';

  String _groupKeyOf(TemplateLibraryEntry entry) {
    if (!entry.isPreset) return _savedGroupKey;
    final TemplateCollection? collection = entry.collection;
    if (collection != null) {
      return collection.category == TemplateCategory.contract
          ? _contractsGroupKey
          : 'collection:${collection.name}';
    }
    return 'category:${entry.category.name}';
  }

  /// يجمّع القوالب المعروضة في أقسام مرتّبة: مجموعات الشهادات/العقود الدلالية
  /// أولاً (بترتيب [TemplateCollection]) ثم "قوالبي المحفوظة" في النهاية.
  List<_LibraryGroup> _groupEntries(List<TemplateLibraryEntry> visible) {
    final Map<String, List<TemplateLibraryEntry>> buckets =
        <String, List<TemplateLibraryEntry>>{};
    for (final TemplateLibraryEntry entry in visible) {
      buckets
          .putIfAbsent(_groupKeyOf(entry), () => <TemplateLibraryEntry>[])
          .add(entry);
    }

    final List<_LibraryGroup> groups = <_LibraryGroup>[];
    for (final TemplateCollection collection in TemplateCollection.values) {
      if (collection.category == TemplateCategory.contract) continue;
      final List<TemplateLibraryEntry>? items =
          buckets.remove('collection:${collection.name}');
      if (items == null || items.isEmpty) continue;
      groups.add(_LibraryGroup(
        key: 'collection:${collection.name}',
        label: collection.labelAr,
        icon: collection.icon,
        entries: items,
      ));
    }
    // قسم العقود الموحّد — بانر واحد يجمع عقود العمل والخدمات.
    final List<TemplateLibraryEntry>? contracts =
        buckets.remove(_contractsGroupKey);
    if (contracts != null && contracts.isNotEmpty) {
      groups.add(_LibraryGroup(
        key: _contractsGroupKey,
        label: 'عقود وتعهّدات',
        icon: Icons.handshake_rounded,
        entries: contracts,
      ));
    }
    // قوالب جاهزة بلا مجموعة دلالية (تصنيف فقط) — احتياط للمستقبل.
    for (final TemplateCategory category in TemplateCategory.values) {
      final List<TemplateLibraryEntry>? items =
          buckets.remove('category:${category.name}');
      if (items == null || items.isEmpty) continue;
      groups.add(_LibraryGroup(
        key: 'category:${category.name}',
        label: category == TemplateCategory.certificate
            ? 'قوالب الشهادات'
            : 'قوالب العقود',
        icon: category == TemplateCategory.certificate
            ? Icons.workspace_premium_rounded
            : Icons.article_rounded,
        entries: items,
      ));
    }
    final List<TemplateLibraryEntry>? saved = buckets.remove(_savedGroupKey);
    if (saved != null && saved.isNotEmpty) {
      groups.add(_LibraryGroup(
        key: _savedGroupKey,
        label: 'قوالبي المحفوظة',
        icon: Icons.folder_special_rounded,
        entries: saved,
      ));
    }
    return groups;
  }

  int _compare(TemplateLibraryEntry a, TemplateLibraryEntry b) {
    switch (_sort) {
      case TemplateLibrarySort.titleAsc:
        return a.title.compareTo(b.title);
      case TemplateLibrarySort.source:
        final int bySource = a.source.index.compareTo(b.source.index);
        return bySource != 0 ? bySource : a.title.compareTo(b.title);
      case TemplateLibrarySort.collection:
        final int byGroup =
            _groupRank(a).compareTo(_groupRank(b));
        return byGroup != 0 ? byGroup : a.title.compareTo(b.title);
      case TemplateLibrarySort.recentlyUpdated:
        // القوالب الجاهزة بلا تاريخ — تُرتَّب بعد المحفوظة.
        final int byDate = _dateRank(b).compareTo(_dateRank(a));
        return byDate != 0 ? byDate : a.title.compareTo(b.title);
    }
  }

  int _dateRank(TemplateLibraryEntry entry) =>
      entry.record.updatedAt?.millisecondsSinceEpoch ?? 0;

  int _groupRank(TemplateLibraryEntry entry) {
    final TemplateCollection? collection = entry.collection;
    if (collection != null) return collection.index;
    return 100 + entry.category.index;
  }

  // ==========================================================================
  //  الإجراءات
  // ==========================================================================

  void _open(TemplateLibraryEntry entry) {
    final String path = entry.category == TemplateCategory.contract
        ? AppRoutes.contractBuilder
        : AppRoutes.certificateBuilder;
    // القالب الجاهز يُفتح مسودةً (بلا معرّف سجل) ليُحفظ كقالب جديد، وبمحتوى
    // اللغة الحالية (أسماء وصيغ البلد) — أما قالب المستخدم فيبقى كما حرّره.
    context.go(
      path,
      extra: entry.isPreset
          ? entry.toDraft(
              languageCode: templateContentLanguageOf(context, listen: false),
            )
          : entry.record,
    );
  }

  void _useInBatch(TemplateLibraryEntry entry) {
    context.go(
      AppRoutes.batchProcessor,
      extra: entry.toRecord(
        languageCode: templateContentLanguageOf(context, listen: false),
      ),
    );
  }

  void _preview(TemplateLibraryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _PreviewDialog(
        entry: entry,
        languageCode: templateContentLanguageOf(context, listen: false),
      ),
    );
  }

  Future<void> _importLocal(TemplateLibraryEntry entry) async {
    final PresetTemplate? preset = entry.preset;
    if (preset == null) return;
    await _controller.importPreset(preset);
    if (!mounted) return;
    final String title = preset.titleFor(
      templateContentLanguageOf(context, listen: false),
    );
    context.showSuccess(
      context.l10n?.tplAddedToLocal(title) ??
          'أُضيف «$title» إلى قوالبك المحلية.',
    );
  }

  Future<void> _saveCloud(TemplateLibraryEntry entry) async {
    if (!_controller.isCloudAvailable) {
      context.showWarning(
        context.l10n?.tplCloudRequiresConnection ??
            'حفظ القوالب في السحابة يتطلب الاتصال بمشروع Supabase. احفظه محلياً بدل ذلك.',
      );
      return;
    }
    final String? title = await _askTitle(context, initial: entry.title);
    if (title == null || !mounted) return;
    try {
      await _controller.saveAsCustom(title: title, entry: entry);
      if (mounted) {
        context.showSuccess(
          context.l10n?.tplSavedToCloud(title) ?? 'حُفظ «$title» في السحابة.',
        );
      }
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
    }
  }

  Future<void> _rename(TemplateLibraryEntry entry) async {
    final String? title = await _askTitle(context, initial: entry.title);
    if (title == null || !mounted || title == entry.title) return;
    await _updateCloud(
      entry,
      title: title,
      successAr: context.l10n?.tplRenamed ?? 'أُعيد تسمية القالب.',
    );
  }

  Future<void> _duplicate(TemplateLibraryEntry entry) async {
    try {
      await _controller.save(
        title: context.l10n?.tplCopySuffix(entry.title) ?? '${entry.title} (نسخة)',
        category: entry.category,
        orientation: entry.orientation,
        layoutData: entry.toDocument().toJson(),
      );
      if (mounted) {
        context.showSuccess(
          context.l10n?.tplCopyCreated(entry.title) ??
              'أُنشئت نسخة من «${entry.title}».',
        );
      }
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
    }
  }

  Future<void> _togglePublic(TemplateLibraryEntry entry) async {
    await _updateCloud(
      entry,
      isPublic: !entry.record.isPublic,
      successAr: entry.record.isPublic
          ? (context.l10n?.tplNowPrivate ?? 'القالب الآن خاص.')
          : (context.l10n?.tplNowPublic ??
              'القالب الآن عام (قراءة فقط للآخرين).'),
    );
  }

  Future<void> _updateCloud(
    TemplateLibraryEntry entry, {
    String? title,
    bool? isPublic,
    required String successAr,
  }) async {
    try {
      await _controller.save(
        id: entry.id,
        title: title ?? entry.title,
        category: entry.category,
        orientation: entry.orientation,
        layoutData: entry.toDocument().toJson(),
        isPublic: isPublic ?? entry.record.isPublic,
      );
      if (mounted) context.showSuccess(successAr);
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
    }
  }

  Future<void> _deleteCloud(TemplateLibraryEntry entry) async {
    final bool? confirmed = await _confirmDelete(
      context: context,
      message: context.l10n?.tplConfirmCloudDelete(entry.title) ??
          'سيُحذف «${entry.title}» من السحابة نهائياً. لا يمكن التراجع.',
    );
    if (confirmed != true || !mounted) return;
    try {
      await _controller.remove(entry.id);
      if (mounted) {
        context.showSuccess(
          context.l10n?.tplCloudDeleted(entry.title) ??
              'حُذف القالب «${entry.title}».',
        );
      }
    } on AppException catch (error) {
      if (mounted) context.showError(error.message);
    }
  }

  Future<void> _deleteLocal(TemplateLibraryEntry entry) async {
    final bool? confirmed = await _confirmDelete(
      context: context,
      message: context.l10n?.tplConfirmLocalDelete(entry.title) ??
          'سيُحذف «${entry.title}» من هذا الجهاز. القالب الجاهز الأصلي '
              'يبقى متاحاً في المكتبة.',
    );
    if (confirmed != true || !mounted) return;
    await _controller.removeLocal(entry.id);
    if (mounted) {
      context.showSuccess(
        context.l10n?.tplLocalDeleted(entry.title) ??
            'حُذف القالب المحلي «${entry.title}».',
      );
    }
  }

  /// نافذة طلب عنوان (تعيد `null` عند الإلغاء).
  static Future<String?> _askTitle(
    BuildContext context, {
    required String initial,
  }) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => _TitleDialog(initial: initial),
    );
  }

  static Future<bool?> _confirmDelete({
    required BuildContext context,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(context.l10n?.tplDeleteTitle ?? 'حذف القالب'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n?.tplDelete ?? 'حذف'),
          ),
        ],
      ),
    );
  }
}

/// حقل العنوان داخل نافذة الإدخال.
class _TitleDialog extends StatefulWidget {
  const _TitleDialog({required this.initial});

  final String initial;

  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  late final TextEditingController _field =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n?.tplRenameTitle ?? 'عنوان القالب'),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLength: AppConstants.maxNameLength,
        // عنوان القالب عربي — اتجاه صريح يمنع انعكاس تنقّل الأسهم.
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          labelText: context.l10n?.tplFieldTitle ?? 'العنوان',
        ),
        onSubmitted: (String value) =>
            Navigator.of(context).pop(value.trim()),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n?.editorCancel ?? 'إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_field.text.trim()),
          child: Text(context.l10n?.commonSave ?? 'حفظ'),
        ),
      ],
    );
  }
}

/// نافذة معاينة القالب (PDF حقيقي + بيانات تجريبية).
class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({required this.entry, required this.languageCode});

  final TemplateLibraryEntry entry;

  /// لغة محتوى المعاينة (أسماء وصيغ البلد للقوالب الجاهزة).
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 960,
        height: 680,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: Row(
                children: <Widget>[
                  Icon(Icons.visibility_rounded,
                      size: 20, color: Theme.of(context).colorScheme.goldDeep),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      context.l10n?.tplPreviewLabel(
                            TemplateLocalization.text(
                              languageCode,
                              entry.title,
                            ),
                          ) ??
                          'معاينة: ${TemplateLocalization.text(languageCode, entry.title)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n?.editorClose ?? 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PdfTemplatePreview(
                document: entry.preset?.documentFor(languageCode) ??
                    entry.toDocument(),
                exportFileName: 'joodcraft-preview.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريحة عدد القوالب في الترويسة.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        context.l10n?.tplCount(count) ?? '$count قالب',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// ملاحظة خطأ السحابة — لا تحجب القوالب الجاهزة/المحلية.
class _SyncNote extends StatelessWidget {
  const _SyncNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded,
              size: 15, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n?.tplCloudLoadError(message) ??
                  'تعذّر تحميل القوالب السحابية: $message',
              style: const TextStyle(fontSize: 11.5, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة قالب واحد داخل الشبكة.
/// قسم واحد في أكورديون المكتبة: مجموعة دلالية + قوالبها.
class _LibraryGroup {
  const _LibraryGroup({
    required this.key,
    required this.label,
    required this.icon,
    required this.entries,
  });

  final String key;
  final String label;
  final IconData icon;
  final List<TemplateLibraryEntry> entries;
}

/// قسم قابل للطي (Accordion) يعرض ترويسة تصنيف ثم شبكة بطاقات متجاوبة.
class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.languageCode,
    required this.cloudAvailable,
    required this.documentOf,
    required this.favorites,
    required this.onFavorite,
    required this.onOpen,
    required this.onPreview,
    required this.onUseInBatch,
    required this.onImportLocal,
    required this.onSaveCloud,
    required this.onRename,
    required this.onDuplicate,
    required this.onTogglePublic,
    required this.onDeleteCloud,
    required this.onDeleteLocal,
  });

  final _LibraryGroup group;
  final bool expanded;
  final VoidCallback onToggle;

  /// لغة محتوى القوالب (لترجمة العناوين والبيانات التجريبية).
  final String languageCode;
  final bool cloudAvailable;
  final TemplateDocument Function(TemplateLibraryEntry) documentOf;
  final Set<String> favorites;
  final ValueChanged<TemplateLibraryEntry> onFavorite;
  final ValueChanged<TemplateLibraryEntry> onOpen;
  final ValueChanged<TemplateLibraryEntry> onPreview;
  final ValueChanged<TemplateLibraryEntry> onUseInBatch;
  final ValueChanged<TemplateLibraryEntry> onImportLocal;
  final ValueChanged<TemplateLibraryEntry> onSaveCloud;
  final ValueChanged<TemplateLibraryEntry> onRename;
  final ValueChanged<TemplateLibraryEntry> onDuplicate;
  final ValueChanged<TemplateLibraryEntry> onTogglePublic;
  final ValueChanged<TemplateLibraryEntry> onDeleteCloud;
  final ValueChanged<TemplateLibraryEntry> onDeleteLocal;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  /// أقصى ارتفاع لمحتوى القسم الموسّع: بعده يصبح للقسم منطقة تمرير داخلية
  /// بذراع تمرير مرئي بدل أن يمدّ الصفحة بلا نهاية.
  static const double _drawerMaxHeight = 470;

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final _LibraryGroup group = widget.group;
    final bool expanded = widget.expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>('library-section-header-${group.key}'),
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space8,
              ),
              decoration: BoxDecoration(
                color: expanded ? scheme.primaryContainer : scheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: expanded ? scheme.primary : scheme.outline,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(group.icon, size: 18, color: scheme.primary),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      group.label,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _CountChip(count: group.entries.length),
                  const SizedBox(width: AppTheme.space8),
                  // زرّ سهم صريح (لا يعتمد على البانر وحده) لفتح/طي القسم.
                  Tooltip(
                    message: expanded ? 'طيّ القسم' : 'فتح القسم',
                    child: InkWell(
                      key: ValueKey<String>(
                          'library-section-toggle-${group.key}'),
                      onTap: widget.onToggle,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      child: AnimatedRotation(
                        turns: expanded ? 0 : -0.5,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space12),
                  child: _drawer(),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// حاوية القسم الموسّع: ارتفاع أقصى محدود + ذراع تمرير رأسي مرئي، فيُمرَّر
  /// داخل القسم وحده بلا توسيع الصفحة.
  Widget _drawer() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _drawerMaxHeight),
      child: Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        thickness: 8,
        radius: const Radius.circular(AppTheme.radiusPill),
        child: SingleChildScrollView(
          controller: _scroll,
          primary: false,
          padding: const EdgeInsets.only(
            top: AppTheme.space4,
            bottom: AppTheme.space4,
            right: 12,
          ),
          child: _grid(),
        ),
      ),
    );
  }

  Widget _grid() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double spacing = AppTheme.space12;
        const double maxCardWidth = 470;
        final int columns = (constraints.maxWidth / (maxCardWidth + spacing))
            .ceil()
            .clamp(1, 6);
        final double cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final TemplateLibraryEntry entry in widget.group.entries)
              SizedBox(
                width: cardWidth,
                child: _EntryCard(
                  entry: entry,
                  languageCode: widget.languageCode,
                  document: widget.documentOf(entry),
                  isFavorite: widget.favorites.contains(entry.id),
                  cloudAvailable: widget.cloudAvailable,
                  onFavorite: widget.onFavorite,
                  onOpen: widget.onOpen,
                  onPreview: widget.onPreview,
                  onUseInBatch: widget.onUseInBatch,
                  onImportLocal: widget.onImportLocal,
                  onSaveCloud: widget.onSaveCloud,
                  onRename: widget.onRename,
                  onDuplicate: widget.onDuplicate,
                  onTogglePublic: widget.onTogglePublic,
                  onDeleteCloud: widget.onDeleteCloud,
                  onDeleteLocal: widget.onDeleteLocal,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.languageCode,
    required this.document,
    required this.isFavorite,
    required this.cloudAvailable,
    required this.onFavorite,
    required this.onOpen,
    required this.onPreview,
    required this.onUseInBatch,
    required this.onImportLocal,
    required this.onSaveCloud,
    required this.onRename,
    required this.onDuplicate,
    required this.onTogglePublic,
    required this.onDeleteCloud,
    required this.onDeleteLocal,
  });

  final TemplateLibraryEntry entry;

  /// لغة محتوى القالب — تُترجم بها عناوين القوالب الجاهزة في البطاقة.
  final String languageCode;
  final TemplateDocument document;
  final bool isFavorite;
  final bool cloudAvailable;
  final ValueChanged<TemplateLibraryEntry> onFavorite;
  final ValueChanged<TemplateLibraryEntry> onOpen;
  final ValueChanged<TemplateLibraryEntry> onPreview;
  final ValueChanged<TemplateLibraryEntry> onUseInBatch;
  final ValueChanged<TemplateLibraryEntry> onImportLocal;
  final ValueChanged<TemplateLibraryEntry> onSaveCloud;
  final ValueChanged<TemplateLibraryEntry> onRename;
  final ValueChanged<TemplateLibraryEntry> onDuplicate;
  final ValueChanged<TemplateLibraryEntry> onTogglePublic;
  final ValueChanged<TemplateLibraryEntry> onDeleteCloud;
  final ValueChanged<TemplateLibraryEntry> onDeleteLocal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final String orientationLabel = entry.orientation.isLandscape
        ? (context.l10n?.tplOrientationLandscape ?? 'أفقي')
        : (context.l10n?.tplOrientationPortrait ?? 'رأسي');
    // عنوان القالب الجاهز بلغة البلد (قوالب المستخدم تبقى كما حرّرها).
    final String displayTitle = entry.isPreset
        ? TemplateLocalization.text(languageCode, entry.title)
        : entry.title;

    return Container(
      key: ValueKey<String>('library-entry-${entry.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isFavorite ? scheme.goldDeep : scheme.outline,
          width: isFavorite ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ---- الصورة المصغّرة: معاينة متجهية حقيقية للقالب ----
          Container(
            height: 150,
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(AppTheme.space12),
            child: TemplateThumbnail(document: document, shadow: true),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                    if (entry.record.isPublic && entry.isCloud)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Tooltip(
                          message: context.l10n?.tplPublicBadge ?? 'قالب عام',
                          child: Icon(Icons.public_rounded,
                              size: 15, color: scheme.goldDeep),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    _SourceBadge(source: entry.source),
                    _Tag(label: orientationLabel),
                    if (entry.collection != null)
                      _Tag(label: entry.collection!.labelAr, gold: true),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  entry.isPreset
                      ? (context.l10n?.tplPresetOffline ??
                          'قالب جاهز • متاح أوفلاين')
                      : '${_EntryCard._formatDate(context, entry.record.updatedAt)} • '
                          '${context.l10n?.tplSchemaVersion((entry.record.layoutData['schema_version'] as num?)?.toInt() ?? 1) ?? 'مخطط v${(entry.record.layoutData['schema_version'] as num?)?.toInt() ?? 1}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onOpen(entry),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(
                          entry.isPreset
                              ? (context.l10n?.tplOpenAsTemplate ?? 'فتح كقالب')
                              : (context.l10n?.tplOpen ?? 'فتح'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    IconAction(
                      icon: Icons.visibility_rounded,
                      tooltip: 'معاينة مكبرة',
                      onPressed: () => onPreview(entry),
                    ),
                    IconAction(
                      icon: isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      tooltip: isFavorite ? 'إزالة التفضيل' : 'تفضيل',
                      selected: isFavorite,
                      onPressed: () => onFavorite(entry),
                    ),
                    PopupMenuButton<_EntryAction>(
                      tooltip: context.l10n?.commonOptions ?? 'خيارات',
                      onSelected: (_EntryAction action) {
                        switch (action) {
                          case _EntryAction.useInBatch:
                            onUseInBatch(entry);
                          case _EntryAction.importLocal:
                            onImportLocal(entry);
                          case _EntryAction.saveCloud:
                            onSaveCloud(entry);
                          case _EntryAction.rename:
                            onRename(entry);
                          case _EntryAction.duplicate:
                            onDuplicate(entry);
                          case _EntryAction.togglePublic:
                            onTogglePublic(entry);
                          case _EntryAction.deleteCloud:
                            onDeleteCloud(entry);
                          case _EntryAction.deleteLocal:
                            onDeleteLocal(entry);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          _menuItems(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Icon(Icons.more_vert_rounded,
                            size: 20, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<_EntryAction>> _menuItems(BuildContext context) {
    return <PopupMenuEntry<_EntryAction>>[
      PopupMenuItem<_EntryAction>(
        value: _EntryAction.useInBatch,
        child: _MenuRow(
          icon: Icons.table_view_rounded,
          label: context.l10n?.tplUseInBatch ?? 'استخدام في التوليد الجماعي',
        ),
      ),
      const PopupMenuDivider(),
      if (entry.isPreset) ...<PopupMenuEntry<_EntryAction>>[
        PopupMenuItem<_EntryAction>(
          value: _EntryAction.importLocal,
          child: _MenuRow(
            icon: Icons.download_for_offline_rounded,
            label: context.l10n?.tplImportLocal ?? 'استيراد محلياً',
          ),
        ),
        if (cloudAvailable)
          PopupMenuItem<_EntryAction>(
            value: _EntryAction.saveCloud,
            child: _MenuRow(
              icon: Icons.cloud_upload_rounded,
              label: context.l10n?.tplSaveToCloud ?? 'حفظ في السحابة',
            ),
          ),
      ],
      if (entry.isLocal) ...<PopupMenuEntry<_EntryAction>>[
        if (cloudAvailable)
          PopupMenuItem<_EntryAction>(
            value: _EntryAction.saveCloud,
            child: _MenuRow(
              icon: Icons.cloud_upload_rounded,
              label: context.l10n?.tplSaveToCloud ?? 'حفظ في السحابة',
            ),
          ),
        PopupMenuItem<_EntryAction>(
          value: _EntryAction.deleteLocal,
          child: _MenuRow(
            icon: Icons.delete_outline_rounded,
            label: context.l10n?.tplDeleteLocal ?? 'حذف محلياً',
            danger: true,
          ),
        ),
      ],
      if (entry.isCloud) ...<PopupMenuEntry<_EntryAction>>[
        PopupMenuItem<_EntryAction>(
          value: _EntryAction.rename,
          child: _MenuRow(
            icon: Icons.drive_file_rename_outline_rounded,
            label: context.l10n?.tplRename ?? 'إعادة التسمية',
          ),
        ),
        PopupMenuItem<_EntryAction>(
          value: _EntryAction.duplicate,
          child: _MenuRow(
            icon: Icons.copy_all_rounded,
            label: context.l10n?.editorDuplicate ?? 'تكرار',
          ),
        ),
        PopupMenuItem<_EntryAction>(
          value: _EntryAction.togglePublic,
          child: _MenuRow(
            icon: entry.record.isPublic
                ? Icons.lock_outline_rounded
                : Icons.public_rounded,
            label: entry.record.isPublic
                ? (context.l10n?.tplMakePrivate ?? 'جعله خاصاً')
                : (context.l10n?.tplMakePublic ?? 'جعله عاماً'),
          ),
        ),
        PopupMenuItem<_EntryAction>(
          value: _EntryAction.deleteCloud,
          child: _MenuRow(
            icon: Icons.delete_forever_rounded,
            label: context.l10n?.tplDelete ?? 'حذف',
            danger: true,
          ),
        ),
      ],
    ];
  }

  static String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return context.l10n?.tplNoDate ?? 'بلا تاريخ';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}/${two(value.month)}/${two(value.day)}';
  }
}

/// إجراءات بطاقة القالب.
enum _EntryAction {
  useInBatch,
  importLocal,
  saveCloud,
  rename,
  duplicate,
  togglePublic,
  deleteCloud,
  deleteLocal,
}

/// شارة المصدر (جاهز/محلي/سحابي).
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});

  final TemplateSource source;

  @override
  Widget build(BuildContext context) {
    final bool gold = source == TemplateSource.preset;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = gold ? scheme.goldDeep : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: gold ? scheme.secondaryContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(source.icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            source.labelAr,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// وسم صغير للتصنيف/الاتجاه/المجموعة.
class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.gold = false});

  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: gold ? scheme.secondaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: scheme.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: gold ? scheme.goldDeep : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = danger ? scheme.danger : scheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}

/// بطاقة حالة موحّدة (لا نتائج).
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppTheme.space12),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.space8),
              Text(
                message,
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
