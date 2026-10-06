import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/snack.dart';
import 'discovery_providers.dart';
import 'discovery_repository.dart';
import 'models.dart';
import 'providers.dart';

/// HTTP 401: the session expired → login.
class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

/// HTTP 426: this app version is too old (forced or optional update).
class UpgradeRequiredException implements Exception {
  const UpgradeRequiredException({this.forced = true, this.newVersion});
  final bool forced;
  final String? newVersion;
}

/// HTTP 503: planned maintenance.
class MaintenanceException implements Exception {
  const MaintenanceException({this.until});
  final String? until;
}

/// No connection / timeout.
class NetworkException implements Exception {
  const NetworkException();
}

/// App-wide status coming from a failed request (overrides the start-up status check).
class StatusOverride extends Notifier<AppStatus?> {
  @override
  AppStatus? build() => null;
  void set(AppStatus? s) => state = s;
}

final statusOverrideProvider = NotifierProvider<StatusOverride, AppStatus?>(StatusOverride.new);

/// Maps shared API error codes (docs/api.md) to what the user sees.
/// Returns true when the error was fully handled here (the caller shows nothing more).
bool handleApiError(WidgetRef ref, BuildContext context, Object error) {
  switch (error) {
    case UnauthorizedException():
      ref.read(sessionProvider.notifier).signOut();
      showSnack(context, 'نشست شما منقضی شده؛ دوباره وارد شوید.');
      context.go('/auth-login');
      return true;
    case PaywallException():
      context.push('/paywall');
      return true;
    case UpgradeRequiredException(:final forced, :final newVersion):
      ref.read(statusOverrideProvider.notifier).set(AppStatus(update: forced ? UpdateKind.forced : UpdateKind.optional, newVersion: newVersion));
      return true;
    case MaintenanceException(:final until):
      ref.read(statusOverrideProvider.notifier).set(AppStatus(maintenance: true, maintenanceUntil: until));
      return true;
    default:
      return false;
  }
}

/// Text for errors that stay on screen (cause + fix, no codes).
String apiErrorText(Object error) => switch (error) {
      NetworkException() => 'اتصال اینترنت قطع است. اتصال را بررسی کنید و دوباره امتحان کنید.',
      DeviceLimitException() => 'دانلود روی حداکثر ۲ دستگاه ممکن است. یکی از دستگاه‌های قبلی را از تنظیمات حساب حذف کنید.',
      _ => 'بارگذاری نشد. دوباره امتحان کنید؛ اگر مشکل ادامه داشت، چند دقیقه بعد سر بزنید.',
    };

// Used by the gate: override wins over the start-up check.
final effectiveStatusProvider = Provider<AppStatus?>((ref) => ref.watch(statusOverrideProvider) ?? ref.watch(appStatusProvider).asData?.value);
