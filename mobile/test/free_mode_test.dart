import 'package:flutter_test/flutter_test.dart';
import 'package:miko/core/app_config.dart';

import 'helpers.dart';

void main() {
  tearDown(() => AppConfig.freeMode = false);

  testWidgets('free mode: chapter past the 3 free ones opens without a subscription', (tester) async {
    await pumpHome(tester, subscribed: false, freeMode: true);
    expect(find.textContaining('خرید اشتراک'), findsNothing);
    routerOf(tester).push('/reader/dawn-blade~10');
    await tester.pumpAndSettle();
    expect(find.textContaining('ادامه این چپتر با اشتراک'), findsNothing);
    expect(routerOf(tester).state.uri.path, '/reader/dawn-blade~10');
  });

  testWidgets('paid mode still sends chapter 10 to the paywall', (tester) async {
    await pumpHome(tester, subscribed: false);
    routerOf(tester).push('/reader/dawn-blade~10');
    await tester.pumpAndSettle();
    expect(find.text('ادامه این چپتر با اشتراک'), findsOneWidget);
  });
}
