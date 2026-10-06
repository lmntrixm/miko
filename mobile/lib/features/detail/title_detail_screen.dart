import '../../core/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/jalali.dart';
import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/chapter_row.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';
import '../../widgets/miko_chip.dart';
import '../home/home_screen.dart' show statusBadge;

/// Work detail for manga, manhwa and comics. Comics group issues into volumes (جلد),
/// the others into chapter ranges of 50.
class TitleDetailScreen extends ConsumerWidget {
  const TitleDetailScreen({super.key, required this.workId});
  final String workId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final work = ref.watch(workProvider(workId));
    final chapters = ref.watch(chaptersProvider(workId));
    return Scaffold(
      body: AsyncView<Work>(
        value: work,
        onRetry: () => ref.invalidate(workProvider(workId)),
        builder: (w) => AsyncView<List<Chapter>>(
          value: chapters,
          onRetry: () => ref.invalidate(chaptersProvider(workId)),
          builder: (list) => _Detail(work: w, chapters: list),
        ),
      ),
    );
  }
}

const _issuesPerVolume = 12;
const _rangeSize = 50;

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.work, required this.chapters});
  final Work work;
  final List<Chapter> chapters; // newest first

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  bool _expanded = false;
  bool _ascending = false;
  late int _group;

  bool get _isComic => widget.work.type == WorkType.comic;
  int _groupOf(Chapter c) => _isComic
      ? (c.number - 1) ~/ _issuesPerVolume
      : (c.number - 1) ~/ _rangeSize;
  int get _groupCount => _groupOf(widget.chapters.first) + 1;

  @override
  void initState() {
    super.initState();
    _group = _groupCount - 1; // newest group first
  }

  String _groupLabel(int g) {
    if (_isComic) return 'جلد ${faDigits(g + 1)}';
    final lo = g * _rangeSize + 1;
    final hi = ((g + 1) * _rangeSize).clamp(1, widget.chapters.first.number);
    return '#$lo – #$hi';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final w = widget.work;
    final sub = ref.watch(subscriptionProvider).asData?.value;
    final progress = ref.watch(lastProgressProvider).asData?.value;
    final resume = progress != null && progress.workId == w.id
        ? progress
        : null;
    final bookmarked = ref.watch(bookmarksProvider).contains(w.id);

    var visible = widget.chapters
        .where((ch) => _groupOf(ch) == _group)
        .toList();
    if (_ascending) visible = visible.reversed.toList();

    final resumeNumber = resume?.chapterNumber ?? 1;
    final resumeLocked = !AppConfig.freeMode && !(sub?.active ?? false) && resumeNumber > 3;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover sits behind; the padded info card (non-positioned) sizes the stack.
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 260,
                    child: CoverPlaceholder(radius: 0),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MRSpacing.space4,
                      190,
                      MRSpacing.space4,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(MRSpacing.space4),
                      decoration: BoxDecoration(
                        color: c.surface1,
                        borderRadius: BorderRadius.circular(MRRadius.radiusXl),
                        border: Border.all(color: c.border1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              MikoBadge(w.type.label),
                              const SizedBox(width: MRSpacing.space2),
                              statusBadge(w.status),
                            ],
                          ),
                          const SizedBox(height: MRSpacing.space2),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                w.nameEn,
                                style: MRText.h1.copyWith(color: c.textPrimary),
                              ),
                            ),
                          ),
                          Text(
                            w.nameFa,
                            style: MRText.bodyLg.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Pressable(
                              onTap: () => context.push('/author/${w.authorId}'),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 44),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    'نویسنده: ${w.author} ›',
                                    style: MRText.caption.copyWith(fontSize: 13, color: c.red300),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: MRSpacing.space2),
                          Wrap(
                            spacing: MRSpacing.space4,
                            runSpacing: 4,
                            children: [
                              _Stat(
                                Icons.star_rounded,
                                faDigits(
                                  w.rating
                                      .toStringAsFixed(1)
                                      .replaceAll('.', '٫'),
                                ),
                                accent: true,
                              ),
                              _Stat(
                                Icons.visibility_outlined,
                                faCompact(w.views),
                              ),
                              _Stat(
                                Icons.menu_book_outlined,
                                '${faDigits(w.chapterCount)} ${w.type.unit}',
                              ),
                              _Stat(
                                Icons.schedule,
                                Jalali.fromDateTime(w.updatedAt).format(),
                              ),
                            ],
                          ),
                          const SizedBox(height: MRSpacing.space3),
                          Wrap(
                            spacing: MRSpacing.space2,
                            runSpacing: MRSpacing.space2,
                            children: [for (final g in w.genres) MikoBadge(g)],
                          ),
                          Divider(color: c.red800, height: MRSpacing.space6),
                          AnimatedSize(
                            duration: MRMotion.base,
                            alignment: Alignment.topCenter,
                            child: Text(
                              w.description,
                              maxLines: _expanded ? null : 3,
                              overflow: _expanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: MRText.body.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          Align(
                            child: Semantics(
                              button: true,
                              label: _expanded
                                  ? 'بستن توضیحات'
                                  : 'نمایش کامل توضیحات',
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _expanded = !_expanded),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    _expanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: c.red400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          MikoButton(
                            label: resume == null
                                ? 'شروع خواندن · ${w.type.unit} ${faDigits(1)}'
                                : 'ادامه خواندن · ${w.type.unit} ${faDigits(resumeNumber)}',
                            icon: resumeLocked
                                ? Icons.lock_outline
                                : Icons.play_arrow_rounded,
                            onPressed: () => _open(
                              resume?.chapterId ?? widget.chapters.last.id,
                              locked: resumeLocked,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: MRSpacing.space4)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          _isComic ? 'ایشوها' : 'چپترها',
                          style: MRText.h2.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: _ascending
                          ? 'مرتب‌سازی از جدید به قدیم'
                          : 'مرتب‌سازی از قدیم به جدید',
                      child: GestureDetector(
                        onTap: () => setState(() => _ascending = !_ascending),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.swap_vert, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MRSpacing.space4,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _groupCount,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: MRSpacing.space2),
                  itemBuilder: (_, i) {
                    final g = _groupCount - 1 - i; // newest first
                    return MikoChip(
                      label: _groupLabel(g),
                      selected: g == _group,
                      ltr: !_isComic,
                      onTap: () => setState(() => _group = g),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                MRSpacing.space4,
                MRSpacing.space3,
                MRSpacing.space4,
                MRSpacing.space6,
              ),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: MRSpacing.space3),
                itemBuilder: (_, i) {
                  final ch = visible[i];
                  final locked = !ch.isFree && !(sub?.active ?? false);
                  final isCurrent = resume?.chapterId == ch.id;
                  final read =
                      resume != null && ch.number < resume.chapterNumber;
                  return ChapterRow(
                    number: ch.number,
                    title: ch.titleEn,
                    dateLabel: Jalali.fromDateTime(ch.date).format(),
                    commentCount: ch.commentCount,
                    state: locked
                        ? ChapterState.locked
                        : isCurrent
                        ? ChapterState.reading
                        : read
                        ? ChapterState.read
                        : ChapterState.unread,
                    progress: isCurrent ? resume!.fraction : 0,
                    onTap: () => _open(ch.id, locked: locked),
                  );
                },
              ),
            ),
            // Room for the bottom tab bar's translucent overlap.
            const SliverToBoxAdapter(child: SizedBox(height: MRSpacing.space4)),
          ],
        ),
        PositionedDirectional(
          top: MediaQuery.paddingOf(context).top + 4,
          start: 8,
          end: 8,
          child: Row(
            children: [
              _OverlayButton(
                icon: Icons.arrow_forward,
                label: 'بازگشت',
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const Spacer(),
              _OverlayButton(
                icon: Icons.share_outlined,
                label: 'اشتراک‌گذاری',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _OverlayButton(
                icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
                label: bookmarked ? 'برداشتن نشان' : 'نشان کردن',
                onTap: () => ref.read(bookmarksProvider.notifier).toggle(w.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _open(String chapterId, {required bool locked}) {
    context.push(locked ? '/paywall?chapter=$chapterId' : '/reader/$chapterId');
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.text, {this.accent = false});
  final IconData icon;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accent ? c.red400 : c.textMuted),
        const SizedBox(width: 4),
        Text(text, style: MRText.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.bgBase.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(MRRadius.radiusMd),
          ),
          child: Icon(icon, size: 22, color: c.textPrimary),
        ),
      ),
    );
  }
}
