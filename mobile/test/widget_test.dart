import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miko/core/jalali.dart';
import 'package:miko/core/persian.dart';
import 'package:miko/core/validators.dart';
import 'package:miko/data/auth_repository.dart';
import 'package:miko/data/providers.dart';
import 'package:miko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(p),
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(latency: Duration.zero),
        ),
      ],
      child: const MikoApp(),
    ),
  );
}

void main() {
  test('Persian digits and grouping', () {
    expect(faDigits(242), '۲۴۲');
    expect(faNumber(1234567), '۱٬۲۳۴٬۵۶۷');
  });

  test('Jalali conversion', () {
    expect(Jalali.fromDateTime(DateTime(2026, 9, 28)).format(), '۶ مهر ۱۴۰۵');
    expect(
      Jalali.fromDateTime(DateTime(2026, 3, 21)).formatNumeric(),
      '۱۴۰۵/۰۱/۰۱',
    );
  });

  test('validators', () {
    expect(normalizeDigits('۱۲۳٤٥٦'), '123456');
    expect(validateEmail('x'), isNotNull);
    expect(validateEmail('name@gmail.com'), isNull);
    expect(validatePassword('1234567'), isNotNull);
    expect(validatePassword('12345678'), isNull);
  });

  testWidgets('first launch: splash → intro → login', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('کاملترین آرشیو'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('بعدی'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('بعدی'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('شروع'));
    await tester.pumpAndSettle();
    expect(find.text('ورود'), findsOneWidget);
  });

  testWidgets('existing user logs in straight to home, no OTP', (tester) async {
    await pumpApp(tester, prefs: {'onboarding_seen': true});
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'demo@miko.test');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();
    expect(find.text('صفحه خانه به‌زودی'), findsOneWidget);
  });

  testWidgets('login shows validation and credential errors', (tester) async {
    await pumpApp(tester, prefs: {'onboarding_seen': true});
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ورود'));
    await tester.pump();
    expect(find.text('ایمیل را وارد کنید'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'demo@miko.test');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-pass');
    await tester.tap(find.text('ورود'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ایمیل یا رمز عبور درست نیست'), findsOneWidget);
  });

  testWidgets('signup → OTP → preferences → home', (tester) async {
    await pumpApp(tester, prefs: {'onboarding_seen': true});
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ثبت نام'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'کاربر نمونه');
    await tester.enterText(find.byType(TextField).at(1), 'new@miko.test');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.tap(find.text('ثبت نام').last);
    await tester.pumpAndSettle();
    expect(find.text('کد ارسال‌شده به ایمیل خود را وارد کنید'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '۱۲۳۴۵۶',
    ); // Persian digits accepted
    await tester.pumpAndSettle();
    expect(find.text('چه چیزهایی دوست دارید؟'), findsOneWidget);

    final next = find.widgetWithText(GestureDetector, 'ادامه');
    expect(next, findsWidgets);
    for (final g in ['اکشن', 'فانتزی', 'کمدی']) {
      await tester.tap(find.text(g));
      await tester.pump();
    }
    await tester.tap(find.text('ادامه'));
    await tester.pumpAndSettle();
    expect(find.text('صفحه خانه به‌زودی'), findsOneWidget);
  });

  testWidgets('forgot password runs all 3 steps', (tester) async {
    await pumpApp(tester, prefs: {'onboarding_seen': true});
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رمز خود را فراموش کرده‌اید'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'demo@miko.test');
    await tester.tap(find.text('ارسال کد بازیابی'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('رمز عبور جدید'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'newpassword1');
    await tester.tap(find.text('ثبت رمز جدید'));
    await tester.pumpAndSettle();
    expect(find.text('رمز عبور را وارد کنید'), findsNothing);
    expect(
      find.text('برای استفاده از برنامه ایمیل و رمز عبور خود را وارد کنید:'),
      findsOneWidget,
    );
  });
}
