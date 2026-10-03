import 'dart:async';

/// حارس التنقّل خارج الشاشات التي قد تحمل عملاً غير محفوظ.
///
/// **المشكلة:** محرّر القوالب يعيش داخل `ShellRoute` مع لوحة جانبية تنتقل
/// مباشرةً عبر `context.go(...)`، فلا يمكن للودجت أن يعترض التنقّل بنفسه.
///
/// **الحل:** نقطة اعتراض واحدة يعرّفها الشاشة النشطة عند الحاجة. تسأل الواجهة
/// (`DashboardShell`) الحارس قبل أي تنقّل، فإن أرجع `false` تُلغى المغادرة.
/// تبقى الشاشات الأخرى بلا حارس ⇒ [canLeave] تُرجع `true` فوراً بلا أي كلفة.
///
/// متعمَّد أن يكون وحيداً (singleton): شاشة نشطة واحدة في كل لحظة، والشاشة
/// تسجّل معالجها عند التصيير وتزيله عند التخلّص.
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
