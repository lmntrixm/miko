import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/account_providers.dart';
import '../../data/account_repository.dart';
import '../../data/content_providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/snack.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _gift = TextEditingController();
  String? _giftError;
  bool _redeeming = false;

  @override
  void dispose() {
    _gift.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_gift.text.trim().isEmpty) return;
    setState(() {
      _redeeming = true;
      _giftError = null;
    });
    try {
      final days = await ref.read(accountRepositoryProvider).redeemGift(_gift.text);
      ref.invalidate(profileProvider);
      ref.invalidate(subscriptionProvider);
      if (!mounted) return;
      _gift.clear();
      showSnack(context, 'کد هدیه فعال شد؛ ${faDigits(days)} روز به اشتراک شما اضافه شد');
    } on InvalidGiftException {
      if (mounted) setState(() => _giftError = 'این کد معتبر نیست یا قبلاً استفاده شده.');
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final profile = ref.watch(profileProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'دعوت و هدیه'),
          Expanded(
            child: AsyncView(
              value: profile,
              onRetry: () => ref.invalidate(profileProvider),
              builder: (p) => ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                Container(
                  padding: const EdgeInsets.all(MRSpacing.space5),
                  decoration: BoxDecoration(gradient: mrCardGradient, borderRadius: BorderRadius.circular(MRRadius.radiusXl)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Semantics(header: true, child: Text('هر دوست = ${faDigits(inviteBonusDays)} روز رایگان', style: MRText.h1.copyWith(fontSize: 22, color: c.onBrand))),
                    const SizedBox(height: MRSpacing.space2),
                    Text('وقتی دوستانتان با کد شما اولین اشتراکش را بخرد، هر دوی شما ${faDigits(inviteBonusDays)} روز اشتراک هدیه می‌گیرید.', style: MRText.body.copyWith(color: c.onBrand)),
                    const SizedBox(height: MRSpacing.space4),
                    Row(children: [
                      Pressable(
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: p.inviteCode));
                          if (context.mounted) showSnack(context, 'کد دعوت کپی شد');
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52, minWidth: 64),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.onBrand, borderRadius: BorderRadius.circular(MRRadius.radiusMd)),
                          child: Text('کپی', style: MRText.h3.copyWith(color: MikoColors.light.red500)),
                        ),
                      ),
                      const SizedBox(width: MRSpacing.space3),
                      Expanded(
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: c.bgBase.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(MRRadius.radiusMd), border: Border.all(color: c.onBrand.withValues(alpha: 0.5))),
                          child: Text(p.inviteCode, textDirection: TextDirection.ltr, style: MRText.h2.copyWith(letterSpacing: 2, color: c.onBrand)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: MRSpacing.space3),
                    MikoButton(
                      label: 'اشتراک‌گذاری لینک دعوت',
                      kind: MikoButtonKind.secondary,
                      // [لینک دانلود]: the store link is not provided yet.
                      onPressed: () => ref.read(shareServiceProvider).share('با کد دعوت ${p.inviteCode} به میکو بپیوند و ${faDigits(inviteBonusDays)} روز اشتراک هدیه بگیر: [لینک دانلود]'),
                    ),
                  ]),
                ),
                const SizedBox(height: MRSpacing.space3),
                Row(children: [
                  for (final (v, l) in [(faDigits(p.invitedFriends), 'دوست دعوت‌شده'), ('${faDigits(p.giftDays)} روز', 'هدیه دریافت‌شده')])
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(MRSpacing.space4),
                        decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(v, style: MRText.h1.copyWith(fontSize: 22, color: c.textPrimary)),
                          Text(l, style: MRText.caption.copyWith(color: c.textMuted)),
                        ]),
                      ),
                    ),
                ]),
                const SizedBox(height: MRSpacing.space5),
                Semantics(header: true, child: Text('کد هدیه دارید؟', style: MRText.h3.copyWith(color: c.textPrimary))),
                const SizedBox(height: MRSpacing.space3),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  MikoButton(label: 'فعال‌سازی', expand: false, height: 56, loading: _redeeming, onPressed: _redeem),
                  const SizedBox(width: MRSpacing.space3),
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: _giftError != null ? c.danger : c.border2)),
                      child: TextField(
                        controller: _gift,
                        textDirection: TextDirection.ltr,
                        textCapitalization: TextCapitalization.characters,
                        cursorColor: c.red400,
                        onSubmitted: (_) => _redeem(),
                        style: MRText.body.copyWith(color: c.textPrimary),
                        decoration: InputDecoration(border: InputBorder.none, hintText: 'GIFT-XXXX', hintStyle: MRText.body.copyWith(color: c.textHint)),
                      ),
                    ),
                  ),
                ]),
                if (_giftError != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_giftError!, style: MRText.caption.copyWith(color: c.danger))),
                const SizedBox(height: MRSpacing.space4),
                SectionCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(MRSpacing.space4),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('اشتراک هدیه بخرید', style: MRText.h3.copyWith(color: c.textPrimary)),
                          Text('برای دوستان، با پیام شخصی', style: MRText.caption.copyWith(color: c.textMuted)),
                        ]),
                      ),
                      Pressable(
                        onTap: () => context.push('/subscription'),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                          child: Center(widthFactor: 1, child: Text('خرید ›', style: MRText.caption.copyWith(fontSize: 13, color: c.red300))),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
