import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/account_providers.dart' show themeModeProvider;
import 'data/models.dart';
import 'data/providers.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/intro_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/account/edit_profile_screen.dart';
import 'features/account/help_center_screen.dart';
import 'features/account/invite_screen.dart';
import 'features/account/legal_screen.dart';
import 'features/account/notification_settings_screen.dart';
import 'features/account/notifications_screen.dart';
import 'features/account/profile_screen.dart';
import 'features/account/report_problem_screen.dart';
import 'features/auth/onboarding_prefs_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/gallery/gallery_screen.dart';
import 'features/billing/manage_subscription_screen.dart';
import 'features/billing/payment_history_screen.dart';
import 'features/billing/payment_pending_screen.dart';
import 'features/billing/payment_result_screen.dart';
import 'features/billing/paywall_screen.dart';
import 'features/billing/subscription_screen.dart';
import 'features/comments/comments_screen.dart';
import 'features/common/todo_screen.dart';
import 'features/detail/title_detail_screen.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/reader/reader_screen.dart';
import 'features/shell/app_shell.dart';

/// Routes follow docs/screens.md. Unauthenticated (401) users are sent to login.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final rootKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
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
        builder: (_, s) => OnboardingPrefsScreen(edit: s.uri.queryParameters['edit'] == '1'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        // Branch order = tab order: profile · search · home · library · add.
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, _) => const TodoScreen('جستجو'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'title/:id',
                    builder: (_, s) =>
                        TitleDetailScreen(workId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (_, _) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/request-title',
                builder: (_, _) => const TodoScreen('درخواست اثر جدید'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/downloads',
        builder: (_, _) => const DownloadsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/reader/:chapterId',
        builder: (_, s) =>
            ReaderScreen(chapterId: s.pathParameters['chapterId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/comments/:chapterId',
        builder: (_, s) =>
            CommentsScreen(chapterId: s.pathParameters['chapterId']!),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/comment-thread/:commentId',
        builder: (_, s) =>
            CommentThreadScreen(commentId: s.pathParameters['commentId']!),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, _) => GalleryScreen(
          onToggleTheme: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
      ),
      // Billing: payment itself happens at the bank, outside the app.
      GoRoute(parentNavigatorKey: rootKey, path: '/paywall', builder: (_, s) => PaywallScreen(chapterId: s.uri.queryParameters['chapter'])),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/subscription',
        builder: (_, s) => SubscriptionScreen(initialPlan: s.uri.queryParameters['plan'], chapterId: s.uri.queryParameters['chapter']),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/payment-pending/:session',
        builder: (_, s) => PaymentPendingScreen(sessionId: s.pathParameters['session']!, chapterId: s.uri.queryParameters['chapter']),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/payment-result/:session',
        // The outcome travels as `extra`; after a process restart it is gone, so show the history instead.
        redirect: (_, s) => s.extra is PaymentOutcome ? null : '/payment-history',
        builder: (_, s) => PaymentResultScreen(outcome: s.extra! as PaymentOutcome, chapterId: s.uri.queryParameters['chapter']),
      ),
      GoRoute(parentNavigatorKey: rootKey, path: '/manage-subscription', builder: (_, _) => const ManageSubscriptionScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/payment-history', builder: (_, _) => const PaymentHistoryScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/notification-settings', builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/edit-profile', builder: (_, _) => const EditProfileScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/invite', builder: (_, _) => const InviteScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/help-center', builder: (_, _) => const HelpCenterScreen()),
      GoRoute(parentNavigatorKey: rootKey, path: '/legal', builder: (_, _) => const LegalScreen()),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/report-problem',
        builder: (_, s) => ReportProblemScreen(
          chapterId: s.uri.queryParameters['chapter'],
          page: int.tryParse(s.uri.queryParameters['page'] ?? ''),
          lang: s.uri.queryParameters['lang'],
        ),
      ),
      // Not built yet.
      GoRoute(path: '/list-all', builder: (_, _) => const TodoScreen('فهرست کامل')),
    ],
  );
});
