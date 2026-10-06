import 'package:flutter_test/flutter_test.dart';
import 'package:miko/core/jalali.dart';
import 'package:miko/core/persian.dart';
import 'package:miko/main.dart';

void main() {
  test('Persian digits and grouping', () {
    expect(faDigits(242), '۲۴۲');
    expect(faNumber(1234567), '۱٬۲۳۴٬۵۶۷');
  });

  test('Jalali conversion', () {
    expect(Jalali.fromDateTime(DateTime(2026, 9, 28)).format(), '۶ مهر ۱۴۰۵');
    expect(Jalali.fromDateTime(DateTime(2026, 3, 21)).formatNumeric(), '۱۴۰۵/۰۱/۰۱');
  });

  testWidgets('gallery renders RTL with both themes', (tester) async {
    await tester.pumpWidget(const MikoApp());
    expect(find.text('کامپوننت‌های میکو'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('تغییر تم'));
    await tester.pump();
    expect(find.text('کامپوننت‌های میکو'), findsOneWidget);
  });
}
