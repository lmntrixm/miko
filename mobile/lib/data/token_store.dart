import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the login token lives. Real app: Keychain / Keystore. Tests: memory.
abstract class TokenStore {
  /// Synchronous read of the value loaded at startup.
  String? get token;
  Future<void> save(String token);
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);
  @override
  String? token;
  @override
  Future<void> save(String t) async => token = t;
  @override
  Future<void> clear() async => token = null;
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore._(this._storage, this.token);
  static const _key = 'access_token';
  final FlutterSecureStorage _storage;
  @override
  String? token;

  /// Loads the token once before `runApp` so the router can decide synchronously.
  static Future<SecureTokenStore> load() async {
    const storage = FlutterSecureStorage();
    String? t;
    try {
      t = await storage.read(key: _key);
    } catch (_) {
      // Keystore can be unavailable or corrupt after a restore; treat as signed out.
      t = null;
    }
    return SecureTokenStore._(storage, t);
  }

  @override
  Future<void> save(String t) async {
    token = t;
    await _storage.write(key: _key, value: t);
  }

  @override
  Future<void> clear() async {
    token = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => throw UnimplementedError());
