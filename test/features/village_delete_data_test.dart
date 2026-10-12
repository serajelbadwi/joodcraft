import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/village/data/village_repository.dart';
import 'package:joodcraft/features/village/domain/national_id.dart';
import 'package:joodcraft/features/village/domain/village.dart';
import 'package:joodcraft/features/village/domain/village_validators.dart';
import 'package:joodcraft/features/village/domain/village_video.dart';
import 'package:joodcraft/features/village/presentation/screens/village_delete_data_screen.dart';
import 'package:joodcraft/features/village/presentation/screens/village_registration_screen.dart';
import 'package:joodcraft/features/village/presentation/village_theme.dart';

/// مستودع وهمي مخصّص لاختبارات الحذف: يسجّل ما وصل إليه ويُعيد النتيجة
/// البرمجيةّة (تطابق/عدم تطابق/استثناء) بلا شبكة.
class _FakeDeleteRepository implements VillageRepository {
  _FakeDeleteRepository({this.available = true, this.deleteResult = true});

  final bool available;
  bool deleteResult;
  VillageException? failDeleteWith;

  /// سجلّ طلبات الحذف كما وصلت — للتحقّق من التطبيع قبل الإرسال.
  final List<String> deleted = <String>[];

  @override
  bool get isAvailable => available;

  @override
  Future<Village?> lookupVillage(String code) async => const Village(
        id: 'v-1',
        name: 'منشأة الأمراء ومحلة حسن',
        code: 'MAA-2026',
      );

  @override
  Future<String> registerMember({
    required String villageCode,
    required String name,
    required String phone,
    required String nationalId,
  }) async =>
      'member-1';

  @override
  Future<bool> deleteMember({
    required String nationalId,
    required String phone,
  }) async {
    final VillageException? failure = failDeleteWith;
    if (failure != null) throw failure;
    deleted.add('$nationalId|$phone');
    return deleteResult;
  }

  @override
  Future<List<VillageVideo>> fetchVideos({required String villageCode}) async =>
      const <VillageVideo>[];
}

/// رقم قومي صالح (1990/05/12 — الدقهلية) وتليفون مصري شائع الصيغة.
const String _validNationalId = '29005121234565';
const String _validPhone = '01012345678';

Future<void> _pumpDeleteScreen(
  WidgetTester tester,
  _FakeDeleteRepository repo,
) async {
  tester.view.physicalSize = const Size(1100, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: VillageTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: VillageDeleteDataScreen(repository: repo),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillAndConfirm(
  WidgetTester tester, {
  required String nationalId,
  required String phone,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('village-delete-national-id-field')),
    nationalId,
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('village-delete-phone-field')),
    phone,
  );
  await tester.pump();
  await tester.tap(
    find.byKey(const ValueKey<String>('village-delete-confirm')),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('مدخل الحذف في الصفحة الرئيسية', () {
    testWidgets('زر «حذف بياناتي» يفتح صفحة الحذف', (tester) async {
      tester.view.physicalSize = const Size(1100, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: VillageTheme.dark,
          locale: const Locale('ar'),
          supportedLocales: const <Locale>[Locale('ar')],
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: VillageRegistrationScreen(
            repository: _FakeDeleteRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('village-delete-data-button')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-data-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('village-delete-form'),
            skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text(VillageText.deleteWarningTitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-delete-cancel')),
        findsOneWidget,
      );
    });
  });

  group('صفحة الحذف', () {
    testWidgets('حقول فارغة تُرفض محلياً بلا نداء للسيرفر', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository();
      await _pumpDeleteScreen(tester, repo);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-confirm')),
      );
      await tester.pumpAndSettle();

      expect(find.text('اكتب رقم التليفون'), findsOneWidget);
      expect(find.text(NationalIdError.empty.message), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('رقم قومي غير صالح يُرفض محلياً بلا نداء', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository();
      await _pumpDeleteScreen(tester, repo);

      await _fillAndConfirm(tester, nationalId: '123', phone: _validPhone);

      expect(find.text(NationalIdError.wrongLength.message), findsOneWidget);
      expect(repo.deleted, isEmpty);
    });

    testWidgets('التطابق الناجح يحذف ويعيد لوحة النجاح', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository();
      await _pumpDeleteScreen(tester, repo);

      await _fillAndConfirm(
        tester,
        nationalId: _validNationalId,
        phone: _validPhone,
      );

      expect(repo.deleted, <String>['$_validNationalId|$_validPhone']);
      expect(find.byKey(const ValueKey<String>('village-delete-success')),
          findsOneWidget);
      expect(find.text(VillageText.deleteSuccessTitle), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('village-delete-form'),
            skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('عدم التطابق يعرض رسالة «لم نجد بيانات متطابقة»',
        (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository(
        deleteResult: false,
      );
      await _pumpDeleteScreen(tester, repo);

      await _fillAndConfirm(
        tester,
        nationalId: _validNationalId,
        phone: _validPhone,
      );

      expect(find.text(VillageText.deleteNotFound), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('village-delete-success')),
          findsNothing);
    });

    testWidgets('خطأ شبكة يُعرض برسالة الحذف لا برسالة التسجيل', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository()
        ..failDeleteWith = const VillageException(
          VillageErrorKind.network,
          VillageText.networkError,
        );
      await _pumpDeleteScreen(tester, repo);

      await _fillAndConfirm(
        tester,
        nationalId: _validNationalId,
        phone: _validPhone,
      );

      expect(find.text(VillageText.deleteNetworkError), findsOneWidget);
      expect(find.text(VillageText.deleteGenericError), findsNothing);
    });

    testWidgets('زر «إلغاء» يُغلق الصفحة عائدةً', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository();
      tester.view.physicalSize = const Size(1100, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: VillageTheme.dark,
          locale: const Locale('ar'),
          supportedLocales: const <Locale>[Locale('ar')],
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey<String>('open-delete'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          VillageDeleteDataScreen(repository: repo),
                    ),
                  ),
                  child: const Text('فتح'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('open-delete')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('village-delete-form'),
            skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-cancel')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('village-delete-form'),
            skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('زر «العودة إلى التسجيل» يُغلق صفحة الحذف', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository();
      await _pumpDeleteScreen(tester, repo);

      await _fillAndConfirm(
        tester,
        nationalId: _validNationalId,
        phone: _validPhone,
      );
      expect(find.byKey(const ValueKey<String>('village-delete-success')),
          findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('village-delete-done')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('village-delete-form'),
            skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('الخدمة غير مُهيّأة تُوضّح بدل نموذج لا يعمل', (tester) async {
      final _FakeDeleteRepository repo = _FakeDeleteRepository(
        available: false,
      );
      await _pumpDeleteScreen(tester, repo);

      expect(
        find.byKey(
          const ValueKey<String>('village-delete-service-unavailable'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('village-delete-confirm')),
        findsNothing,
      );
    });
  });
}
