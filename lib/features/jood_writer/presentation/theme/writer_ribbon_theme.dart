/// هوية شريط Ribbon في «جود كاتب» — ألوان وأنماط ثابتة **مستقلّة عن الثيم
/// العام** كي يبقى الشريط بمظهر احترافي موحّد (كـWord) في الوضعين الفاتح
/// والداكن: شريط رمادي داكن، تبويب نشط ذهبي، وحدود رمادية.
library;

import 'package:flutter/material.dart';

abstract final class WriterRibbonTheme {
  // ----------------------------- الألوان الأساسية -----------------------------
  /// خلفية الشريط (رمادي داكن).
  static const Color bar = Color(0xFF1A1A1A);

  /// التبويب النشط (ذهبي) — نصّه كحلي كما في الهوية.
  static const Color tabActive = Color(0xFFB8932E);
  static const Color tabActiveText = Color(0xFF1A1A1A);

  /// التبويب غير النشط.
  static const Color tabInactive = Color(0xFF2A2A2A);
  static const Color tabInactiveText = Colors.white;

  /// مرور المؤشّر فوق التبويب أو الأداة.
  static const Color hover = Color(0xFF2E2E2E);

  /// حدود الأقسام والتبويبات.
  static const Color border = Color(0xFF3A3A3A);

  /// نصوص الأدوات على الداكن.
  static const Color text = Colors.white;
  static const Color textMuted = Color(0xFFB7B7B7);
  static const Color textDisabled = Color(0xFF6B6B6B);

  /// تعبئة الأداة المُفعَّلة (تمييز ذهبي شفّاف).
  static const Color activeFill = Color(0x33B8932E);
  static const Color activeBorder = tabActive;

  /// لون نصّ الأدوات داخل قوائم الاختيار الداكنة.
  static const Color menuText = Color(0xFFEDEDED);
  static const Color menuSurface = Color(0xFF242424);

  // ----------------------------- المقاسات -----------------------------
  /// ارتفاع صف التبويبات.
  static const double tabsRowHeight = 34;

  /// الارتفاع الكلي للشريط (تبويبات + محتوى) — ضمن نطاق 90-120px.
  static const double contentHeight = 84;
  static const double totalHeight = tabsRowHeight + contentHeight;

  /// حجم أيقونة الأداة الصغيرة/الكبيرة.
  static const double smallIcon = 18;
  static const double largeIcon = 22;

  /// أنماط النصوص.
  static TextStyle tabLabel({required bool active}) => TextStyle(
    fontSize: 13.5,
    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
    color: active ? tabActiveText : tabInactiveText,
    height: 1,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 10.5,
    color: textMuted,
    height: 1,
  );

  static const TextStyle toolLabel = TextStyle(
    fontSize: 11,
    color: text,
    height: 1.1,
  );

  /// قائمة ألوان موحّدة لأدوات الشريط (منتقي اللون).
  static const List<Color> swatches = <Color>[
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFD32F2F),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF1976D2),
    Color(0xFF0288D1),
    Color(0xFF0097A7),
    Color(0xFF009688),
    Color(0xFF388E3C),
    Color(0xFF7CB342),
    Color(0xFFCDDC39),
    Color(0xFFFFC107),
    Color(0xFFFFA000),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFB8932E),
    Color(0xFF9E7B45),
  ];
}
