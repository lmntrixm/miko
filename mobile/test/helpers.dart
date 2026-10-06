import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:miko/data/auth_repository.dart';
import 'package:miko/data/content_providers.dart';
import 'dart:async';

import 'package:miko/data/content_repository.dart';
import 'package:miko/data/downloads.dart';
import 'package:miko/data/network.dart';
import 'package:miko/data/providers.dart';
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
  FakeConnectivity? net,
}) async {
  await loadFonts();
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(p),
      authRepositoryProvider.overrideWithValue(MockAuthRepository(latency: Duration.zero)),
      contentRepositoryProvider.overrideWithValue(MockContentRepository(subscribed: subscribed, latency: Duration.zero, seedProgress: seedProgress, deviceLimitReached: deviceLimitReached)),
      connectivitySourceProvider.overrideWithValue(net ?? FakeConnectivity()),
      downloadAutoTickProvider.overrideWithValue(false),
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
  FakeConnectivity? net,
}) async {
  await pumpApp(tester,
      prefs: {'onboarding_seen': true, 'access_token': 't', ...prefs},
      subscribed: subscribed,
      seedProgress: seedProgress,
      deviceLimitReached: deviceLimitReached,
      net: net);
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

ProviderContainer containerOf(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(MikoApp)));
