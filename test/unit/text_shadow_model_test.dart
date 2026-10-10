import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/editor/template_editor_controller.dart';
import 'package:joodcraft/core/models/template_document.dart';
import 'package:joodcraft/core/models/template_element.dart';

/// اختبارات نموذج **ظل النص**: قيمه الافتراضية، شروط ظهوره، وحفظه واسترجاعه
/// من JSON — فلا يضيع بين اللوحة والقالب والطباعة.
void main() {
  group('نموذج ظل النص', () {
    test('القيم الافتراضية ظل خفيف مرئي', () {
      const TextShadow shadow = TextShadow();
      expect(shadow.colorHex, '#000000');
      expect(shadow.opacity, 0.5);
      expect(shadow.blurRadius, 4);
      expect(shadow.offsetX, 1.5);
      expect(shadow.offsetY, 1.5);
      expect(shadow.isVisible, isTrue);
    });

    test('ظل بلا تمويه ولا إزاحة (أو شفاف) لا يُرسم', () {
      expect(
        const TextShadow(blurRadius: 0, offsetX: 0, offsetY: 0).isVisible,
        isFalse,
      );
      expect(const TextShadow(opacity: 0).isVisible, isFalse);
      expect(const TextShadow(opacity: -1).isVisible, isFalse);
    });

    test('النسخ المعدّل يغيّر حقلاً واحداً ويحفظ الباقي', () {
      const TextShadow shadow = TextShadow();
      final TextShadow edited = shadow.copyWith(
        colorHex: '#C7A26B',
        blurRadius: 12,
      );
      expect(edited.colorHex, '#C7A26B');
      expect(edited.blurRadius, 12);
      expect(edited.opacity, shadow.opacity);
      expect(edited.offsetX, shadow.offsetX);
      expect(edited.offsetY, shadow.offsetY);
    });

    test('التسلسل يُسقط القيم الافتراضية ويعود بها عند القراءة', () {
      const TextShadow defaults = TextShadow();
      expect(defaults.toJson(), <String, dynamic>{'color': '#000000'});
      expect(TextShadow.fromJson(defaults.toJson()), defaults);

      const TextShadow custom = TextShadow(
        colorHex: '#1B2539',
        opacity: 0.8,
        blurRadius: 9,
        offsetX: -3,
        offsetY: 6,
      );
      expect(TextShadow.fromJson(custom.toJson()), custom);
    });

    test('القراءة تقبل نصوصاً رقمية وتُقيّد الشفافية', () {
      final TextShadow? shadow = TextShadow.fromJson(<String, dynamic>{
        'color': '#FFFFFF',
        'opacity': '2',
        'blur': '6',
        'x': '-2.5',
        'y': 'abc',
      });
      expect(shadow, isNotNull);
      expect(shadow!.opacity, 1);
      expect(shadow.blurRadius, 6);
      expect(shadow.offsetX, -2.5);
      expect(shadow.offsetY, 1.5);
      expect(TextShadow.fromJson(null), isNull);
      expect(TextShadow.fromJson('nonsense'), isNull);
    });
  });

  group('ظل النص في عنصر النص', () {
    const TextElement element = TextElement(
      id: 'text-1',
      box: ElementBox(x: 10, y: 20, width: 300, height: 60),
      text: 'مرحباً {{اسم_المتدرب}}',
      shadow: TextShadow(colorHex: '#123456', opacity: 0.7, blurRadius: 5),
    );

    test('يُحفظ في JSON ويُقرأ كما هو', () {
      final Map<String, dynamic> json = element.toJson();
      expect(json['shadow'], isA<Map<String, dynamic>>());

      final TemplateElement round = TemplateElement.fromJson(json, 0);
      expect(round, isA<TextElement>());
      final TextElement restored = round as TextElement;
      expect(restored.shadow, element.shadow);
      expect(restored.shadow!.colorHex, '#123456');
      expect(restored.shadow!.opacity, 0.7);
      expect(restored.shadow!.blurRadius, 5);
    });

    test('بلا ظل لا يُكتب مفتاح الظل في JSON', () {
      const TextElement plain = TextElement(
        id: 't',
        box: ElementBox(),
        text: 'نص',
      );
      expect(plain.toJson().containsKey('shadow'), isFalse);
      expect(TextElement.fromJson(plain.toJson(), 't').shadow, isNull);
    });

    test('يُقرأ من المفتاح القديم `textShadow` أيضاً', () {
      final TextElement parsed = TextElement.fromJson(<String, dynamic>{
        'text': 'نص',
        'w': 100,
        'h': 40,
        'textShadow': <String, dynamic>{'color': '#AABBCC', 'blur': 7},
      }, 't');
      expect(parsed.shadow, isNotNull);
      expect(parsed.shadow!.colorHex, '#AABBCC');
      expect(parsed.shadow!.blurRadius, 7);
    });

    test('copyWith يضيف الظل ويزيله', () {
      const TextElement plain =
          TextElement(id: 't', box: ElementBox(), text: 'نص');
      final TextElement added = plain.copyWith(shadow: const TextShadow());
      expect(added.shadow, isNotNull);
      expect(added.copyWith(shadow: null).shadow, isNull);
      // `copyWith` بلا معامل الظل يحتفظ بالقيمة الحالية.
      expect(added.copyWith(fontSize: 22).shadow, added.shadow);
    });
  });

  group('بقاء الظل عبر عمليات المحرّر', () {
    test('التكرار يُنسخ الظل مع العنصر', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: const TemplateDocument(
          elements: <TemplateElement>[
            TextElement(
              id: 'text-1',
              box: ElementBox(x: 100, y: 100, width: 300, height: 60),
              text: 'نص',
              shadow: TextShadow(colorHex: '#654321'),
            ),
          ],
        ),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.select('text-1');
      controller.duplicateSelected();

      final TextElement copy = controller.selected! as TextElement;
      expect(copy.shadow, isNotNull);
      expect(copy.shadow!.colorHex, '#654321');
    });

    test('التحديث الجماعي يُطبّق الظل على كل عناصر النص المحددة', () {
      final TemplateEditorController controller = TemplateEditorController(
        document: const TemplateDocument(
          elements: <TemplateElement>[
            TextElement(
              id: 'a',
              box: ElementBox(),
              text: 'نص أول',
            ),
            TextElement(
              id: 'b',
              box: ElementBox(),
              text: 'نص ثان',
            ),
          ],
        ),
        category: TemplateCategory.certificate,
      );
      addTearDown(controller.dispose);

      controller.select('a');
      controller.toggleSelection('b');
      controller.setSelectedTextShadow(const TextShadow(blurRadius: 8));

      for (final TemplateElement element in controller.document.elements) {
        expect((element as TextElement).shadow, isNotNull);
        expect(element.shadow!.blurRadius, 8);
      }

      controller.setSelectedTextShadow(null);
      for (final TemplateElement element in controller.document.elements) {
        expect((element as TextElement).shadow, isNull);
      }
    });
  });
}
