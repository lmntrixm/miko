import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/jalali.dart';
import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/downloads.dart';
import '../../data/models.dart';
import '../../data/network.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';
import '../downloads/downloads_screen.dart';
import 'offline_banner.dart';

/// «کتابخانه من»: reading · bookmarks · downloads · history.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _tab = 0;
  static const _tabs = ['در حال خواندن', 'نشان‌شده', 'دانلودها', 'تاریخچه'];

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final offline = ref.watch(networkStatusProvider).isOffline;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MRSpacing.space5,
              MRSpacing.space5,
              MRSpacing.space3,
              MRSpacing.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'کتابخانه من',
                      style: MRText.h1.copyWith(
                        fontSize: 28,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
                MikoIconButton(
                  icon: Icons.notifications_none,
                  semanticLabel: 'اعلان‌ها',
                  filled: false,
                  onPressed: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
          if (offline)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                MRSpacing.space4,
                0,
                MRSpacing.space4,
                MRSpacing.space2,
              ),
              child: OfflineBanner(),
            ),
          // Tab strip with red underline on the selected one.
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
            child: Row(
              children: [
                for (final (i, t) in _tabs.indexed)
                  Semantics(
                    selected: i == _tab,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          minWidth: 44,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: MRSpacing.space3,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == _tab ? c.red500 : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          t,
                          style: MRText.body.copyWith(
                            fontWeight: i == _tab
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i == _tab ? c.textPrimary : c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => const _ReadingTab(),
              1 => const _BookmarksTab(),
              2 => const DownloadsBody(),
              _ => const _HistoryTab(),
            },
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body, this.cta});
  final String title, body;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MRSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 96,
              decoration: BoxDecoration(
                color: c.red900,
                border: Border.all(color: c.red600, width: 2),
                borderRadius: BorderRadius.circular(MRRadius.radiusMd),
              ),
              child: Icon(Icons.add, size: 32, color: c.red400),
            ),
            const SizedBox(height: MRSpacing.space5),
            Semantics(
              header: true,
              child: Text(
                title,
                style: MRText.h2.copyWith(color: c.textPrimary),
              ),
            ),
            const SizedBox(height: MRSpacing.space2),
            Text(
              body,
              textAlign: TextAlign.center,
              style: MRText.body.copyWith(color: c.textMuted),
            ),
            if (cta != null) ...[
              const SizedBox(height: MRSpacing.space5),
              cta!,
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadingTab extends ConsumerWidget {
  const _ReadingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final list = ref.watch(readingListProvider);
    final used = ref.watch(downloadsProvider).usedMb;
    return AsyncView<List<ReadingProgress>>(
      value: list,
      onRetry: () => ref.invalidate(readingListProvider),
      builder: (items) => items.isEmpty
          ? _Empty(
              title: 'هنوز چیزی نخوانده‌اید',
              body: 'هر اثری که شروع کنید اینجا نگه می‌داریم تا از همان صفحه‌ای که ماندید ادامه دهید.',
              cta: MikoButton(
                label: 'کشف آثار محبوب',
                expand: false,
                onPressed: () => context.go('/home'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(MRSpacing.space4),
              children: [
                for (final p in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MRSpacing.space3),
                    child: _ReadingCard(progress: p),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MRSpacing.space4,
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
                          'فضای دانلودها: ${faSize(used)}',
                          style: MRText.body.copyWith(color: c.textSecondary),
                        ),
                      ),
                      Pressable(
                        onTap: () => context.push('/downloads'),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 52,
                            minWidth: 44,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              'مدیریت فضا ›',
                              style: MRText.caption.copyWith(
                                fontSize: 13,
                                color: c.red300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReadingCard extends ConsumerWidget {
  const _ReadingCard({required this.progress});
  final ReadingProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final work = ref.watch(workProvider(progress.workId)).asData?.value;
    final lang = switch (progress.lang) {
      'en' => 'انگلیسی',
      'both' => 'دوزبانه',
      _ => 'فارسی',
    };
    return Pressable(
      onTap: () => context.push('/reader/${progress.chapterId}'),
      semanticLabel: 'ادامه خواندن ${work?.nameFa ?? ''}',
      child: Container(
        padding: const EdgeInsets.all(MRSpacing.space3),
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: BorderRadius.circular(MRRadius.radiusLg),
          border: Border.all(color: c.border1),
        ),
        child: Row(
          children: [
            const CoverPlaceholder(width: 70, height: 96, radius: 12),
            const SizedBox(width: MRSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work?.nameFa ?? '…',
                    style: MRText.h3.copyWith(color: c.textPrimary),
                  ),
                  Text(
                    '${work?.type.unit ?? 'چپتر'} ${faDigits(progress.chapterNumber)} · $lang',
                    style: MRText.caption.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 5,
                      backgroundColor: c.switchOff,
                      valueColor: AlwaysStoppedAnimation(c.red500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'صفحه ${faDigits(progress.page + 1)} از ${faDigits(progress.pageCount)}',
                    style: MRText.caption.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MRSpacing.space2),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: mrBrandGradient,
                borderRadius: BorderRadius.circular(MRRadius.radiusMd),
              ),
              child: Icon(Icons.play_arrow_rounded, color: c.onBrand),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarksTab extends ConsumerWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final ids = ref.watch(bookmarksProvider);
    final works = ref.watch(worksProvider(null));
    return AsyncView<List<Work>>(
      value: works,
      onRetry: () => ref.invalidate(worksProvider(null)),
      builder: (all) {
        final marked = all.where((w) => ids.contains(w.id)).toList();
        if (marked.isEmpty) {
          return _Empty(
            title: 'چیزی نشان نکرده‌اید',
            body: 'در صفحهٔ هر اثر روی نشان بزنید تا اینجا پیدایش کنید.',
            cta: MikoButton(
              label: 'کشف آثار محبوب',
              expand: false,
              onPressed: () => context.go('/home'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(MRSpacing.space4),
          children: [
            for (final w in marked)
              Padding(
                padding: const EdgeInsets.only(bottom: MRSpacing.space3),
                child: Pressable(
                  onTap: () => context.push('/home/title/${w.id}'),
                  semanticLabel: w.nameFa,
                  child: Container(
                    padding: const EdgeInsets.all(MRSpacing.space3),
                    decoration: BoxDecoration(
                      color: c.surface1,
                      borderRadius: BorderRadius.circular(MRRadius.radiusLg),
                      border: Border.all(color: c.border1),
                    ),
                    child: Row(
                      children: [
                        const CoverPlaceholder(
                          width: 56,
                          height: 76,
                          radius: 10,
                        ),
                        const SizedBox(width: MRSpacing.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.nameFa,
                                style: MRText.h3.copyWith(color: c.textPrimary),
                              ),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  w.nameEn,
                                  style: MRText.caption.copyWith(
                                    color: c.textMuted,
                                  ),
                                ),
                              ),
                              Text(
                                '${faDigits(w.chapterCount)} ${w.type.unit}',
                                style: MRText.caption.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MikoIconButton(
                          icon: Icons.bookmark,
                          semanticLabel: 'برداشتن نشان ${w.nameFa}',
                          filled: false,
                          onPressed: () =>
                              ref.read(bookmarksProvider.notifier).toggle(w.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final list = ref.watch(readingListProvider);
    return AsyncView<List<ReadingProgress>>(
      value: list,
      onRetry: () => ref.invalidate(readingListProvider),
      builder: (items) => items.isEmpty
          ? const _Empty(
              title: 'تاریخچه خالی است',
              body: 'چپترهایی که بخوانید اینجا ثبت می‌شوند.',
            )
          : ListView(
              padding: const EdgeInsets.all(MRSpacing.space4),
              children: [
                for (final p in items)
                  Consumer(
                    builder: (context, ref, _) {
                      final w = ref.watch(workProvider(p.workId)).asData?.value;
                      return Pressable(
                        onTap: () => context.push('/reader/${p.chapterId}'),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 64),
                          margin: const EdgeInsets.only(
                            bottom: MRSpacing.space2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: MRSpacing.space4,
                            vertical: MRSpacing.space3,
                          ),
                          decoration: BoxDecoration(
                            color: c.surface1,
                            borderRadius: BorderRadius.circular(
                              MRRadius.radiusLg,
                            ),
                            border: Border.all(color: c.border1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${w?.nameFa ?? '…'} · ${faDigits(p.chapterNumber)}',
                                  style: MRText.h3.copyWith(
                                    fontSize: 14,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                Jalali.fromDateTime(p.updatedAt).format(),
                                style: MRText.caption.copyWith(
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
