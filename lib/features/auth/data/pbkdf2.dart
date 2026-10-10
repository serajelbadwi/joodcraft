import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// **PBKDF2-HMAC-SHA256** (RFC 2898/8018) — التنفيذ الوحيد للتقطير المفتاحي في
/// التطبيق، مكتوب يدوياً لأن حزمة `crypto` لا تُوفّره (تُوفّر التجزئات و`Hmac`
/// فقط).
///
/// يُستعمل في موضعين:
/// * **تجزئة كلمات مرور الأدمنز** ([PasswordHasher]) — بحيث لا تُخزَّن كلمة
///   المرور أبداً، ولا يكفي تسريب الملف لتجريب كل الكلمات فوراً.
/// * **اشتقاق مفاتيح تصدير/استيراد حسابات الأدمنز** ([AdminConfigCipher]).
///
/// استُخلص في دالة نقية بلا حالة كي يُختبر وحده مقابل متجهات RFC المعروفة.
abstract final class Pbkdf2 {
  const Pbkdf2._();

  /// طول الناتج الموجب لـ`Hmac-SHA256` بالبايت.
  static const int hmacLength = 32;

  /// يشتقّ [keyLength] بايتاً من [password] و[salt] بعدد [iterations] دورة.
  ///
  /// الخوارزمية: لكل كتلة ناتج `i` (بدءاً من ‎1‎، بترميز big-endian):
  /// `U1 = PRF(P, S ‖ INT(i))` ثم `Uj = PRF(P, Uj−1)` والحصيلة هي
  /// `U1 ⊕ U2 ⊕ … ⊕ Uiterations`.
  static Uint8List deriveKey({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    int keyLength = 32,
  }) {
    if (iterations < 1) {
      throw ArgumentError.value(iterations, 'iterations', 'يجب أن يكون ≥ 1');
    }
    if (keyLength < 1) {
      throw ArgumentError.value(keyLength, 'keyLength', 'يجب أن يكون ≥ 1');
    }

    final Hmac prf = Hmac(sha256, password);
    final int blockCount = (keyLength + hmacLength - 1) ~/ hmacLength;
    final BytesBuilder out = BytesBuilder(copy: false);

    for (int block = 1; block <= blockCount; block++) {
      // `S ‖ INT_32_BE(i)` — الكتلة الأولى من السلسلة.
      final Uint8List seed = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt);
      final int base = salt.length;
      seed[base] = (block >> 24) & 0xff;
      seed[base + 1] = (block >> 16) & 0xff;
      seed[base + 2] = (block >> 8) & 0xff;
      seed[base + 3] = block & 0xff;

      List<int> u = prf.convert(seed).bytes;
      final Uint8List accumulator = Uint8List.fromList(u);

      for (int round = 1; round < iterations; round++) {
        u = prf.convert(u).bytes;
        for (int i = 0; i < hmacLength; i++) {
          accumulator[i] ^= u[i];
        }
      }
      out.add(accumulator);
    }

    final Uint8List all = out.toBytes();
    return Uint8List.fromList(all.sublist(0, keyLength));
  }

  /// بايتات عشوائية آمنة (للملح والأرقام المستعملة مرة واحدة).
  static Uint8List randomBytes(int length, {Random? random}) {
    final Random source = random ?? Random.secure();
    final Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = source.nextInt(256);
    }
    return bytes;
  }

  /// مقارنة **ثابتة الزمن**: لا تُخرج المهلة أي معلومة عن موضع أول اختلاف،
  /// فلا يمكن استخلاص البصمة تدريجياً بالقياس (timing attack).
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
