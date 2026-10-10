import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/editor/widgets/template_editor_view.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/templates/template_draft.dart';
import '../../../../core/templates/template_record.dart';
import '../../../../core/templates/template_repository.dart';
import '../../../project_hub/presentation/dialogs/new_document_dialog.dart';

class _TabSession {
  _TabSession({
    required this.id,
    required this.title,
    this.record,
    this.draft,
  });

  final String id;
  final String title;
  final TemplateRecord? record;
  final TemplateDraft? draft;
}

/// محرّر قوالب الشهادات — A4 أفقي بمحرك التحرير المركزي.
/// تم إضافة دعم نظام التبويبات المتعددة (Multi-Document Tabs).
class CertificateTemplateEditorScreen extends StatefulWidget {
  const CertificateTemplateEditorScreen({
    super.key,
    this.repository,
    this.record,
    this.draft,
  });

  final TemplateRepository? repository;
  final TemplateRecord? record;
  final TemplateDraft? draft;

  @override
  State<CertificateTemplateEditorScreen> createState() => _CertificateTemplateEditorScreenState();
}

class _CertificateTemplateEditorScreenState extends State<CertificateTemplateEditorScreen> {
  final List<_TabSession> _tabs = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // التهيئة بتبويب واحد بناءً على المعطيات من مكتبة القوالب
    final String initialTitle = widget.draft?.title ??
        widget.record?.title ??
        'شهادة جديدة';

    _tabs.add(_TabSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: initialTitle,
      record: widget.record,
      draft: widget.draft,
    ));
  }

  @override
  void didUpdateWidget(covariant CertificateTemplateEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عندما يقوم AppRouter بتمرير مستند جديد في نفس الشاشة، نضيفه كتبويب بدل استبدال الشاشة
    if (widget.record != oldWidget.record || widget.draft != oldWidget.draft) {
      if (widget.record == null && widget.draft == null) return;
      
      // هل التبويب مفتوح مسبقاً؟
      for (int i = 0; i < _tabs.length; i++) {
        if (widget.record != null && _tabs[i].record?.id == widget.record!.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _currentIndex = i);
          });
          return;
        }
      }

      // إضافة التبويب الجديد والانتقال إليه
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          final String title = widget.draft?.title ?? widget.record?.title ?? 'شهادة جديدة';
          _tabs.add(_TabSession(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            record: widget.record,
            draft: widget.draft,
          ));
          _currentIndex = _tabs.length - 1;
        });
      });
    }
  }

  void _addNewTab() {
    setState(() {
      _tabs.add(_TabSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'مستند بدون عنوان',
      ));
      _currentIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    // إغلاق التبويب مبدئياً دون فحص الحالة المعقد (تُضاف لاحقاً عبر اتصال بالمتحكم)
    setState(() {
      _tabs.removeAt(index);
      if (_tabs.isEmpty) {
        _addNewTab();
      } else if (_currentIndex >= _tabs.length) {
        _currentIndex = _tabs.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // شريط التبويبات (Document Tabs Bar) - نمط Photoshop
        Container(
          height: 48,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final isActive = index == _currentIndex;

                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.surface
                              : Colors.transparent,
                          border: Border(
                            top: BorderSide(
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            right: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withAlpha(50),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                color: isActive
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // نسبة الزوم التوضيحية
                            const Text(
                              '@ 100%',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _closeTab(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // زر إضافة تبويب جديد
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _addNewTab,
                  tooltip: 'فتح مستند جديد',
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        
        // مساحة العمل (محرر القوالب الحي)
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs.map((tab) {
              // نستخدم key محدد لكل تبويب للحفاظ على الـ Controller والذاكرة بداخل IndexedStack
              if (tab.draft != null) {
                return TemplateEditorView(
                  key: ValueKey('editor_${tab.id}'),
                  category: tab.draft!.category,
                  initialTemplateAsset: AppAssets.sampleCertificateTemplate,
                  exportFileName: 'joodcraft-certificate.pdf',
                  repository: widget.repository,
                  title: tab.draft!.title,
                  document: tab.draft!.document,
                  onNewDocument: () => openNewDocumentDialog(
                    context,
                    initialCategory: tab.draft!.category,
                  ),
                );
              }

              return TemplateEditorView(
                key: ValueKey('editor_${tab.id}'),
                category: TemplateCategory.certificate,
                initialTemplateAsset: AppAssets.sampleCertificateTemplate,
                exportFileName: 'joodcraft-certificate.pdf',
                repository: widget.repository,
                title: tab.title,
                document: tab.record?.toDocument(),
                initialRecordId: tab.record?.id,
                onNewDocument: () => openNewDocumentDialog(
                  context,
                  initialCategory: TemplateCategory.certificate,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
