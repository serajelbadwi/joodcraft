import 'app_user.dart';

/// واجهة المصادقة — تفصل منطق التطبيق عن Supabase.
///
/// الفائدة: يمكن استبدال المزوّد أو محاكاة المصادقة في الاختبارات دون لمس
/// الشاشات ولا `AuthProvider`.
abstract interface class AuthRepository {
  /// المستخدم الحالي من الجلسة المخزّنة محلياً (دون أي طلب شبكة).
  AppUser? get currentUser;

  /// تدفّق تغيّر حالة الدخول/الخروج.
  Stream<AppUser?> authStateChanges();

  /// تسجيل الدخول بالبريد وكلمة المرور.
  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  });

  /// إنشاء حساب جديد.
  Future<SignUpOutcome> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
    String? organizationName,
  });

  /// إرسال رابط/رمز استعادة كلمة المرور.
  Future<void> sendPasswordReset(String email);

  /// جلب سجل `public.profiles` للمستخدم الحالي (لتحديث الاسم والمؤسسة).
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// إنهاء الجلسة.
  Future<void> signOut();
}
