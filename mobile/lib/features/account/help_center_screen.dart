import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

class _Faq {
  const _Faq(this.q, this.a);
  final String q, a;
}

// Answers follow rules already fixed by the design; the release-date answer needs the owner's text.
const _faqs = [
  _Faq('پول کم شد ولی اشتراک فعال نشد', 'اگر تا ۲ دقیقه فعال نشد، از «تاریخچه پرداخت‌ها» وضعیت را ببینید. تراکنش ناموفق حداکثر تا ۷۲ ساعت توسط بانک برگشت داده می‌شود.'),
  _Faq('چطور بین فارسی و انگلیسی جابه‌جا شوم؟', 'در بالای صفحهٔ خواندن، سوییچ FA / EN را بزنید. زبان پیش‌فرض را هم از «زبان و ژانرهای مورد علاقه» در پروفایل عوض کنید.'),
  _Faq('دانلودها کجا ذخیره می‌شوند؟', 'روی همین دستگاه، تا پایان اشتراک شما. دانلود روی حداکثر ۲ دستگاه ممکن است و فضای مصرفی را در «مدیریت دانلودها» می‌بینید.'),
  _Faq('چپتر جدید کی منتشر می‌شود؟', '[پاسخ: زمان‌بندی انتشار]'),
  _Faq('چطور حسابم را حذف کنم؟', 'از پروفایل وارد «ویرایش پروفایل» شوید و «حذف دائمی حساب کاربری» را بزنید. این کار برگشت ندارد.'),
];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _q = TextEditingController();
  int? _open = 0;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final query = _q.text.trim();
    final shown = [for (final f in _faqs) if (query.isEmpty || f.q.contains(query) || f.a.contains(query)) f];

    Widget shortcut(String title, String sub, String route, {bool primary = false}) => Expanded(
          child: Pressable(
            onTap: () => context.push(route),
            child: Container(
              constraints: const BoxConstraints(minHeight: 84),
              padding: const EdgeInsets.all(MRSpacing.space4),
              decoration: BoxDecoration(
                color: primary ? c.red900 : c.surface1,
                borderRadius: BorderRadius.circular(MRRadius.radiusLg),
                border: Border.all(color: primary ? c.red800 : c.border1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, style: MRText.h3.copyWith(color: c.textPrimary)),
                Text(sub, style: MRText.caption.copyWith(color: c.textMuted)),
              ]),
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'پشتیبانی'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _q,
                      onChanged: (_) => setState(() => _open = null),
                      cursorColor: c.red400,
                      style: MRText.body.copyWith(color: c.textPrimary),
                      decoration: InputDecoration(border: InputBorder.none, hintText: 'سؤالتان را بنویسید…', hintStyle: MRText.body.copyWith(color: c.textHint)),
                    ),
                  ),
                  Icon(Icons.search, color: c.textMuted),
                ]),
              ),
              const SizedBox(height: MRSpacing.space3),
              Row(children: [
                shortcut('گزارش مشکل', 'ترجمهٔ اشتباه، صفحهٔ خراب', '/report-problem', primary: true),
                const SizedBox(width: MRSpacing.space3),
                shortcut('مشکل پرداخت', 'پیگیری با کد تراکنش', '/payment-history'),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: MRSpacing.space5, bottom: MRSpacing.space3),
                child: Semantics(header: true, child: Text('سؤالات متداول', style: MRText.h3.copyWith(color: c.textPrimary))),
              ),
              if (shown.isEmpty) Padding(padding: const EdgeInsets.all(MRSpacing.space4), child: Text('پاسخی پیدا نشد. از «گزارش مشکل» برایمان بنویسید.', style: MRText.body.copyWith(color: c.textMuted))),
              SectionCard(children: [
                for (final (i, f) in shown.indexed)
                  Semantics(
                    expanded: _open == i,
                    button: true,
                    child: Pressable(
                      onTap: () => setState(() => _open = _open == i ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(MRSpacing.space4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            Expanded(child: Text(f.q, style: MRText.bodyLg.copyWith(color: c.textPrimary))),
                            Icon(_open == i ? Icons.remove : Icons.add, size: 20, color: c.red400),
                          ]),
                          if (_open == i) Padding(padding: const EdgeInsets.only(top: MRSpacing.space3), child: Text(f.a, style: MRText.body.copyWith(color: c.textSecondary))),
                        ]),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: MRSpacing.space4),
              // [ایمیل پشتیبانی] stays a placeholder until the owner provides it.
              Text.rich(
                TextSpan(style: MRText.caption.copyWith(color: c.textMuted), children: [
                  const TextSpan(text: 'پاسخ نگرفتید؟ ایمیل: [ایمیل پشتیبانی] · پاسخگویی تا ۲۴ ساعت · '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Pressable(
                      onTap: () => context.push('/legal'),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(widthFactor: 1, child: Text('قوانین و حریم خصوصی', style: MRText.caption.copyWith(color: c.red300))),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
