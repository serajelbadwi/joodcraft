@Tags(<String>['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/constants/app_constants.dart';
import 'package:joodcraft/core/constants/app_env.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// اختبارات تكامل **حيّة** ضد مشروع Supabase الفعلي.
///
/// التشغيل (تحتاج مفاتيح حقيقية واتصالاً بالإنترنت):
/// ```bash
/// flutter test test/integration --dart-define-from-file=env.json
/// ```
/// وبلا مفاتيح: يُتخطّى الاختبار بالكامل فلا يُعطّل `flutter test` العادي.
///
/// المجموعة الثالثة تحتاج حساب اختبار مُؤكَّد البريد وتُفعَّل فقط عند تمرير:
/// `--dart-define=TEST_USER_EMAIL=... --dart-define=TEST_USER_PASSWORD=...`
void main() {
  const String testEmail = String.fromEnvironment('TEST_USER_EMAIL');
  const String testPassword = String.fromEnvironment('TEST_USER_PASSWORD');
  final bool hasTestAccount = testEmail != '' && testPassword != '';

  const String skipReason = 'مفاتيح Supabase غير مضبوطة (--dart-define-from-file)';
  const String skipAccountReason = 'لا يوجد حساب اختبار مؤكد البريد';

  GoTrueClient buildAuth() => GoTrueClient(
        url: '${AppEnv.supabaseUrl}/auth/v1',
        headers: <String, String>{'apikey': AppEnv.supabaseAnonKey},
        autoRefreshToken: false,
      );

  PostgrestClient buildRest({String? accessToken}) => PostgrestClient(
        '${AppEnv.supabaseUrl}/rest/v1',
        headers: <String, String>{
          'apikey': AppEnv.supabaseAnonKey,
          'Authorization': 'Bearer ${accessToken ?? AppEnv.supabaseAnonKey}',
        },
      );

  // =========================================================================
  // 1) الاتصال وتحويل الأخطاء
  // =========================================================================
  group('Supabase — اتصال وتحويل أخطاء', () {
    test('المشروع متاح وخطأ الدخول يُترجم إلى رسالة عربية صحيحة', () async {
      final GoTrueClient auth = buildAuth();
      final String email =
          'no-such-user-${DateTime.now().millisecondsSinceEpoch}@joodcraft.test';

      Object? caught;
      try {
        await auth.signInWithPassword(email: email, password: 'Str0ng!Pass123');
      } catch (error) {
        caught = error;
      }

      expect(caught, isNotNull, reason: 'يجب أن يفشل الدخول بحساب غير موجود');
      expect(caught, isA<AuthException>());

      final AppException mapped = ErrorMapper.map(caught!);
      expect(mapped.code, AppErrorCode.invalidCredentials);
      expect(mapped.message, AppErrorCode.invalidCredentials.messageAr);
    });
  }, skip: AppEnv.isSupabaseConfigured ? false : skipReason);

  // =========================================================================
  // 2) لا وصول بدون جلسة
  // =========================================================================
  group('Supabase — منع الوصول المجهول', () {
    test('زائر بلا جلسة لا يرى أي بيانات من جداول المنصة', () async {
      final PostgrestClient rest = buildRest();

      for (final String table in <String>[
        AppConstants.templatesTable,
        AppConstants.profilesTable,
        AppConstants.userAssetsTable,
      ]) {
        Object? caught;
        dynamic rows;
        try {
          rows = await rest.from(table).select();
        } catch (error) {
          caught = error;
        }

        // إما رفض صريح (نقص صلاحيات/جدول غير موجود بعد التأسيس) وإمّا نتيجة فارغة.
        if (caught != null) {
          expect(caught, isA<PostgrestException>(), reason: 'خطأ غير متوقع في $table');
        } else {
          expect(rows, isEmpty, reason: 'لا يجوز أن يرى الزائر أي صف في $table');
        }
      }
    });
  }, skip: AppEnv.isSupabaseConfigured ? false : skipReason);

  // =========================================================================
  // 3) دورة حياة كاملة + عزل RLS (تحتاج حساب اختبار مؤكَّد)
  // =========================================================================
  group('Supabase — دورة حياة القوالب وعزل RLS', () {
    late GoTrueClient auth;

    setUp(() => auth = buildAuth());

    test('دخول → ملف شخصي → قالب خاص → رفض كتابة لمالك آخر → تنظيف', () async {
      final AuthResponse response = await auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );
      final User user = response.user!;
      final String token = response.session!.accessToken;
      final PostgrestClient rest = buildRest(accessToken: token);

      // (1) سجل profiles أُنشئ تلقائياً بالـ trigger و RLS تسمح لمالكه بقراءته.
      final dynamic profiles =
          await rest.from(AppConstants.profilesTable).select().eq('id', user.id);
      expect((profiles as List<dynamic>).length, 1);

      // (2) كتابة قالب خاص بالمستخدم.
      final dynamic inserted = await rest
          .from(AppConstants.templatesTable)
          .insert(<String, dynamic>{
            'user_id': user.id,
            'title': 'قالب اختبار آلي',
            'category': 'certificate',
            'orientation': 'landscape',
            'layout_data': <String, dynamic>{
              'schema_version': 1,
              'elements': <dynamic>[],
            },
          })
          .select();

      final Map<String, dynamic> row =
          (inserted as List<dynamic>).first as Map<String, dynamic>;
      expect(row['title'], 'قالب اختبار آلي');
      expect(
        (row['layout_data'] as Map<String, dynamic>)['schema_version'],
        1,
        reason: 'الـ JSON يعود كما حُفظ، وإصدار المخطط إلزامي داخل layout_data',
      );

      // (3) RLS تمنع كتابة صف باسم مستخدم آخر (with check).
      Object? denied;
      try {
        await rest.from(AppConstants.templatesTable).insert(<String, dynamic>{
          'user_id': '00000000-0000-0000-0000-000000000000',
          'title': 'محاولة تجاوز',
          'category': 'certificate',
          'orientation': 'landscape',
        });
      } catch (error) {
        denied = error;
      }
      expect(denied, isNotNull, reason: 'يجب أن تُرفض كتابة قالب باسم مستخدم آخر');

      // (4) تنظيف أثر الاختبار.
      await rest
          .from(AppConstants.templatesTable)
          .delete()
          .eq('id', row['id'] as String);

      // (5) بعد الخروج: القالب لم يعد مرئياً لأي طرف مجهول.
      await auth.signOut();
      final PostgrestClient anonymous = buildRest();
      Object? anonymousCaught;
      dynamic anonymousRows;
      try {
        anonymousRows = await anonymous
            .from(AppConstants.templatesTable)
            .select()
            .eq('id', row['id'] as String);
      } catch (error) {
        anonymousCaught = error;
      }
      if (anonymousCaught == null) {
        expect(anonymousRows, isEmpty);
      }
    });
  }, skip: (AppEnv.isSupabaseConfigured && hasTestAccount)
      ? false
      : (AppEnv.isSupabaseConfigured ? skipAccountReason : skipReason));
}
