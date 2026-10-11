/// مُنسِّقات حقول الإدخال في صفحة القرية.
///
/// الأرقام العربية-الهندية (٠١٢…) مقبولة في الكتابة لأن كثيراً من أهالي القرية
/// يكتبون بها، والتحويل إلى أرقام لاتينية يحدث عند التحقق والحفظ — فلا يُرفض
/// إدخال صحيح بسبب شكل الأرقام.
library;

import 'package:flutter/services.dart';

/// يقبل الأرقام فقط (اللاتينية والعربية-الهندية والفارسية) بلا حروف أو رموز.
class VillageDigitsFormatter extends TextInputFormatter {
  const VillageDigitsFormatter();

  static final RegExp _allowed = RegExp(r'[0-9\u0660-\u0669\u06F0-\u06F9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final StringBuffer buffer = StringBuffer();
    for (final String ch in newValue.text.split('')) {
      if (_allowed.hasMatch(ch)) buffer.write(ch);
    }
    final String text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// يقبل حروف أكواد القرية بالأحرف اللاتينية أو الأرقام والشرطة، بأحرف كبيرة.
class VillageCodeFormatter extends TextInputFormatter {
  const VillageCodeFormatter();

  static final RegExp _allowed =
      RegExp(r'[A-Za-z0-9\u0660-\u0669\u06F0-\u06F9\-]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final StringBuffer buffer = StringBuffer();
    for (final String ch in newValue.text.split('')) {
      if (!_allowed.hasMatch(ch)) continue;
      buffer.write(ch.toUpperCase());
    }
    final String text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
