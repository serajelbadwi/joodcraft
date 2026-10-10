import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/print/imposition_calculator.dart';

/// اختبارات محرّك الحصر (Imposition) على الورقة.
///
/// الجوهر المطلوب التحقق منه:
/// * عدّ الشبكة الأقصى `columns × rows` لكل ورقة.
/// * التدوير التلقائي ‎90°‎ عند استيعابه لنسخ أكثر.
/// * إحداثيات X/Y وصناديق محدّدة (bounding boxes) دقيقة لكل نسخة.
/// * الحدود: الهامش، احتياط النزف (bleed)، الفواصل، وحالات عدم الملاءمة.
void main() {
  /// الحساب المباشر المستقل عن المحرّك — مرجع ثانٍ للكشف عن أخطاء التفسير.
  int gridCount({
    required double usable,
    required double cell,
    required double gutter,
  }) {
    if (cell <= 0 || usable <= 0 || cell + gutter <= 0) return 0;
    return ((usable + gutter) / (cell + gutter)).floor();
  }

  /// يتحقق أن كل صندوق يقع داخل المساحة الصالحة ولا تتقاطع أي صندوقان.
  void expectLayoutIsSound(ImpositionResult result) {
    final double inset = result.insetMm;
    final double limitRight = result.sheetWidthMm - inset;
    final double limitBottom = result.sheetHeightMm - inset;

    expect(result.placements, hasLength(result.count), reason: 'العدد يطابق الشبكة');
    expect(result.count, result.columns * result.rows, reason: 'count = rows×cols');

    for (final ImpositionPlacement p in result.placements) {
      expect(p.leftMm, greaterThanOrEqualTo(inset - 1e-9));
      expect(p.topMm, greaterThanOrEqualTo(inset - 1e-9));
      expect(p.rightMm, lessThanOrEqualTo(limitRight + 1e-9),
          reason: 'الصندوق يخرج يميناً: $p');
      expect(p.bottomMm, lessThanOrEqualTo(limitBottom + 1e-9),
          reason: 'الصندوق يخرج أسفل: $p');
      // كل نسخة بحجم الخلية الواحد بعد أي تدوير.
      expect(p.widthMm, result.cellWidthMm, reason: '$p');
      expect(p.heightMm, result.cellHeightMm, reason: '$p');
      expect(p.rotated, result.rotated, reason: '$p');
    }

    // لا تداخل بين أي صندوقين (اللمس مسموح: الفاصل قد يكون صفراً).
    for (int i = 0; i < result.placements.length; i++) {
      for (int j = i + 1; j < result.placements.length; j++) {
        final ImpositionPlacement a = result.placements[i];
        final ImpositionPlacement b = result.placements[j];
        final bool separated =
            a.rightMm <= b.leftMm + 1e-9 ||
            b.rightMm <= a.leftMm + 1e-9 ||
            a.bottomMm <= b.topMm + 1e-9 ||
            b.bottomMm <= a.topMm + 1e-9;
        expect(separated, isTrue, reason: 'تداخل بين $a و$b');
      }
    }
  }

  // ==========================================================================
  //  أوراق الطباعة
  // ==========================================================================
  group('أوراق الطباعة', () {
    test('مقاسات A4 وA3 وربع الفرخ بالمليمتر', () {
      expect(ImpositionSheet.a4.widthMm, 210);
      expect(ImpositionSheet.a4.heightMm, 297);
      expect(ImpositionSheet.a3.widthMm, 297);
      expect(ImpositionSheet.a3.heightMm, 420);
      expect(ImpositionSheet.quarter.widthMm, 350);
      expect(ImpositionSheet.quarter.heightMm, 500);
    });

    test('مساحة الورقة هي الضرب في المقاسين', () {
      expect(ImpositionSheet.a4.areaMm2, closeTo(62370, 1e-9));
      expect(ImpositionSheet.quarter.areaMm2, closeTo(175000, 1e-9));
    });
  });

  // ==========================================================================
  //  عدّ الشبكة
  // ==========================================================================
  group('عدّ الشبكة الأقصى', () {
    test('A4 + بطاقة 90×55 بدون فواصل ⇒ 2×5 = 10 نسخ', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
      );
      expect(r.columns, 2);
      expect(r.rows, 5);
      expect(r.count, 10);
      expect(r.rotated, isFalse, reason: 'الأصل أفضل هنا (10 > 9)');
      expectLayoutIsSound(r);
    });

    test('A3 + بطاقة 90×55 ⇒ 3×7 = 21 نسخة', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a3,
      );
      expect(r.columns, 3);
      expect(r.rows, 7);
      expect(r.count, 21);
      expect(r.rotated, isFalse);
      expectLayoutIsSound(r);
    });

    test('ربع الفرخ + بطاقة 90×55 ⇒ التدوير يكسب (30 > 27)', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.quarter,
      );
      // بلا تدوير: 350/90=3 و 500/55=9 ⇒ 27.
      // مدوّراً: 350/55=6 و 500/90=5 ⇒ 30.
      expect(r.rotated, isTrue);
      expect(r.columns, 6);
      expect(r.rows, 5);
      expect(r.count, 30);
      expect(r.cellWidthMm, 55);
      expect(r.cellHeightMm, 90);
      expectLayoutIsSound(r);
    });

    test('تطابق التام مع مقاس الورقة نفسها ⇒ نسخة واحدة', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 210,
        itemHeightMm: 297,
        sheet: ImpositionSheet.a4,
      );
      expect(r.count, 1);
      expect(r.columns, 1);
      expect(r.rows, 1);
      expect(r.rotated, isFalse);
      expect(r.placements.single.leftMm, 0);
      expect(r.placements.single.topMm, 0);
      expect(r.usedWidthMm, closeTo(210, 1e-9));
      expect(r.usedHeightMm, closeTo(297, 1e-9));
    });

    test('حجمان مختلفان في المحورين محسوبان مستقلّاً', () {
      // 105×99 على A4: عرضان من 105 (210/105) وثلاثة صفوف (297/99).
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 105,
        itemHeightMm: 99,
        sheet: ImpositionSheet.a4,
      );
      expect(r.columns, 2);
      expect(r.rows, 3);
      expect(r.count, 6);
      // ملاءمة تامة: الصندوق الأخير يلامس حدّ المساحة الصالحة بالضبط.
      expect(r.maxRightMm, closeTo(210, 1e-9));
      expect(r.maxBottomMm, closeTo(297, 1e-9));
      expectLayoutIsSound(r);
    });

    test('نتيجة ثابتة وقابلة للتكرار (نفس المدخلات ⇒ نفس الناتج)', () {
      ImpositionResult first = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
        marginMm: 5,
        bleedMm: 3,
        gutterXMm: 4,
        gutterYMm: 6,
      );
      ImpositionResult second = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
        marginMm: 5,
        bleedMm: 3,
        gutterXMm: 4,
        gutterYMm: 6,
      );
      expect(second.count, first.count);
      expect(second.rotated, first.rotated);
      for (int i = 0; i < first.placements.length; i++) {
        expect(second.placements[i].leftMm, first.placements[i].leftMm);
        expect(second.placements[i].topMm, first.placements[i].topMm);
      }
    });
  });

  // ==========================================================================
  //  التدوير التلقائي (90°)
  // ==========================================================================
  group('التدوير التلقائي', () {
    test('التدوير يختار لما يستوعب نسخاً أكثر (60×200 على A4 ⇒ 4 > 3)', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 60,
        itemHeightMm: 200,
        sheet: ImpositionSheet.a4,
      );
      expect(r.rotated, isTrue);
      expect(r.count, 4);
      expect(r.columns, 1);
      expect(r.rows, 4);
      // الصندوق معكوس: 200 عرضاً و60 طولاً.
      expect(r.cellWidthMm, 200);
      expect(r.cellHeightMm, 60);
      for (final ImpositionPlacement p in r.placements) {
        expect(p.rotated, isTrue);
        expect(p.widthMm, 200);
        expect(p.heightMm, 60);
      }
      expectLayoutIsSound(r);
    });

    test('إلغاء التدوير يستعيد التوزيع الأصلي', () {
      final ImpositionResult off = ImpositionCalculator.calculate(
        itemWidthMm: 60,
        itemHeightMm: 200,
        sheet: ImpositionSheet.a4,
        allowRotation: false,
      );
      expect(off.rotated, isFalse);
      expect(off.columns, 3);
      expect(off.rows, 1);
      expect(off.count, 3);

      final ImpositionResult on = ImpositionCalculator.calculate(
        itemWidthMm: 60,
        itemHeightMm: 200,
        sheet: ImpositionSheet.a4,
        allowRotation: true,
      );
      expect(on.count, greaterThan(off.count));
    });

    test('التعادل يبقي على الاتجاه الأصلي (لا تدوير بلا فائدة)', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
      );
      expect(r.rotated, isFalse, reason: 'القطعة مربّعة: التعادل يفضّل الأصل');
      expect(r.cellWidthMm, 100);
      expect(r.cellHeightMm, 100);
    });

    test('تحوّل السلوك عبر العتبة: 90×55 لا تُدوَّر على A4، 60×200 تُدوَّر',
        () {
      final ImpositionResult wide = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
      );
      expect(wide.rotated, isFalse, reason: '10 مقابل 9 ⇒ الأصل أفضل');

      final ImpositionResult tall = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.quarter,
      );
      expect(tall.rotated, isTrue, reason: '30 مقابل 27 ⇒ التدوير أفضل');
    });
  });

  // ==========================================================================
  //  الفواصل (Gutter)
  // ==========================================================================
  group('الفواصل بين النسخ', () {
    test('فاصل 10×10 على A4 بقطعة مربّعة 50 ⇒ 3×5 = 15', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 50,
        itemHeightMm: 50,
        sheet: ImpositionSheet.a4,
        gutterXMm: 10,
        gutterYMm: 10,
      );
      expect(r.columns, 3);
      expect(r.rows, 5);
      expect(r.count, 15);

      // المسافة بين المحاور صحيحة: 0، 60، 120.
      final List<double> xs = r.placements
          .map((ImpositionPlacement p) => p.leftMm)
          .toSet()
          .toList()
        ..sort();
      expect(xs, <double>[0, 60, 120]);

      final List<double> ys = r.placements
          .map((ImpositionPlacement p) => p.topMm)
          .toSet()
          .toList()
        ..sort();
      expect(ys, <double>[0, 60, 120, 180, 240]);

      expect(r.usedWidthMm, closeTo(170, 1e-9));
      expect(r.usedHeightMm, closeTo(290, 1e-9));
      expectLayoutIsSound(r);
    });

    test('الفواصل تقلّل العدّ مقابل نفس القطعة بلا فواصل', () {
      final ImpositionResult plain = ImpositionCalculator.calculate(
        itemWidthMm: 50,
        itemHeightMm: 50,
        sheet: ImpositionSheet.a4,
      );
      final ImpositionResult gapped = ImpositionCalculator.calculate(
        itemWidthMm: 50,
        itemHeightMm: 50,
        sheet: ImpositionSheet.a4,
        gutterXMm: 10,
        gutterYMm: 10,
      );
      expect(gapped.count, lessThan(plain.count));
      expect(gapped.count, 15);
      expect(plain.count, 20); // 210/50 = 4 و 297/50 = 5 ⇒ 4×5.
    });

    test('الفواصل تُهمّ في المسافة بين المحاور فقط (عنصر واحد يتبقى)',
        () {
      // فاصل أكبر من الورقة: الصندوق الواحد ما زال ينطبق، فلا يُهمل الفاصل
      // المصبوب في كل محور على حدة.
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 10,
        itemHeightMm: 10,
        sheet: ImpositionSheet.a4,
        gutterXMm: 1000,
        gutterYMm: 1000,
      );
      expect(r.count, 1);
      expect(r.placements.single.leftMm, 0);
      expect(r.placements.single.topMm, 0);
    });

    test('فصل أفقي ورأسي مختلفان يؤثّران على محورَيْهما منفصلين', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 50,
        itemHeightMm: 50,
        sheet: ImpositionSheet.a4,
        gutterXMm: 30,
        gutterYMm: 0,
      );
      // أفقياً: (210+30)/(50+30) = 3. عمودياً بلا فاصل: 297/50 = 5.
      expect(r.columns, 3);
      expect(r.rows, 5);
      expect(r.usedHeightMm, closeTo(250, 1e-9)); // 5×50 بلا فواصل
      expectLayoutIsSound(r);
    });
  });

  // ==========================================================================
  //  الهامش والاحتياط (bleed) وحدودهما
  // ==========================================================================
  group('الهامش والاحتياط وحدودهما', () {
    test('هامش 10 على A4 يبدأ الإحداثيات من (10,10)', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        marginMm: 10,
      );
      expect(r.insetMm, 10);
      expect(r.usableWidthMm, 190);
      expect(r.usableHeightMm, 277); // 297 - 2×10
      expect(r.columns, 1);
      expect(r.rows, 2);
      expect(r.count, 2);
      expect(r.placements[0].leftMm, 10);
      expect(r.placements[0].topMm, 10);
      expect(r.placements[1].topMm, 110);
      expectLayoutIsSound(r);
    });

    test('الاحتياط (bleed) يُضاف إلى الهامش من كل حافة', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        marginMm: 5,
        bleedMm: 3,
      );
      expect(r.insetMm, 8);
      expect(r.usableWidthMm, 194);
      expect(r.usableHeightMm, 281);
      expect(r.count, 2);
      expect(r.placements.first.leftMm, 8);
      expect(r.placements.first.topMm, 8);
      expectLayoutIsSound(r);
    });

    test('الهامش والاحتياط متساويان النتيجة إن كانا بنفس المبلغ', () {
      final ImpositionResult marginOnly = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        marginMm: 8,
      );
      final ImpositionResult bleedOnly = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        bleedMm: 8,
      );
      expect(marginOnly.count, bleedOnly.count);
      expect(marginOnly.usableWidthMm, bleedOnly.usableWidthMm);
    });

    test('حدود الهامش: الحدّ الأقصى يعطي 1 نسخة، وما بعده لا شيء', () {
      // لقطع 100×100 على A4 يلزم عرض صالح ≥ 100 ⇐ (210 - 2×inset) ≥ 100
      // ⇐ inset ≤ 55.
      final ImpositionResult atLimit = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        marginMm: 55,
      );
      expect(atLimit.count, 1);
      expect(atLimit.placements.single.leftMm, 55);
      expect(atLimit.placements.single.topMm, 55);
      expect(atLimit.maxRightMm, closeTo(155, 1e-9));
      expectLayoutIsSound(atLimit);

      final ImpositionResult beyond = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        marginMm: 55.5,
      );
      expect(beyond.count, 0, reason: 'العرض الصالح 99 < 100 ⇒ لا ينطبق');
      expect(beyond.isEmpty, isTrue);
      expect(beyond.columns, 0);
      expect(beyond.rows, 0);
    });

    test('هامش واحتياط مجتمعان يتجاوزان الحدّ ⇒ لا شيء', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 100,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        marginMm: 40,
        bleedMm: 20, // inset = 60 > 55
      );
      expect(r.count, 0);
      expect(r.isEmpty, isTrue);
      expect(r.maxRightMm, 0);
      expect(r.maxBottomMm, 0);
      expect(r.usedWidthMm, 0);
      expect(r.usedHeightMm, 0);
      expect(r.coverage, 0);
    });

    test('هامش مفرط الحجم على كل المقاسات لا ينتج نسخاً', () {
      for (final ImpositionSheet sheet in ImpositionSheet.values) {
        final ImpositionResult r = ImpositionCalculator.calculate(
          itemWidthMm: 100,
          itemHeightMm: 100,
          sheet: sheet,
          marginMm: sheet.widthMm / 2,
        );
        expect(r.count, 0, reason: sheet.name);
        expect(r.isEmpty, isTrue, reason: sheet.name);
      }
    });
  });

  // ==========================================================================
  //  حالات الحواف (Edge Cases)
  // ==========================================================================
  group('حالات الحواف', () {
    test('القطعة أكبر من الورقة ⇒ بلا نسخ وبلا خطأ', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 300,
        itemHeightMm: 400,
        sheet: ImpositionSheet.a4,
      );
      expect(r.isEmpty, isTrue);
      expect(r.count, 0);
      expect(r.columns, 0);
      expect(r.rows, 0);
      expect(r.placements, isEmpty);
      expect(r.coverage, 0);
    });

    test('قطعة أعرض من الورقة تنطبق فور أن تُدوَّر 90°', () {
      // 280 عرضاً لا ينطبق على A4 (210)، لكن مدوّرةً تصير 100 عرضاً × 280
      // طولاً فتنطبق عمودان (210/100) وصف واحد (297/280).
      final ImpositionResult off = ImpositionCalculator.calculate(
        itemWidthMm: 280,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        allowRotation: false,
      );
      expect(off.count, 0);

      final ImpositionResult on = ImpositionCalculator.calculate(
        itemWidthMm: 280,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        allowRotation: true,
      );
      expect(on.rotated, isTrue);
      expect(on.columns, 2);
      expect(on.rows, 1);
      expect(on.count, 2);
      expectLayoutIsSound(on);
    });

    test('أبعاد سالبة أو صفراً ترمي ArgumentError', () {
      expect(
        () => ImpositionCalculator.calculate(
          itemWidthMm: 0,
          itemHeightMm: 50,
          sheet: ImpositionSheet.a4,
        ),
        throwsArgumentError,
      );
      expect(
        () => ImpositionCalculator.calculate(
          itemWidthMm: 50,
          itemHeightMm: -5,
          sheet: ImpositionSheet.a4,
        ),
        throwsArgumentError,
      );
    });

    test('فاصل سالب يرمي ArgumentError', () {
      expect(
        () => ImpositionCalculator.calculate(
          itemWidthMm: 50,
          itemHeightMm: 50,
          sheet: ImpositionSheet.a4,
          gutterXMm: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => ImpositionCalculator.calculate(
          itemWidthMm: 50,
          itemHeightMm: 50,
          sheet: ImpositionSheet.a4,
          gutterYMm: -0.001,
        ),
        throwsArgumentError,
      );
    });

    test('هامش أو احتياط سالب يرمي ArgumentError', () {
      expect(
        () => ImpositionCalculator.calculate(
          itemWidthMm: 50,
          itemHeightMm: 50,
          sheet: ImpositionSheet.a4,
          marginMm: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => ImpositionCalculator.calculate(
          itemWidthMm: 50,
          itemHeightMm: 50,
          sheet: ImpositionSheet.a4,
          bleedMm: -1,
        ),
        throwsArgumentError,
      );
    });

    test('هامش صفر وبلا فواصل مدخلات افتراضية', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
      );
      expect(r.marginMm, 0);
      expect(r.bleedMm, 0);
      expect(r.gutterXMm, 0);
      expect(r.gutterYMm, 0);
      expect(r.insetMm, 0);
      expect(r.usableWidthMm, 210);
      expect(r.usableHeightMm, 297);
    });

    test('القائمة غير قابلة للتعديل', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
      );
      expect(
        () => r.placements.add(r.placements.first),
        throwsUnsupportedError,
      );
    });
  });

  // ==========================================================================
  //  الإحداثيات وصناديق الارتباط الدقيقة
  // ==========================================================================
  group('الإحداثيات وصناديق الارتباط', () {
    test('هامش 5 + احتياط 3 + فواصل 4×6 على A4: إحداثيات محسوبة بالضبط',
        () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
        marginMm: 5,
        bleedMm: 3,
        gutterXMm: 4,
        gutterYMm: 6,
      );
      // inset = 8، عرض صالح 194، ارتفاع صالح 281.
      // أفقياً: (194+4)/(90+4) = 2.11 ⇒ 2 عمود.
      // رأسياً: (281+6)/(55+6) = 4.70 ⇒ 4 صفوف.
      expect(r.columns, 2);
      expect(r.rows, 4);
      expect(r.count, 8);
      expect(r.rotated, isFalse);

      ImpositionPlacement p(int index) => r.placements[index];
      expect(p(0).leftMm, 8);
      expect(p(0).topMm, 8);
      expect(p(1).leftMm, 102); // 8 + (90+4)
      expect(p(1).topMm, 8);
      expect(p(2).leftMm, 8);
      expect(p(2).topMm, 69); // 8 + (55+6)
      expect(p(7).leftMm, 102);
      expect(p(7).topMm, 191); // 8 + 3×61

      expect(r.usedWidthMm, closeTo(184, 1e-9)); // 2×90 + 4
      expect(r.usedHeightMm, closeTo(238, 1e-9)); // 4×55 + 3×6
      expect(r.surplusWidthMm, closeTo(10, 1e-9)); // 194 - 184
      expect(r.surplusHeightMm, closeTo(43, 1e-9)); // 281 - 238
      expectLayoutIsSound(r);
    });

    test('كل صندوق حجمه الخلية وأبعاده بعد التدوير', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
        marginMm: 5,
        bleedMm: 3,
        gutterXMm: 4,
        gutterYMm: 6,
      );
      for (final ImpositionPlacement p in r.placements) {
        expect(p.widthMm, 90, reason: '$p');
        expect(p.heightMm, 55, reason: '$p');
        expect(p.rightMm, p.leftMm + 90, reason: '$p');
        expect(p.bottomMm, p.topMm + 55, reason: '$p');
        expect(p.rotated, isFalse);
      }
    });

    test('الترقيم صفاً صفاً: index = row×columns + column', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
      );
      for (final ImpositionPlacement p in r.placements) {
        expect(p.index, p.row * r.columns + p.column);
      }
      final List<int> indices =
          r.placements.map((ImpositionPlacement p) => p.index).toList();
      expect(indices, List<int>.generate(r.count, (int i) => i));
    });

    test('أقصى إحداثي يمتدّ داخل المساحة الصالحة لكل النتائج', () {
      for (final ImpositionSheet sheet in ImpositionSheet.values) {
        final ImpositionResult r = ImpositionCalculator.calculate(
          itemWidthMm: 90,
          itemHeightMm: 55,
          sheet: sheet,
          marginMm: 6,
          bleedMm: 3,
        );
        expect(
          r.maxRightMm,
          lessThanOrEqualTo(sheet.widthMm - r.insetMm + 1e-9),
          reason: sheet.name,
        );
        expect(
          r.maxBottomMm,
          lessThanOrEqualTo(sheet.heightMm - r.insetMm + 1e-9),
          reason: sheet.name,
        );
        expectLayoutIsSound(r);
      }
    });
  });

  // ==========================================================================
  //  قلب الورقة (sheetLandscape)
  // ==========================================================================
  group('قلب الورقة', () {
    test('A4 عرضية تغيّر المحاور وأبعاد الورقة الفعّالة', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 280,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        sheetLandscape: true,
      );
      expect(r.sheetLandscape, isTrue);
      expect(r.sheetWidthMm, 297);
      expect(r.sheetHeightMm, 210);
      // 297/280 = 1 عمود و 210/100 = 2 صف.
      expect(r.columns, 1);
      expect(r.rows, 2);
      expect(r.count, 2);
      expectLayoutIsSound(r);
    });

    test('نفس القطعة تتناسب مع قلب الورقة عند تعطيل التدوير', () {
      final ImpositionResult portrait = ImpositionCalculator.calculate(
        itemWidthMm: 280,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        sheetLandscape: false,
        allowRotation: false,
      );
      // 280 عرضاً لا ينطبق على طول A4 (210).
      expect(portrait.count, 0);

      final ImpositionResult landscape = ImpositionCalculator.calculate(
        itemWidthMm: 280,
        itemHeightMm: 100,
        sheet: ImpositionSheet.a4,
        sheetLandscape: true,
        allowRotation: false,
      );
      // مقلوبةً (297×210) ينطبق عمودان: 297/280 = 1 و 210/100 = 2.
      expect(landscape.count, 2);
      expect(landscape.count, greaterThan(portrait.count));
    });

    test('قلب الورقة يحفظ مجموع المحاور (المساحة نفسها بمحاور مبدلة)', () {
      final ImpositionResult straight = ImpositionCalculator.calculate(
        itemWidthMm: 60,
        itemHeightMm: 60,
        sheet: ImpositionSheet.a4,
        sheetLandscape: false,
      );
      final ImpositionResult flipped = ImpositionCalculator.calculate(
        itemWidthMm: 60,
        itemHeightMm: 60,
        sheet: ImpositionSheet.a4,
        sheetLandscape: true,
      );
      expect(straight.usableWidthMm, flipped.usableHeightMm);
      expect(straight.usableHeightMm, flipped.usableWidthMm);
      // القطعة مربّعة والمحاور تتبادلان: العدّان متساويان (4×3 مقابل 3×4).
      expect(straight.count, 12);
      expect(flipped.count, 12);
      expect(flipped.columns, 4); // 297/60 = 4
      expect(flipped.rows, 3); // 210/60 = 3
    });
  });

  // ==========================================================================
  //  مؤشرات مشتقة
  // ==========================================================================
  group('المؤشرات المشتقة', () {
    test('نسبة الاستغلال = مساحة النسخ ÷ مساحة الورقة', () {
      final ImpositionResult r = ImpositionCalculator.calculate(
        itemWidthMm: 90,
        itemHeightMm: 55,
        sheet: ImpositionSheet.a4,
      );
      expect(r.count, 10);
      expect(r.coverage, closeTo(10 * 90 * 55 / (210 * 297), 1e-9));
      expect(r.coverage, greaterThan(0));
      expect(r.coverage, lessThan(1));
    });

    test('المساحة المستهلكة لا تتجاوز المساحة الصالحة أبداً', () {
      for (final ImpositionSheet sheet in ImpositionSheet.values) {
        for (final double gutter in <double>[0, 5, 15]) {
          final ImpositionResult r = ImpositionCalculator.calculate(
            itemWidthMm: 90,
            itemHeightMm: 55,
            sheet: sheet,
            gutterXMm: gutter,
            gutterYMm: gutter,
            marginMm: 4,
            bleedMm: 3,
          );
          expect(r.surplusWidthMm, greaterThanOrEqualTo(-1e-9),
              reason: '${sheet.name} gutter=$gutter');
          expect(r.surplusHeightMm, greaterThanOrEqualTo(-1e-9),
              reason: '${sheet.name} gutter=$gutter');
          expectLayoutIsSound(r);
        }
      }
    });

    test('عدّ الشبكة يطابق المرجع المستقلّ عبر شبكة مدخلات', () {
      final List<double> items = <double>[30, 55, 70, 90, 100, 148.5, 210];
      final List<double> gutters = <double>[0, 4, 10];
      final List<double> insets = <double>[0, 5, 10];

      for (final ImpositionSheet sheet in ImpositionSheet.values) {
        for (final double item in items) {
          for (final double gutter in gutters) {
            for (final double inset in insets) {
              final ImpositionResult r = ImpositionCalculator.calculate(
                itemWidthMm: item,
                itemHeightMm: item * 1.4,
                sheet: sheet,
                gutterXMm: gutter,
                gutterYMm: gutter,
                marginMm: inset,
                bleedMm: 0,
                allowRotation: false,
              );
              final double usableW = sheet.widthMm - 2 * inset;
              final double usableH = sheet.heightMm - 2 * inset;
              expect(
                r.columns,
                gridCount(usable: usableW, cell: item, gutter: gutter),
                reason: '${sheet.name} item=$item gutter=$gutter inset=$inset',
              );
              expect(
                r.rows,
                gridCount(
                    usable: usableH, cell: item * 1.4, gutter: gutter),
                reason: '${sheet.name} item=$item gutter=$gutter inset=$inset',
              );
              expect(r.count, r.columns * r.rows);
              expectLayoutIsSound(r);
            }
          }
        }
      }
    });
  });
}
