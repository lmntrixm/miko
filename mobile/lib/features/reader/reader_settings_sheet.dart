import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/miko_switch.dart';
import '../../widgets/pressable.dart';

Future<void> showReaderSettings(BuildContext context, WorkType type) {
  final c = context.mr;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface1,
    barrierColor: c.scrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MRRadius.radiusSheet))),
    builder: (_) => ReaderSettingsSheet(type: type),
  );
}

/// Settings apply live; «اعمال تنظیمات» just closes the sheet.
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({super.key, required this.type});
  final WorkType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final s = ref.watch(readerSettingsProvider);
    final ctl = ref.read(readerSettingsProvider.notifier);
    final layout = s.layoutFor(type);
    final rtl = s.rtlFor(type);

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: MRSpacing.space5, bottom: MRSpacing.space2),
          child: Text(t, style: MRText.body.copyWith(color: c.textMuted)),
        );

    Widget layoutCard(ReaderLayout l, String title, String sub) => Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: MRSpacing.space2),
            child: Semantics(
              selected: layout == l,
              inMutuallyExclusiveGroup: true,
              child: Pressable(
                onTap: () => ctl.update(s.copyWith(layout: l)),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: layout == l ? c.red900 : c.surface2,
                    borderRadius: BorderRadius.circular(MRRadius.radiusLg),
                    border: Border.all(color: layout == l ? c.red600 : c.border2, width: layout == l ? 2 : 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(title, style: MRText.h3.copyWith(fontSize: 14, color: c.textPrimary)),
                    Text(sub, style: MRText.caption.copyWith(fontSize: 11, color: c.textMuted)),
                  ]),
                ),
              ),
            ),
          ),
        );

    Widget switchRow(String t, bool v, ValueChanged<bool> on) => Row(children: [
          Expanded(child: Text(t, style: MRText.bodyLg.copyWith(color: c.textPrimary))),
          MikoSwitch(value: v, onChanged: on, label: t),
        ]);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(MRSpacing.space5, MRSpacing.space3, MRSpacing.space5, MRSpacing.space5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: c.switchOff, borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            MikoIconButton(icon: Icons.close, semanticLabel: 'بستن', filled: false, onPressed: () => Navigator.of(context).pop()),
            const SizedBox(width: MRSpacing.space2),
            Expanded(child: Semantics(header: true, child: Text('تنظیمات خواندن', style: MRText.h2.copyWith(color: c.textPrimary)))),
          ]),
          label('حالت خواندن'),
          Row(children: [
            layoutCard(ReaderLayout.vertical, 'عمودی', 'اسکرول پیوسته'),
            layoutCard(ReaderLayout.paged, 'صفحه‌ای', 'ورق زدن'),
            layoutCard(ReaderLayout.webtoon, 'وبتون', 'بدون فاصله'),
          ]),
          label('جهت ورق زدن'),
          Row(children: [
            Expanded(child: _Choice('راست به چپ (مانگا)', rtl, () => ctl.update(s.copyWith(rtl: true)))),
            const SizedBox(width: MRSpacing.space2),
            Expanded(child: _Choice('چپ به راست (کامیک)', !rtl, () => ctl.update(s.copyWith(rtl: false)))),
          ]),
          label('روشنایی'),
          Row(children: [
            Expanded(
              child: _MikoSlider(value: s.brightness, label: 'روشنایی', onChanged: (v) => ctl.update(s.copyWith(brightness: v))),
            ),
            SizedBox(width: 44, child: Text('${faDigits((s.brightness * 100).round())}٪', textAlign: TextAlign.end, style: MRText.caption.copyWith(color: c.textMuted))),
          ]),
          label('کیفیت تصویر'),
          Wrap(spacing: MRSpacing.space2, children: [
            MikoChip(label: 'کم‌حجم', selected: s.quality == ImageQuality.low, onTap: () => ctl.update(s.copyWith(quality: ImageQuality.low))),
            MikoChip(label: 'متوسط', selected: s.quality == ImageQuality.medium, onTap: () => ctl.update(s.copyWith(quality: ImageQuality.medium))),
            MikoChip(label: 'اصلی', selected: s.quality == ImageQuality.original, onTap: () => ctl.update(s.copyWith(quality: ImageQuality.original))),
          ]),
          const SizedBox(height: MRSpacing.space3),
          switchRow('روشن ماندن صفحه هنگام خواندن', s.keepScreenOn, (v) => ctl.update(s.copyWith(keepScreenOn: v))),
          switchRow('رفتن خودکار به چپتر بعدی', s.autoNext, (v) => ctl.update(s.copyWith(autoNext: v))),
          const SizedBox(height: MRSpacing.space4),
          MikoButton(label: 'اعمال تنظیمات', onPressed: () => Navigator.of(context).pop()),
          Center(
            child: Pressable(
              onTap: () {
                Navigator.of(context).pop();
                context.push('/report-problem');
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(widthFactor: 1, child: Text('گزارش مشکل همین صفحه', style: MRText.caption.copyWith(fontSize: 13, color: c.red300))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice(this.text, this.selected, this.onTap);
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.red500 : c.surface2,
            borderRadius: BorderRadius.circular(MRRadius.radiusLg),
            border: selected ? null : Border.all(color: c.border2),
          ),
          child: Text(text, style: MRText.body.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? c.onBrand : c.textSecondary)),
        ),
      ),
    );
  }
}

class _MikoSlider extends StatelessWidget {
  const _MikoSlider({required this.value, required this.onChanged, required this.label});
  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: c.red500,
        inactiveTrackColor: c.switchOff,
        thumbColor: c.red500,
        overlayColor: c.red500.withValues(alpha: 0.15),
        trackHeight: 5,
      ),
      child: Slider(value: value, min: 0.2, max: 1, semanticFormatterCallback: (v) => '${faDigits((v * 100).round())} درصد', label: label, onChanged: onChanged),
    );
  }
}

/// Reusable for the webtoon bar.
Widget mikoSlider({required double value, required ValueChanged<double> onChanged, required String label}) =>
    _MikoSlider(value: value, onChanged: onChanged, label: label);
