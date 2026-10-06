/// Converts Persian/Arabic-Indic digits to Latin so codes and numbers typed on a
/// Persian keyboard are accepted.
String normalizeDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    var i = fa.indexOf(ch);
    if (i < 0) i = ar.indexOf(ch);
    b.write(i < 0 ? ch : '$i');
  }
  return b.toString();
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Returns an error message (UXCopy wording) or null when valid.
String? validateEmail(String v) {
  final t = v.trim();
  if (t.isEmpty) return 'ایمیل را وارد کنید';
  return _emailRe.hasMatch(t) ? null : 'ایمیل معتبر نیست؛ مثلاً name@gmail.com';
}

String? validatePassword(String v) {
  if (v.isEmpty) return 'رمز عبور را وارد کنید';
  return v.length >= 8 ? null : 'رمز عبور حداقل ۸ کاراکتر باشد';
}

String? validateName(String v) =>
    v.trim().length >= 2 ? null : 'نام و نام خانوادگی را وارد کنید';
