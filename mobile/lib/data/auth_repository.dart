import 'dart:async';

enum AuthError {
  invalidCredentials,
  emailTaken,
  invalidCode,
  codeExpired,
  network,
}

class AuthException implements Exception {
  const AuthException(this.error);
  final AuthError error;
  @override
  String toString() => 'AuthException($error)';
}

enum ReadingLanguage { fa, en, both }

/// Auth + onboarding API (docs/api.md: /v1/auth/*). Swap the implementation
/// when the real backend exists; screens only depend on this interface.
abstract class AuthRepository {
  /// Returns an access token. Existing users go straight to home, no OTP.
  Future<String> login(String email, String password);

  /// Registers and sends a 6-digit code to [email].
  Future<void> signup(String name, String email, String password);

  /// Verifies the signup code and returns an access token.
  Future<String> verify(String email, String code);

  Future<void> resendCode(String email);

  /// Forgot password, step 1: sends a recovery code.
  Future<void> requestReset(String email);

  /// Forgot password, step 2: checks the code before asking for a new password.
  Future<void> checkResetCode(String email, String code);

  /// Forgot password, step 3.
  Future<void> confirmReset(String email, String code, String newPassword);

  Future<void> savePreferences(Set<String> genres, ReadingLanguage language);

  /// Current preferences, to pre-fill the edit screen.
  Future<({Set<String> genres, ReadingLanguage language})> loadPreferences();
}

/// In-memory fake. Demo account: demo@miko.test / password123. Every code is 123456.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;
  static const demoCode = '123456';
  final _users = <String, String>{'demo@miko.test': 'password123'};
  final _pending = <String, ({String name, String password})>{};

  Future<void> _wait() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);
  String _key(String e) => e.trim().toLowerCase();
  String _token(String e) => 'mock-token-${_key(e)}';

  @override
  Future<String> login(String email, String password) async {
    await _wait();
    if (_users[_key(email)] != password) {
      throw const AuthException(AuthError.invalidCredentials);
    }
    return _token(email);
  }

  @override
  Future<void> signup(String name, String email, String password) async {
    await _wait();
    if (_users.containsKey(_key(email))) {
      throw const AuthException(AuthError.emailTaken);
    }
    _pending[_key(email)] = (name: name, password: password);
  }

  @override
  Future<String> verify(String email, String code) async {
    await _wait();
    final p = _pending[_key(email)];
    if (p == null) throw const AuthException(AuthError.codeExpired);
    if (code != demoCode) throw const AuthException(AuthError.invalidCode);
    _users[_key(email)] = p.password;
    _pending.remove(_key(email));
    return _token(email);
  }

  @override
  Future<void> resendCode(String email) => _wait();

  @override
  Future<void> requestReset(String email) => _wait(); // never reveal whether the email exists

  @override
  Future<void> checkResetCode(String email, String code) async {
    await _wait();
    if (code != demoCode) throw const AuthException(AuthError.invalidCode);
  }

  @override
  Future<void> confirmReset(
    String email,
    String code,
    String newPassword,
  ) async {
    await checkResetCode(email, code);
    if (_users.containsKey(_key(email))) _users[_key(email)] = newPassword;
  }

  var _prefs = (genres: <String>{'اکشن', 'فانتزی', 'کمدی'}, language: ReadingLanguage.fa);

  @override
  Future<void> savePreferences(Set<String> genres, ReadingLanguage language) async {
    await _wait();
    _prefs = (genres: {...genres}, language: language);
  }

  @override
  Future<({Set<String> genres, ReadingLanguage language})> loadPreferences() async {
    await _wait();
    return _prefs;
  }
}
