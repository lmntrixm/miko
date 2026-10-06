import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/jalali.dart';
import '../../core/persian.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';
import 'billing_widgets.dart';

/// Result of a payment. [outcome] is passed from the pending screen.
class PaymentResultScreen extends ConsumerWidget {
  const PaymentResultScreen({super.key, required this.outcome, this.chapterId});
  final PaymentOutcome outcome;
  final String? chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    final ok = outcome.status == PaymentStatus.success;
    final pay = outcome.payment;
    final plan = outcome.plan;
    final ch = ChapterRef.tryParse(chapterId);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(MRSpacing.space5), children: [
            const SizedBox(height: MRSpacing.space6),
            Center(
              child: Semantics(
                label: ok ? 'پرداخت موفق' : 'پرداخت ناموفق',
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ok ? c.successBg : c.dangerBg,
                    border: Border.all(color: ok ? c.success : c.danger, width: 3),
                  ),
                  child: Icon(ok ? Icons.check : Icons.close, size: 48, color: ok ? c.success : c.danger),
                ),
              ),
            ),
            const SizedBox(height: MRSpacing.space5),
            Semantics(
              liveRegion: true,
              header: true,
              child: Text(ok ? 'اشتراک ${plan?.name ?? ''} فعال شد' : 'پرداخت انجام نشد', textAlign: TextAlign.center, style: MRText.h1.copyWith(fontSize: 24, color: c.textPrimary)),
            ),
            const SizedBox(height: MRSpacing.space2),
            Text(
              ok
                  ? (outcome.endsAt == null ? '' : 'تا ${Jalali.fromDateTime(outcome.endsAt!).format()} به همه چپترها دسترسی دارید.')
                  : 'اگر مبلغی کم شده، تا ۷۲ ساعت برمی‌گردد. می‌توانید دوباره امتحان کنید.',
              textAlign: TextAlign.center,
              style: MRText.body.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: MRSpacing.space5),
            if (pay != null)
              Container(
                padding: const EdgeInsets.all(MRSpacing.space4),
                decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                child: Column(children: [
                  const InfoRow('مبلغ', '$amountPlaceholder تومان'),
                  InfoRow('درگاه', pay.gateway ?? '—'),
                  InfoRow('کد پیگیری', pay.trackingCode, ltr: true),
                  InfoRow('تاریخ', Jalali.fromDateTime(pay.date).format()),
                ]),
              ),
            const SizedBox(height: MRSpacing.space5),
            if (ok)
              MikoButton(
                label: ch == null ? 'بازگشت به خانه' : 'ادامه خواندن ${faDigits(ch.number)} #',
                onPressed: () {
                  context.go('/home');
                  if (ch != null) context.push('/reader/${ch.id}');
                },
              )
            else ...[
              MikoButton(label: 'تلاش دوباره', onPressed: () => context.pushReplacement('/subscription${chapterId == null ? '' : '?chapter=$chapterId'}')),
              const SizedBox(height: MRSpacing.space2),
              MikoButton(label: 'پشتیبانی', kind: MikoButtonKind.secondary, onPressed: () => context.push('/help-center')),
            ],
            const SizedBox(height: MRSpacing.space2),
            Center(
              child: GestureDetector(
                onTap: () => context.go(ok ? '/payment-history' : '/home'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(widthFactor: 1, child: Text(ok ? 'تاریخچه پرداخت‌ها' : 'بازگشت به خانه', style: MRText.caption.copyWith(fontSize: 13, color: c.textSecondary))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
