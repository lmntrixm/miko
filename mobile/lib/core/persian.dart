/// Persian digits and number formatting. Latin text (English titles, `#242`,
/// emails, tracking codes) must NOT go through these helpers.
const _fa = '۰۱۲۳۴۵۶۷۸۹';

String faDigits(Object value) =>
    value.toString().replaceAllMapped(RegExp(r'\d'), (m) => _fa[int.parse(m[0]!)]);

/// 1234567 → ۱٬۲۳۴٬۵۶۷
String faNumber(num n) {
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') buf.write('٬');
    buf.write(s[i]);
  }
  return faDigits(buf);
}

/// 12400 → ۱۲٫۴K style compact counts.
String faCompact(num n) {
  if (n >= 1000000) return '${faDigits((n / 1e6).toStringAsFixed(1).replaceAll('.', '٫'))}M';
  if (n >= 1000) return '${faDigits((n / 1e3).toStringAsFixed(1).replaceAll('.', '٫'))}K';
  return faDigits(n.round());
}
