import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/intro_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_prefs_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/gallery/gallery_screen.dart';
import 'features/home/home_stub_screen.dart';

/// Routes follow docs/screens.md. Unauthenticated (401) users are sent to login.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(sessionProvider).signedIn;
      final loc = state.matchedLocation;
      if (!signedIn && loc.startsWith('/home')) return '/auth-login';
      if (signedIn && loc == '/auth-login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const IntroScreen()),
      GoRoute(path: '/auth-login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/auth-signup', builder: (_, _) => const SignupScreen()),
      GoRoute(
        path: '/auth-otp',
        builder: (_, s) => OtpScreen(email: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding-prefs',
        builder: (_, _) => const OnboardingPrefsScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeStubScreen()),
      GoRoute(
        path: '/gallery',
        builder: (context, _) => GalleryScreen(
          onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ),
      // Not built yet; shared targets from auth screens.
      GoRoute(
        path: '/legal',
        builder: (_, _) => const _Todo('قوانین و حریم خصوصی'),
      ),
      GoRoute(path: '/help-center', builder: (_, _) => const _Todo('پشتیبانی')),
    ],
  );
});

class _Todo extends StatelessWidget {
  const _Todo(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: const Center(child: Text('به‌زودی')),
  );
}

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // dark is the default

  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
