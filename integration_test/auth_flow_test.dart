import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:joodcraft/app/app.dart';
import 'package:joodcraft/core/constants/app_env.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/services/supabase_service.dart';
import 'package:joodcraft/features/auth/data/supabase_auth_repository.dart';

/// اختبار طرف-إلى-طرف يشغّل التطبيق الحقيقي على جهاز حقيقي (Windows/Chrome)
/// ويتصل بمشروع Supabase الفعلي — أي أنه يغطي الوصلة الوحيدة التي لا تغطيها
/// الاختبارات الوحدوية: الواجهة ← المزوّد ← المستودع الحقيقي ← الشبكة.
///
/// التشغيل:
/// ```bash
/// flutter test integration_test/auth_flow_test.dart -d windows
/// ```
/// المفاتيح تُقرأ تلقائياً من `env.json` (لا حاجة لأي علامة تشغيل)،
/// ويتفوق `--dart-define-from-file=env.json` عليها إن مرّرتها.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('دخول حقيقي ببيانات غير صحيحة يعرض الرسالة العربية',
      (WidgetTester tester) async {
    // تجلب المفاتيح من env.json (القرص/الحزمة) قبل التحقق منها.
    await AppEnv.load();

    expect(
      AppEnv.isSupabaseConfigured,
      isTrue,
      reason: 'أنشئ env.json في جذر المشروع (من env.example.json) واملأه',
    );

    expect(await SupabaseService.initialize(), isTrue);

    await tester.pumpWidget(
      JoodCraftApp(
        authRepository: SupabaseAuthRepository(SupabaseService.client),
      ),
    );
    await tester.pumpAndSettle();

    // التطبيق يوجّه غير المسجّل إلى شاشة الدخول.
    expect(find.text('دخول إلى اللوحة'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'no-such-user-e2e-${DateTime.now().millisecondsSinceEpoch}@joodcraft.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Str0ng!Pass123');

    await tester.ensureVisible(find.text('دخول إلى اللوحة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دخول إلى اللوحة'));

    // انتظار حقيقي لاستجابة الشبكة (pumpAndSettle وحدها لا تنتظر HTTP).
    final String expected = AppErrorCode.invalidCredentials.messageAr;
    bool appeared = false;
    for (int i = 0; i < 40 && !appeared; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      appeared = find.text(expected).evaluate().isNotEmpty;
    }

    expect(
      appeared,
      isTrue,
      reason: 'كان المتوقع ظهور رسالة "$expected" بعد فشل الدخول',
    );
    // لا يجب أن يكتمل الدخول.
    expect(find.text('دخول إلى اللوحة'), findsOneWidget);
  });
}
