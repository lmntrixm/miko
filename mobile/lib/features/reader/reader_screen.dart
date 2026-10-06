import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import 'reader_page.dart';
import 'reader_settings_sheet.dart';

class _ReaderData {
  const _ReaderData(this.work, this.chapter, this.resumePage);
  final Work work;
  final Chapter chapter;
  final int resumePage;
}

/// Loaded once per chapter. Reads progress directly so saving progress never reloads the reader.
final _readerDataProvider = FutureProvider.autoDispose.family<_ReaderData, String>((ref, id) async {
  final repo = ref.watch(contentRepositoryProvider);
  final chapter = await repo.openChapter(id); // throws PaywallException (402)
  final work = await repo.work(chapter.workId);
  final p = await repo.lastProgress();
  final resume = p != null && p.chapterId == id ? p.page : 0;
  return _ReaderData(work, chapter, resume);
});

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_readerDataProvider(chapterId));
    if (data.hasError && data.error is PaywallException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pushReplacement('/paywall');
      });
    }
    return Scaffold(
      backgroundColor: context.mr.bgBase,
      body: data.hasError && data.error is PaywallException
          ? const SizedBox()
          : AsyncView<_ReaderData>(
              value: data,
              onRetry: () => ref.invalidate(_readerDataProvider(chapterId)),
              builder: (d) => _ReaderView(key: ValueKey(chapterId), data: d),
            ),
    );
  }
}

enum _Lang { fa, en, both }

class _ReaderView extends ConsumerStatefulWidget {
  const _ReaderView({super.key, required this.data});
  final _ReaderData data;

  @override
  ConsumerState<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends ConsumerState<_ReaderView> {
  late int _page = widget.data.resumePage; // first visible page, 0-based
  bool _bars = true;
  bool _twoPage = true;
  _Lang _lang = _Lang.fa;
  bool _showResume = false;
  PageController? _pager;
  ScrollController? _scroll;
  Timer? _resumeTimer;
  Timer? _saveTimer;

  Chapter get _ch => widget.data.chapter;
  Work get _work => widget.data.work;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_page > 0) {
      _showResume = true;
      _resumeTimer = Timer(const Duration(seconds: 4), () => mounted ? setState(() => _showResume = false) : null);
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _saveTimer?.cancel();
    _pager?.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  // ---- layout helpers ----

  bool _spread(BuildContext context, ReaderLayout layout) =>
      layout == ReaderLayout.paged && _twoPage && MediaQuery.sizeOf(context).width >= 700;

  int _lastVisible(bool spread) => spread ? (_page + 1).clamp(0, _ch.pageCount - 1) : _page;
  double get _fraction => (_lastVisible(_spreadNow) + 1) / _ch.pageCount;
  bool _spreadNow = false;

  void _setPage(int p) {
    if (p == _page) return;
    setState(() => _page = p);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      ref.read(contentRepositoryProvider).saveProgress(ReadingProgress(
            workId: _work.id,
            chapterId: _ch.id,
            chapterNumber: _ch.number,
            page: _page,
            pageCount: _ch.pageCount,
          ));
      ref.invalidate(lastProgressProvider);
    });
  }

  bool get _hasNext => _ch.number < _work.chapterCount;
  bool get _hasPrev => _ch.number > 1;

  void _goChapter(int n) => context.pushReplacement('/reader/${_work.id}~$n');

  void _toggleBars() => setState(() => _bars = !_bars);

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _go(PageController c, int index) async {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      c.jumpToPage(index);
    } else {
      await c.animateToPage(index, duration: const Duration(milliseconds: 280), curve: MRMotion.emphasized);
    }
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final s = ref.watch(readerSettingsProvider);
    final layout = s.layoutFor(_work.type);
    final rtl = s.rtlFor(_work.type);
    final spread = _spreadNow = _spread(context, layout);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final bookmarked = ref.watch(bookmarksProvider).contains(_work.id);

    return Stack(fit: StackFit.expand, children: [
      if (layout == ReaderLayout.paged) _paged(context, rtl, spread) else _scrolling(context, layout, s),
      // In-app brightness dimmer (system brightness is untouched).
      IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: (1 - s.brightness) * 0.7))),
      if (layout == ReaderLayout.webtoon)
        IgnorePointer(child: ColoredBox(color: c.warning.withValues(alpha: s.nightFilter * 0.25))),
      // Top bar
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: _BarFade(
          visible: _bars,
          reduce: reduce,
          child: Container(
            color: c.bgBase.withValues(alpha: 0.94),
            padding: EdgeInsets.fromLTRB(MRSpacing.space3, MediaQuery.paddingOf(context).top + 4, MRSpacing.space3, MRSpacing.space2),
            child: Row(children: [
              MikoIconButton(icon: Icons.arrow_forward, semanticLabel: 'بازگشت', filled: false, onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_work.nameFa, maxLines: 1, overflow: TextOverflow.ellipsis, style: MRText.h3.copyWith(color: c.textPrimary)),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${_work.type.unit} ${faDigits(_ch.number)} · '),
                      TextSpan(text: _ch.titleEn, style: const TextStyle(fontFamily: MRText.family)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MRText.caption.copyWith(color: c.textMuted),
                  ),
                ]),
              ),
              if (spread || MediaQuery.sizeOf(context).width >= 700 && layout == ReaderLayout.paged)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: MRSpacing.space2),
                  child: _Toggle(labels: const ['تک صفحه', 'دو صفحه'], index: _twoPage ? 1 : 0, onChanged: (i) => setState(() {
                        _twoPage = i == 1;
                        final old = _pager;
                        _pager = null;
                        WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
                      })),
                ),
              _Toggle(
                labels: layout == ReaderLayout.webtoon ? const ['فارسی', 'EN', 'دوزبانه'] : const ['EN', 'FA'],
                index: layout == ReaderLayout.webtoon ? [_Lang.fa, _Lang.en, _Lang.both].indexOf(_lang) : (_lang == _Lang.en ? 0 : 1),
                latin: layout != ReaderLayout.webtoon,
                onChanged: (i) => setState(() => _lang = layout == ReaderLayout.webtoon ? [_Lang.fa, _Lang.en, _Lang.both][i] : (i == 0 ? _Lang.en : _Lang.fa)),
              ),
            ]),
          ),
        ),
      ),
      if (_showResume)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 72,
          left: MRSpacing.space5,
          right: MRSpacing.space5,
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(MRSpacing.space3),
              decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
              child: Row(children: [
                Icon(Icons.replay, color: c.success, size: 22),
                const SizedBox(width: MRSpacing.space3),
                Expanded(child: Text('از صفحه ${faDigits(_page + 1)} که روی گوشی دیگرتان ماندید ادامه دادیم', style: MRText.body.copyWith(color: c.textPrimary))),
                MikoIconButton(icon: Icons.close, semanticLabel: 'بستن پیام', filled: false, size: 36, onPressed: () => setState(() => _showResume = false)),
              ]),
            ),
          ),
        ),
      // Bottom bar
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _BarFade(
          visible: _bars,
          reduce: reduce,
          child: _bottomBar(context, layout, rtl, spread, bookmarked),
        ),
      ),
    ]);
  }

  Widget _bottomBar(BuildContext context, ReaderLayout layout, bool rtl, bool spread, bool bookmarked) {
    final c = context.mr;
    final s = ref.watch(readerSettingsProvider);
    final ctl = ref.read(readerSettingsProvider.notifier);
    final pageText = spread && _page + 1 < _ch.pageCount
        ? 'صفحه ${faDigits(_page + 1)}–${faDigits(_page + 2)} از ${faDigits(_ch.pageCount)}'
        : 'صفحه ${faDigits(_page + 1)} از ${faDigits(_ch.pageCount)}';

    Widget action(IconData icon, String text, VoidCallback onTap, {bool active = false}) => Expanded(
          child: Semantics(
            button: true,
            label: text,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: SizedBox(
                height: 52,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, size: 22, color: active ? c.red400 : c.textPrimary),
                  const SizedBox(height: 2),
                  ExcludeSemantics(child: Text(text, style: MRText.label.copyWith(color: c.textPrimary))),
                ]),
              ),
            ),
          ),
        );

    return Container(
      color: c.bgBase.withValues(alpha: 0.96),
      padding: EdgeInsets.fromLTRB(MRSpacing.space4, MRSpacing.space3, MRSpacing.space4, MediaQuery.paddingOf(context).bottom + MRSpacing.space2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (layout != ReaderLayout.webtoon)
          Row(children: [
            // Previous chapter sits at the start (right in RTL), next at the end — direction-neutral labels.
            MikoIconButton(icon: Icons.chevron_right, semanticLabel: rtl ? 'چپتر قبلی' : 'چپتر بعدی', onPressed: rtl ? (_hasPrev ? () => _goChapter(_ch.number - 1) : null) : (_hasNext ? () => _goChapter(_ch.number + 1) : null)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space3),
                child: Column(children: [
                  Directionality(
                    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: _fraction, minHeight: 6, backgroundColor: c.switchOff, valueColor: AlwaysStoppedAnimation(c.red500)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(pageText, style: MRText.caption.copyWith(fontSize: 11, color: c.textMuted)),
                    Text('${faDigits((_fraction * 100).round())}٪', style: MRText.caption.copyWith(fontSize: 11, color: c.textMuted)),
                  ]),
                ]),
              ),
            ),
            MikoIconButton(icon: Icons.chevron_left, semanticLabel: rtl ? 'چپتر بعدی' : 'چپتر قبلی', onPressed: rtl ? (_hasNext ? () => _goChapter(_ch.number + 1) : null) : (_hasPrev ? () => _goChapter(_ch.number - 1) : null)),
          ]),
        if (layout == ReaderLayout.webtoon) ...[
          _SliderRow('فیلتر شب', s.nightFilter, (v) => ctl.update(s.copyWith(nightFilter: v))),
          _SliderRow('روشنایی', s.brightness, (v) => ctl.update(s.copyWith(brightness: v))),
          Text('$pageText · قسمت بعدی تا پیش‌بارگذاری شود', style: MRText.caption.copyWith(color: c.textMuted)),
        ] else
          Row(children: [
            action(Icons.chat_bubble_outline, '${faDigits(_ch.commentCount)} نظر', () => context.push('/comments/${_ch.id}')),
            action(bookmarked ? Icons.bookmark : Icons.bookmark_border, bookmarked ? 'نشان شد' : 'نشان', () => ref.read(bookmarksProvider.notifier).toggle(_work.id), active: bookmarked),
            action(Icons.download_outlined, 'دانلود', () => _snack('دانلود به‌زودی فعال می‌شود')),
            action(Icons.tune, 'تنظیمات', () => showReaderSettings(context, _work.type)),
          ]),
        if (layout == ReaderLayout.webtoon)
          Row(children: [
            action(Icons.chat_bubble_outline, '${faDigits(_ch.commentCount)} نظر', () => context.push('/comments/${_ch.id}')),
            action(Icons.tune, 'تنظیمات', () => showReaderSettings(context, _work.type)),
          ]),
      ]),
    );
  }

  // ---- paged (manga RTL / comic LTR) ----

  Widget _paged(BuildContext context, bool rtl, bool spread) {
    final total = spread ? (_ch.pageCount + 1) ~/ 2 : _ch.pageCount;
    final items = total + 1; // + end card
    _pager ??= PageController(initialPage: (spread ? _page ~/ 2 : _page).clamp(0, items - 1));
    final pager = _pager!;

    Widget pageAt(int i) {
      if (i == total) return _EndCard(hasNext: _hasNext, number: _ch.number, unit: _work.type.unit, onNext: () => _goChapter(_ch.number + 1), onBack: () => context.pop());
      if (!spread) return ReaderPagePlaceholder(page: i, lang: _langLabel);
      // Spread: first page on the reading-start side.
      final a = i * 2, b = a + 1;
      return Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Row(children: [
          Expanded(child: ReaderPagePlaceholder(page: a, lang: _langLabel)),
          const SizedBox(width: 4),
          Expanded(child: b < _ch.pageCount ? ReaderPagePlaceholder(page: b, lang: _langLabel) : const SizedBox()),
        ]),
      );
    }

    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final x = d.localPosition.dx / box.maxWidth;
          final cur = pager.hasClients ? (pager.page ?? 0).round() : 0;
          if (x < 0.28 || x > 0.72) {
            // Forward = toward the end of the chapter: left side for RTL reading, right for LTR.
            final forward = rtl ? x < 0.28 : x > 0.72;
            final target = cur + (forward ? 1 : -1);
            if (target >= 0 && target < items) _go(pager, target);
          } else {
            _toggleBars();
          }
        },
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: 0),
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: PageView.builder(
              key: ValueKey('pager-$spread-$rtl'),
              controller: pager,
              itemCount: items,
              onPageChanged: (i) => _setPage(i >= total ? _ch.pageCount - 1 : (spread ? i * 2 : i)),
              itemBuilder: (_, i) => Padding(padding: const EdgeInsets.fromLTRB(8, 72, 8, 130), child: pageAt(i)),
            ),
          ),
        ),
      ),
    );
  }

  String get _langLabel => switch (_lang) { _Lang.fa => 'FA', _Lang.en => 'EN', _Lang.both => 'FA · EN' };

  // ---- vertical / webtoon ----

  Widget _scrolling(BuildContext context, ReaderLayout layout, ReaderSettings s) {
    final width = MediaQuery.sizeOf(context).width;
    final gap = layout == ReaderLayout.vertical ? 12.0 : 0.0;
    final extent = width * 1.35 + gap;
    _scroll ??= ScrollController(initialScrollOffset: _page * extent)
      ..addListener(() {
        final p = (_scroll!.offset / extent).floor().clamp(0, _ch.pageCount - 1);
        _setPage(p);
      });
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleBars,
      child: ListView.builder(
        key: ValueKey('scroll-$layout'),
        controller: _scroll,
        itemExtent: extent,
        itemCount: _ch.pageCount + 1,
        itemBuilder: (_, i) => i == _ch.pageCount
            ? _EndCard(hasNext: _hasNext, number: _ch.number, unit: _work.type.unit, onNext: () => _goChapter(_ch.number + 1), onBack: () => context.pop())
            : Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: ReaderPagePlaceholder(page: i, lang: _langLabel, borderless: layout == ReaderLayout.webtoon),
              ),
      ),
    );
  }
}

class _BarFade extends StatelessWidget {
  const _BarFade({required this.visible, required this.reduce, required this.child});
  final bool visible, reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: reduce ? Duration.zero : MRMotion.base, child: child),
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.labels, required this.index, required this.onChanged, this.latin = false});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool latin;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MRRadius.radiusMd)),
      child: Directionality(
        textDirection: latin ? TextDirection.ltr : TextDirection.rtl,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < labels.length; i++)
            Semantics(
              selected: i == index,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: i == index ? c.red500 : null, borderRadius: BorderRadius.circular(MRRadius.radiusSm)),
                  child: Text(labels[i], style: MRText.label.copyWith(fontSize: 12, color: i == index ? c.onBrand : c.textMuted)),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow(this.label, this.value, this.onChanged);
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: MRText.body.copyWith(color: c.textPrimary))),
      Expanded(child: mikoSlider(value: value, label: label, onChanged: onChanged)),
      SizedBox(width: 40, child: Text('${faDigits((value * 100).round())}٪', textAlign: TextAlign.end, style: MRText.caption.copyWith(color: c.textMuted))),
    ]);
  }
}

class _EndCard extends StatelessWidget {
  const _EndCard({required this.hasNext, required this.number, required this.unit, required this.onNext, required this.onBack});
  final bool hasNext;
  final int number;
  final String unit;
  final VoidCallback onNext, onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('پایان $unit ${faDigits(number)}', style: MRText.h2.copyWith(color: c.textPrimary)),
          const SizedBox(height: MRSpacing.space4),
          if (hasNext) MikoButton(label: '$unit بعدی', onPressed: onNext) else Text('آخرین $unit تا اینجا منتشر شده', style: MRText.body.copyWith(color: c.textMuted)),
          const SizedBox(height: MRSpacing.space2),
          MikoButton(label: 'بازگشت به صفحه اثر', kind: MikoButtonKind.secondary, onPressed: onBack),
        ]),
      ),
    );
  }
}
