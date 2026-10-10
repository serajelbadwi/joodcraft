import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'pbkdf2.dart';

/// عدد دورات PBKDF2 الافتراضي — يفصل كلمة المرور عن بصمتها المخزَّنة.
const int kDefaultPbkdf2Iterations = 100000;

/// طول الملح العشوائي لكل حساب بالبايت.
const int kPbkdf2SaltBytes = 16;

/// طول المفتاح المشتقّ (بصمة كلمة المرور) بالبايت.
const int kPbkdf2KeyBytes = 32;

/// بادئة صيغة التخزين الحالية داخل ملف الحسابات.
const String kPbkdf2Prefix = 'pbkdf2_sha256';

/// نتيجة التحقّق من كلمة مرور مقابل بصمة مخزَّنة.
enum PasswordVerification {
  /// كلمة المرور صحيحة والبصمة بالصيغة الحديثة — لا عمل مطلوب.
  match,

  /// كلمة المرور خاطئة.
  mismatch,

  /// صحيحة لكن بصمتها بصيغة قديمة (‎SHA-256‎ مفرد) — تُرقّى فوراً عند الدخول.
  needsUpgrade,
}

/// **البوابة الوحيدة** لتجزئة كلمات المرور والتحقّق منها.
///
/// صيغة التخزين: `pbkdf2_sha256$<iterations>$<saltBase64Url>$<hashBase64Url>`
/// — تحمل كل معاملاتها معها، فيمكن رفع عدد الدورات لاحقاً بلا كسر أي حساب قديم.
///
/// توافق خلفي: البصمات القديمة (`sha256` مفرد بصيغة `hex`) تبقى قابلة
/// للتحقّق، ويُعاد تجزئتها بـPBKDF2 عند أول دخول ناجح — فلا يُقفل حساب قائم.
abstract final class PasswordHasher {
  const PasswordHasher._();

  static final RegExp _legacySha256 = RegExp(r'^[0-9a-f]{64}$');

  /// يُجزّئ [password] ويُعيد سلسلة التخزين الكاملة.
  ///
  /// [salt] يُمرَّر للاختبارات فقط (وإلا وُلّد عشوائياً من `Random.secure`).
  static String hash(
    String password, {
    int iterations = kDefaultPbkdf2Iterations,
    List<int>? salt,
  }) {
    final Uint8List saltBytes = salt == null
        ? Pbkdf2.randomBytes(kPbkdf2SaltBytes)
        : Uint8List.fromList(salt);
    final Uint8List key = Pbkdf2.deriveKey(
      password: utf8.encode(password),
      salt: saltBytes,
      iterations: iterations,
      keyLength: kPbkdf2KeyBytes,
    );
    return '$kPbkdf2Prefix\$$iterations\$'
        '${base64Url.encode(saltBytes)}\$${base64Url.encode(key)}';
  }

  /// يتحقّق من [password] مقابل البصمة [stored] بلا تسريب زمني.
  static PasswordVerification verify(String password, String? stored) {
    if (stored == null || stored.isEmpty) {
      return PasswordVerification.mismatch;
    }

    if (stored.startsWith('$kPbkdf2Prefix\$')) {
      final List<String> parts = stored.split(r'$');
      if (parts.length != 4) return PasswordVerification.mismatch;
      final int? iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 1) {
        return PasswordVerification.mismatch;
      }
      final Uint8List? salt = _tryDecodeBase64(parts[2]);
      final Uint8List? expected = _tryDecodeBase64(parts[3]);
      if (salt == null || expected == null || expected.isEmpty) {
        return PasswordVerification.mismatch;
      }
      final Uint8List actual = Pbkdf2.deriveKey(
        password: utf8.encode(password),
        salt: salt,
        iterations: iterations,
        keyLength: expected.length,
      );
      return Pbkdf2.constantTimeEquals(actual, expected)
          ? PasswordVerification.match
          : PasswordVerification.mismatch;
    }

    // توافق خلفي: بصمة SHA-256 قديمة (hex مفرد).
    if (_legacySha256.hasMatch(stored)) {
      final String legacy = sha256.convert(utf8.encode(password)).toString();
      return legacy == stored
          ? PasswordVerification.needsUpgrade
          : PasswordVerification.mismatch;
    }

    return PasswordVerification.mismatch;
  }

  /// هل البصمة بالصيغة الحديثة؟ (لفحص صحة ملف مُستورد قبل قبوله)
  static bool isModernHash(String? stored) =>
      stored != null && stored.startsWith('$kPbkdf2Prefix\$');

  static Uint8List? _tryDecodeBase64(String value) {
    try {
      return base64Url.decode(value);
    } catch (_) {
      return null;
    }
  }
}
