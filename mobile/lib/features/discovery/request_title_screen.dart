import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persian.dart';
import '../../data/discovery_providers.dart';
import '../../data/discovery_repository.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/cover_placeholder.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/pressable.dart';
import '../../widgets/snack.dart';
import '../account/account_widgets.dart';

/// "درخواست اثر جدید": ask for a title and vote on popular requests.
class RequestTitleScreen extends ConsumerStatefulWidget {
  const RequestTitleScreen({super.key, this.initialName = ''});
  final String initialName;

  @override
  ConsumerState<RequestTitleScreen> createState() => _RequestTitleScreenState();
}

class _RequestTitleScreenState extends ConsumerState<RequestTitleScreen> {
  late final _name = TextEditingController(text: widget.initialName);
  final _note = TextEditingController();
  WorkType _type = WorkType.manga;
  String _lang = 'fa';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'نام اثر را بنویسید');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(discoveryRepositoryProvider).submitRequest(name: _name.text.trim(), type: _type, lang: _lang, note: _note.text.trim());
      ref.invalidate(requestsProvider);
      if (!mounted) return;
      _name.clear();
      _note.clear();
      showSnack(context, 'درخواست ثبت شد. وقتی اضافه شد خبرتان می‌کنیم.');
    } catch (_) {
      if (mounted) setState(() => _error = 'ثبت نشد. اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final requests = ref.watch(requestsProvider);
    Widget label(String t) => Padding(padding: const EdgeInsets.only(top: MRSpacing.space4, bottom: MRSpacing.space2), child: Text(t, style: MRText.body.copyWith(color: c.textMuted)));
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'درخواست اثر جدید'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
              Text('اثری که دوست دارید در اپ نیست؟ درخواست بدهید؛ آثار پرطرفدار زودتر اضافه می‌شوند.', style: MRText.body.copyWith(color: c.textMuted)),
              label('نام اثر (فارسی یا انگلیسی)'),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: _error != null ? c.danger : c.border2)),
                child: TextField(controller: _name, cursorColor: c.red400, style: MRText.bodyLg.copyWith(color: c.textPrimary), decoration: InputDecoration(border: InputBorder.none, hintText: 'مثلاً Chainsaw Man', hintStyle: MRText.bodyLg.copyWith(color: c.textHint))),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, style: MRText.caption.copyWith(color: c.danger))),
              label('نوع'),
              Wrap(spacing: MRSpacing.space2, children: [for (final t in WorkType.values) MikoChip(label: t.label, selected: _type == t, onTap: () => setState(() => _type = t))]),
              label('زبان مورد نیاز'),
              Wrap(spacing: MRSpacing.space2, children: [
                MikoChip(label: 'فارسی', selected: _lang == 'fa', onTap: () => setState(() => _lang = 'fa')),
                MikoChip(label: 'انگلیسی', selected: _lang == 'en', onTap: () => setState(() => _lang = 'en')),
                MikoChip(label: 'هر دو', selected: _lang == 'both', onTap: () => setState(() => _lang = 'both')),
              ]),
              label('توضیح (اختیاری)'),
              Container(
                padding: const EdgeInsets.all(MRSpacing.space4),
                decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border2)),
                child: TextField(controller: _note, minLines: 4, maxLines: 6, cursorColor: c.red400, style: MRText.body.copyWith(color: c.textPrimary), decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'از کدام چپتر به بعد؟ لینک رسمی ناشر؟', hintStyle: MRText.body.copyWith(color: c.textHint))),
              ),
              const SizedBox(height: MRSpacing.space4),
              MikoButton(label: 'ثبت درخواست', loading: _sending, loadingLabel: 'در حال ثبت…', onPressed: _submit),
              Padding(padding: const EdgeInsets.only(top: MRSpacing.space6, bottom: MRSpacing.space3), child: Semantics(header: true, child: Text('درخواست‌های پرطرفدار', style: MRText.h3.copyWith(color: c.textPrimary)))),
              AsyncViewInline<List<TitleRequest>>(
                value: requests,
                onRetry: () => ref.invalidate(requestsProvider),
                builder: (list) => Column(children: [
                  for (final r in list)
                    Container(
                      margin: const EdgeInsets.only(bottom: MRSpacing.space3),
                      padding: const EdgeInsets.all(MRSpacing.space3),
                      decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                      child: Row(children: [
                        const CoverPlaceholder(width: 40, height: 56, radius: 8),
                        const SizedBox(width: MRSpacing.space3),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Directionality(textDirection: TextDirection.ltr, child: Text(r.nameEn, style: MRText.h3.copyWith(color: c.textPrimary))),
                            Text('${faDigits(r.votes)} رأی · ${r.status}', style: MRText.caption.copyWith(color: c.textMuted)),
                          ]),
                        ),
                        Semantics(
                          button: true,
                          toggled: r.votedByMe,
                          label: 'رأی به ${r.nameEn}',
                          child: Pressable(
                            onTap: () async {
                              await ref.read(discoveryRepositoryProvider).vote(r.id);
                              ref.invalidate(requestsProvider);
                            },
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: r.votedByMe ? c.red900 : c.surface3, borderRadius: BorderRadius.circular(MRRadius.radiusMd), border: r.votedByMe ? Border.all(color: c.red600) : null),
                              child: ExcludeSemantics(child: Text('+ رأی', style: MRText.body.copyWith(fontWeight: FontWeight.w700, color: r.votedByMe ? c.red300 : c.textPrimary))),
                            ),
                          ),
                        ),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
