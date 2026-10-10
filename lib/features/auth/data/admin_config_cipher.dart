import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/errors/app_error_code.dart';
import '../../../core/errors/app_exception.dart';
import 'pbkdf2.dart';

/// **مغلّف تصدير/استيراد حسابات الأدمنز** — تشفير مُصادَق عليه (Encrypt-then-MAC)
/// بلا أي اعتماد خارجي: كل شيء مبنيّ من `crypto` (‏`Hmac`/`Sha256`) و[Pbkdf2].
///
/// البنية النصّية (نوع ملف خاص) قابلة للنسخ كـ**شفرة** أو للحفظ في ملف
/// بامتداد [fileExtension]:
///
/// ```
/// JCAC1.<iterations>.<salt>.<nonce>.<ciphertext>.<tag>
/// ```
///
/// عدد الدورات **مكتوب داخل الشفرة** لا في الشيفرة: تعديله في الإصدارات
/// القادمة لا يكسر أي ملف قديم، ويستحيل خطأ اشتقاق مفتاح بمعاملات مختلفة عن
/// التي شُفّر بها (وهو ما كان يُفشل الفكّ بصمت).
///
/// * **المفتاح**: `PBKDF2-HMAC-SHA256(عبارة المرور, salt, iterations, 64)`
///   يُشقّ نصفه الأول مفتاح تشفير (`encKey`) ونصفه الثاني مفتاح مصادقة (`macKey`).
///   فصل المفتاحين يمنع تعارض الأدوار (لا يُستخدم مفتاح واحد للتشفير والوسم).
/// * **التشفير**: تيّار مفاتيح (Keystream) من `HMAC(encKey, nonce ‖ counter)`
///   يُجمَع بـXOR مع النصّ الصريح (‏CTR). لا حاجة لـAES: سرعة كافية لحجم
///   ملف حسابات صغير، والأمان يرجع إلى PBKDF2 + HMAC لا إلى التشفير وحده.
/// * **الوسم**: `HMAC-SHA256(macKey, header ‖ salt ‖ nonce ‖ ciphertext)`
///   — يُتحقَّق منه **قبل** فكّ التشفير وبمقارنة ثابتة الزمن، فتُرفض أي شفرة
///   معدَّلة أو عبارة مرور خاطئة بلا كشف أي معلومة.
///
/// كل هذا **بلا شبكة**: الملف يُنقل يدوياً بين الأجهزة المحلية فيعمل الجهاز
/// الجديد بنفس الحسابات والصلاحيات.
abstract final class AdminConfigCipher {
  const AdminConfigCipher._();

  /// وسم الصيغة (Header) — يتغيّر إن تغيّرت البنية فيستحيل خلط الإصدارات.
  static const String header = 'JCAC1';

  /// الامتداد الخاص لملف إعدادات الأدمنز.
  static const String fileExtension = 'jcadm';

  /// اسم ملف التصدير المقترح.
  static const String suggestedFileName = 'joodcraft-admins.$fileExtension';

  /// وسيط نوع MIME عند حفظ الملف.
  static const String mimeType = 'application/x-joodcraft-admins';

  /// دورات اشتقاق المفتاح من عبارة المرور.
  static const int iterations = 100000;

  static const int _saltBytes = 16;
  static const int _nonceBytes = 16;

  /// يشفر [payload] (نصّ JSON عادةً) بعبارة المرور ويُعيد الشفرة النصّية.
  ///
  /// يرمي [AppException] بـ[AppErrorCode.weakPassword] إن كانت عبارة المرور
  /// أقصر من الحدّ الأدنى: عبارة قصيرة تُبطل قوة PBKDF2 كلها.
  static String encrypt({
    required String payload,
    required String passphrase,
    int minPassphraseLength = 6,
    int? iterationsOverride,
  }) {
    _requirePassphrase(passphrase, minPassphraseLength);
    final int rounds = iterationsOverride ?? iterations;

    final Uint8List salt = Pbkdf2.randomBytes(_saltBytes);
    final Uint8List nonce = Pbkdf2.randomBytes(_nonceBytes);
    final Uint8List keys = Pbkdf2.deriveKey(
      password: utf8.encode(passphrase),
      salt: salt,
      iterations: rounds,
      keyLength: 64,
    );
    final Uint8List encKey = Uint8List.sublistView(keys, 0, 32);
    final Uint8List macKey = Uint8List.sublistView(keys, 32, 64);

    final Uint8List plain = utf8.encode(payload);
    final Uint8List stream = _keystream(encKey, nonce, plain.length);
    final Uint8List cipher = Uint8List(plain.length);
    for (int i = 0; i < plain.length; i++) {
      cipher[i] = plain[i] ^ stream[i];
    }

    final Uint8List tag = _tag(macKey, salt, nonce, cipher);
    return <String>[
      header,
      '$rounds',
      base64Url.encode(salt),
      base64Url.encode(nonce),
      base64Url.encode(cipher),
      base64Url.encode(tag),
    ].join('.');
  }

  /// يفكّ تشفير [code] بعبارة المرور ويُعيد النصّ الأصلي.
  ///
  /// يرمي [AppException]:
  /// * [AppErrorCode.validation] إن كانت الشفرة مشوّهة أو من إصدار آخر.
  /// * [AppErrorCode.invalidCredentials] إن فشل التحقّق (عبارة خاطئة/تعديل).
  static String decrypt({
    required String code,
    required String passphrase,
  }) {
    final List<String> parts = _normalize(code).split('.');
    if (parts.length != 6 || parts.first != header) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'شفرة الحسابات غير صالحة أو من إصدار غير مدعوم.',
      );
    }

    final int? rounds = int.tryParse(parts[1]);
    final Uint8List? salt = _decode(parts[2]);
    final Uint8List? nonce = _decode(parts[3]);
    final Uint8List? cipher = _decode(parts[4]);
    final Uint8List? tag = _decode(parts[5]);
    if (rounds == null ||
        rounds < 1 ||
        salt == null ||
        nonce == null ||
        cipher == null ||
        tag == null) {
      throw const AppException(
        AppErrorCode.validation,
        message: 'شفرة الحسابات تالفة (تنسيق غير صالح).',
      );
    }

    // المعاملات المقروءة من الشفرة نفسها — لا الشيفرة.
    final Uint8List keys = Pbkdf2.deriveKey(
      password: utf8.encode(passphrase),
      salt: salt,
      iterations: rounds,
      keyLength: 64,
    );
    final Uint8List encKey = Uint8List.sublistView(keys, 0, 32);
    final Uint8List macKey = Uint8List.sublistView(keys, 32, 64);

    // التحقّق **قبل** أي فكّ تشفير: لا نُخرج نصاً على شفرة غير موثوقة.
    if (!Pbkdf2.constantTimeEquals(_tag(macKey, salt, nonce, cipher), tag)) {
      throw const AppException(
        AppErrorCode.invalidCredentials,
        message: 'عبارة المرور غير صحيحة أو الشفرة مُعدّلة.',
      );
    }

    final Uint8List stream = _keystream(encKey, nonce, cipher.length);
    final Uint8List plain = Uint8List(cipher.length);
    for (int i = 0; i < cipher.length; i++) {
      plain[i] = cipher[i] ^ stream[i];
    }
    return utf8.decode(plain);
  }

  /// هل النصّ يشبه شفرة إعدادات أدمنز؟ (يكفي لتمييز المُدخلَين في الواجهة)
  static bool looksLikeCode(String value) =>
      _normalize(value).startsWith('$header.');

  // ==========================================================================
  //                              أدوات داخلية
  // ==========================================================================

  /// يزيل بياض الأسطر التي يضيفها النسخ/اللصق في ملفات نصية طويلة.
  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), '');

  /// وسم المصادقة: `HMAC(macKey, header ‖ salt ‖ nonce ‖ ciphertext)`.
  static Uint8List _tag(
    List<int> macKey,
    List<int> salt,
    List<int> nonce,
    List<int> cipher,
  ) {
    final Hmac mac = Hmac(sha256, macKey);
    final BytesBuilder body = BytesBuilder(copy: false)
      ..add(utf8.encode(header))
      ..add(salt)
      ..add(nonce)
      ..add(cipher);
    return Uint8List.fromList(mac.convert(body.toBytes()).bytes);
  }

  /// تيّار المفاتيح: `HMAC(encKey, nonce ‖ counter_be32)` مكرّراً حتى الطول.
  static Uint8List _keystream(List<int> encKey, List<int> nonce, int length) {
    final Hmac mac = Hmac(sha256, encKey);
    final BytesBuilder out = BytesBuilder(copy: false);
    int counter = 0;
    while (out.length < length) {
      final Uint8List block = Uint8List(nonce.length + 4)
        ..setRange(0, nonce.length, nonce);
      final int base = nonce.length;
      block[base] = (counter >> 24) & 0xff;
      block[base + 1] = (counter >> 16) & 0xff;
      block[base + 2] = (counter >> 8) & 0xff;
      block[base + 3] = counter & 0xff;
      out.add(mac.convert(block).bytes);
      counter++;
    }
    final Uint8List all = out.toBytes();
    return Uint8List.fromList(all.sublist(0, length));
  }

  static Uint8List? _decode(String value) {
    try {
      return base64Url.decode(value);
    } catch (_) {
      return null;
    }
  }

  static void _requirePassphrase(String passphrase, int minLength) {
    if (passphrase.trim().length < minLength) {
      throw AppException(
        AppErrorCode.weakPassword,
        message: 'عبارة مرور التصدير قصيرة جداً '
            '(‎$minLength‎ أحرف على الأقل).',
      );
    }
  }
}
