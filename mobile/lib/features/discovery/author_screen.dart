import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/discovery_providers.dart';
import '../../data/discovery_repository.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';

class AuthorScreen extends ConsumerWidget {
  const AuthorScreen({super.key, required this.authorId});
  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final author = ref.watch(authorProvider(authorId));
    final all = ref.watch(worksProvider(null)).asData?.value ?? const <Work>[];
    final following = ref.watch(followedAuthorsProvider).contains(authorId);
    return Scaffold(
      body: AsyncView<Author>(
        value: author,
        onRetry: () => ref.invalidate(authorProvider(authorId)),
        builder: (a) {
          final works = all.where((w) => a.workIds.contains(w.id)).toList();
          final avg = works.isEmpty ? 0.0 : works.fold<double>(0, (s, w) => s + w.rating) / works.length;
          return ListView(padding: EdgeInsets.zero, children: [
            Container(
              height: 150,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.red800, c.bgPage])),
              padding: EdgeInsets.fromLTRB(MRSpacing.space3, MediaQuery.paddingOf(context).top + 4, MRSpacing.space3, 0),
              alignment: AlignmentDirectional.topEnd,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: MikoIconButton(icon: Icons.arrow_forward, semanticLabel: 'بازگشت', onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      width: 96,
                      height: 96,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MRRadius.radiusXl), border: Border.all(color: c.bgPage, width: 4)),
                      child: Text(a.nameFa.characters.first, style: MRText.display.copyWith(color: c.textPrimary)),
                    ),
                    const SizedBox(width: MRSpacing.space3),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Semantics(header: true, child: Text(a.nameFa, style: MRText.h1.copyWith(fontSize: 24, color: c.textPrimary))),
                        Text.rich(TextSpan(children: [TextSpan(text: a.nameEn, style: const TextStyle(fontFamily: MRText.family)), TextSpan(text: ' · ${a.role}')]), style: MRText.caption.copyWith(color: c.textMuted)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: MRSpacing.space4),
                  Row(children: [
                    Expanded(
                      child: MikoButton(
                        label: following ? 'دنبال می‌کنید' : 'دنبال کردن نویسنده',
                        kind: following ? MikoButtonKind.secondary : MikoButtonKind.primary,
                        onPressed: () => ref.read(followedAuthorsProvider.notifier).toggle(authorId),
                      ),
                    ),
                    const SizedBox(width: MRSpacing.space3),
                    MikoIconButton(icon: Icons.share_outlined, semanticLabel: 'اشتراک‌گذاری', size: 52, onPressed: () {}),
                  ]),
                  const SizedBox(height: MRSpacing.space3),
                  Row(children: [
                    for (final (v, l) in [(faDigits(works.length), 'اثر در اپ'), (faCompact(a.followers + (following ? 1 : 0)), 'دنبال‌کننده'), (faDigits(avg.toStringAsFixed(1).replaceAll('.', '٫')), 'میانگین امتیاز')])
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: MRSpacing.space4),
                          decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                          child: Column(children: [Text(v, style: MRText.h1.copyWith(fontSize: 22, color: c.textPrimary)), Text(l, style: MRText.caption.copyWith(color: c.textMuted))]),
                        ),
                      ),
                  ]),
                  const SizedBox(height: MRSpacing.space4),
                  Text(a.bio, style: MRText.body.copyWith(color: c.textSecondary)),
                  const SizedBox(height: MRSpacing.space5),
                  Semantics(header: true, child: Text('آثار', style: MRText.h2.copyWith(color: c.textPrimary))),
                  const SizedBox(height: MRSpacing.space3),
                  SizedBox(
                    height: 236,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: works.length,
                      separatorBuilder: (_, _) => const SizedBox(width: MRSpacing.space3),
                      itemBuilder: (_, i) => Pressable(
                        onTap: () => context.push('/home/title/${works[i].id}'),
                        semanticLabel: works[i].nameFa,
                        child: SizedBox(
                          width: 108,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const CoverPlaceholder(height: 150, radius: MRRadius.radiusLg),
                            const SizedBox(height: 6),
                            Text(works[i].nameFa, maxLines: 1, overflow: TextOverflow.ellipsis, style: MRText.h3.copyWith(fontSize: 13, color: c.textPrimary)),
                            Text('${faDigits(works[i].chapterCount)} ${works[i].type.unit}${works[i].status == WorkStatus.finished ? ' · تمام‌شده' : ''}', style: MRText.caption.copyWith(color: c.textMuted)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
