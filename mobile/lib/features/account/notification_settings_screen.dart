import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persian.dart';
import '../../data/account_providers.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_switch.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

String _clock(int minutes) => faDigits('${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}');

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final p = ref.watch(notificationPrefsProvider);
    final ctl = ref.read(notificationPrefsProvider.notifier);
    // Works the user follows: bookmarked + currently reading.
    final bookmarks = ref.watch(bookmarksProvider);
    final reading = ref.watch(readingListProvider).asData?.value ?? const <ReadingProgress>[];
    final ids = {...bookmarks, ...reading.map((r) => r.workId)};
    final works = (ref.watch(worksProvider(null)).asData?.value ?? const <Work>[]).where((w) => ids.contains(w.id)).toList();

    Widget toggle(String title, String sub, bool v, ValueChanged<bool> on) => Padding(
          padding: const EdgeInsetsDirectional.only(start: MRSpacing.space4, end: MRSpacing.space1, top: 4, bottom: 4),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: MRText.bodyLg.copyWith(color: c.textPrimary)),
                Text(sub, style: MRText.caption.copyWith(color: c.textMuted)),
              ]),
            ),
            MikoSwitch(value: v, onChanged: on, label: title),
          ]),
        );

    Widget timeBox(String label, int minutes, ValueChanged<int> on) => Expanded(
          child: Semantics(
            button: true,
            label: '$label ${_clock(minutes)}',
            child: Pressable(
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
                if (t != null) on(t.hour * 60 + t.minute);
              },
              child: ExcludeSemantics(
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MRRadius.radiusMd), border: Border.all(color: c.border2)),
                  child: Text('$label ${_clock(minutes)}', style: MRText.body.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary)),
                ),
              ),
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'تنظیمات اعلان‌ها'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
              SectionCard(children: [
                toggle('چپتر جدید', 'برای آثار نشان‌شده', p.newChapter, (v) => ctl.update(p.copyWith(newChapter: v))),
                toggle('پاسخ به نظر من', 'وقتی کسی به نظر شما پاسخ داد', p.reply, (v) => ctl.update(p.copyWith(reply: v))),
                toggle('یادآوری اشتراک', '۵ روز و ۱ روز قبل از پایان', p.subscription, (v) => ctl.update(p.copyWith(subscription: v))),
                toggle('تخفیف‌ها و پیشنهادها', 'حداکثر ۲ بار در ماه', p.promo, (v) => ctl.update(p.copyWith(promo: v))),
              ]),
              if (works.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: MRSpacing.space5, bottom: MRSpacing.space3),
                  child: Semantics(header: true, child: Text('چپتر جدید برای این آثار', style: MRText.h3.copyWith(color: c.textPrimary))),
                ),
                SectionCard(children: [
                  for (final w in works)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: MRSpacing.space4, end: MRSpacing.space3, top: 4, bottom: 4),
                      child: Row(children: [
                        Expanded(child: Text(w.nameFa, style: MRText.bodyLg.copyWith(color: c.textPrimary))),
                        const CoverPlaceholder(width: 36, height: 48, radius: 8),
                        const SizedBox(width: MRSpacing.space2),
                        MikoSwitch(
                          value: !p.mutedWorks.contains(w.id),
                          label: 'اعلان چپتر جدید ${w.nameFa}',
                          onChanged: (v) => ctl.update(p.copyWith(mutedWorks: v ? ({...p.mutedWorks}..remove(w.id)) : {...p.mutedWorks, w.id})),
                        ),
                      ]),
                    ),
                ]),
              ],
              const SizedBox(height: MRSpacing.space4),
              SectionCard(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('مزاحم نشو', style: MRText.bodyLg.copyWith(color: c.textPrimary)),
                      Text('اعلان‌ها در این بازه بی‌صدا می‌آیند', style: MRText.caption.copyWith(color: c.textMuted)),
                    ]),
                  ),
                  MikoSwitch(value: p.dnd, onChanged: (v) => ctl.update(p.copyWith(dnd: v)), label: 'مزاحم نشو'),
                ]),
                if (p.dnd) ...[
                  const SizedBox(height: MRSpacing.space3),
                  Row(children: [
                    timeBox('از', p.dndFromMin, (m) => ctl.update(p.copyWith(dndFromMin: m))),
                    const SizedBox(width: MRSpacing.space3),
                    timeBox('تا', p.dndToMin, (m) => ctl.update(p.copyWith(dndToMin: m))),
                  ]),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
