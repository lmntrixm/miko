import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/pressable.dart';
import '../account/account_widgets.dart';

enum ListBy { popular, updated, added }

/// «فهرست کامل»: popular · latest · newly added, in a 3-column grid.
class ListAllScreen extends ConsumerStatefulWidget {
  const ListAllScreen({super.key, this.type});
  final WorkType? type;

  @override
  ConsumerState<ListAllScreen> createState() => _ListAllScreenState();
}

class _ListAllScreenState extends ConsumerState<ListAllScreen> {
  ListBy _by = ListBy.popular;
  int _cols = 3;
  int _range = 0; // this week / this month / all time (backend filters by range; the mock ignores it)
  static const _titles = {ListBy.popular: 'محبوب‌ترین‌ها', ListBy.updated: 'بروزترین‌ها', ListBy.added: 'تازه اضافه‌شده'};

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final works = ref.watch(worksProvider(widget.type));
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          SubHeader(
            title: _titles[_by]!,
            trailing: MikoIconButton(
              icon: _cols == 3 ? Icons.grid_view : Icons.view_module_outlined,
              semanticLabel: _cols == 3 ? 'نمایش دو ستونه' : 'نمایش سه ستونه',
              onPressed: () => setState(() => _cols = _cols == 3 ? 2 : 3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
            child: Wrap(spacing: MRSpacing.space2, children: [for (final e in _titles.entries) MikoChip(label: e.value, selected: _by == e.key, onTap: () => setState(() => _by = e.key))]),
          ),
          if (_by == ListBy.popular)
            Padding(
              padding: const EdgeInsets.fromLTRB(MRSpacing.space4, 0, MRSpacing.space4, MRSpacing.space2),
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('بازه:', style: MRText.caption.copyWith(color: c.textMuted)),
                const SizedBox(width: MRSpacing.space2),
                for (final (i, l) in ['این هفته', 'این ماه', 'همه زمان‌ها'].indexed) Padding(padding: const EdgeInsetsDirectional.only(end: MRSpacing.space2), child: MikoChip(label: l, selected: _range == i, onTap: () => setState(() => _range = i))),
              ]),
            ),
          Expanded(
            child: AsyncView<List<Work>>(
              value: works,
              onRetry: () => ref.invalidate(worksProvider(widget.type)),
              builder: (all) {
                final list = [...all];
                switch (_by) {
                  case ListBy.popular:
                    list.sort((a, b) => b.views.compareTo(a.views));
                  case ListBy.updated:
                    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                  case ListBy.added:
                    list.sort((a, b) => b.chapterCount.compareTo(a.chapterCount)); // placeholder until the API has "added at"
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(MRSpacing.space4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _cols, mainAxisSpacing: MRSpacing.space4, crossAxisSpacing: MRSpacing.space3, childAspectRatio: _cols == 3 ? 0.56 : 0.7),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final w = list[i];
                    return Pressable(
                      onTap: () => context.push('/home/title/${w.id}'),
                      semanticLabel: '${w.nameFa}، رتبه ${faDigits(i + 1)}',
                      child: ExcludeSemantics(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Stack(children: [
                              const Positioned.fill(child: CoverPlaceholder(radius: MRRadius.radiusLg)),
                              PositionedDirectional(
                                top: 6,
                                end: 6,
                                child: Container(
                                  width: 28,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: i < 3 ? c.red500 : c.bgBase, borderRadius: BorderRadius.circular(8)),
                                  child: Text(faDigits(i + 1), style: MRText.label.copyWith(color: i < 3 ? c.onBrand : c.textPrimary)),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 4),
                          Text(w.nameFa, maxLines: 1, overflow: TextOverflow.ellipsis, style: MRText.h3.copyWith(fontSize: 13, color: c.textPrimary)),
                          Text('★ ${faDigits(w.rating.toStringAsFixed(1).replaceAll('.', '٫'))} · ${w.type.label}', style: MRText.caption.copyWith(fontSize: 11, color: c.textMuted)),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
