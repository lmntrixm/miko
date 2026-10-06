import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/account_providers.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../data/network.dart';
import '../library/offline_view.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/pressable.dart';
import '../../widgets/rank_card.dart';

/// HomeTypes: greeting, type segments, weekly feature, continue reading, latest, popular.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _seg = 0;
  WorkType get _type => WorkType.values[_seg];

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    if (ref.watch(networkStatusProvider).isOffline) return const OfflineView();
    final works = ref.watch(worksProvider(_type));
    final sub = ref.watch(subscriptionProvider).asData?.value;
    final name = ref.watch(profileProvider).asData?.value.name ?? '';
    final unread = (ref.watch(unreadCountProvider).asData?.value ?? 0) > 0;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          MRSpacing.space5,
          MRSpacing.space5,
          MRSpacing.space5,
          MRSpacing.space6,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'سلام $name',
                        style: MRText.h1.copyWith(
                          fontSize: 22,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (sub != null)
                      Pressable(
                        // Temporary entry point until Profile (step 6) links to these.
                        onTap: () => context.push(
                          sub.active ? '/manage-subscription' : '/subscription',
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: 1,
                            child: Text(
                              sub.active
                                  ? '${faDigits(sub.daysLeft)} روز از اشتراک باقی مانده'
                                  : 'اشتراک فعال ندارید · خرید اشتراک ›',
                              style: MRText.caption.copyWith(
                                color: sub.active ? c.textMuted : c.red300,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              MikoIconButton(
                icon: Icons.notifications_none,
                semanticLabel: 'اعلان‌ها',
                filled: false,
                badge: unread,
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: MRSpacing.space4),
          MikoSegmented(
            labels: [for (final t in WorkType.values) t.label],
            index: _seg,
            onChanged: (i) => setState(() => _seg = i),
          ),
          const SizedBox(height: MRSpacing.space5),
          AsyncView<List<Work>>(
            value: works,
            onRetry: () => ref.invalidate(worksProvider(_type)),
            builder: (list) => list.isEmpty
                ? const SizedBox()
                : _Body(type: _type, works: list),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.type, required this.works});
  final WorkType type;
  final List<Work> works;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final featured = works.first;
    final latest = [...works]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final popular = [...works]..sort((a, b) => b.views.compareTo(a.views));
    final progress = ref.watch(lastProgressProvider).asData?.value;
    final progressWork = progress == null
        ? null
        : ref.watch(workProvider(progress.workId)).asData?.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Hero(work: featured),
        if (progress != null && progressWork != null) ...[
          const SizedBox(height: MRSpacing.space4),
          _ContinueCard(progress: progress, work: progressWork),
        ],
        const SizedBox(height: MRSpacing.space6),
        _SectionHeader(
          title: 'بروزترین ${type.label}ها',
          onMore: () => context.push('/list-all'),
        ),
        const SizedBox(height: MRSpacing.space3),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: latest.length,
            separatorBuilder: (_, _) => const SizedBox(width: MRSpacing.space3),
            itemBuilder: (_, i) => _WorkTile(work: latest[i]),
          ),
        ),
        const SizedBox(height: MRSpacing.space6),
        Semantics(
          header: true,
          child: Text(
            'محبوب‌ترین‌ها',
            style: MRText.h2.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: MRSpacing.space3),
        for (final (i, w) in popular.take(3).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: MRSpacing.space2),
            child: RankCard(
              rank: i + 1,
              title: w.nameFa,
              rating: w.rating,
              views: w.views,
              onTap: () => context.push('/home/title/${w.id}'),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: MRText.h2.copyWith(color: c.textPrimary)),
          ),
        ),
        Pressable(
          onTap: onMore,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Center(
              child: Text(
                'بیشتر ›',
                style: MRText.caption.copyWith(
                  fontSize: 13,
                  color: c.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final dir = switch (work.type.defaultMode) {
      ReadMode.pagedRtl => 'راست به چپ',
      ReadMode.pagedLtr => 'چپ به راست',
      ReadMode.webtoon => 'اسکرول عمودی',
    };
    return Pressable(
      onTap: () => context.push('/home/title/${work.id}'),
      semanticLabel: '${work.nameFa}، ${work.type.label} هفته',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MRRadius.radiusXl),
        child: SizedBox(
          height: 170,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CoverPlaceholder(radius: 0),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      c.bgBase.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MRSpacing.space4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${work.type.label} هفته',
                            style: MRText.caption.copyWith(color: c.red300),
                          ),
                          Text(
                            '${work.nameFa} · ${work.type.unit} ${faDigits(work.chapterCount)}',
                            style: MRText.h1.copyWith(
                              fontSize: 22,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.bgBase,
                        borderRadius: BorderRadius.circular(
                          MRRadius.radiusFull,
                        ),
                      ),
                      child: Text(
                        dir,
                        style: MRText.label.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.progress, required this.work});
  final ReadingProgress progress;
  final Work work;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Pressable(
      onTap: () => context.push('/reader/${progress.chapterId}'),
      semanticLabel: 'ادامه خواندن ${work.nameFa}',
      child: Container(
        padding: const EdgeInsets.all(MRSpacing.space3),
        decoration: BoxDecoration(
          color: c.red900,
          borderRadius: BorderRadius.circular(MRRadius.radiusLg),
          border: Border.all(color: c.red800),
        ),
        child: Row(
          children: [
            const CoverPlaceholder(width: 52, height: 64, radius: 12),
            const SizedBox(width: MRSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ادامه خواندن',
                    style: MRText.caption.copyWith(color: c.red300),
                  ),
                  Text(
                    '${work.nameFa} · ${faDigits(progress.chapterNumber)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MRText.h3.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: MRSpacing.space2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.fraction,
                      minHeight: 5,
                      backgroundColor: c.switchOff,
                      valueColor: AlwaysStoppedAnimation(c.red500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MRSpacing.space3),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.red500,
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

class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Pressable(
      onTap: () => context.push('/home/title/${work.id}'),
      semanticLabel: work.nameFa,
      child: SizedBox(
        width: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CoverPlaceholder(height: 150, radius: MRRadius.radiusLg),
            const SizedBox(height: MRSpacing.space2),
            Text(
              work.nameFa,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MRText.h3.copyWith(fontSize: 13, color: c.textPrimary),
            ),
            Text(
              '${work.type.unit} ${faDigits(work.chapterCount)}',
              style: MRText.caption.copyWith(color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// Used by detail/list screens too.
Widget statusBadge(WorkStatus s) => s == WorkStatus.ongoing
    ? const MikoBadge.status('در حال انتشار', kind: MikoBadgeKind.success)
    : const MikoBadge.status('تمام‌شده', kind: MikoBadgeKind.info);
