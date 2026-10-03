import 'package:flutter/material.dart';

/// تحويل لون HEX نصي (كما في قوالب JSON) إلى [Color] الخاص بفلاتر.
///
/// الصيغ المقبولة: `#RRGGBB` و`RRGGBB` و`#AARRGGBB` و`#RGB`.
Color colorFromHex(String? hex, {Color fallback = const Color(0xFF000000)}) {
  if (hex == null) return fallback;
  String value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 3) {
    // #RGB → #RRGGBB
    value = value.split('').map((String c) => '$c$c').join();
  }
  if (value.length == 8 || value.length == 6) {
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return fallback;
    return Color(value.length == 6 ? parsed | 0xFF000000 : parsed);
  }
  return fallback;
}

/// تحويل لون إلى صيغة `#RRGGBB` (بلا قناة الشفافية — الشفافية تُدار بحقل مستقل).
String hexFromColor(Color color) {
  final int argb = color.toARGB32();
  final String rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '#${rgb.toUpperCase()}';
}
