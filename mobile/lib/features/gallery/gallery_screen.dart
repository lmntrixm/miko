import 'package:flutter/material.dart';

import '../../core/jalali.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/chapter_row.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/miko_tab_bar.dart';
import '../../widgets/miko_text_field.dart';
import '../../widgets/rank_card.dart';

/// Dev-only catalogue of base components, used to compare against design/screens.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _tab = 2, _seg = 0;
  final _chips = <int>{0};

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    Widget section(String t, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: MRSpacing.space6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: MRText.h2.copyWith(color: c.textPrimary)),
            const SizedBox(height: MRSpacing.space3),
            child,
          ]),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('کامپوننت‌های میکو'),
        actions: [
          MikoIconButton(
              icon: Icons.brightness_6_outlined,
              semanticLabel: 'تغییر تم',
              onPressed: widget.onToggleTheme),
        ],
      ),
      bottomNavigationBar: MikoTabBar(index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: ListView(
        padding: const EdgeInsets.all(MRSpacing.space5),
        children: [
          section(
              'دکمه',
              Column(spacing: MRSpacing.space3, children: [
                MikoButton(label: 'ادامه خواندن', onPressed: () {}),
                MikoButton(
                    label: 'ذخیره پیش‌نویس',
                    kind: MikoButtonKind.secondary,
                    onPressed: () {}),
                MikoButton(
                    label: 'خروج از حساب', kind: MikoButtonKind.danger, onPressed: () {}),
                const MikoButton(label: 'غیرفعال'),
                MikoButton(label: 'ورود', loading: true, loadingLabel: 'در حال ورود…'),
              ])),
          section(
              'فیلد',
              Column(spacing: MRSpacing.space5, children: [
                const MikoTextField(
                    label: 'ایمیل', icon: Icons.mail_outline, ltr: true, hint: 'name@example.com'),
                const MikoTextField(
                    label: 'رمز عبور', icon: Icons.lock_outline, obscure: true),
                const MikoTextField(
                    label: 'ایمیل',
                    icon: Icons.mail_outline,
                    ltr: true,
                    errorText: 'ایمیل واردشده معتبر نیست'),
              ])),
          section(
              'چیپ و سگمنت',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                MikoSegmented(
                    labels: const ['همه', 'مانگا', 'مانهوا', 'کامیک'],
                    index: _seg,
                    onChanged: (i) => setState(() => _seg = i)),
                const SizedBox(height: MRSpacing.space3),
                Wrap(spacing: MRSpacing.space2, children: [
                  for (final (i, g) in ['اکشن', 'فانتزی', 'عاشقانه'].indexed)
                    MikoChip(
                        label: g,
                        selected: _chips.contains(i),
                        onTap: () => setState(
                            () => _chips.contains(i) ? _chips.remove(i) : _chips.add(i))),
                  const MikoChip(label: '#200 – #250', ltr: true),
                ]),
              ])),
          section(
              'بج',
              Wrap(spacing: MRSpacing.space2, runSpacing: MRSpacing.space2, children: [
                const MikoBadge.status('در حال انتشار', kind: MikoBadgeKind.success),
                const MikoBadge.status('تمام‌شده', kind: MikoBadgeKind.info),
                const MikoBadge.status('در انتظار', kind: MikoBadgeKind.warning),
                const MikoBadge.status('مسدود', kind: MikoBadgeKind.danger),
                const MikoBadge('اکشن'),
                const MikoBadge.language(),
                const MikoCountBadge('۳'),
              ])),
          section(
              'ردیف چپتر',
              Column(spacing: MRSpacing.space3, children: [
                ChapterRow(
                    number: 242,
                    title: 'Sample chapter',
                    dateLabel: Jalali.fromDateTime(DateTime(2026, 9, 28)).format(),
                    commentCount: 12,
                    state: ChapterState.reading,
                    progress: 0.4),
                ChapterRow(
                    number: 241,
                    title: 'Sample chapter',
                    dateLabel: Jalali.fromDateTime(DateTime(2026, 9, 21)).format(),
                    commentCount: 8,
                    state: ChapterState.read),
                const ChapterRow(
                    number: 4,
                    title: 'Locked chapter',
                    dateLabel: '۱ مهر ۱۴۰۵',
                    state: ChapterState.locked),
              ])),
          section(
              'کارت رتبه',
              Column(spacing: MRSpacing.space3, children: const [
                RankCard(rank: 1, title: 'عنوان نمونه ۱', rating: 4.8, views: 124000, nextChapterIn: '۲ روز تا چپتر بعدی'),
                RankCard(rank: 2, title: 'عنوان نمونه ۲', rating: 4.6, views: 98000),
                RankCard(rank: 3, title: 'عنوان نمونه ۳', rating: 4.5, views: 71000),
              ])),
        ],
      ),
    );
  }
}
