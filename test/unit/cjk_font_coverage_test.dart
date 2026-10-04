import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_assets.dart';
import 'package:joodcraft/core/fonts/font_inspector.dart';

/// حرس تغطية الصينية: يمنع عودة مربعات فارغة (□□□) في واجهة الواجهة بالصينية.
///
/// الخلفية: فلاتر لا تحزم خطاً صينياً، والخط الأساسي (Cairo) لا يعرف محارف
/// CJK، فتظهر ترجمات `app_zh.arb` كلها مربعات على المنصات بلا خطوط نظام (الويب
/// تحديداً). الحل: خط محزوم داخل الحزمة + تمريره أولاً في `uiFontFallback`.
/// هذا الاختبار يثبت أن الملف المحزوم فعلاً يغطي الترجمة حرف بحرف.
const List<String> _locales = <String>[
  'ar',
  'en',
  'fr',
  'es',
  'tr',
  'ur',
  'de',
  'id',
  'ru',
  'zh',
];

/// نطاقات الكتابات شرق آسيا — محرف خارجها ليس من مسؤولية خط الصينية.
bool _isCjk(int code) =>
    (0x2E80 <= code && code <= 0x9FFF) ||
    (0x3000 <= code && code <= 0x30FF) ||
    (0xF900 <= code && code <= 0xFAFF) ||
    (0xFF00 <= code && code <= 0xFFEF);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FontInspection notoSc;
  late FontInspection cairo;

  /// قيم الترجمة فقط (بلا مفاتيح `@` الوصفية).
  Iterable<String> messages(String locale) {
    final Map<String, dynamic> arb = jsonDecode(
      File('lib/l10n/app_$locale.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    return arb.entries
        .where((MapEntry<String, dynamic> e) => !e.key.startsWith('@'))
        .map((MapEntry<String, dynamic> e) => e.value)
        .whereType<String>();
  }

  Iterable<int> codePointsOf(String locale) =>
      messages(locale).expand((String value) => value.runes);

  /// الحروف غير المغطاة بخط واحد — تُطبع للتشخيص عند الفشل.
  List<String> uncoveredBy(String locale, bool Function(int code) covered) {
    final List<String> out = <String>[];
    for (final int code in codePointsOf(locale)) {
      if (code < 0x80) continue; // ASCII يرسمه أي خط أساسي.
      if (code == 0x20 || code == 0x0A) continue;
      if (!covered(code)) out.add(String.fromCharCode(code));
    }
    return out;
  }

  setUpAll(() async {
    notoSc = FontInspector.inspect(
      (await rootBundle.load(AppAssets.notoScFontFile)).buffer.asUint8List(),
    );
    cairo = FontInspector.inspect(
      (await rootBundle.load(AppAssets.pdfCairoRegular)).buffer.asUint8List(),
    );
  });

  group('خط الصينية المحزوم', () {
    test('ملف صالح بمحيطات TrueType واسم عائلة صيني', () {
      expect(notoSc.isValid, isTrue, reason: notoSc.errorAr);
      expect(notoSc.hasTrueTypeOutlines, isTrue);
      expect(notoSc.familyName, AppAssets.notoScFont);
      expect(notoSc.covers(0x6587), isTrue, reason: 'محرف 文');
    });

    test('يبقى خفيفاً — تجديده بلا تكبير يعيد 17MB', () {
      final File file = File(AppAssets.notoScFontFile);
      expect(file.existsSync(), isTrue, reason: 'الخط غير محزوم');
      // الخط الكامل يبلغ ‎~17MB‎؛ أي تجديد نسي التصغير يظهر فوراً هنا.
      expect(
        file.lengthSync(),
        lessThan(4 * 1024 * 1024),
        reason: 'الملف ${file.lengthSync()} بايت — هل نُسي التصغير؟',
      );
    });

    test('يتصدّر قائمة احتياط الواجهة لأنه المضمون على كل منصة', () {
      expect(AppAssets.uiFontFallback.first, AppAssets.notoScFont);
      expect(AppAssets.uiFontFallback.first, 'Noto Sans SC');
    });

    test('pubspec يسجّل العائلة بمسارها الفعلي', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Noto Sans SC'));
      expect(pubspec, contains('asset: ${AppAssets.notoScFontFile}'));
      expect(File(AppAssets.notoScFontFile).existsSync(), isTrue);
    });
  });

  group('تغطية الترجمات', () {
    test('كل محرف في الترجمة الصينية يُرسم بلا مربعات', () {
      // Cairo يرسم العربي/اللاتيني، وخط الصينية يرسم CJK — معًا لا مربعات.
      final List<String> uncovered = uncoveredBy(
        'zh',
        (int code) => notoSc.covers(code) || cairo.covers(code),
      );
      expect(
        uncovered,
        isEmpty,
        reason: 'محارف بلا خط يرسمها: ${uncovered.join()}',
      );
    });

    test('كل محرف CJK في الترجمة الصينية يغطيه خط الصينية نفسه', () {
      // هذا هو جوهر الإصلاح: الحروف شرق آسيا من مسؤولية الخط المحزوم، لا من
      // صدفة وجود خط نظام على جهاز المستخدم.
      final List<String> uncovered = <String>[];
      for (final int code in codePointsOf('zh')) {
        if (!_isCjk(code)) continue;
        if (!notoSc.covers(code)) uncovered.add(String.fromCharCode(code));
      }
      expect(
        uncovered,
        isEmpty,
        reason: 'CJK يغيب عن الخط المحزوم: ${uncovered.join()}',
      );
    });

    test('ترجمات اللغات العشر كلها تُرسم بـ Cairo + خط الصينية معاً', () {
      // ضمان أعمّ: أي حرف في أي ترجمة له خط يرسمه — فلا مربعات في أي لغة.
      for (final String locale in _locales) {
        final List<String> uncovered = uncoveredBy(
          locale,
          (int code) => notoSc.covers(code) || cairo.covers(code),
        );
        expect(
          uncovered,
          isEmpty,
          reason: '$locale: محارف بلا خط يرسمها: ${uncovered.join()}',
        );
      }
    });

    test('الخط يغطي الفراغ الصيني الكامل U+3000', () {
      // GB2312 تبدأ به؛ سقوطه يعني نصاً صينياً مقطّعاً.
      expect(notoSc.covers(0x3000), isTrue);
    });
  });
}
