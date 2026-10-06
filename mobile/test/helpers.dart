import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:miko/data/auth_repository.dart';
import 'package:miko/data/content_providers.dart';
import 'package:miko/data/content_repository.dart';
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

Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  bool subscribed = true,
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
      contentRepositoryProvider.overrideWithValue(MockContentRepository(subscribed: subscribed, latency: Duration.zero)),
    ],
    child: const MikoApp(),
  ));
}

/// Boots a signed-in app on the home screen.
Future<void> pumpHome(WidgetTester tester, {Map<String, Object> prefs = const {}, bool subscribed = true}) async {
  await pumpApp(tester, prefs: {'onboarding_seen': true, 'access_token': 't', ...prefs}, subscribed: subscribed);
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));
