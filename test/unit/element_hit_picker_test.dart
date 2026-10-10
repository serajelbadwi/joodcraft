import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/editor/element_hit_picker.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات منطق اختيار العنصر تحت المؤشر (اختبار الإصابة في المحرّر).
///
/// الجوهر: عند تداخل عناصر تحت النقرة يفوز **الأصغر مساحة** (الأدلى)، وعند
/// التساوي يفوز **الأعلى طبقة (z)**، والحاويات المفرغة لا تسرق نقرات ما داخلها.
void main() {
  ElementBox box(double x, double y, double width, double height) =>
      ElementBox(x: x, y: y, width: width, height: height);

  /// مستطيل مصمت (بتعبئة) — سلوكه كعنصر عادي يستقبل النقرة أينما وقع.
  ShapeElement solid(String id, ElementBox b) => ShapeElement(
        id: id,
        box: b,
        kind: ShapeKind.rect,
        fillHex: '#FFFFFFFF',
      );

  /// حاوية مفرغة: حدود فقط بلا تعبئة.
  ShapeElement outline(String id, ElementBox b, {double strokeWidth = 6}) =>
      ShapeElement(
        id: id,
        box: b,
        kind: ShapeKind.rect,
        strokeHex: '#FF1B2539',
        strokeWidth: strokeWidth,
      );

  Offset at(double x, double y) => Offset(x, y);

  group('الأصغر مساحة أولاً', () {
    test('عنصر صغير داخل عنصر أكبر: الأصغر يفوز من أول نقرة', () {
      final ShapeElement big = solid('big', box(0, 0, 400, 300));
      final ShapeElement small = solid('small', box(150, 100, 60, 40));

      // الأصغر تحت الأكبر في الترتيب (الأعلى طبقة) — ولا يهم: المساحة تفوز.
      final TemplateElement? first = pickElementAt(
        <TemplateElement>[small, big],
        point: at(180, 120),
      );
      // والأكبر تحت الأصغر في الترتيب (الأعلى طبقة هو الأكبر) — ويلزم نفسه.
      final TemplateElement? second = pickElementAt(
        <TemplateElement>[big, small],
        point: at(180, 120),
      );

      expect(first?.id, 'small');
      expect(second?.id, 'small');
    });

    test('النقر خارج الصغير داخل الكبير يُصيب الكبير', () {
      final ShapeElement big = solid('big', box(0, 0, 400, 300));
      final ShapeElement small = solid('small', box(150, 100, 60, 40));

      expect(
        pickElementAt(<TemplateElement>[small, big], point: at(20, 20))?.id,
        'big',
      );
    });

    test('ثلاثة عناصر متداخلة: الأصغر في القلب يفوز', () {
      final TemplateElement outer = solid('outer', box(0, 0, 600, 400));
      final TemplateElement middle = solid('middle', box(100, 100, 300, 200));
      final TemplateElement inner = solid('inner', box(200, 150, 80, 60));

      expect(
        pickElementAt(
          <TemplateElement>[outer, middle, inner],
          point: at(240, 180),
        )?.id,
        'inner',
      );
      expect(
        pickElementAt(
          <TemplateElement>[outer, middle, inner],
          point: at(120, 120),
        )?.id,
        'middle',
      );
      expect(
        pickElementAt(
          <TemplateElement>[outer, middle, inner],
          point: at(10, 10),
        )?.id,
        'outer',
      );
    });

    test('عند تساوي المساحات يفوز الأعلى طبقة (آخر في القائمة)', () {
      final ShapeElement lower = solid('lower', box(100, 100, 50, 50));
      final ShapeElement upper = solid('upper', box(100, 100, 50, 50));

      expect(
        pickElementAt(<TemplateElement>[lower, upper], point: at(120, 120))
            ?.id,
        'upper',
      );
      expect(
        pickElementAt(<TemplateElement>[upper, lower], point: at(120, 120))
            ?.id,
        'lower',
      );
    });

    test('نقطة خارج كل العناصر تعيد لا شيء (تمرّ إلى الورقة)', () {
      final TemplateElement only = solid('only', box(100, 100, 50, 50));

      expect(pickElementAt(<TemplateElement>[only], point: at(99, 150)), isNull);
      expect(pickElementAt(<TemplateElement>[], point: at(0, 0)), isNull);
    });

    test('عناصر بصفر عرض أو ارتفاع لا تُعَد', () {
      final TemplateElement flat =
          solid('flat', box(100, 100, 0, 80));
      expect(pickElementAt(<TemplateElement>[flat], point: at(100, 140)), isNull);
    });
  });

  group('الحاويات المفرغة (الإطارات والأشكال الحدودية)', () {
    test('إطار مفرغ لا يسرق نقرة العنصر الصغير داخله', () {
      // إطار يغطي الصفحة كلها (كإطار الخلفية) وصورة صغيرة داخله.
      final ImageElement frame = ImageElement(
        id: 'frame',
        box: box(0, 0, 600, 400),
        sourceKind: ImageSourceKind.asset,
        path: 'frame.png',
      );
      final ShapeElement small = solid('small', box(250, 150, 60, 40));

      // داخل قلب الإطار على الصورة الصغيرة ⇒ الصغيرة (حتى لو كان الإطار أعلى).
      expect(
        pickElementAt(
          <TemplateElement>[small, frame],
          point: at(280, 170),
          frameIds: <String>{'frame'},
        )?.id,
        'small',
      );
      expect(
        pickElementAt(
          <TemplateElement>[frame, small],
          point: at(280, 170),
          frameIds: <String>{'frame'},
        )?.id,
        'small',
      );
    });

    test('إطار مفرغ: النقرة على حدّه تلتقطه، وفي قلبه لا شيء', () {
      final ImageElement frame = ImageElement(
        id: 'frame',
        box: box(0, 0, 600, 400),
        sourceKind: ImageSourceKind.asset,
        path: 'frame.png',
      );

      // النقرة على الحدّ الخارجي (ضمن المسكة) ⇒ الإطار.
      expect(
        pickElementAt(
          <TemplateElement>[frame],
          point: at(6, 200),
          frameIds: <String>{'frame'},
        )?.id,
        'frame',
      );
      // النقرة في القلب (بعيداً عن الحدّ) ⇒ لا شيء: تمرّ إلى الورقة.
      expect(
        pickElementAt(
          <TemplateElement>[frame],
          point: at(300, 200),
          frameIds: <String>{'frame'},
        ),
        isNull,
      );
    });

    test('صورة الإطار المسجَّلة مفرغة — وغير المسجَّلة مصمتة', () {
      final ImageElement image = ImageElement(
        id: 'img',
        box: box(0, 0, 600, 400),
        sourceKind: ImageSourceKind.asset,
        path: 'frame.png',
      );

      // غير مسجَّلة ⇒ صندوق مصمت يستقبل النقرة في قلبه.
      expect(
        pickElementAt(<TemplateElement>[image], point: at(300, 200))?.id,
        'img',
      );
      // مسجَّلة كإطار ⇒ صارت مفرغة: القلب لا شيء، والحدّ يلتقطها.
      expect(
        pickElementAt(
          <TemplateElement>[image],
          point: at(300, 200),
          frameIds: <String>{'img'},
        ),
        isNull,
      );
      expect(
        pickElementAt(
          <TemplateElement>[image],
          point: at(4, 200),
          frameIds: <String>{'img'},
        )?.id,
        'img',
      );
    });

    test('شكل حدودي: النقرة على الحدّ تلتقطه وفي قلبه لا شيء', () {
      final ShapeElement outlineShape = outline('rect', box(100, 100, 400, 300));

      expect(
        pickElementAt(
          <TemplateElement>[outlineShape],
          point: at(110, 250),
        )?.id,
        'rect',
      );
      expect(
        pickElementAt(<TemplateElement>[outlineShape], point: at(300, 250)),
        isNull,
      );
    });

    test('شكل بلا تعبئة ولا حدّ شفاف لا يعترض إطلاقاً', () {
      final ShapeElement invisible = ShapeElement(
        id: 'ghost',
        box: box(0, 0, 600, 400),
        kind: ShapeKind.rect,
      );

      expect(isTransparentElement(invisible), isTrue);
      expect(pickElementAt(<TemplateElement>[invisible], point: at(300, 200)),
          isNull);
      // حتى على «حدّه» لا يُلتقط لأنه لا يُرى أصلاً.
      expect(
        pickElementAt(<TemplateElement>[invisible], point: at(4, 200)),
        isNull,
      );
    });

    test('تعبئة شفافة (‎#00000000‎) تُعامَل كغياب تعبئة', () {
      final ShapeElement clearFill = ShapeElement(
        id: 'clear',
        box: box(100, 100, 400, 300),
        kind: ShapeKind.rect,
        fillHex: '#00000000',
        strokeHex: '#FF1B2539',
        strokeWidth: 4,
      );

      expect(isHollowContainerElement(clearFill, isFrame: false), isTrue);
      expect(
        pickElementAt(<TemplateElement>[clearFill], point: at(300, 250)),
        isNull,
      );
    });

    test('تصنيف الحاويات: النص والصورة غير الإطار مصمتة', () {
      final TextElement text = TextElement(
        id: 't',
        box: box(0, 0, 200, 100),
        text: 'شهادة',
      );
      final ImageElement image = ImageElement(
        id: 'img',
        box: box(0, 0, 200, 100),
        sourceKind: ImageSourceKind.asset,
        path: 'logo.png',
      );

      expect(isHollowContainerElement(text, isFrame: false), isFalse);
      expect(isHollowContainerElement(image, isFrame: false), isFalse);
      expect(isHollowContainerElement(image, isFrame: true), isTrue);
      expect(isTransparentElement(text), isFalse);
    });

    test('مسكة الحاوية محصورة بين 8 و48 وحدة تصميم', () {
      expect(hollowBandFor(box(0, 0, 600, 400)), 48.0);
      expect(hollowBandFor(box(0, 0, 40, 40)), 8.0);
      expect(hollowBandFor(box(0, 0, 200, 100)), 12.0);
    });
  });

  group('الدوران', () {
    test('نقطة داخل الصندوق بعد عكس الدوران تُصيب العنصر', () {
      // مستطيل أفقي مُدوَّر 90° ⇒ صار عمودياً حول مركزه (100،50).
      final ShapeElement rotated = ShapeElement(
        id: 'rotated',
        box: box(0, 0, 200, 100),
        kind: ShapeKind.rect,
        fillHex: '#FFFFFFFF',
        rotation: 90,
      );

      // نقطة داخل الشكل بعد الدوران: يغطّيه لأن الصدر اتّسع عمودياً.
      expect(
        pickElementAt(<TemplateElement>[rotated], point: at(100, 140))?.id,
        'rotated',
      );
      // نقطة داخل الصندوق الأصلي لكنها خارج الشكل المُدوَّر ⇒ ليست مرشّحاً،
      // فتمرّ النقرة إلى ما تحتها بدل أن يُخطئ عنصراً لا يظهر هناك أصلاً.
      expect(
        pickElementAt(<TemplateElement>[rotated], point: at(10, 10)),
        isNull,
      );
      expect(
        pickElementAt(<TemplateElement>[rotated], point: at(-40, -40)),
        isNull,
      );
    });

    test('العناصر غير المُدوَّرة لا تتأثر بعكس الدوران', () {
      final ShapeElement flat = solid('flat', box(10, 10, 100, 50));
      expect(
        pickElementAt(<TemplateElement>[flat], point: at(20, 20))?.id,
        'flat',
      );
      expect(
        pickElementAt(<TemplateElement>[flat], point: at(9, 9)),
        isNull,
      );
    });
  });
}
