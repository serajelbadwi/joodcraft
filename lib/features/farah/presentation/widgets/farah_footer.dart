/// تذييل (فاتور) شاشات «فرح» — عمود متوسّط من ثلاث قطع بالترتيب:
///
/// 1. «من أعمال JoodCraft» — نصّ فقط بلا أي لوجو.
/// 2. الإمضاء (`serag_signature.jpeg`).
/// 3. حقوق النشر.
///
/// ما حُذف عمداً بطلب صاحب العمل: شعار JoodCraft وشعار القرية وبطاقة
/// المطوّر كاملة (اللّقب «المطور» + الاسم + التليفون) — الفوتر صار توقيعاً
/// موجزاً لا بطاقة تعريف.
///
/// الشريط لا يحمل خلفية ملوّنة بل **نفس لون الصفحة** `#3D3D3D` عمداً: هالات
/// `_FarahGlow` خلف المحتوى تلوّن الشريط لو كان شفّافاً، وثبات اللون هو ما
/// يجعل حيلة إزالة أسود الإمضاء (‎`BlendMode.screen`‎) تطابق الشريط حرفياً.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../domain/farah_text.dart';
import '../../../village/presentation/village_theme.dart';

class FarahFooter extends StatelessWidget {
  const FarahFooter({super.key});

  /// نصّ «من أعمال JoodCraft» — هنا لا في `FarahText` عمداً: هذا الملف
  /// وحده هو ما تغيّر في هذه المهمة، والنصّ هوية هذا التذييل الجديد.
  static const String _brandLine = 'من أعمال JoodCraft';

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('farah-footer'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: VillageMetrics.space16,
        vertical: VillageMetrics.space12,
      ),
      decoration: BoxDecoration(
        color: VillageColors.background,
        border: Border(
          top: BorderSide(
            color: VillageColors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      // عمود متوسّط بثلاث قطع تحت بعضها — لا `Wrap` أفقياً كما كان: بعد
      // حذف بطاقة المطوّر صار الثلاثة سطراً واحداً لا تحتمل صفّاً.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Text(
            _brandLine,
            key: ValueKey<String>('farah-footer-brand'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppAssets.cairoFont,
              fontSize: 14,
              color: Color(0xB3FFFFFF), // أبيض @ 0.7
              height: 1.5,
            ),
          ),
          const SizedBox(height: VillageMetrics.space12),
          // الإمضاء: حبر أبيض على أسود (JPEG بلا قناة شفافية). حيلة `screen`
          // مع لون الشريط: الأسود يصير لون الشريط بالضبط (‎#3D3D3D‎ — يذوب
          // في الخلفية) والأبيض يبقى أبيضاً: إمضاء بلا ورقة ولا صندوق أسود.
          Image.asset(
            AppAssets.developerSignatureImage,
            key: const ValueKey<String>('farah-footer-signature'),
            height: 34,
            fit: BoxFit.contain,
            color: VillageColors.background,
            colorBlendMode: BlendMode.screen,
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) =>
                const SizedBox.shrink(),
          ),
          const SizedBox(height: VillageMetrics.space8),
          const Text(
            FarahText.footerCopyright,
            key: ValueKey<String>('farah-footer-copyright'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppAssets.cairoFont,
              fontSize: 12,
              color: Color(0x80FFFFFF), // أبيض @ 0.5
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
