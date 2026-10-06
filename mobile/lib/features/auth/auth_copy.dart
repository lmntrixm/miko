import '../../data/auth_repository.dart';

/// Error = cause + fix, no error codes in the main text (docs UXCopy).
String authErrorMessage(AuthError e) => switch (e) {
  AuthError.invalidCredentials =>
    'ایمیل یا رمز عبور درست نیست. دوباره امتحان کنید یا رمز را بازیابی کنید.',
  AuthError.emailTaken =>
    'این ایمیل قبلاً ثبت شده. وارد شوید یا رمز را بازیابی کنید.',
  AuthError.invalidCode => 'کد درست نیست. دوباره وارد کنید یا کد جدید بگیرید.',
  AuthError.codeExpired => 'کد منقضی شده. کد جدید بگیرید.',
  AuthError.network =>
    'اتصال اینترنت قطع است. اتصال را بررسی کنید و دوباره امتحان کنید.',
};

String errorOf(Object e) => e is AuthException
    ? authErrorMessage(e.error)
    : authErrorMessage(AuthError.network);
