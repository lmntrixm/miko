import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/data/account_providers.dart';
import 'package:miko/data/account_repository.dart';
import 'package:miko/data/providers.dart';
import 'package:miko/widgets/miko_switch.dart';

import 'helpers.dart';

void main() {
  testWidgets('profile tab shows account, subscription, stats; theme choice persists; logout asks first', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('پروفایل'));
    await tester.pumpAndSettle();
    expect(find.text('امیر حسین'), findsOneWidget);
    expect(find.text('demo@miko.test'), findsOneWidget);
    expect(find.text('اشتراک سه ماهه'), findsOneWidget);
    expect(find.text('۲۶ روز از اشتراک شما باقی مانده است'), findsOneWidget);
    expect(find.text('۳۲۴'), findsOneWidget);
    expect(find.text('تیره'), findsOneWidget);

    await tester.tap(find.text('ظاهر برنامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('روشن').last);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(themeModeProvider), ThemeMode.light);
    expect(containerOf(tester).read(sharedPrefsProvider).getString('theme_mode'), 'light');

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروج از حساب'));
    await tester.pumpAndSettle();
    expect(find.text('خروج از حساب'), findsWidgets);
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(find.text('امیر حسین'), findsOneWidget); // still signed in
    await tester.tap(find.text('خروج از حساب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروج'));
    await tester.pumpAndSettle();
    expect(find.text('برای استفاده از برنامه ایمیل و رمز عبور خود را وارد کنید:'), findsOneWidget);
  });

  testWidgets('notifications: unread, open target, mark all read clears the badge', (tester) async {
    await pumpHome(tester);
    final c = containerOf(tester);
    expect(await c.read(unreadCountProvider.future), 2);
    routerOf(tester).push('/notifications');
    await tester.pumpAndSettle();
    expect(find.text('امروز'), findsOneWidget);
    expect(find.text('این هفته'), findsOneWidget);
    expect(find.text('چپتر جدید شمشیر سپیده'), findsOneWidget);
    await tester.tap(find.text('همه خوانده شد'));
    await tester.pumpAndSettle();
    expect(await c.read(unreadCountProvider.future), 0);

    await tester.tap(find.text('چپتر جدید شمشیر سپیده'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets); // opened chapter 243
  });

  testWidgets('notification settings persist, quiet hours show Persian clock', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/notification-settings');
    await tester.pumpAndSettle();
    expect(find.text('از ۲۳:۰۰'), findsOneWidget);
    expect(find.text('تا ۰۸:۰۰'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('تخفیف‌ها و پیشنهادها'));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(notificationPrefsProvider).promo, isTrue);
    expect(containerOf(tester).read(sharedPrefsProvider).getString('notification_prefs'), contains('"promo":true'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MikoSwitch).last);
    await tester.pumpAndSettle();
    expect(find.text('از ۲۳:۰۰'), findsNothing);
  });

  testWidgets('edit profile validates, rejects a wrong current password, saves the name', (tester) async {
    final account = MockAccountRepository(latency: Duration.zero);
    await pumpHome(tester, account: account);
    routerOf(tester).push('/edit-profile');
    await tester.pumpAndSettle();
    expect(find.text('تاییدشده'), findsOneWidget);

    await tester.tap(find.text('تغییر رمز عبور'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'wrong-pass');
    await tester.enterText(fields.at(2), 'newpassword1');
    await tester.enterText(fields.at(3), 'different11');
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect(find.text('تکرار رمز با رمز جدید یکی نیست'), findsOneWidget);

    await tester.enterText(fields.at(3), 'newpassword1');
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect(find.text('رمز فعلی درست نیست'), findsOneWidget);

    await tester.enterText(fields.at(0), 'نام تازه');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();
    expect((await account.profile()).name, 'نام تازه');
    expect(find.text('سلام نام تازه'), findsOneWidget); // greeting follows the profile
  });

  testWidgets('delete account needs confirmation and signs out', (tester) async {
    final account = MockAccountRepository(latency: Duration.zero);
    await pumpHome(tester, account: account);
    routerOf(tester).push('/edit-profile');
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف دائمی حساب کاربری'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(account.deleted, isFalse);
    await tester.tap(find.text('حذف دائمی حساب کاربری'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف دائمی حساب').last);
    await tester.pumpAndSettle();
    expect(account.deleted, isTrue);
    expect(find.text('برای استفاده از برنامه ایمیل و رمز عبور خود را وارد کنید:'), findsOneWidget);
  });

  testWidgets('invite: copy code, share text carries the placeholder link, gift redemption', (tester) async {
    final share = FakeShare();
    String? clip;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clip = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await pumpHome(tester, share: share);
    routerOf(tester).push('/invite');
    await tester.pumpAndSettle();
    expect(find.text('AMIR-7K2Q'), findsOneWidget);
    expect(find.text('هر دوست = ۷ روز رایگان'), findsOneWidget);
    await tester.tap(find.text('کپی'));
    await tester.pumpAndSettle();
    expect(clip, 'AMIR-7K2Q');
    await tester.tap(find.text('اشتراک‌گذاری لینک دعوت'));
    await tester.pumpAndSettle();
    expect(share.shared.single, allOf(contains('AMIR-7K2Q'), contains('[لینک دانلود]')));

    await tester.enterText(find.byType(TextField), 'NOPE');
    await tester.tap(find.text('فعال‌سازی'));
    await tester.pumpAndSettle();
    expect(find.textContaining('این کد معتبر نیست'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'gift-test');
    await tester.tap(find.text('فعال‌سازی'));
    await tester.pumpAndSettle();
    expect(find.textContaining('۳۰ روز به اشتراک شما اضافه شد'), findsOneWidget);
    expect(find.text('۴۴ روز'), findsOneWidget); // 14 + 30
  });

  testWidgets('help center: accordion, search, support email stays a placeholder', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/help-center');
    await tester.pumpAndSettle();
    expect(find.textContaining('تراکنش ناموفق حداکثر تا ۷۲ ساعت'), findsOneWidget);
    await tester.tap(find.text('دانلودها کجا ذخیره می‌شوند؟'));
    await tester.pumpAndSettle();
    expect(find.textContaining('روی همین دستگاه'), findsOneWidget);
    expect(find.textContaining('تراکنش ناموفق حداکثر تا ۷۲ ساعت'), findsNothing);
    await tester.enterText(find.byType(TextField), 'حذف');
    await tester.pumpAndSettle();
    expect(find.text('چطور حسابم را حذف کنم؟'), findsOneWidget);
    expect(find.text('دانلودها کجا ذخیره می‌شوند؟'), findsNothing);
    expect(find.textContaining('[ایمیل پشتیبانی]'), findsOneWidget);
  });

  testWidgets('report a problem from the reader keeps chapter and page', (tester) async {
    final account = MockAccountRepository(latency: Duration.zero);
    await pumpHome(tester, account: account);
    routerOf(tester).push('/reader/dawn-blade~5');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('تنظیمات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('گزارش مشکل همین صفحه'));
    await tester.pumpAndSettle();
    expect(find.textContaining('شمشیر سپیده · چپتر ۵'), findsOneWidget);
    expect(find.textContaining('صفحه ۱'), findsOneWidget);

    await tester.tap(find.text('مورد دیگر'));
    await tester.pump();
    await tester.tap(find.text('ارسال گزارش'));
    await tester.pumpAndSettle();
    expect(find.textContaining('لطفاً توضیح بنویسید'), findsOneWidget);

    await tester.tap(find.text('ترجمه اشتباه'));
    await tester.enterText(find.byType(TextField), 'نام شخصیت اشتباه است');
    await tester.tap(find.text('ارسال گزارش'));
    await tester.pumpAndSettle();
    expect(account.reports.single.kind, ProblemKind.translation);
    expect(account.reports.single.chapterId, 'dawn-blade~5');
    expect(account.reports.single.page, 0);
  });

  testWidgets('legal: tabs; unprovided texts are placeholders and the legal-review notice is shown', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/legal');
    await tester.pumpAndSettle();
    expect(find.textContaining('مشاور حقوقی'), findsOneWidget);
    await tester.tap(find.text('حریم خصوصی'));
    await tester.pumpAndSettle();
    expect(find.text('[متن حریم خصوصی]'), findsOneWidget);
  });

  testWidgets('profile → language & genres edit opens pre-filled and saves back', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/onboarding-prefs?edit=1');
    await tester.pumpAndSettle();
    expect(find.text('ذخیره'), findsOneWidget);
    expect(find.text('رد شدن'), findsNothing);
    // Pre-filled with 3 genres: save is enabled immediately.
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('علاقه‌مندی‌ها ذخیره شد'), findsOneWidget);
  });
}
