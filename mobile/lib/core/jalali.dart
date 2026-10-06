import 'persian.dart';

/// Gregorian → Jalali (Persian) calendar, algorithm by jalaali-js.
class Jalali {
  const Jalali(this.year, this.month, this.day);
  final int year, month, day;

  static const monthNames = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  factory Jalali.fromDateTime(DateTime d) {
    final gy = d.year, gm = d.month, gd = d.day;
    const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    final gy2 = gm > 2 ? gy + 1 : gy;
    var days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gdm[gm - 1];
    var jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    final jm = days < 186 ? 1 + days ~/ 31 : 7 + (days - 186) ~/ 30;
    final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
    return Jalali(jy, jm, jd);
  }

  /// ۶ مهر ۱۴۰۵
  String format() => '${faDigits(day)} ${monthNames[month - 1]} ${faDigits(year)}';

  /// ۱۴۰۵/۰۷/۰۶
  String formatNumeric() =>
      faDigits('$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}');
}
