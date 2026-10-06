import 'persian.dart';

/// 480 → «۴۸۰ مگابایت», 1228 → «۱٫۲ گیگابایت».
String faSize(double mb) {
  if (mb >= 1024) {
    return '${faDigits((mb / 1024).toStringAsFixed(1).replaceAll('.', '٫'))} گیگابایت';
  }
  return '${faDigits(mb.round())} مگابایت';
}
