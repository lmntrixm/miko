import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/data/discovery_providers.dart';
import 'package:miko/data/discovery_repository.dart';
import 'package:miko/data/downloads.dart';

import 'package:miko/widgets/miko_chip.dart';

import 'helpers.dart';

Future<void> typeQuery(WidgetTester tester, String q) async {
  await tester.enterText(find.byType(TextField), q);
  await tester.pump(const Duration(milliseconds: 400)); // debounce
  await tester.pumpAndSettle();
}

void main() {
  test('edit distance', () {
    expect(editDistance('kitten', 'sitting'), 3);
    expect(editDistance('abc', 'abc'), 0);
  });

  testWidgets('search: results, filters, sort, recent searches', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('جستجو'));
    await tester.pumpAndSettle();
    expect(find.text('نام یک اثر را بنویسید؛ فارسی یا انگلیسی.'), findsOneWidget);

    await typeQuery(tester, 'dawn');
    expect(find.text('۱ نتیجه برای «dawn»'), findsOneWidget);
    expect(find.text('Dawn Blade'), findsOneWidget);

    await typeQuery(tester, 'a'); // matches several
    expect(find.textContaining('نتیجه برای «a»'), findsOneWidget);
    await tester.tap(find.widgetWithText(MikoChip, 'کامیک'));
    await tester.pumpAndSettle();
    expect(find.text('Iron Harbor'), findsOneWidget);
    expect(find.text('Dawn Blade'), findsNothing);

    await tester.tap(find.widgetWithText(MikoChip, 'کامیک')); // toggle off
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MikoChip, 'انگلیسی'));
    await tester.pumpAndSettle();
    expect(find.text('Paper Moon'), findsNothing); // Persian-only in the mock

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(recentSearchesProvider), contains('a'));
  });

  testWidgets('search without results suggests the nearest title and offers a request', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('جستجو'));
    await tester.pumpAndSettle();
    await typeQuery(tester, 'Dawn Blde');
    expect(find.text('نتیجه‌ای برای «Dawn Blde» پیدا نشد'), findsOneWidget);
    expect(find.text('منظورتان این بود؟'), findsOneWidget);
    expect(find.text('شمشیر سپیده'), findsOneWidget);
    await tester.tap(find.text('مشاهده ›'));
    await tester.pumpAndSettle();
    expect(find.textContaining('نتیجه برای «شمشیر سپیده»'), findsOneWidget);

    await typeQuery(tester, 'zzzzqqq');
    await tester.tap(find.text('درخواست افزودن اثر'));
    await tester.pumpAndSettle();
    expect(find.text('درخواست اثر جدید'), findsOneWidget);
    expect(find.text('zzzzqqq'), findsOneWidget); // name carried over
  });

  testWidgets('request a title and vote', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('افزودن'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ثبت درخواست'));
    await tester.pumpAndSettle();
    expect(find.text('نام اثر را بنویسید'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'My Wish');
    await tester.tap(find.text('مانهوا'));
    await tester.tap(find.text('انگلیسی'));
    await tester.tap(find.text('ثبت درخواست'));
    await tester.pumpAndSettle();
    expect(find.textContaining('درخواست ثبت شد'), findsOneWidget);
    expect(find.text('My Wish'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('رأی به Sample Request A'));
    await tester.pumpAndSettle();
    expect(find.text('۴۱۳ رأی · در حال بررسی'), findsOneWidget);
  });

  testWidgets('list-all sorts and shows ranks', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/list-all');
    await tester.pumpAndSettle();
    expect(find.text('محبوب‌ترین‌ها'), findsWidgets);
    expect(find.text('بازه:'), findsOneWidget);
    await tester.tap(find.text('بروزترین‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('بازه:'), findsNothing);
  });

  testWidgets('author page: reached from detail, follow persists', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/home/title/dawn-blade');
    await tester.pumpAndSettle();
    await tester.tap(find.text('نویسنده: نویسنده نمونه ›'));
    await tester.pumpAndSettle();
    expect(find.text('نویسنده نمونه'), findsWidgets);
    expect(find.text('[معرفی کوتاه نویسنده]'), findsOneWidget);
    expect(find.text('۸'), findsOneWidget); // works in the app
    await tester.tap(find.text('دنبال کردن نویسنده'));
    await tester.pumpAndSettle();
    expect(find.text('دنبال می‌کنید'), findsOneWidget);
    expect(containerOf(tester).read(followedAuthorsProvider), contains('sample-author'));
  });

  testWidgets('maintenance replaces the app; downloaded chapters stay reachable', (tester) async {
    await pumpHome(tester, appStatus: const AppStatus(maintenance: true, maintenanceUntil: '04:30'));
    expect(find.text('در حال به‌روزرسانی سرورها'), findsOneWidget);
    expect(find.textContaining('۰۴:۳۰'), findsOneWidget);
    expect(find.textContaining('[کانال یا صفحه اطلاع‌رسانی]'), findsOneWidget);
    await tester.tap(find.text('خواندن چپترهای دانلودشده'));
    await tester.pumpAndSettle();
    expect(find.text('دانلودها'), findsWidgets);
    expect(containerOf(tester).read(downloadsProvider).done, isEmpty);
  });

  testWidgets('forced update blocks, optional update can be dismissed once', (tester) async {
    await pumpHome(tester, appStatus: const AppStatus(update: UpdateKind.forced, newVersion: '1.5'));
    expect(find.text('نسخه جدید آماده است'), findsOneWidget);
    expect(find.text('بعداً'), findsNothing);
  });

  testWidgets('optional update shows release notes and stays dismissed', (tester) async {
    await pumpHome(tester, appStatus: const AppStatus(update: UpdateKind.optional, newVersion: '1.5', releaseNotes: ['حالت وبتون با فیلتر شب']));
    expect(find.text('تازه‌های نسخه ۱.۵'), findsOneWidget);
    expect(find.textContaining('فیلتر شب'), findsOneWidget);
    await tester.tap(find.text('بعداً'));
    await tester.pumpAndSettle();
    expect(find.text('نسخه جدید آماده است'), findsNothing);
    expect(find.text('سلام امیر حسین'), findsOneWidget);
    expect(containerOf(tester).read(dismissedUpdateProvider), '1.5');
  });
}
