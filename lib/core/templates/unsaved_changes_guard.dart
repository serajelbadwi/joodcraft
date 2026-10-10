import 'dart:async';

/// حارس **الإجراءات الإتلافية الصريحة** التي قد تُسقط عملاً غير محفوظ.
///
/// **مهم — لا يُستدعى عند التنقّل بين الأقسام:** الأقسام تعيش في هيكل ذي فروع
/// (`StatefulShellRoute.indexedStack`) فلا يُهدَم عمل أي قسم عند تبديل
/// التبويبات، ومن ثمّ لا معنى لسؤال المستخدم عن المغادرة هناك. التأكيد يقع فقط
/// عند إجراء صريح داخل الشاشة (قالب جديد / مسح البيانات)، وهناك تَسأل الشاشة
/// [canLeave] بنفسها قبل التنفيذ.
///
/// متعمَّد أن يكون وحيداً (singleton): شاشة نشطة واحدة في كل لحظة، والشاشة
/// تسجّل معالجها عند التصيير وتزيله عند التخلّص، فتبقى الشاشات الأخرى بلا حارس
/// ⇒ [canLeave] تُرجع `true` فوراً بلا أي كلفة.
class UnsavedChangesGuard {
  UnsavedChangesGuard._();

  static final UnsavedChangesGuard instance = UnsavedChangesGuard._();

  Future<bool> Function()? _handler;

  /// هل يوجد حارس مسجَّل حالياً؟
  bool get isActive => _handler != null;

  /// تسجيل معالج المغادرة (يُستبدل أي معالج سابق).
  void register(Future<bool> Function() handler) => _handler = handler;

  /// إزالة المعالج — لكن فقط إن كان هو نفسه المسجَّل، حتى لا تُزيل شاشةٌ
  /// متأخّرة التخلّص معالج شاشة أحدث حلّت مكانها.
  void unregister(Future<bool> Function() handler) {
    if (identical(_handler, handler)) _handler = null;
  }

  /// هل يُسمح بمغادرة الشاشة الحالية؟ `true` إن لا حارس مسجَّل.
  Future<bool> canLeave() async {
    final Future<bool> Function()? handler = _handler;
    if (handler == null) return true;
    return handler();
  }
}
