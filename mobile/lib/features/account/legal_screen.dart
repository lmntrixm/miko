import 'package:flutter/material.dart';

import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_chip.dart';
import 'account_widgets.dart';

class _Section {
  const _Section(this.title, this.body);
  final String title, body;
}

// Structure comes from the design; the final text must be written/approved by a legal advisor.
const _terms = [
  _Section('حساب کاربری', 'هر حساب شخصی است و تا ۲ دستگاه همزمان می‌تواند چپترها را دانلود کند.'),
  _Section('اشتراک و تمدید', 'اشتراک پس از پرداخت فعال می‌شود و در صورت روشن بودن تمدید خودکار، در پایان دوره تمدید می‌شود. لغو تمدید در هر زمان از «مدیریت اشتراک» ممکن است.'),
  _Section('استفاده از محتوا', 'محتوا فقط برای مطالعهٔ شخصی است؛ ذخیره، بازنشر یا فروش صفحات مجاز نیست.'),
  _Section('نظرات', 'نظرات حاوی اسپویل بدون علامت، توهین، تبلیغ یا لینک حذف می‌شوند.'),
];

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  int _tab = 0;
  static const _tabs = ['قوانین', 'حریم خصوصی', 'درباره ما'];

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'قوانین استفاده'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
              MikoSegmented(labels: _tabs, index: _tab, onChanged: (i) => setState(() => _tab = i)),
              const SizedBox(height: MRSpacing.space3),
              Text('آخرین به‌روزرسانی: [تاریخ] · نسخهٔ [۱.۰]', style: MRText.caption.copyWith(color: c.textMuted)),
              const SizedBox(height: MRSpacing.space3),
              if (_tab == 0) ...[
                for (final s in _terms) ...[
                  Semantics(header: true, child: Text(s.title, style: MRText.h2.copyWith(fontSize: 18, color: c.textPrimary))),
                  const SizedBox(height: MRSpacing.space1),
                  Text(s.body, style: MRText.body.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MRSpacing.space4),
                ],
                Container(
                  padding: const EdgeInsets.all(MRSpacing.space4),
                  decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.warning.withValues(alpha: 0.4))),
                  child: Text('متن نهایی این بخش باید توسط مشاور حقوقی نوشته و تأیید شود؛ متن بالا فقط ساختار پیشنهادی است.', style: MRText.body.copyWith(color: c.warning)),
                ),
              ] else
                Text(_tab == 1 ? '[متن حریم خصوصی]' : '[متن دربارهٔ ما]', style: MRText.body.copyWith(color: c.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
