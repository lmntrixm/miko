import 'api_client.dart';
import 'auth_repository.dart';
import 'api_errors.dart';

/// [AuthRepository] over the real API.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);
  final ApiClient _api;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on NetworkException {
      throw const AuthException(AuthError.network);
    } on ApiException catch (e) {
      throw AuthException(switch (e.code) {
        'bad_credentials' => AuthError.invalidCredentials,
        'email_taken' => AuthError.emailTaken,
        'code_wrong' => AuthError.invalidCode,
        'code_expired' => AuthError.codeExpired,
        'too_many_attempts' => AuthError.tooManyAttempts,
        _ => AuthError.network,
      });
    }
  }

  @override
  Future<String> login(String email, String password) => _guard(() async {
        final r = await _api.send('POST', '/auth/login', auth: false, body: {'email': email.trim(), 'password': password});
        return r['token'] as String;
      });

  @override
  Future<void> signup(String name, String email, String password) => _guard(() => _api.send('POST', '/auth/signup', auth: false, body: {'name': name.trim(), 'email': email.trim(), 'password': password}));

  @override
  Future<String> verify(String email, String code) => _guard(() async {
        final r = await _api.send('POST', '/auth/verify', auth: false, body: {'email': email.trim(), 'code': code});
        return r['token'] as String;
      });

  @override
  Future<void> resendCode(String email) => _guard(() => _api.send('POST', '/auth/resend', auth: false, body: {'email': email.trim()}));

  @override
  Future<void> requestReset(String email) => _guard(() => _api.send('POST', '/auth/password/reset', auth: false, body: {'email': email.trim()}));

  @override
  Future<void> checkResetCode(String email, String code) => _guard(() => _api.send('POST', '/auth/password/check', auth: false, body: {'email': email.trim(), 'code': code}));

  @override
  Future<void> confirmReset(String email, String code, String newPassword) =>
      _guard(() => _api.send('POST', '/auth/password/reset', auth: false, body: {'email': email.trim(), 'code': code, 'password': newPassword}));

  @override
  Future<void> savePreferences(Set<String> genres, ReadingLanguage language) =>
      _guard(() => _api.send('PUT', '/me/preferences', body: {'genres': genres.toList(), 'language': language.name}));

  @override
  Future<({Set<String> genres, ReadingLanguage language})> loadPreferences() => _guard(() async {
        final r = await _api.send('GET', '/me');
        return (
          genres: {for (final g in (r['genres'] as List)) '$g'},
          language: ReadingLanguage.values.firstWhere((l) => l.name == r['language'], orElse: () => ReadingLanguage.fa),
        );
      });
}
