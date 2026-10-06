import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import 'api_client.dart';
import 'auth_repository.dart';
import 'http_auth_repository.dart';
import 'token_store.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      baseUrl: AppConfig.apiUrl,
      token: () => ref.read(tokenStoreProvider).token,
    ));

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AppConfig.useApi ? HttpAuthRepository(ref.watch(apiClientProvider)) : MockAuthRepository(),
);

class SessionState {
  const SessionState({required this.signedIn, required this.onboardingSeen});
  final bool signedIn;
  final bool onboardingSeen;
}

/// Login session + "intro seen" flag.
/// The token is kept in [TokenStore] (Keychain/Keystore); only the intro flag is in prefs.
class SessionController extends Notifier<SessionState> {
  static const _onbKey = 'onboarding_seen';

  @override
  SessionState build() {
    final p = ref.watch(sharedPrefsProvider);
    return SessionState(
      signedIn: ref.watch(tokenStoreProvider).token != null,
      onboardingSeen: p.getBool(_onbKey) ?? false,
    );
  }

  Future<void> signIn(String token) async {
    await ref.read(tokenStoreProvider).save(token);
    state = SessionState(signedIn: true, onboardingSeen: state.onboardingSeen);
  }

  Future<void> signOut() async {
    await ref.read(tokenStoreProvider).clear();
    state = SessionState(signedIn: false, onboardingSeen: state.onboardingSeen);
  }

  Future<void> markOnboardingSeen() async {
    await ref.read(sharedPrefsProvider).setBool(_onbKey, true);
    state = SessionState(signedIn: state.signedIn, onboardingSeen: true);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
