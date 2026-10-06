import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/discovery_providers.dart';
import '../../data/discovery_repository.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_badge.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/pressable.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;
  bool _filters = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => ref.read(searchQueryProvider.notifier).set(v));
  }

  void _submit(String v) {
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).set(v);
    ref.read(recentSearchesProvider.notifier).add(v);
  }

  void _use(String q) {
    _text.text = q;
    _submit(q);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final q = ref.watch(searchQueryProvider);
    final f = ref.watch(searchFiltersProvider);
    final fctl = ref.read(searchFiltersProvider.notifier);
    final result = ref.watch(searchResultProvider);
    final recent = ref.watch(recentSearchesProvider);

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.all(MRSpacing.space5), children: [
        Row(children: [
          MikoIconButton(
            icon: Icons.tune,
            semanticLabel: _filters ? 'پنهان کردن فیلترها' : 'نمایش فیلترها',
            size: 56,
            onPressed: () => setState(() => _filters = !_filters),
          ),
          const SizedBox(width: MRSpacing.space3),
          Expanded(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
              decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusXl), border: Border.all(color: c.red600)),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    onChanged: _onChanged,
                    onSubmitted: _submit,
                    textInputAction: TextInputAction.search,
                    cursorColor: c.red400,
                    style: MRText.bodyLg.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'جستجوی نام اثر…', hintStyle: MRText.bodyLg.copyWith(color: c.textHint)),
                  ),
                ),
                Icon(Icons.search, color: c.textMuted),
              ]),
            ),
          ),
        ]),
        if (_filters) ...[
          const SizedBox(height: MRSpacing.space3),
          Wrap(spacing: MRSpacing.space2, children: [
            for (final t in WorkType.values) MikoChip(label: t.label, selected: f.type == t, onTap: () => fctl.set(f.type == t ? f.copyWith(clearType: true) : f.copyWith(type: t))),
            MikoChip(label: 'در حال انتشار', selected: f.ongoingOnly, onTap: () => fctl.set(f.copyWith(ongoingOnly: !f.ongoingOnly))),
            MikoChip(label: 'فارسی', selected: f.lang == 'fa', onTap: () => fctl.set(f.lang == 'fa' ? f.copyWith(clearLang: true) : f.copyWith(lang: 'fa'))),
            MikoChip(label: 'انگلیسی', selected: f.lang == 'en', onTap: () => fctl.set(f.lang == 'en' ? f.copyWith(clearLang: true) : f.copyWith(lang: 'en'))),
          ]),
        ],
        const SizedBox(height: MRSpacing.space3),
        if (q.trim().isEmpty)
          ..._idle(context, recent)
        else
          AsyncViewInline<SearchResult>(
            value: result,
            onRetry: () => ref.invalidate(searchResultProvider),
            builder: (r) => r.works.isEmpty ? _NoResults(query: q, suggestion: r.suggestion, onSuggest: _use) : _Results(query: q, works: r.works, sort: f.sort, onSort: () => fctl.set(f.copyWith(sort: f.sort == SearchSort.popular ? SearchSort.updated : SearchSort.popular))),
          ),
      ]),
    );
  }

  List<Widget> _idle(BuildContext context, List<String> recent) {
    final c = context.mr;
    return [
      Row(children: [
        Expanded(child: Semantics(header: true, child: Text('جستجوهای اخیر', style: MRText.h3.copyWith(color: c.textPrimary)))),
        if (recent.isNotEmpty)
          Pressable(
            onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
            child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44, minWidth: 44), child: Center(widthFactor: 1, child: Text('پاک کردن', style: MRText.caption.copyWith(fontSize: 13, color: c.red300)))),
          ),
      ]),
      if (recent.isEmpty)
        Text('نام یک اثر را بنویسید؛ فارسی یا انگلیسی.', style: MRText.body.copyWith(color: c.textMuted))
      else
        Wrap(spacing: MRSpacing.space2, children: [for (final r in recent) MikoChip(label: r, onTap: () => _use(r))]),
    ];
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.query, required this.works, required this.sort, required this.onSort});
  final String query;
  final List<Work> works;
  final SearchSort sort;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Semantics(liveRegion: true, child: Text('${faDigits(works.length)} نتیجه برای «$query»', style: MRText.body.copyWith(color: c.textMuted)))),
        Pressable(
          onTap: onSort,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(sort == SearchSort.popular ? 'محبوب‌ترین' : 'بروزترین', style: MRText.body.copyWith(color: c.textPrimary)),
              const SizedBox(width: 4),
              Icon(Icons.swap_vert, size: 20, color: c.textPrimary),
            ]),
          ),
        ),
      ]),
      for (final w in works) Padding(padding: const EdgeInsets.only(bottom: MRSpacing.space3), child: WorkResultCard(work: w)),
    ]);
  }
}

class WorkResultCard extends StatelessWidget {
  const WorkResultCard({super.key, required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Pressable(
      onTap: () => context.push('/home/title/${work.id}'),
      semanticLabel: '${work.nameFa}، ${work.nameEn}',
      child: Container(
        padding: const EdgeInsets.all(MRSpacing.space3),
        decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
        child: Row(children: [
          const CoverPlaceholder(width: 76, height: 104, radius: 12),
          const SizedBox(width: MRSpacing.space3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Directionality(textDirection: TextDirection.ltr, child: Align(alignment: AlignmentDirectional.centerStart, child: Text(work.nameEn, style: MRText.h3.copyWith(color: c.textPrimary)))),
              Text(work.nameFa, style: MRText.body.copyWith(color: c.textSecondary)),
              Text('${faDigits(work.chapterCount)} ${work.type.unit} · ${work.status == WorkStatus.ongoing ? 'در حال انتشار' : 'تمام‌شده'}', style: MRText.caption.copyWith(color: c.textMuted)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.star_rounded, size: 16, color: c.red400),
                const SizedBox(width: 2),
                Text(faDigits(work.rating.toStringAsFixed(1).replaceAll('.', '٫')), style: MRText.caption.copyWith(color: c.textSecondary)),
                const Spacer(),
                if (work.langs.length > 1) const MikoBadge.language() else MikoBadge(work.langs.first.toUpperCase()),
                const SizedBox(width: MRSpacing.space2),
                MikoBadge(work.type.label),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.suggestion, required this.onSuggest});
  final String query;
  final Work? suggestion;
  final ValueChanged<String> onSuggest;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(liveRegion: true, child: Text('نتیجه‌ای برای «$query» پیدا نشد', style: MRText.body.copyWith(color: c.textMuted))),
      const SizedBox(height: MRSpacing.space4),
      if (suggestion != null)
        Container(
          padding: const EdgeInsets.all(MRSpacing.space4),
          decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('منظورتان این بود؟', style: MRText.caption.copyWith(color: c.textMuted)),
            Row(children: [
              Expanded(child: Text(suggestion!.nameFa, style: MRText.h2.copyWith(color: c.textPrimary))),
              Pressable(
                onTap: () => onSuggest(suggestion!.nameFa),
                child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44, minWidth: 44), child: Center(widthFactor: 1, child: Text('مشاهده ›', style: MRText.caption.copyWith(fontSize: 13, color: c.red300)))),
              ),
            ]),
          ]),
        ),
      const SizedBox(height: MRSpacing.space4),
      Semantics(header: true, child: Text('پیشنهادها', style: MRText.h3.copyWith(color: c.textPrimary))),
      const SizedBox(height: MRSpacing.space2),
      Text('· املای نام را بررسی کنید یا نام انگلیسی را امتحان کنید', style: MRText.body.copyWith(color: c.textSecondary)),
      Text('· فیلترهای «فارسی» و «مانگا» را بردارید', style: MRText.body.copyWith(color: c.textSecondary)),
      const SizedBox(height: MRSpacing.space4),
      Container(
        padding: const EdgeInsets.all(MRSpacing.space4),
        decoration: BoxDecoration(color: c.red900, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.red800)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('اثری که دنبالش هستید را نداریم؟', style: MRText.h3.copyWith(color: c.textPrimary)),
          const SizedBox(height: 4),
          Text('درخواست ثبت کنید؛ وقتی اضافه شد خبرتان می‌کنیم.', style: MRText.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: MRSpacing.space3),
          MikoButton(label: 'درخواست افزودن اثر', onPressed: () => context.push(Uri(path: '/request-title', queryParameters: {'name': query}).toString())),
        ]),
      ),
    ]);
  }
}
