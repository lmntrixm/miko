import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/downloads.dart';
import '../../data/models.dart';
import '../../data/network.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_switch.dart';

/// Starts a download and explains the 402 / 409 outcomes.
Future<void> startDownload(
  BuildContext context,
  WidgetRef ref,
  Work work,
  Chapter chapter,
) async {
  final result = await ref
      .read(downloadsProvider.notifier)
      .enqueue(work, chapter);
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  switch (result) {
    case EnqueueResult.started:
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'دانلود ${work.type.unit} ${faDigits(chapter.number)} شروع شد',
          ),
        ),
      );
    case EnqueueResult.alreadyThere:
      messenger.showSnackBar(
        const SnackBar(
          content: Text('این چپتر قبلاً در صف دانلود یا دانلودشده‌هاست'),
        ),
      );
    case EnqueueResult.needsSubscription:
      context.push('/paywall');
    case EnqueueResult.deviceLimit:
      await showDialog<void>(
        context: context,
        builder: (_) => const _InfoDialog(
          title: 'سقف دستگاه‌ها پر است',
          body: 'دانلود روی حداکثر ۲ دستگاه ممکن است. یکی از دستگاه‌های قبلی را از تنظیمات حساب حذف کنید و دوباره امتحان کنید.',
        ),
      );
  }
}

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final s = ref.watch(downloadsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MRSpacing.space3,
                MRSpacing.space2,
                MRSpacing.space4,
                MRSpacing.space2,
              ),
              child: Row(
                children: [
                  MikoIconButton(
                    icon: Icons.arrow_forward,
                    semanticLabel: 'بازگشت',
                    filled: false,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/library'),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'دانلودها',
                        style: MRText.h1.copyWith(
                          fontSize: 22,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (s.active.isNotEmpty)
                    MikoButton(
                      label: s.paused ? 'ادامه همه' : 'توقف همه',
                      kind: MikoButtonKind.secondary,
                      expand: false,
                      height: 44,
                      onPressed: () =>
                          ref.read(downloadsProvider.notifier).togglePause(),
                    ),
                ],
              ),
            ),
            const Expanded(child: DownloadsBody()),
          ],
        ),
      ),
    );
  }
}

/// Storage, queue, downloaded list and the Wi-Fi switch. Shared by the screen and the Library tab.
class DownloadsBody extends ConsumerWidget {
  const DownloadsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final s = ref.watch(downloadsProvider);
    final ctl = ref.read(downloadsProvider.notifier);
    final net = ref.watch(networkStatusProvider);
    final sub = ref.watch(subscriptionProvider).asData?.value;

    final byWork = <String, List<DownloadItem>>{};
    for (final i in s.done) {
      byWork.putIfAbsent(i.workId, () => []).add(i);
    }

    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(
        top: MRSpacing.space5,
        bottom: MRSpacing.space3,
      ),
      child: Semantics(
        header: true,
        child: Text(t, style: MRText.h3.copyWith(color: c.textPrimary)),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MRSpacing.space4,
        0,
        MRSpacing.space4,
        MRSpacing.space6,
      ),
      children: [
        _StorageCard(usedMb: s.usedMb, queuedMb: s.queuedMb),
        if (s.paused ||
            (s.active.isNotEmpty &&
                net == NetworkStatus.mobile &&
                s.wifiOnly) ||
            (s.active.isNotEmpty && net.isOffline))
          Padding(
            padding: const EdgeInsets.only(top: MRSpacing.space3),
            child: Text(
              s.paused
                  ? 'دانلودها متوقف شده‌اند.'
                  : net.isOffline
                  ? 'اتصال اینترنت قطع است؛ با وصل شدن ادامه می‌یابد.'
                  : 'منتظر اتصال وای‌فای هستیم (دانلود با اینترنت همراه خاموش است).',
              style: MRText.caption.copyWith(color: c.warning),
            ),
          ),
        if (s.active.isNotEmpty) ...[
          title('در حال دانلود'),
          for (final i in s.active)
            Padding(
              padding: const EdgeInsets.only(bottom: MRSpacing.space3),
              child: _ActiveRow(
                item: i,
                onCancel: () => ctl.cancel(i.chapterId),
              ),
            ),
        ],
        title('دانلودشده'),
        if (byWork.isEmpty)
          Text(
            'هنوز چیزی دانلود نکرده‌اید. در صفحهٔ خواندن، دکمهٔ دانلود را بزنید.',
            style: MRText.body.copyWith(color: c.textMuted),
          ),
        for (final e in byWork.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: MRSpacing.space3),
            child: _DoneRow(
              items: e.value,
              subscriptionActive: sub?.active ?? true,
              onDelete: () => _confirmDelete(context, ctl, e.value),
            ),
          ),
        const SizedBox(height: MRSpacing.space3),
        Container(
          padding: const EdgeInsetsDirectional.only(
            start: MRSpacing.space4,
            end: MRSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: BorderRadius.circular(MRRadius.radiusLg),
            border: Border.all(color: c.border1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'فقط با وای‌فای دانلود شود',
                  style: MRText.bodyLg.copyWith(color: c.textPrimary),
                ),
              ),
              MikoSwitch(
                value: s.wifiOnly,
                onChanged: ctl.setWifiOnly,
                label: 'فقط با وای‌فای دانلود شود',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DownloadsController ctl,
    List<DownloadItem> items,
  ) async {
    final mb = items.fold<double>(0, (a, i) => a + i.sizeMb);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _InfoDialog(
        title: 'حذف دانلودها',
        body:
            'حذف ${faDigits(items.length)} چپتر دانلودشده (${faSize(mb)})؟ هر وقت خواستید دوباره دانلود می‌کنید.',
        confirmLabel: 'حذف',
        destructive: true,
      ),
    );
    if (ok == true) ctl.deleteWork(items.first.workId);
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.usedMb, required this.queuedMb});
  final double usedMb, queuedMb;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final used = (usedMb / downloadQuotaMb).clamp(0.0, 1.0);
    final queued = (queuedMb / downloadQuotaMb).clamp(0.0, 1.0 - used);
    Widget dot(Color col, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: col,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(t, style: MRText.caption.copyWith(color: c.textMuted)),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(MRSpacing.space4),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(MRRadius.radiusLg),
        border: Border.all(color: c.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'فضای استفاده‌شده',
                style: MRText.body.copyWith(color: c.textPrimary),
              ),
              const Spacer(),
              Text(
                '${faSize(usedMb)} از ${faSize(downloadQuotaMb)} مجاز',
                style: MRText.caption.copyWith(color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: MRSpacing.space3),
          Semantics(
            label: 'فضای استفاده‌شده ${faDigits((used * 100).round())} درصد',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 10,
                child: Stack(
                  children: [
                    Positioned.fill(child: ColoredBox(color: c.switchOff)),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: (used + queued).clamp(0.0, 1.0),
                      child: ColoredBox(color: c.red800),
                    ),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: used,
                      child: ColoredBox(color: c.red500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MRSpacing.space2),
          Row(
            children: [
              dot(c.red500, 'دانلودشده'),
              const SizedBox(width: MRSpacing.space4),
              dot(c.red800, 'در صف'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.item, required this.onCancel});
  final DownloadItem item;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final downloading = item.state == DownloadState.downloading;
    final doneMb = item.sizeMb * item.progress;
    return Container(
      padding: const EdgeInsets.all(MRSpacing.space3),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(MRRadius.radiusLg),
        border: Border.all(color: c.border1),
      ),
      child: Row(
        children: [
          const CoverPlaceholder(width: 44, height: 56, radius: 10),
          const SizedBox(width: MRSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.workNameFa} · ${faDigits(item.number)}',
                  style: MRText.h3.copyWith(fontSize: 14, color: c.textPrimary),
                ),
                const SizedBox(height: 6),
                Semantics(
                  label:
                      'پیشرفت ${faDigits((item.progress * 100).round())} درصد',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 5,
                      backgroundColor: c.switchOff,
                      valueColor: AlwaysStoppedAnimation(c.red500),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  downloading
                      ? '${faSize(doneMb)} از ${faSize(item.sizeMb)}'
                      : 'در صف',
                  style: MRText.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
          MikoIconButton(
            icon: Icons.close,
            semanticLabel:
                'لغو دانلود ${item.workNameFa} ${faDigits(item.number)}',
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({
    required this.items,
    required this.subscriptionActive,
    required this.onDelete,
  });
  final List<DownloadItem> items;
  final bool subscriptionActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final mb = items.fold<double>(0, (a, i) => a + i.sizeMb);
    final first = items.first;
    return Container(
      padding: const EdgeInsets.all(MRSpacing.space3),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(MRRadius.radiusLg),
        border: Border.all(color: c.border1),
      ),
      child: Row(
        children: [
          const CoverPlaceholder(width: 44, height: 56, radius: 10),
          const SizedBox(width: MRSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first.workNameFa,
                  style: MRText.h3.copyWith(color: c.textPrimary),
                ),
                Text(
                  '${faDigits(items.length)} ${first.type.unit} · ${faSize(mb)} · ${subscriptionActive ? 'تا پایان اشتراک' : 'اشتراک تمام شده'}',
                  style: MRText.caption.copyWith(
                    color: subscriptionActive ? c.textMuted : c.warning,
                  ),
                ),
              ],
            ),
          ),
          MikoIconButton(
            icon: Icons.delete_outline,
            semanticLabel: 'حذف دانلودهای ${first.workNameFa}',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  const _InfoDialog({
    required this.title,
    required this.body,
    this.confirmLabel,
    this.destructive = false,
  });
  final String title, body;
  final String? confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Dialog(
      backgroundColor: c.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MRRadius.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MRSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: MRText.h2.copyWith(color: c.textPrimary),
              ),
            ),
            const SizedBox(height: MRSpacing.space3),
            Text(body, style: MRText.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: MRSpacing.space5),
            if (confirmLabel != null) ...[
              MikoButton(
                label: confirmLabel!,
                kind: destructive
                    ? MikoButtonKind.danger
                    : MikoButtonKind.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: MRSpacing.space2),
              MikoButton(
                label: 'انصراف',
                kind: MikoButtonKind.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ] else
              MikoButton(
                label: 'متوجه شدم',
                kind: MikoButtonKind.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}
