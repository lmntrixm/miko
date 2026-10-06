import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/data/models.dart';

import 'helpers.dart';

/// Pending screen has an endless spinner, so settle by pumping time instead.
Future<void> settleFor(WidgetTester tester, {int seconds = 4}) async {
  for (var i = 0; i < seconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  testWidgets('locked chapter → paywall → subscription → bank → pending → success → reading', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/home/title/dawn-blade');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('#241'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('#241'));
    await tester.pumpAndSettle();

    expect(find.text('ادامه این چپتر با اشتراک'), findsOneWidget);
    expect(find.textContaining('شمشیر سپیده · چپتر ۲۴۱'), findsOneWidget);
    expect(find.textContaining('همه ۲۴۲ چپتر'), findsOneWidget);
    expect(find.text('[قیمت]'), findsNWidgets(3)); // prices are placeholders, never invented
    await tester.tap(find.text('یک ماهه'));
    await tester.pump();
    await tester.tap(find.text('خرید اشتراک و ادامه خواندن'));
    await tester.pumpAndSettle();

    expect(find.text('خرید اشتراک'), findsOneWidget);
    expect(find.text('پرداخت از درگاه بانکی'), findsOneWidget);
    expect(find.textContaining('لغو تمدید در هر زمان'), findsOneWidget);
    await tester.tap(find.text('پرداخت از درگاه بانکی'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('در حال بررسی پرداخت'), findsWidgets);
    await settleFor(tester);
    expect(find.text('اشتراک یک ماهه فعال شد'), findsOneWidget);
    expect(find.text('[مبلغ] تومان'), findsOneWidget);
    expect(find.text('A-000281735'), findsOneWidget);

    await tester.tap(find.text('ادامه خواندن ۲۴۱ #'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets);
  });

  testWidgets('invalid coupon explains itself, valid coupon is accepted', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/subscription');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'NOPE');
    await tester.tap(find.text('اعمال'));
    await tester.pumpAndSettle();
    expect(find.textContaining('این کد معتبر نیست'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'welcome');
    await tester.tap(find.text('اعمال'));
    await tester.pumpAndSettle();
    expect(find.text('کد تخفیف اعمال شد'), findsOneWidget);
  });

  testWidgets('failed payment shows reassurance and a retry', (tester) async {
    await pumpHome(tester, subscribed: false, checkoutResult: PaymentStatus.failed);
    routerOf(tester).push('/subscription');
    await tester.pumpAndSettle();
    await tester.tap(find.text('پرداخت از درگاه بانکی'));
    await tester.pump();
    await settleFor(tester);
    expect(find.text('پرداخت انجام نشد'), findsOneWidget);
    expect(find.textContaining('تا ۷۲ ساعت برمی‌گردد'), findsOneWidget);
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(find.text('پرداخت از درگاه بانکی'), findsOneWidget);
  });

  testWidgets('manage subscription: turning off auto-renew asks first', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('۲۶ روز از اشتراک باقی مانده'));
    await tester.pumpAndSettle();
    expect(find.text('مدیریت اشتراک'), findsOneWidget);
    expect(find.text('سه ماهه'), findsOneWidget);
    expect(find.textContaining('تمدید خودکار در'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('تمدید خودکار'));
    await tester.pumpAndSettle();
    expect(find.text('تمدید خودکار خاموش شود؟'), findsOneWidget);
    await tester.tap(find.text('نگه داشتن تمدید'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تمدید خودکار در'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('تمدید خودکار'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خاموش کردن تمدید'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تمدید نمی‌شود'), findsOneWidget);
  });

  testWidgets('payment history lists statuses and the active plan', (tester) async {
    await pumpHome(tester);
    routerOf(tester).push('/payment-history');
    await tester.pumpAndSettle();
    expect(find.text('اشتراک فعلی'), findsOneWidget);
    expect(find.text('موفق'), findsOneWidget);
    expect(find.text('ناموفق'), findsOneWidget);
    expect(find.text('برگشت داده شد'), findsOneWidget);
    expect(find.text('A-000281730'), findsOneWidget);
  });

  testWidgets('free chapter link on the paywall opens chapter 1', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/paywall?chapter=dawn-blade~50');
    await tester.pumpAndSettle();
    await tester.tap(find.text('خواندن چپتر ۱ رایگان'));
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحه ۱ از'), findsWidgets);
  });

  testWidgets('restore purchase tells the user when nothing was found', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/paywall');
    await tester.pumpAndSettle();
    await tester.tap(find.text('بازیابی خرید قبلی'));
    await tester.pumpAndSettle();
    expect(find.textContaining('خرید قبلی پیدا نشد'), findsOneWidget);
  });
}
