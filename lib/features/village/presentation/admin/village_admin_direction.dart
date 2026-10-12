/// تثبيت اتجاه الكتابة (RTL) على شاشات لوحة تحكم القرى.
///
/// **لماذا هذا اللازم؟** كل نصوص هذه اللوحة عربية ثابتة (`VillageAdminText`
/// و`VillageText`) بلا أي ترجمة، بينما يغلّف تطبيق JoodCraft الشجرة كلّها
/// بـ`Directionality` يتبع **لغة التطبيق المختارة** (`app.dart` ←
/// `_directionBuilder`). فمتى اختار المستخدم لغة إنجليزية لُفّت نصوص عربية
/// بمحاذاة LTR: العناوين والأزرار والجداول تُقرأ من اليسار والهوامش
/// تتقلّب جهة.
///
/// هذا المُغلِّف يجعل الاتجاه خاصيةً **للمحتوى لا بلغة المضيف** — تماماً
/// كما تفعل صفحة القرية العامة (`VillageApp` تفرض `locale: Locale('ar')`).
///
/// الاستعمال: تُغلَّف به النتيجة الأولى من `build` في كل شاشة، وبشاشات
/// النوافذ (`showDialog`) لأنها تُبنى فوق شجرة الـNavigator الجذرية فلا
/// ترث هذا الاتجاه من الشاشة التي فتحتها.
library;

import 'package:flutter/material.dart';

class VillageAdminDirection extends StatelessWidget {
  const VillageAdminDirection({super.key, required this.child});

  /// محتوى الشاشة أو النافذة.
  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: child,
  );
}
