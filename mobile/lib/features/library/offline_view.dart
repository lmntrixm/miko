import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/downloads.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/pressable.dart';
import 'offline_banner.dart';

/// Shown on the Home tab while offline: only downloaded chapters are available.
class OfflineView extends ConsumerWidget {
  const OfflineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final done = ref.watch(downloadsProvider).done;
    final byWork = <String, List<DownloadItem>>{};
    for (final i in done) {
      byWork.putIfAbsent(i.workId, () => []).add(i);
    }
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(MRSpacing.space4),
        children: [
          const OfflineBanner(),
          const SizedBox(height: MRSpacing.space4),
          Semantics(
            header: true,
            child: Text(
              'بدون اینترنت هم بخوانید',
              style: MRText.h1.copyWith(fontSize: 22, color: c.textPrimary),
            ),
          ),
          const SizedBox(height: MRSpacing.space2),
          Text(
            byWork.isEmpty
                ? 'هنوز چیزی دانلود نکرده‌اید. وقتی اینترنت وصل شد، چپترها را دانلود کنید تا بدون اینترنت هم در دسترس باشند.'
                : 'چپترهای دانلودشده شما در دسترس هستند.',
            style: MRText.body.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: MRSpacing.space4),
          for (final e in byWork.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: MRSpacing.space3),
              child: _OfflineWork(items: e.value),
            ),
          const SizedBox(height: MRSpacing.space2),
          Container(
            padding: const EdgeInsets.all(MRSpacing.space4),
            decoration: BoxDecoration(
              color: c.surface1,
              borderRadius: BorderRadius.circular(MRRadius.radiusLg),
              border: Border.all(color: c.border1),
            ),
            child: Text(
              'جستجو، نظرات و چپترهای جدید بعد از وصل شدن دوباره فعال می‌شوند. پیشرفت خواندن شما ذخیره و بعداً همگام می‌شود.',
              style: MRText.body.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineWork extends StatelessWidget {
  const _OfflineWork({required this.items});
  final List<DownloadItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final sorted = [...items]..sort((a, b) => a.number.compareTo(b.number));
    final first = sorted.first, last = sorted.last;
    final range = first.number == last.number
        ? ''
        : ' · ${faDigits(first.number)} تا ${faDigits(last.number)}';
    return Pressable(
      // Open the newest downloaded chapter.
      onTap: () => context.push('/reader/${last.chapterId}'),
      semanticLabel: '${first.workNameFa}، آفلاین',
      child: Container(
        padding: const EdgeInsets.all(MRSpacing.space3),
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: BorderRadius.circular(MRRadius.radiusLg),
          border: Border.all(color: c.border1),
        ),
        child: Row(
          children: [
            const MikoBadge.status('آفلاین', kind: MikoBadgeKind.success),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  first.workNameFa,
                  style: MRText.h3.copyWith(color: c.textPrimary),
                ),
                Text(
                  '${faDigits(items.length)} ${first.type.unit}$range',
                  style: MRText.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(width: MRSpacing.space3),
            const CoverPlaceholder(width: 56, height: 72, radius: 10),
          ],
        ),
      ),
    );
  }
}
