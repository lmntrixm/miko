import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_repository.dart';

/// Overridden in `main()` with the loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

class SessionState {
  const SessionState({required this.signedIn, required this.onboardingSeen});
  final bool signedIn;
  final bool onboardingSeen;
}

/// Login session + "intro seen" flag.
/// TODO: keep the token in flutter_secure_storage once the real backend exists.
class SessionController extends Notifier<SessionState> {
  static const _tokenKey = 'access_token';
  static const _onbKey = 'onboarding_seen';

  @override
  SessionState build() {
    final p = ref.watch(sharedPrefsProvider);
    return SessionState(
      signedIn: p.getString(_tokenKey) != null,
      onboardingSeen: p.getBool(_onbKey) ?? false,
    );
  }

  Future<void> signIn(String token) async {
    await ref.read(sharedPrefsProvider).setString(_tokenKey, token);
    state = SessionState(signedIn: true, onboardingSeen: state.onboardingSeen);
  }

  Future<void> signOut() async {
    await ref.read(sharedPrefsProvider).remove(_tokenKey);
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
