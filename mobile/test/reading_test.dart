import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('home greets, shows subscription and switches type', (tester) async {
    await pumpHome(tester);
    expect(find.text('سلام امیر حسین'), findsOneWidget);
    expect(find.text('۲۶ روز از اشتراک باقی مانده'), findsOneWidget);
    expect(find.text('بروزترین مانگاها'), findsOneWidget);
    await tester.tap(find.text('مانهوا'));
    await tester.pumpAndSettle();
    expect(find.text('بروزترین مانهواها'), findsOneWidget);
    expect(find.text('پیک شب'), findsWidgets);
  });

  testWidgets('home → detail → reader resumes mid-chapter; RTL taps go forward on the left', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/home/title/dawn-blade');
    await tester.pumpAndSettle();
    expect(find.text('Dawn Blade'), findsOneWidget);
    await tester.tap(find.textContaining('ادامه خواندن'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۳ از'), findsWidgets);
    expect(find.textContaining('ادامه دادیم'), findsOneWidget);

    // Manga is right-to-left: forward = tap the left edge.
    await tester.tapAt(const Offset(10, 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۴ از'), findsWidgets);
    // Tap the center toggles the bars.
    await tester.tapAt(const Offset(195, 400));
    await tester.pumpAndSettle();
  });

  testWidgets('comic direction setting flips paging to left-to-right', (tester) async {
    await pumpHome(tester, prefs: {'reader_settings': '{"rtl":false}'});
    routerOf(tester).push('/reader/dawn-blade~5');
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets);
    await tester.tapAt(const Offset(10, 400)); // left = back, already first page
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets);
    await tester.tapAt(const Offset(380, 400)); // right = forward
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۲ از'), findsWidgets);
  });

  testWidgets('free user is sent to the paywall from a locked chapter', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/home/title/dawn-blade');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('#241'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('#241'));
    await tester.pumpAndSettle();
    expect(find.text('ادامه این چپتر با اشتراک'), findsOneWidget);
    // The reader itself also refuses locked chapters (402).
    routerOf(tester).pushReplacement('/reader/dawn-blade~10');
    await tester.pumpAndSettle();
    expect(find.text('ادامه این چپتر با اشتراک'), findsOneWidget);
  });

  testWidgets('free chapters stay readable without a subscription', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/reader/dawn-blade~2');
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets);
  });

  testWidgets('reader settings persist the chosen layout', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/reader/dawn-blade~5');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('تنظیمات'));
    await tester.pumpAndSettle();
    expect(find.text('تنظیمات خواندن'), findsOneWidget);
    await tester.tap(find.text('وبتون'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اعمال تنظیمات'));
    await tester.pumpAndSettle();
    expect(find.text('دوزبانه'), findsOneWidget); // webtoon language toggle
  });

  testWidgets('comments: sort, like, spoiler, post and replies', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/comments/dawn-blade~242');
    await tester.pumpAndSettle();
    expect(find.text('نظرات'), findsOneWidget);
    expect(find.textContaining('این نظر حاوی اسپویل است'), findsOneWidget);
    expect(find.textContaining('مرگ شخصیت اصلی'), findsNothing);
    await tester.tap(find.textContaining('این نظر حاوی اسپویل است'));
    await tester.pumpAndSettle();
    expect(find.textContaining('مرگ شخصیت اصلی'), findsOneWidget);

    await tester.tap(find.text('جدیدترین'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'نظر آزمایشی من');
    await tester.tap(find.bySemanticsLabel('ارسال نظر'));
    await tester.pumpAndSettle();
    expect(find.text('نظر آزمایشی من'), findsOneWidget);

    await tester.tap(find.text('پاسخ (۳)'));
    await tester.pumpAndSettle();
    expect(find.text('پاسخ‌ها'), findsOneWidget);
    expect(find.textContaining('چپتر بعدی امشب'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'پاسخ من');
    await tester.tap(find.bySemanticsLabel('ارسال نظر'));
    await tester.pumpAndSettle();
    expect(find.text('پاسخ من'), findsOneWidget);
  });
}
