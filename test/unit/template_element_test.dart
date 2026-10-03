import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/models/template_element.dart';
import 'package:joodcraft/core/pdf/pdf_font_catalog.dart';

void main() {
  group('صندوق العنصر', () {
    test('النسخ والترجمة يحفظان القيم غير المذكورة', () {
      const ElementBox box = ElementBox(x: 10, y: 20, width: 30, height: 40);
      final ElementBox moved = box.translated(dx: 5, dy: -5);

      expect(moved.x, 15);
      expect(moved.y, 15);
      expect(moved.width, 30);
      expect(moved.height, 40);
      expect(box.translated().x, 10);
    });

    test('القراءة تقبل `w`/`h` و`width`/`height` والنصوص الرقمية', () {
      final ElementBox a = ElementBox.fromJson(<String, dynamic>{
        'x': 1,
        'y': 2,
        'w': 3,
        'h': 4,
      });
      expect(<double>[a.x, a.y, a.width, a.height], <double>[1, 2, 3, 4]);

      final ElementBox b = ElementBox.fromJson(<String, dynamic>{
        'x': '5',
        'y': '6',
        'width': 7,
        'height': 8,
      });
      expect(<double>[b.x, b.y, b.width, b.height], <double>[5, 6, 7, 8]);
    });

    test('الكتابة تُسقط الأبعاد الصفرية (تعني «تلقائي»)', () {
      expect(const ElementBox(x: 1, y: 2).toJson().containsKey('w'), isFalse);
      expect(
        const ElementBox(x: 1, y: 2, width: 5).toJson()['w'],
        5,
      );
    });
  });

  group('الدوران', () {
    test('يُقرأ من `rotation` أو `rotate`', () {
      expect(TemplateElement.readRotation(<String, dynamic>{'rotation': 45}), 45);
      expect(TemplateElement.readRotation(<String, dynamic>{'rotate': '-30'}), -30);
      expect(TemplateElement.readRotation(<String, dynamic>{}), 0);
    });

    for (final MapEntry<String, Map<String, dynamic>> sample
        in _samples.entries) {
      test('عنصر «${sample.key}» يحفظ الدوران ويعيده', () {
        final Map<String, dynamic> json = <String, dynamic>{
          ...sample.value,
          'rotation': 33.5,
        };
        final TemplateElement element = TemplateElement.fromJson(json, 0);

        expect(element.rotation, closeTo(33.5, 0.0001));
        expect(element.hasRotation, isTrue);
        expect(element.withRotation(33.5).rotation, closeTo(33.5, 0.0001));

        final Map<String, dynamic> round = element.toJson();
        expect(round['rotation'], closeTo(33.5, 0.0001));
      });

      test('عنصر «${sample.key}» بلا دوران لا يُكتب في JSON', () {
        final TemplateElement element =
            TemplateElement.fromJson(sample.value, 0);
        expect(element.rotation, 0);
        expect(element.hasRotation, isFalse);
        expect(element.toJson().containsKey('rotation'), isFalse);
      });
    }
  });

  group('withBox / moved / resized', () {
    test('withBox يستبدل الصندوق ويحفظ بقية الخصائص', () {
      const TextElement text = TextElement(
        id: 't1',
        box: ElementBox(x: 1, y: 2, width: 3, height: 4),
        text: 'نص',
        fontSize: 22,
        colorHex: '#123456',
      );

      final TextElement moved = text.withBox(
        const ElementBox(x: 50, y: 60, width: 70, height: 80),
      );

      expect(moved.box.x, 50);
      expect(moved.text, 'نص');
      expect(moved.fontSize, 22);
      expect(moved.colorHex, '#123456');
    });

    test('moved وresized يعملان على كل الأنواع بلا استثناء', () {
      for (final Map<String, dynamic> sample in _samples.values) {
        final TemplateElement element = TemplateElement.fromJson(sample, 0);

        final TemplateElement moved = element.moved(dx: 10, dy: 20);
        expect(moved.box.x, closeTo(element.box.x + 10, 0.0001));
        expect(moved.box.y, closeTo(element.box.y + 20, 0.0001));

        final TemplateElement resized =
            element.resized(width: 111, height: 222);
        expect(resized.box.width, 111);
        expect(resized.box.height, 222);
        expect(resized.box.x, closeTo(element.box.x, 0.0001));
      }
    });
  });

  group('copyWith', () {
    test('يمكن مسح خلفية النص صراحةً بـ null', () {
      const TextElement text = TextElement(
        id: 't1',
        box: ElementBox(),
        text: 'x',
        backgroundHex: '#FFFFFF',
      );

      expect(text.copyWith(backgroundHex: null).backgroundHex, isNull);
      // عدم تمرير المعامل يُبقي القيمة كما هي.
      expect(text.copyWith(text: 'y').backgroundHex, '#FFFFFF');
    });

    test('يمكن مسح تعبئة الشكل صراحةً بـ null', () {
      const ShapeElement shape = ShapeElement(
        id: 's1',
        box: ElementBox(),
        kind: ShapeKind.rect,
        fillHex: '#000000',
      );

      expect(shape.copyWith(fillHex: null).fillHex, isNull);
      expect(shape.copyWith(radius: 5).fillHex, '#000000');
    });

    test('تعديل النمط لا يمسّ النص', () {
      const TextElement text = TextElement(
        id: 't1',
        box: ElementBox(),
        text: 'العنوان',
      );
      final TextElement styled = text.copyWith(
        family: PdfFontFamily.amiri,
        weight: PdfFontWeight.bold,
        letterSpacing: 2,
      );

      expect(styled.text, 'العنوان');
      expect(styled.family, PdfFontFamily.amiri);
      expect(styled.weight, PdfFontWeight.bold);
      expect(styled.letterSpacing, 2);
    });
  });

  group('التوافق الأمامي', () {
    test('نوع غير معروف يُحفظ كما هو ويُدرج كـ UnknownElement', () {
      final TemplateElement element = TemplateElement.fromJson(
        <String, dynamic>{
          'id': 'future-1',
          'type': 'watermark',
          'x': 1,
          'y': 2,
          'rotation': 10,
          'alphaMode': 'multiply',
        },
        0,
      );

      expect(element, isA<UnknownElement>());
      final UnknownElement unknown = element as UnknownElement;
      expect(unknown.typeName, 'watermark');
      expect(unknown.rotation, 10);
      expect(unknown.toJson()['alphaMode'], 'multiply');
    });

    test('معرّف مفقود يُولَّد من الترتيب', () {
      final TemplateElement element = TemplateElement.fromJson(
        <String, dynamic>{'type': 'text', 'text': 'x'},
        3,
      );
      expect(element.id, 'element_3');
    });
  });

  group('طريقة الضبط (JustifyMode)', () {
    test('الافتراضي هو الفراغات ولا يُكتب في JSON', () {
      const TextElement text = TextElement(
        id: 't1',
        box: ElementBox(x: 0, y: 0, width: 10, height: 10),
        text: 'نص',
        align: ElementTextAlign.justify,
      );
      expect(text.justifyMode, JustifyMode.spaces);
      expect(text.toJson().containsKey('justifyMode'), isFalse);
    });

    test('الكشيدة تُكتب في JSON وتُقرأ منه', () {
      const TextElement text = TextElement(
        id: 't1',
        box: ElementBox(x: 0, y: 0, width: 10, height: 10),
        text: 'نص',
        align: ElementTextAlign.justify,
        justifyMode: JustifyMode.kashida,
      );
      final Map<String, dynamic> json = text.toJson();
      expect(json['justifyMode'], 'kashida');

      final TemplateElement round = TemplateElement.fromJson(json, 0);
      expect(round, isA<TextElement>());
      expect((round as TextElement).justifyMode, JustifyMode.kashida);
    });

    test('copyWith يبدّل الطريقة دون المساس ببقية الخصائص', () {
      const TextElement text = TextElement(
        id: 't1',
        box: ElementBox(x: 1, y: 2, width: 3, height: 4),
        text: 'نص',
        align: ElementTextAlign.justify,
      );
      final TextElement changed =
          text.copyWith(justifyMode: JustifyMode.kashida);
      expect(changed.justifyMode, JustifyMode.kashida);
      expect(changed.align, ElementTextAlign.justify);
      expect(changed.text, 'نص');

      // القيم غير المعروفة ترجع للافتراضي (فراغات).
      expect(JustifyMode.fromJson('???'), JustifyMode.spaces);
      expect(JustifyMode.fromJson('tatweel'), JustifyMode.kashida);
    });
  });
}

/// عيّنات لكل نوع مدعوم.
const Map<String, Map<String, dynamic>> _samples = <String, Map<String, dynamic>>{
  'text': <String, dynamic>{
    'id': 't',
    'type': 'text',
    'x': 10,
    'y': 10,
    'w': 100,
    'h': 20,
    'text': 'نص',
  },
  'rect': <String, dynamic>{
    'id': 'r',
    'type': 'rect',
    'x': 0,
    'y': 0,
    'w': 50,
    'h': 50,
  },
  'ellipse': <String, dynamic>{
    'id': 'e',
    'type': 'ellipse',
    'x': 0,
    'y': 0,
    'w': 50,
    'h': 50,
  },
  'line': <String, dynamic>{
    'id': 'l',
    'type': 'line',
    'x': 0,
    'y': 5,
    'w': 80,
    'h': 1,
  },
  'seal': <String, dynamic>{
    'id': 's',
    'type': 'seal',
    'x': 5,
    'y': 5,
    'w': 60,
    'h': 60,
  },
  'image': <String, dynamic>{
    'id': 'i',
    'type': 'image',
    'x': 5,
    'y': 5,
    'w': 60,
    'h': 40,
    'path': 'assets/images/logo.png',
  },
  'qr': <String, dynamic>{
    'id': 'q',
    'type': 'qr',
    'x': 5,
    'y': 5,
    'w': 40,
    'h': 40,
    'data': 'https://joodcraft.app',
  },
};
