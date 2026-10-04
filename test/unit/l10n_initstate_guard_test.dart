import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// اختبار حرس (static analysis) يمنع تكرار انحدار حقيقي:
///
/// قراءة `context.l10n` — أو أي بحث عن عنصر موروث (`Localizations.of`،
/// `AppL10n.of`، `dependOnInheritedWidgetOfExactType`) — داخل `initState()`
/// ترمي استثناءً وقت التشغيل:
///
/// ```
/// dependOnInheritedWidgetOfExactType<_LocalizationsScope>() ... was called
/// before _XxxState.initState() completed.
/// ```
///
/// ولأن الاختبارات لا تلتقط هذا دائمًا (يظهر عند فتح الشاشة فعلاً)، نفحص الشيفرة
/// نصيًّا هنا. القاعدة: اقرأ الترجمة في `build` أو `didChangeDependencies`، لا
/// في `initState`.
void main() {
  test('الكاشف يرفض قراءة الترجمة داخل initState', () {
    const String violating = '''
class _FooState extends State<Foo> {
  @override
  void initState() {
    super.initState();
    _title = context.l10n?.fooTitle ?? 'افتراضي';
  }
}
''';
    expect(initStateL10nViolations(violating), isNotEmpty);
  });

  test('الكاشف يرفض Localizations.of و AppL10n.of داخل initState', () {
    const String localized = '''
class _A extends State<A> {
  @override
  void initState() {
    super.initState();
    _l = Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
}
''';
    const String app = '''
class _B extends State<B> {
  @override
  void initState() {
    super.initState();
    _l = AppL10n.of(context);
  }
}
''';
    expect(initStateL10nViolations(localized), isNotEmpty);
    expect(initStateL10nViolations(app), isNotEmpty);
  });

  test('الكاشف يقبل القراءة خارج initState (build / didChangeDependencies)', () {
    const String clean = '''
class _FooState extends State<Foo> {
  @override
  void initState() {
    super.initState();
    _title = 'قالب جديد';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _title = context.l10n?.fooTitle ?? _title;
  }

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n?.fooTitle ?? '—');
  }
}
''';
    expect(initStateL10nViolations(clean), isEmpty);
  });

  test('لا قراءة للترجمة داخل initState في أي ملف من lib', () {
    final Directory lib = Directory('lib');
    expect(lib.existsSync(), isTrue, reason: 'مجلد lib غير موجود');

    final List<String> violations = <String>[];
    for (final FileSystemEntity entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String source = entity.readAsStringSync();
      for (final int line in initStateL10nViolations(source)) {
        violations.add('${entity.path}:$line');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'قراءة context.l10n داخل initState ممنوعة — استخدم '
          'didChangeDependencies أو build بدلاً منها. المواضع المخالفة:\n'
          '${violations.join('\n')}',
    );
  });
}

/// الأنماط الممنوعة داخل جسم `initState`.
final RegExp _forbidden = RegExp(
  r'\bl10n\b'
  r'|Localizations\s*\.\s*of'
  r'|AppL10n\s*\.\s*of'
  r'|dependOnInheritedWidgetOfExactType',
);

/// مطابقة ترويسة `initState(...) {` (لا تطابق النداء `super.initState();`).
final RegExp _initStateHeader =
    RegExp(r'\binitState\s*\([^)]*\)\s*(?:async\s*)?\{');

/// يعيد أرقام الأسطر (1-based) التي تقرأ الترجمة/عنصرًا موروثًا داخل `initState`.
///
/// يُنظّف المصدر أولاً من التعليقات والنصوص حفاظًا على أرقام الأسطر، ثم يُحدَّد
/// جسم كل `initState` بمطابقة الأقواس.
List<int> initStateL10nViolations(String source) {
  final String stripped = _stripCommentsAndStrings(source);
  final List<int> lines = <int>[];
  for (final RegExpMatch match in _initStateHeader.allMatches(stripped)) {
    final int open = match.end - 1; // موضع `{`.
    final int close = _matchingBrace(stripped, open);
    if (close < 0) continue;
    final String body = stripped.substring(open + 1, close);
    for (final RegExpMatch hit in _forbidden.allMatches(body)) {
      lines.add(_lineOf(stripped, open + 1 + hit.start));
    }
  }
  return lines;
}

/// يستبدل محتوى التعليقات والنصوص بمسافات (ويُبقي الأسطر كما هي).
String _stripCommentsAndStrings(String source) {
  final StringBuffer out = StringBuffer();
  final int n = source.length;
  int i = 0;
  while (i < n) {
    final String c = source[i];
    final String? next = i + 1 < n ? source[i + 1] : null;

    if (c == '/' && next == '/') {
      while (i < n && source[i] != '\n') {
        out.write(' ');
        i++;
      }
      continue;
    }
    if (c == '/' && next == '*') {
      out.write('  ');
      i += 2;
      while (i < n &&
          !(source[i] == '*' && i + 1 < n && source[i + 1] == '/')) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      if (i < n) {
        out.write('  ');
        i += 2;
      }
      continue;
    }
    if (c == "'" || c == '"') {
      final bool triple =
          next == c && i + 2 < n && source[i + 2] == c;
      if (triple) {
        out.write('   ');
        i += 3;
        while (i < n &&
            !(source[i] == c &&
                i + 1 < n &&
                source[i + 1] == c &&
                i + 2 < n &&
                source[i + 2] == c)) {
          if (source[i] == '\\' && i + 1 < n) {
            out.write(' ');
            i++;
          }
          out.write(source[i] == '\n' ? '\n' : ' ');
          i++;
        }
        if (i < n) {
          out.write('   ');
          i += 3;
        }
      } else {
        out.write(' ');
        i++;
        while (i < n && source[i] != c && source[i] != '\n') {
          if (source[i] == '\\' && i + 1 < n) {
            out.write(' ');
            i++;
          }
          out.write(' ');
          i++;
        }
        if (i < n && source[i] == c) {
          out.write(' ');
          i++;
        }
      }
      continue;
    }
    out.write(c);
    i++;
  }
  return out.toString();
}

/// موضع قوس الإغلاق المطابق لـ [open]، أو `-1` إن لم يوجد.
int _matchingBrace(String text, int open) {
  int depth = 0;
  for (int i = open; i < text.length; i++) {
    final String c = text[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// رقم السطر (1-based) للموضع [index].
int _lineOf(String text, int index) {
  int line = 1;
  for (int i = 0; i < index && i < text.length; i++) {
    if (text[i] == '\n') line++;
  }
  return line;
}
