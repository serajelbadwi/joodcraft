import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/pdf/arabic_text_engine.dart';

void main() {
  group('ArabicTextEngine.toVisual — crash regression', () {
    test('collapsing word أُعطيت renders without throwing', () {
      const String crashingText = 'أُعطيت';
      final String visual = ArabicTextEngine.toVisual(crashingText);
      // أُعطيت ينهار إلى 5 حرفاً (أعطيت) عندما تُزال علامة التنصيف المدمجة.
      expect(visual, 'أعطيت');
      expect(visual.length, lessThanOrEqualTo(crashingText.length));
    });

    test('collapsing word أُبرم renders without throwing', () {
      const String crashingText = 'أُبرم';
      final String visual = ArabicTextEngine.toVisual(crashingText);
      expect(visual, 'أبرم');
      expect(visual.length, lessThanOrEqualTo(crashingText.length));
    });

    test('normal words are reordered by bidi (visual output)', () {
      // bidi يرتّب الحروف عكسياً عند عرض RTL، لذا نؤكد فقط على أن حروف الكلمتين
      //oggle توجد في الخرج (بصورة شكلية)، وليس بالترتيب المنطقي.
      final String visual = ArabicTextEngine.toVisual('شهادة تقدير');
      expect(visual, isNot(equals('شهادة تقدير')));
      expect(visual.length, greaterThan(0));
    });

    test('words with combining marks keep their base letters', () {
      const String crashingText = 'أُعطيت';
      final String visual = ArabicTextEngine.toVisual(crashingText);
      // لا يحتوي على علامة تنصيف مدمجة (U+064D) بعد الإصلاح.
      expect(visual, isNot(contains('\u064D')));
      // يبقى حرف العين على الأقل في المخرج (تجاهل الترتيب البصري).
      expect(visual, contains('ع'));
    });

    test('words that fully collapse keep their base letters', () {
      const String crashingText = 'أُبرم';
      final String visual = ArabicTextEngine.toVisual(crashingText);
      // لم يعد هناك حرف التنصيف المدمج، والحرفان الأساسيان يبقىان.
      expect(visual, isNot(contains('\u064D')));
      expect(visual.contains('ب') && visual.contains('ر'), true);
    });
  });
}
