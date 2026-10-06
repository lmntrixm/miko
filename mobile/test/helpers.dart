import 'dart:io';

import 'package:miko/core/app_config.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:miko/data/account_providers.dart';
import 'package:miko/data/account_repository.dart';
import 'package:miko/data/auth_repository.dart';
import 'package:miko/data/content_providers.dart';
import 'dart:async';

import 'package:miko/data/content_repository.dart';
import 'package:miko/data/discovery_providers.dart';
import 'package:miko/data/discovery_repository.dart';
import 'package:miko/data/downloads.dart';
import 'package:miko/data/models.dart';
import 'package:miko/features/billing/payment_pending_screen.dart';
import 'package:miko/data/network.dart';
import 'package:miko/data/providers.dart';
import 'package:miko/data/token_store.dart';
import 'package:miko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _fontsLoaded = false;

/// Real Vazirmatn instead of the test font, so overflow checks match the device.
Future<void> loadFonts() async {
  if (_fontsLoaded) return;
  final loader = FontLoader('Vazirmatn');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    final bytes = File('assets/fonts/Vazirmatn-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
  _fontsLoaded = true;
}

class FakeShare implements ShareService {
  final shared = <String>[];
  @override
  Future<void> share(String text) async => shared.add(text);
}

/// Controllable connectivity for tests.
class FakeConnectivity implements ConnectivitySource {
  FakeConnectivity([this.status = NetworkStatus.wifi]);
  NetworkStatus status;
  final _c = StreamController<NetworkStatus>.broadcast();
  void set(NetworkStatus s) {
    status = s;
    _c.add(s);
  }

  @override
  Future<NetworkStatus> current() async => status;
  @override
  Stream<NetworkStatus> changes() => _c.stream;
}

Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool subscribed = true,
  bool seedProgress = true,
  bool deviceLimitReached = false,
  PaymentStatus checkoutResult = PaymentStatus.success,
  FakeConnectivity? net,
  MockAccountRepository? account,
  FakeShare? share,
  AppStatus appStatus = const AppStatus(),
  Object? failure,
  String? tokenValue,
  bool freeMode = false,
}) async {
  await loadFonts();
  AppConfig.freeMode = freeMode;
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    retry: (_, _) => null,
    overrides: [
      sharedPrefsProvider.overrideWithValue(p),
      tokenStoreProvider.overrideWithValue(MemoryTokenStore(tokenValue)),
      authRepositoryProvider.overrideWithValue(MockAuthRepository(latency: Duration.zero)),
      contentRepositoryProvider.overrideWithValue(MockContentRepository(subscribed: subscribed, latency: Duration.zero, seedProgress: seedProgress, deviceLimitReached: deviceLimitReached, checkoutResult: checkoutResult)..failure = failure),
      paymentPollIntervalProvider.overrideWithValue(const Duration(seconds: 1)),
      connectivitySourceProvider.overrideWithValue(net ?? FakeConnectivity()),
      downloadAutoTickProvider.overrideWithValue(false),
      accountRepositoryProvider.overrideWithValue(account ?? MockAccountRepository(latency: Duration.zero)),
      shareServiceProvider.overrideWithValue(share ?? FakeShare()),
      discoveryRepositoryProvider.overrideWith((ref) => MockDiscoveryRepository(ref.watch(contentRepositoryProvider), latency: Duration.zero, status: appStatus)),
    ],
    child: const MikoApp(),
  ));
}

/// Boots a signed-in app on the home screen.
Future<void> pumpHome(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool subscribed = true,
  bool seedProgress = true,
  bool deviceLimitReached = false,
  PaymentStatus checkoutResult = PaymentStatus.success,
  FakeConnectivity? net,
  MockAccountRepository? account,
  FakeShare? share,
  AppStatus appStatus = const AppStatus(),
  Object? failure,
  bool freeMode = false,
}) async {
  await pumpApp(tester,
      freeMode: freeMode,
      tokenValue: 't',
      prefs: {'onboarding_seen': true, ...prefs},
      subscribed: subscribed,
      seedProgress: seedProgress,
      deviceLimitReached: deviceLimitReached,
      checkoutResult: checkoutResult,
      net: net,
      account: account,
      share: share,
      appStatus: appStatus,
      failure: failure);
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MikoApp)));
