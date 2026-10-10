import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/templates/template_draft.dart';
import '../../../../core/theme/app_theme.dart';
import '../dialogs/new_document_dialog.dart';

/// صفحة مسار `/new-project` — **مُشغِّل** لا شاشة.
///
/// «مستند جديد» ليس مكاناً في التطبيق بل نافذة عائمة فوق ما يعمل عليه المستخدم،
/// ولهذا كل مداخل التطبيق (قائمة اللوحة الجانبية، بطاقات لوحة التحكم، وأزرار
/// المحرّرات) تستدعي [openNewDocumentDialog] مباشرةً بلا تنقّل.
///
/// هذه الصفحة موجودة لتبقى **الروابط المباشرة** (`/new-project`) صالحة: تفتح
/// النافذة فور الوصول، وتُعيد المستخدم إلى لوحة التحكم إن ألغى — فلا يبقى على
/// صفحة فارغة.
class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _open());
  }

  Future<void> _open() async {
    if (_opened || !mounted) return;
    _opened = true;
    final TemplateDraft? draft = await showNewDocumentDialog(context);
    if (!mounted) return;
    if (draft == null) {
      // إلغاء بلا قرار: نعود إلى لوحة التحكم بدل البقاء في صفحة المُرحّل.
      context.go(AppRoutes.dashboard);
      return;
    }
    context.go(
      draft.category == TemplateCategory.contract
          ? AppRoutes.contractBuilder
          : AppRoutes.certificateBuilder,
      extra: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ما يظهر خلف النافذة لحظةً واحدة: عنوان مختصر يؤكد أن العمل لم يُفقَد.
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            context.l10n?.newDocTitle ?? 'مستند جديد',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            context.l10n?.hubSubtitle ??
                'اختر مقاساً جاهزاً أو حدّد أبعادك — تُفتح اللوحة '
                    'بالمقاس والنسبة بالضبط.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
