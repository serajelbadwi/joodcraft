/// أدوات إدراج وقياس مشتركة لألسنة الشريط: إدراج عند المؤشّر، وإحصاءات
/// المستند (كلمات/حروف/وقت قراءة) — كلّها بلا تدخّل في نموذج الكتل.
library;

import 'package:flutter/widgets.dart';

import '../../writer_document_controller.dart';

abstract final class WriterRibbonInsert {
  /// يُدرج [text] عند موضع المؤشّر في الكتلة النشطة (أو في نهايتها إن غاب
  /// التحديد) — يمرّ عبر محرّر الحقل فيسري عليه كل مسار الكتابة الآلي.
  static void atCaret(WriterDocumentController controller, String text) {
    final int index = controller.activeBlockIndex;
    if (index < 0 || index >= controller.controllers.length) return;
    final TextEditingController tec = controller.controllers[index];
    final TextEditingValue value = tec.value;
    final TextSelection selection = value.selection;
    final int at =
        selection.isValid && selection.baseOffset >= 0 && selection.baseOffset <= value.text.length
            ? selection.baseOffset
            : value.text.length;
    tec.value = TextEditingValue(
      text: value.text.replaceRange(at, at, text),
      selection: TextSelection.collapsed(offset: at + text.length),
    );
  }

  /// تاريخ اليوم بالعربية (مثل «١٢ أكتوبر ٢٠٢٦») — مبني يدوياً بلا بيانات
  /// locale فيتعلّق باختبارات الودجات (بلا مندوبي ترجمة) أو ترميز intl.
  static String today() {
    const List<String> months = <String>[
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final DateTime now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  /// وقت الآن بصيغة ١٢ ساعة مع ص/م (مثل «٠٣:٤٥ م»).
  static String nowTime() {
    final DateTime now = DateTime.now();
    final int hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    String two(int n) => n < 10 ? '0$n' : '$n';
    return '${two(hour12)}:${two(now.minute)} ${now.hour < 12 ? 'ص' : 'م'}';
  }

  /// تاريخ ووقت مختصرَان للإدراج معاً.
  static String dateTime() =>
      '${today()} — ${nowTime()}';
}

/// إحصاءات المستند: كلمات، أحرف، أسطر، تقدير وقت القراءة.
class WriterDocumentStats {
  const WriterDocumentStats({
    required this.words,
    required this.characters,
    required this.charactersNoSpaces,
    required this.lines,
    required this.paragraphs,
  });

  final int words;
  final int characters;
  final int charactersNoSpaces;
  final int lines;
  final int paragraphs;

  /// دقائق القراءة — ٢٠٠ كلمة في الدقيقة كمتوسط القراءة العربية.
  int get readingMinutes => (words / 200).ceil();

  static WriterDocumentStats of(List<String> texts) {
    int words = 0;
    int chars = 0;
    int noSpaces = 0;
    int lines = 0;
    for (final String text in texts) {
      chars += text.length;
      noSpaces += text.replaceAll(RegExp(r'\s'), '').length;
      final String trimmed = text.trim();
      if (trimmed.isEmpty) continue;
      lines += 1 + '\n'.allMatches(text).length;
      words += trimmed.split(RegExp(r'\s+')).length;
    }
    return WriterDocumentStats(
      words: words,
      characters: chars,
      charactersNoSpaces: noSpaces,
      lines: lines,
      paragraphs: texts.length,
    );
  }
}

/// كشف تكرار الكلمات المتتالية (أداة تدقيق بسيطة بلا قاموس):
/// تُعيد الكلمات المكرّرة مرّتين فأكثر خلال المستند مع مواضعها.
class WriterRepeatedWords {
  const WriterRepeatedWords(this.word, this.count);

  final String word;
  final int count;

  static List<WriterRepeatedWords> find(List<String> texts, {int minCount = 2}) {
    final Map<String, int> counts = <String, int>{};
    for (final String text in texts) {
      final List<String> parts =
          text.trim().split(RegExp(r'\s+')).where((String w) => w.length > 2).toList();
      for (int i = 1; i < parts.length; i++) {
        if (parts[i] == parts[i - 1]) {
          counts[parts[i]] = (counts[parts[i]] ?? 0) + 1;
        }
      }
    }
    final List<WriterRepeatedWords> result = counts.entries
        .where((MapEntry<String, int> e) => e.value + 1 >= minCount)
        .map((MapEntry<String, int> e) => WriterRepeatedWords(e.key, e.value + 1))
        .toList()
      ..sort((WriterRepeatedWords a, WriterRepeatedWords b) => b.count.compareTo(a.count));
    return result;
  }
}
