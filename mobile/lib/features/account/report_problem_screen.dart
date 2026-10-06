import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/account_providers.dart';
import '../../data/account_repository.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/snack.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

const _kinds = {
  ProblemKind.translation: 'ترجمه اشتباه',
  ProblemKind.brokenPage: 'صفحه خراب یا جاافتاده',
  ProblemKind.pageOrder: 'ترتیب صفحات',
  ProblemKind.lowQuality: 'کیفیت تصویر پایین',
  ProblemKind.wrongLanguage: 'زبان اشتباه',
  ProblemKind.other: 'مورد دیگر',
};

/// Report a translation/page problem. Chapter, page and language are attached automatically when known.
class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key, this.chapterId, this.page, this.lang});
  final String? chapterId, lang;
  final int? page;

  @override
  ConsumerState<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  ProblemKind _kind = ProblemKind.translation;
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_kind == ProblemKind.other && _text.text.trim().isEmpty) {
      setState(() => _error = 'برای «مورد دیگر» لطفاً توضیح بنویسید');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).reportProblem(ProblemReport(kind: _kind, description: _text.text.trim(), chapterId: widget.chapterId, page: widget.page, lang: widget.lang));
      if (!mounted) return;
      showSnack(context, 'گزارش شما ثبت شد. ممنون که کمک می‌کنید.');
      context.canPop() ? context.pop() : context.go('/home');
    } catch (_) {
      if (mounted) setState(() => _error = 'ارسال نشد. اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final ref0 = ChapterRef.tryParse(widget.chapterId);
    final work = ref0 == null ? null : ref.watch(workProvider(ref0.workId)).asData?.value;
    final lang = switch (widget.lang) { 'en' => 'انگلیسی', 'both' => 'دوزبانه', 'fa' => 'فارسی', _ => null };
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'گزارش مشکل'),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
              if (work != null)
                Container(
                  padding: const EdgeInsets.all(MRSpacing.space4),
                  decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${work.nameFa} · ${work.type.unit} ${faDigits(ref0!.number)}', style: MRText.h3.copyWith(color: c.textPrimary)),
                    Text(
                      [if (widget.page != null) 'صفحه ${faDigits(widget.page! + 1)}', ?lang, 'به‌صورت خودکار ضمیمه شد'].join(' · '),
                      style: MRText.caption.copyWith(color: c.textMuted),
                    ),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.only(top: MRSpacing.space5, bottom: MRSpacing.space3),
                child: Semantics(header: true, child: Text('مشکل چیست؟', style: MRText.h3.copyWith(color: c.textPrimary))),
              ),
              Wrap(spacing: MRSpacing.space2, children: [for (final e in _kinds.entries) MikoChip(label: e.value, selected: _kind == e.key, onTap: () => setState(() => _kind = e.key))]),
              const SizedBox(height: MRSpacing.space4),
              Text('توضیح', style: MRText.body.copyWith(color: c.textMuted)),
              const SizedBox(height: MRSpacing.space2),
              Container(
                padding: const EdgeInsets.all(MRSpacing.space4),
                decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: _error != null ? c.danger : c.border2)),
                child: TextField(
                  controller: _text,
                  minLines: 5,
                  maxLines: 8,
                  cursorColor: c.red400,
                  style: MRText.body.copyWith(color: c.textPrimary),
                  decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'مثلاً: در حباب دوم، نام شخصیت اشتباه ترجمه شده', hintStyle: MRText.body.copyWith(color: c.textHint)),
                ),
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_error!, style: MRText.caption.copyWith(color: c.danger))),
              const SizedBox(height: MRSpacing.space3),
              // Screenshot upload needs image_picker + backend storage; not wired yet.
              Pressable(
                onTap: () => showSnack(context, 'افزودن اسکرین‌شات به‌زودی فعال می‌شود'),
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border2)),
                  child: Text('+ افزودن اسکرین‌شات', style: MRText.body.copyWith(color: c.textSecondary)),
                ),
              ),
              const SizedBox(height: MRSpacing.space6),
              MikoButton(label: 'ارسال گزارش', loading: _sending, loadingLabel: 'در حال ارسال…', onPressed: _send),
            ]),
          ),
        ]),
      ),
    );
  }
}
