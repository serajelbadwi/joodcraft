import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/core/errors/app_error_code.dart';
import 'package:joodcraft/core/errors/app_exception.dart';
import 'package:joodcraft/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ErrorMapper — أخطاء المصادقة', () {
    test('يقرأ رمز SDK الرسمي', () {
      final AppException mapped = ErrorMapper.map(
        const AuthApiException('Invalid login credentials', code: 'invalid_credentials'),
      );
      expect(mapped.code, AppErrorCode.invalidCredentials);
      expect(mapped.message, 'البريد الإلكتروني أو كلمة المرور غير صحيحة.');
    });

    test('يعتمد الاحتياط النصي عندما يكون رمز SDK فارغاً', () {
      // هذا ما يحدث فعلياً مع بوابة Supabase الحالية: الحقل `code` رقم HTTP
      // لا نص، فيُرجع SDK قيمة null ويبقى الاعتماد على نص الرسالة.
      final AppException mapped = ErrorMapper.map(
        const AuthApiException(
          'Invalid login credentials',
          statusCode: '400',
        ),
      );
      expect(mapped.code, AppErrorCode.invalidCredentials);
    });

    test('يترجم رسائل التسجيل الشائعة', () {
      expect(
        ErrorMapper.map(const AuthApiException('User already registered')).code,
        AppErrorCode.emailAlreadyInUse,
      );
      expect(
        ErrorMapper.map(const AuthApiException('Email not confirmed')).code,
        AppErrorCode.emailNotConfirmed,
      );
      expect(
        ErrorMapper.map(
          const AuthApiException('Password should be at least 6 characters'),
        ).code,
        AppErrorCode.weakPassword,
      );
      expect(
        ErrorMapper.map(
          const AuthApiException(
            'New password should be different from the old password',
          ),
        ).code,
        AppErrorCode.samePassword,
      );
      expect(
        ErrorMapper.map(
          const AuthApiException(
            'For security purposes, you can only request this after 41 seconds',
          ),
        ).code,
        AppErrorCode.rateLimited,
      );
      expect(
        ErrorMapper.map(const AuthApiException('User not found')).code,
        AppErrorCode.userNotFound,
      );
    });

    test('فشل الشبكة يُترجم إلى network', () {
      final AppException mapped = ErrorMapper.map(
        AuthRetryableFetchException(message: 'SocketException: failed'),
      );
      expect(mapped.code, AppErrorCode.network);
    });

    test('خطأ 5xx من الخادم يُترجم إلى server', () {
      final AppException mapped = ErrorMapper.map(
        const AuthApiException('Internal error', statusCode: '500'),
      );
      expect(mapped.code, AppErrorCode.server);
    });

    test('الرسالة المجهولة تُترجم إلى unknown', () {
      final AppException mapped =
          ErrorMapper.map(const AuthApiException('Something odd'));
      expect(mapped.code, AppErrorCode.unknown);
      expect(mapped.message, AppErrorCode.unknown.messageAr);
    });
  });

  group('ErrorMapper — قاعدة البيانات والشبكة', () {
    test('خطأ RLS (42501) يُترجم إلى permissionDenied', () {
      final AppException mapped = ErrorMapper.map(
        const PostgrestException(
          message: 'new row violates row-level security policy',
          code: '42501',
        ),
      );
      expect(mapped.code, AppErrorCode.permissionDenied);
    });

    test('مخالفة قيد CHECK تُترجم إلى validation', () {
      final AppException mapped = ErrorMapper.map(
        const PostgrestException(message: 'check violation', code: '23514'),
      );
      expect(mapped.code, AppErrorCode.validation);
    });

    test('SocketException الخام يُترجم إلى network', () {
      final AppException mapped = ErrorMapper.map(
        Exception('SocketException: Failed host lookup: project.supabase.co'),
      );
      expect(mapped.code, AppErrorCode.network);
    });

    test('AppException تُمرَّر كما هي دون تغليف', () {
      const AppException original =
          AppException(AppErrorCode.notConfigured, message: 'رسالة مخصّصة');
      final AppException mapped = ErrorMapper.map(original);
      expect(identical(mapped, original), isTrue);
      expect(mapped.message, 'رسالة مخصّصة');
    });

    test('الخطأ غير المعروف يُغلَّف مع حفظ الأصل', () {
      final Object cause = StateError('boom');
      final AppException mapped = ErrorMapper.map(cause);
      expect(mapped.code, AppErrorCode.unknown);
      expect(mapped.cause, same(cause));
    });
  });
}
