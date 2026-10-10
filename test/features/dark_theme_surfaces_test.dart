import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/theme/app_colors.dart';
import 'package:joodcraft/core/theme/app_theme.dart';
import 'package:joodcraft/features/auth/presentation/widgets/auth_scaffold.dart';

/// اختبارات توحيد الأسطح: **لا كحلي في المظهر الداكن**. هيكل المصادقة (الذي
/// يستخدم نفس أسطح الهوية المستعملة في اللوحة والدرج) يجب أن يصير فحمياً
/// محايداً ليلاً، مع بقاء الكحلي في النهار.
void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const AuthScaffold(
          title: 'تسجيل الدخول',
          subtitle: 'مرحباً بك',
          child: Text('نموذج'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// كل ألوان التدرّجات المستخدمة في الشجرة.
  List<Color> gradientColors(WidgetTester tester) {
    final List<Color> colors = <Color>[];
    for (final DecoratedBox box
        in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
      final Decoration decoration = box.decoration;
      if (decoration is BoxDecoration &&
          decoration.gradient is LinearGradient) {
        colors.addAll((decoration.gradient! as LinearGradient).colors);
      }
    }
    return colors;
  }

  testWidgets('المظهر الداكن: خلفية الهيكل فحمية لا كحلية',
      (WidgetTester tester) async {
    await pump(tester, AppTheme.dark);

    final Scaffold scaffold =
        tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.darkSurface);
    expect(scaffold.backgroundColor, isNot(AppColors.navy));

    final List<Color> gradients = gradientColors(tester);
    expect(gradients, contains(AppColors.darkSurface));
    expect(gradients, contains(AppColors.darkBackground));
    expect(gradients, isNot(contains(AppColors.navy)));
    expect(gradients, isNot(contains(AppColors.navyDeep)));
  });

  testWidgets('المظهر الفاتح: خلفية الهيكل كحلية (لا تراجع)',
      (WidgetTester tester) async {
    await pump(tester, AppTheme.light);

    final Scaffold scaffold =
        tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.navy);

    final List<Color> gradients = gradientColors(tester);
    expect(gradients, contains(AppColors.navy));
    expect(gradients, contains(AppColors.navyDeep));
  });
}
