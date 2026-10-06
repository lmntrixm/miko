import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:miko/data/api_client.dart';
import 'package:miko/data/api_errors.dart';
import 'package:miko/data/auth_repository.dart';
import 'package:miko/data/http_auth_repository.dart';
import 'package:miko/data/models.dart';

ApiClient client(MockClientHandler h, {String? token = 'tok'}) =>
    ApiClient(baseUrl: 'http://api.test', token: () => token, client: MockClient(h));

http.Response json(int status, Object body) => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});
http.Response err(int status, String code) => json(status, {'error': {'code': code, 'message': 'پیام'}});

void main() {
  test('login sends JSON, no auth header, and returns the token', () async {
    late http.Request seen;
    final repo = HttpAuthRepository(client((r) async {
      seen = r;
      return json(200, {'token': 'abc', 'user': {}});
    }));
    expect(await repo.login(' A@b.co ', 'password123'), 'abc');
    expect(seen.url.toString(), 'http://api.test/v1/auth/login');
    expect(seen.headers.containsKey('authorization'), isFalse);
    expect(jsonDecode(seen.body), {'email': 'A@b.co', 'password': 'password123'});
  });

  test('backend error codes map to the auth errors the screens already explain', () async {
    Future<AuthError> run(String code, int status) async {
      final repo = HttpAuthRepository(client((_) async => err(status, code)));
      try {
        await repo.verify('a@b.co', '123456');
      } on AuthException catch (e) {
        return e.error;
      }
      fail('no error');
    }

    expect(await run('code_wrong', 400), AuthError.invalidCode);
    expect(await run('code_expired', 400), AuthError.codeExpired);
    expect(await run('too_many_attempts', 429), AuthError.tooManyAttempts);
    expect(await run('email_taken', 409), AuthError.emailTaken);
  });

  test('no connection and server errors become network errors', () async {
    final down = HttpAuthRepository(client((_) async => throw http.ClientException('offline')));
    expect(() => down.login('a@b.co', 'x'), throwsA(isA<AuthException>().having((e) => e.error, 'error', AuthError.network)));
    final broken = HttpAuthRepository(client((_) async => http.Response('<html>', 502)));
    expect(() => broken.login('a@b.co', 'x'), throwsA(isA<AuthException>().having((e) => e.error, 'error', AuthError.network)));
  });

  test('shared status codes become app-wide exceptions; the token is sent when signed in', () async {
    String? auth;
    ApiClient c(int s) => client((r) async {
          auth = r.headers['authorization'];
          return err(s, 'x');
        });
    await expectLater(c(401).send('GET', '/me'), throwsA(isA<UnauthorizedException>()));
    expect(auth, 'Bearer tok');
    await expectLater(c(402).send('GET', '/chapters/x/pages'), throwsA(isA<PaywallException>()));
    await expectLater(c(426).send('GET', '/home'), throwsA(isA<UpgradeRequiredException>()));
    await expectLater(c(503).send('GET', '/home'), throwsA(isA<MaintenanceException>()));
    // A 401 with no token (e.g. wrong password) is a normal error, not "session expired".
    final anon = client((_) async => err(401, 'bad_credentials'), token: null);
    await expectLater(anon.send('POST', '/auth/login'), throwsA(isA<ApiException>()));
  });

  test('preferences round-trip', () async {
    final repo = HttpAuthRepository(client((r) async {
      if (r.method == 'PUT') {
        expect(jsonDecode(r.body), {'genres': ['اکشن'], 'language': 'both'});
        return json(200, {'ok': true});
      }
      return json(200, {'genres': ['اکشن'], 'language': 'both'});
    }));
    await repo.savePreferences({'اکشن'}, ReadingLanguage.both);
    final p = await repo.loadPreferences();
    expect(p.genres, {'اکشن'});
    expect(p.language, ReadingLanguage.both);
  });
}
