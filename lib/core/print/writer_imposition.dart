/// تخطيط تجميع صفحات «جود كاتب» على ورق الطباعة — «A4 → 2 × A5».
///
/// **لماذا ملف منفصل؟** المحرّر يعمل على مقاس صفحة **مُقسَّم** (A5)، أمّا الطباعة
/// فتحتاج صفحتين متتاليتين على ورقة A4 واحدة. هذا الجسر يحوّل بين المقاسين،
/// وهو مبنيّ على [ImpositionCalculator] الموجود في المشروع — فلا خوارزمية رياضية
/// جديدة ولا تكرار منطق.
///
/// **لا يلمس هذا الملف محرّك PDF إطلاقاً**: مهمّته حساب **أين** تُوضَع كل صفحة
/// على الورقة، لا كيف تُرسم. البناء الفعليّ لملف الـPDF يحتاج محرّك الوثائق.
library;

import 'imposition_calculator.dart';

/// اتجاه طيّ الورقة: أفقي (نصفان فوق بعض) أو عمودي (نصفان جنب بعض).
enum WriterSplitFold {
  /// طيّ أفقي: صفحتان فوق بعض — الورقة A4 رأسية.
  horizontal,

  /// طيّ عمودي: صفحتان جنب بعض — الورقة A4 عرضية.
  vertical,
}

/// تخطيط ورقة تجميع واحدة لمستند «جود كاتب».
class WriterSheetLayout {
  const WriterSheetLayout({required this.imposition, required this.fold});

  /// شبكة الحصر كما يحسبها [ImpositionCalculator] — مصدر الحقيقة الرياضي.
  final ImpositionResult imposition;

  /// اتجاه الطيّ المطلوب.
  final WriterSplitFold fold;

  /// عدد صفحات المحرّر (الأقسام) التي تتّسع على الورقة الواحدة.
  int get slotsPerSheet => imposition.count;

  /// عدد أوراق الطباعة اللازمة لعدد الصفحات المُعطى.
  int sheetsFor(int pageCount) {
    if (slotsPerSheet <= 0 || pageCount <= 0) return 0;
    return (pageCount + slotsPerSheet - 1) ~/ slotsPerSheet;
  }

  /// موضع صفحة المحرّر رقم [pageIndex] (من صفر) على ورقتها.
  ///
  /// يُعيد `null` إن لم يكتمل زوج الصفحتين على الورقة نفسها (صفحة أخيرة
  /// وحدها) — فيصير موضعها الافتراضي أول خلية.
  ImpositionPlacement? placementOf(int pageIndex) {
    if (pageIndex < 0) return null;
    final int slot = pageIndex % slotsPerSheet;
    if (slot >= imposition.placements.length) return null;
    return imposition.placements[slot];
  }

  /// رقم ورقة الطباعة التي تقع عليها صفحة المحرّر رقم [pageIndex].
  int sheetOf(int pageIndex) =>
      slotsPerSheet <= 0 ? 0 : pageIndex ~/ slotsPerSheet;
}

/// يبني تخطيط التجميع لمستند «جود كاتب».
///
/// * [pageWidthMm]/[pageHeightMm] — أبعاد صفحة المحرّر الواحدة ( A5 عادةً).
/// * [fold] — اتجاه الطيّ؛ يُحدّد إن كانت الورقة رأسية أم عرضية.
/// * [gutterMm] — الفراغ بين النصفين (موضع الطيّ)؛ صفر يعني التماس.
/// * [marginMm] — هامش الورقة من كل حافة.
///
/// **التدوير مُعطَّل عن قصد** (`allowRotation: false`): تدوير صفحة المحرّر
/// 90° يقلب اتجاه نصّها فيبدو المستند المطبوع معكوساً. الحصر هنا هندسة وضعٍ
/// لا توليد نسخ، فعلى كل قسم أن يحفظ اتجاهه.
abstract final class WriterImposition {
  static WriterSheetLayout build({
    required double pageWidthMm,
    required double pageHeightMm,
    required WriterSplitFold fold,
    double gutterMm = 0,
    double marginMm = 0,
  }) {
    final ImpositionResult imposition = ImpositionCalculator.calculate(
      itemWidthMm: pageWidthMm,
      itemHeightMm: pageHeightMm,
      sheet: ImpositionSheet.a4,
      gutterXMm: fold == WriterSplitFold.vertical ? gutterMm : 0,
      gutterYMm: fold == WriterSplitFold.horizontal ? gutterMm : 0,
      marginMm: marginMm,
      bleedMm: 0,
      allowRotation: false,
      // الورقة **رأسية دائماً**: نصفا A4 (أفقهما أو عمودهما) يعيدانان A4
      // رأسية بالضبط. كان `sheetLandscape: fold == vertical` وهو خطأ: يجعل
      // الشبكة 2x0 فارغة لأن 297 لا يتّسع داخل 210.
      sheetLandscape: false,
    );

    return WriterSheetLayout(imposition: imposition, fold: fold);
  }
}
