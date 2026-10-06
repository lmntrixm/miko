import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/pressable.dart';
import 'billing_widgets.dart';

/// 402 target: "ادامه این چپتر با اشتراک". [chapterId] is the locked chapter, if known.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.chapterId});
  final String? chapterId;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _plan = 'month3';

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final plans = ref.watch(plansProvider);
    final ref0 = ChapterRef.tryParse(widget.chapterId);
    final work = ref0 == null
        ? null
        : ref.watch(workProvider(ref0.workId)).asData?.value;

    return Scaffold(
      backgroundColor: c.bgBase,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.switchOff, c.bgBase],
            stops: const [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MRSpacing.space4),
                child: Row(
                  children: [
                    MikoIconButton(
                      icon: Icons.arrow_forward,
                      semanticLabel: 'بازگشت',
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                    const SizedBox(width: MRSpacing.space3),
                    if (work != null)
                      Expanded(
                        child: Text(
                          '${work.nameFa} · ${work.type.unit} ${faDigits(ref0!.number)}',
                          style: MRText.h3.copyWith(color: c.textPrimary),
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
              // Scrolls on short screens (landscape, 160% font); sits at the bottom otherwise.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MRSpacing.space5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: mrBrandGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 34,
                          color: c.onBrand,
                        ),
                      ),
                    ),
                    const SizedBox(height: MRSpacing.space4),
                    Semantics(
                      header: true,
                      child: Text(
                        'ادامه این چپتر با اشتراک',
                        textAlign: TextAlign.center,
                        style: MRText.h1.copyWith(
                          fontSize: 24,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: MRSpacing.space3),
                    Text(
                      work == null
                          ? '۳ چپتر اول هر اثر رایگان است. با اشتراک، همهٔ چپترها را به فارسی و انگلیسی بخوانید و دانلود کنید.'
                          : '۳ چپتر اول هر اثر رایگان است. با اشتراک، همه ${faDigits(work.chapterCount)} ${work.type.unit} را به فارسی و انگلیسی بخوانید و دانلود کنید.',
                      textAlign: TextAlign.center,
                      style: MRText.body.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: MRSpacing.space5),
                    SizedBox(
                      height: 90,
                      child: AsyncView<List<Plan>>(
                        value: plans,
                        onRetry: () => ref.invalidate(plansProvider),
                        builder: (list) => Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final p in list)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: PlanTile(
                                    plan: p,
                                    selected: p.id == _plan,
                                    onTap: () => setState(() => _plan = p.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: MRSpacing.space4),
                    MikoButton(
                      label: 'خرید اشتراک و ادامه خواندن',
                      kind: MikoButtonKind.hero,
                      onPressed: () {
                        final q = {
                          'plan': _plan,
                          if (widget.chapterId != null)
                            'chapter': widget.chapterId!,
                        };
                        context.push(
                          Uri(
                            path: '/subscription',
                            queryParameters: q,
                          ).toString(),
                        );
                      },
                    ),
                    const SizedBox(height: MRSpacing.space2),
                    Row(
                      children: [
                        if (ref0 != null)
                          _Link(
                            'خواندن ${work?.type.unit ?? 'چپتر'} ${faDigits(1)} رایگان',
                            onTap: () => context.pushReplacement(
                              '/reader/${ref0.workId}~1',
                            ),
                          ),
                        const Spacer(),
                        _Link(
                          'بازیابی خرید قبلی',
                          muted: true,
                          onTap: _restore,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                          const SizedBox(height: MRSpacing.space3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(contentRepositoryProvider).restorePurchase();
    ref.invalidate(subscriptionProvider);
    final sub = await ref.read(subscriptionProvider.future);
    if (!mounted) return;
    if (sub.active) {
      messenger.showSnackBar(
        const SnackBar(content: Text('اشتراک شما بازیابی شد')),
      );
      context.pop();
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'خرید قبلی پیدا نشد. اگر پرداخت کرده‌اید، با پشتیبانی تماس بگیرید.',
          ),
        ),
      );
    }
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, {required this.onTap, this.muted = false});
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Pressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: MRText.caption.copyWith(
              fontSize: 13,
              color: muted ? c.textMuted : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
