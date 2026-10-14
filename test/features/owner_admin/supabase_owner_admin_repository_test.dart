import 'dart:async' show FutureOr;

import 'package:flutter_test/flutter_test.dart';
import 'package:joodcraft/features/owner_admin/data/supabase_owner_admin_repository.dart';
import 'package:joodcraft/features/owner_admin/domain/owner_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// اختبارات **تدرّج القراءة** في `SupabaseOwnerAdminRepository`.
///
/// الخطأ الحقيقي الذي كان يُخفى خلف «تعذّر جلب التراخيص»:
/// `PostgrestException(42703) — column farah_licenses.subscriber_name does
/// not exist`، لأن قسم 20 من `supabase_village.sql` (أعمدة المشترك والمدة)
/// لم يكن مُشغَّلاً على القاعدة بينما التطبيق يطلب تلك الأعمدة.
///
/// هذه الاختبارات تقفل الإصلاح: التراخيص تظهر رغم غياب الأعمدة، والرسالة
/// العربية الواضحة تظهر حين يكون المنع حقيقياً (RLS/دالة مفقودة).
void main() {
  group('جلب التراخيص — تدرّج آمن', () {
    test('التراخيص تظهر وإن غابت أعمدة المشترك (قسم 20 غير مُشغَّل)',
        () async {
      final SupabaseOwnerAdminRepository repository =
          SupabaseOwnerAdminRepository(
        _FakeSupabaseClient(<String, _FakeTable>{
          'farah_licenses': _FakeTable(
            const <String>{
              'id',
              'code',
              'village_id',
              'is_active',
              'created_at',
            },
            <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'l1',
                'code': 'FRH-MAA-001',
                'village_id': 'v1',
                'is_active': false,
                'created_at': '2026-10-01T10:00:00Z',
              },
            ],
          ),
          'villages': _FakeTable(
            const <String>{'id', 'name'},
            <Map<String, dynamic>>[
              <String, dynamic>{'id': 'v1', 'name': 'قرية التجارب'},
            ],
          ),
        }),
      );

      final List<OwnerLicense> licenses = await repository.fetchLicenses();

      expect(licenses, hasLength(1));
      expect(licenses.single.code, 'FRH-MAA-001');
      // اسم القرية يُلحق من جدول القرى رغم الأعمدة الناقصة.
      expect(licenses.single.villageName, 'قرية التجارب');
      // بيانات المشترك غائبة بلا انهيار — الشاشة تعرض «—» لا شاشة خطأ.
      expect(licenses.single.subscriberName, isNull);
      expect(licenses.single.durationLabel, '—');
    });

    test('بيانات المشترك والمدة تظهر حين تكون الأعمدة موجودة', () async {
      final SupabaseOwnerAdminRepository repository =
          SupabaseOwnerAdminRepository(
        _FakeSupabaseClient(<String, _FakeTable>{
          'farah_licenses': _FakeTable(
            const <String>{
              'id',
              'code',
              'village_id',
              'subscriber_name',
              'subscriber_phone',
              'months',
              'is_active',
              'created_at',
            },
            <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'l1',
                'code': 'FRH-MAA-001',
                'village_id': 'v1',
                'subscriber_name': 'مكتب الأمل',
                'subscriber_phone': '01001234567',
                'months': 3,
                'is_active': true,
                'created_at': '2026-10-01T10:00:00Z',
              },
            ],
          ),
          'villages': _FakeTable(
            const <String>{'id', 'name'},
            <Map<String, dynamic>>[
              <String, dynamic>{'id': 'v1', 'name': 'قرية التجارب'},
            ],
          ),
        }),
      );

      final List<OwnerLicense> licenses = await repository.fetchLicenses();

      expect(licenses.single.subscriberName, 'مكتب الأمل');
      expect(licenses.single.months, 3);
      expect(licenses.single.durationLabel, '3 شهور');
      expect(licenses.single.isActive, isTrue);
    });

    test('قائمة فارغة ⇒ «لا تراخيص» بلا خطأ', () async {
      final SupabaseOwnerAdminRepository repository =
          SupabaseOwnerAdminRepository(
        _FakeSupabaseClient(<String, _FakeTable>{
          'farah_licenses': _FakeTable(
            const <String>{
              'id',
              'code',
              'village_id',
              'is_active',
              'created_at',
            },
            const <Map<String, dynamic>>[],
          ),
          'villages': _FakeTable(
            const <String>{'id', 'name'},
            const <Map<String, dynamic>>[],
          ),
        }),
      );

      expect(await repository.fetchLicenses(), isEmpty);
    });

    test('منع RLS (42501) ⇒ رسالة عربية واضحة لا «تعذّر جلب…» فقط',
        () async {
      final SupabaseOwnerAdminRepository repository =
          SupabaseOwnerAdminRepository(
        _FakeSupabaseClient(<String, _FakeTable>{
          'farah_licenses': _FakeTable(
            const <String>{
              'id',
              'code',
              'village_id',
              'is_active',
              'created_at',
            },
            const <Map<String, dynamic>>[],
            always: const PostgrestException(
              code: '42501',
              message: 'permission denied for table farah_licenses',
            ),
          ),
          'villages': _FakeTable(
            const <String>{'id', 'name'},
            const <Map<String, dynamic>>[],
          ),
        }),
      );

      await expectLater(
        repository.fetchLicenses(),
        throwsA(
          isA<OwnerAdminException>().having(
            (OwnerAdminException e) => e.message,
            'message',
            'غير مصرَّح بهذا الإجراء',
          ),
        ),
      );
    });
  });

  group('إصدار الترخيص — دالّة مفقودة', () {
    test('PGRST202 ⇒ رسالة عربية تشرح المطلوب تشغيله', () async {
      final SupabaseOwnerAdminRepository repository =
          SupabaseOwnerAdminRepository(
        _FakeSupabaseClient(<String, _FakeTable>{}),
      );

      await expectLater(
        repository.createLicense(
          villageId: 'v1',
          subscriberName: 'مكتب الأمل',
          phone: '01001234567',
          months: 3,
        ),
        throwsA(
          isA<OwnerAdminException>().having(
            (OwnerAdminException e) => e.message,
            'message',
            contains('supabase_village.sql'),
          ),
        ),
      );
    });
  });
}

/// جدول وهمي: أعمدة متاحة + صفوف + خطأ ثابت اختياري (لمحاكاة منع RLS).
class _FakeTable {
  const _FakeTable(this.columns, this.rows, {this.always});

  final Set<String> columns;
  final List<Map<String, dynamic>> rows;

  /// خطأ يُرفض به كل استعلام على الجدول — يحاكي `42501`.
  final PostgrestException? always;
}

/// منشئ استعلامات وهمي يحاكي PostgREST: يرفض عموداً غير موجود بالرمز
/// `42703` (نفس ما يفعله الخادم حين يُختار عمودٌ غائب)، ويرفض الجدول
/// كاملاً بالخطأ الثابت إن وُجد (`42501` مثل منع RLS).
///
/// يُنفّذ واجهة `PostgrestFilterBuilder<PostgrestList>` الحقيقية كي ينجح
/// التحويل الضمني لنوع إرجاع `.select(...)`؛ وما عدا `then` يمرّ عبر
/// `noSuchMethod` ويعيد نفس الكائن لسلاسل `order`/`limit`/`eq`.
class _FakeFilterBuilder implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder(this._table, this._schema, this._selected);

  final String _table;
  final _FakeTable _schema;
  final List<String> _selected;

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList value) onValue, {
    Function? onError,
  }) => _resolve().then<R>(onValue, onError: onError);

  /// كل ما لم يُعرَّف صراحةً سلسلة استعلام — يرجع نفس الكائن.
  @override
  dynamic noSuchMethod(Invocation invocation) => this;

  /// القرار: خطأ الجدول إن وُجد، وإلا رفض العمود الغائب، وإلا الصفوف
  /// مقتصرة على الأعمدة المطلوبة (كما يفعل PostgREST).
  Future<PostgrestList> _resolve() async {
    final PostgrestException? fixed = _schema.always;
    if (fixed != null) throw fixed;
    for (final String column in _selected) {
      if (!_schema.columns.contains(column)) {
        throw PostgrestException(
          code: '42703',
          message: 'column $_table.$column does not exist',
        );
      }
    }
    if (_selected.isEmpty) return _schema.rows;
    return _schema.rows
        .map(
          (Map<String, dynamic> row) => <String, dynamic>{
            for (final String column in _selected)
              if (row.containsKey(column)) column: row[column],
          },
        )
        .toList(growable: false);
  }
}

/// بادئ جدول وهمي يُنفّذ `SupabaseQueryBuilder` الحقيقية كي ينجح التحويل
/// الضمني لنوع إرجاع `SupabaseClient.from()`؛ و`select` يسلّم فيلترًا
/// وهميًا يحمل أعمدة الاستعلام.
class _FakeTableBuilder implements SupabaseQueryBuilder {
  _FakeTableBuilder(this._table, this._schema);

  final String _table;
  final _FakeTable _schema;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    final List<String> selected = columns
        .split(',')
        .map((String c) => c.trim())
        .where((String c) => c.isNotEmpty)
        .toList(growable: false);
    return _FakeFilterBuilder(_table, _schema, selected);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// عميل Supabase وهمي — لا يخدم إلا `from()` و`rpc()`؛ وما عداها
/// `noSuchMethod` كي لا يُبنى عميل شبكي في اختبار وحدة.
///
/// `from` يعيد `_FakeTableBuilder` الذي يُنفّذ `SupabaseQueryBuilder`
/// فعلياً، فينجح التحويل الضمني في الموقع؛ و`rpc` يرمي `PGRST202`
/// مباشرة كي يختبر المستودع رسالة الدالة المفقودة.
class _FakeSupabaseClient implements SupabaseClient {
  _FakeSupabaseClient(this._tables);

  final Map<String, _FakeTable> _tables;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #from) {
      final String table = invocation.positionalArguments.first as String;
      return _FakeTableBuilder(
        table,
        _tables[table] ??
            const _FakeTable(<String>{}, <Map<String, dynamic>>[]),
      );
    }
    if (invocation.memberName == #rpc) {
      final String functionName =
          invocation.positionalArguments.first as String;
      throw PostgrestException(
        code: 'PGRST202',
        message: 'Could not find the function public.$functionName',
      );
    }
    throw UnimplementedError('${invocation.memberName}');
  }
}
