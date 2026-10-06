import 'package:flutter_test/flutter_test.dart';
import 'package:miko/data/api_errors.dart';
import 'package:miko/data/providers.dart';

import 'helpers.dart';

void main() {
  testWidgets('401 clears the session and sends the user to login', (tester) async {
    await pumpHome(tester, failure: const UnauthorizedException());
    expect(containerOf(tester).read(sessionProvider).signedIn, isFalse);
    expect(find.text('برای استفاده از برنامه ایمیل و رمز عبور خود را وارد کنید:'), findsOneWidget);
    expect(find.text('نشست شما منقضی شده؛ دوباره وارد شوید.'), findsOneWidget);
  });

  testWidgets('503 shows the maintenance screen', (tester) async {
    await pumpHome(tester, failure: const MaintenanceException(until: '04:30'));
    expect(find.text('در حال به‌روزرسانی سرورها'), findsOneWidget);
    expect(find.textContaining('۰۴:۳۰'), findsOneWidget);
  });

  testWidgets('426 forces an update', (tester) async {
    await pumpHome(tester, failure: const UpgradeRequiredException(newVersion: '2.0'));
    expect(find.text('نسخه جدید آماده است'), findsOneWidget);
    expect(find.text('بعداً'), findsNothing);
  });

  testWidgets('network failure stays on screen with a retry that recovers', (tester) async {
    await pumpHome(tester, failure: const NetworkException());
    expect(find.textContaining('اتصال اینترنت قطع است. اتصال را بررسی کنید'), findsOneWidget);
    expect(find.text('تلاش دوباره'), findsOneWidget);
  });

  testWidgets('unknown failures use a generic cause + fix message, no codes', (tester) async {
    await pumpHome(tester, failure: StateError('boom'));
    expect(find.textContaining('دوباره امتحان کنید'), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
  });
}
