import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/data/content_providers.dart';
import 'package:miko/data/downloads.dart';
import 'package:miko/data/network.dart';

import 'helpers.dart';

/// Opens the reader on [chapterId], taps download, then returns to home.
Future<void> downloadFromReader(WidgetTester tester, String chapterId) async {
  routerOf(tester).push('/reader/$chapterId');
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel('دانلود'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('library lists reading progress and resumes a chapter', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('کتابخانه'));
    await tester.pumpAndSettle();
    expect(find.text('کتابخانه من'), findsOneWidget);
    expect(find.text('شمشیر سپیده'), findsOneWidget);
    expect(find.text('دروازهٔ خاموش'), findsOneWidget);
    expect(find.textContaining('انگلیسی'), findsOneWidget); // Star Cafe read in EN
    await tester.tap(find.text('شمشیر سپیده'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۳ از'), findsWidgets);
  });

  testWidgets('empty library invites discovery', (tester) async {
    await pumpHome(tester, seedProgress: false);
    await tester.tap(find.bySemanticsLabel('کتابخانه'));
    await tester.pumpAndSettle();
    expect(find.text('هنوز چیزی نخوانده‌اید'), findsOneWidget);
    await tester.tap(find.text('کشف آثار محبوب'));
    await tester.pumpAndSettle();
    expect(find.text('سلام امیر حسین'), findsOneWidget);
  });

  testWidgets('bookmarks persist and show in the library', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/home/title/silent-gate');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('نشان کردن'));
    await tester.pumpAndSettle();
    routerOf(tester).go('/library');
    await tester.pumpAndSettle();
    await tester.tap(find.text('نشان‌شده'));
    await tester.pumpAndSettle();
    expect(find.text('Silent Gate'), findsOneWidget);
    expect(containerOf(tester).read(bookmarksProvider).contains('silent-gate'), isTrue);
  });

  testWidgets('download: queue → progress → done → delete, announced on completion', (tester) async {
    await pumpHome(tester);
    await downloadFromReader(tester, 'dawn-blade~242');
    expect(find.textContaining('شروع شد'), findsOneWidget);

    final c = containerOf(tester);
    expect(c.read(downloadsProvider).active.length, 1);
    for (var i = 0; i < 10; i++) {
      c.read(downloadsProvider.notifier).tick();
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // old snackbar leaves, new one enters
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.read(downloadsProvider).done.length, 1);
    expect(find.textContaining('کامل شد'), findsOneWidget);

    routerOf(tester).go('/downloads');
    await tester.pumpAndSettle();
    expect(find.text('دانلودها'), findsWidgets);
    expect(find.textContaining('تا پایان اشتراک'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('حذف دانلودها'), findsOneWidget);
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(c.read(downloadsProvider).done, isEmpty);
  });

  testWidgets('wifi-only holds downloads on mobile data', (tester) async {
    final net = FakeConnectivity(NetworkStatus.mobile);
    await pumpHome(tester, net: net);
    await downloadFromReader(tester, 'dawn-blade~242');
    final c = containerOf(tester);
    c.read(downloadsProvider.notifier).tick();
    expect(c.read(downloadsProvider).active.single.progress, 0); // waiting for wifi

    c.read(downloadsProvider.notifier).setWifiOnly(false);
    c.read(downloadsProvider.notifier).tick();
    expect(c.read(downloadsProvider).active.single.progress, greaterThan(0));
  });

  testWidgets('free users are sent to the paywall; 3rd device gets a clear dialog', (tester) async {
    await pumpHome(tester, subscribed: false);
    await downloadFromReader(tester, 'dawn-blade~2');
    expect(find.text('اشتراک'), findsOneWidget); // paywall stub
  });

  testWidgets('device limit (409) explains what to do', (tester) async {
    await pumpHome(tester, deviceLimitReached: true);
    await downloadFromReader(tester, 'dawn-blade~242');
    expect(find.text('سقف دستگاه‌ها پر است'), findsOneWidget);
  });

  testWidgets('offline: home becomes the offline view and only downloaded chapters open', (tester) async {
    final net = FakeConnectivity();
    await pumpHome(tester, net: net);
    await downloadFromReader(tester, 'dawn-blade~242');
    final c = containerOf(tester);
    for (var i = 0; i < 10; i++) {
      c.read(downloadsProvider.notifier).tick();
    }
    routerOf(tester).go('/home');
    await tester.pumpAndSettle();

    net.set(NetworkStatus.offline);
    await tester.pumpAndSettle();
    expect(find.text('بدون اینترنت هم بخوانید'), findsOneWidget);
    expect(find.text('اتصال اینترنت قطع است'), findsOneWidget);
    expect(find.text('آفلاین'), findsOneWidget);

    await tester.tap(find.text('شمشیر سپیده'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets); // opened from the download

    routerOf(tester).pushReplacement('/reader/dawn-blade~100');
    await tester.pumpAndSettle();
    expect(find.text('این چپتر دانلود نشده'), findsOneWidget);

    net.set(NetworkStatus.wifi);
    await tester.pumpAndSettle();
  });
}
