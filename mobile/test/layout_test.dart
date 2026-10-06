import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Screens that must survive 160% system font size, tablets and landscape without overflow.
const _routes = [
  '/home',
  '/library',
  '/profile',
  '/search',
  '/request-title',
  '/home/title/dawn-blade',
  '/home/title/iron-harbor',
  '/reader/dawn-blade~242',
  '/comments/dawn-blade~242',
  '/comment-thread/c1',
  '/notifications',
  '/notification-settings',
  '/edit-profile',
  '/invite',
  '/help-center',
  '/report-problem?chapter=dawn-blade~5&page=1&lang=fa',
  '/legal',
  '/downloads',
  '/list-all',
  '/author/sample-author',
  '/paywall?chapter=dawn-blade~242',
  '/subscription',
  '/payment-history',
  '/manage-subscription',
  '/onboarding-prefs?edit=1',
];

/// Visits every route and fails once with the full list of overflowing screens.
Future<void> visitAll(WidgetTester tester, {required Size size, double textScale = 1}) async {
  await pumpHome(tester);
  tester.view.physicalSize = size * 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final r = routerOf(tester);
  final problems = <String>[];
  final original = FlutterError.onError;
  var current = '';
  FlutterError.onError = (d) {
    final msg = '$current: ${d.exceptionAsString().split('\n').first}';
    if (!problems.contains(msg)) problems.add(msg);
  };
  addTearDown(() => FlutterError.onError = original);
  for (final route in _routes) {
    current = route;
    r.go(route);
    await tester.pumpAndSettle();
    tester.takeException();
  }
  FlutterError.onError = original;
  expect(problems, isEmpty, reason: '$size ×$textScale');
}

void main() {
  testWidgets('every screen survives 160% font size', (tester) async {
    await visitAll(tester, size: const Size(390, 844), textScale: 1.6);
  });

  testWidgets('small phone (320 wide) at 130% font', (tester) async {
    await visitAll(tester, size: const Size(320, 640), textScale: 1.3);
  });

  testWidgets('tablet portrait and landscape', (tester) async {
    await visitAll(tester, size: const Size(834, 1194));
    await visitAll(tester, size: const Size(1194, 834));
  });

  testWidgets('phone landscape', (tester) async {
    await visitAll(tester, size: const Size(844, 390));
  });
}
