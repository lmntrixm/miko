import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';

/// How often the bank confirmation is polled. Shortened in tests.
final paymentPollIntervalProvider = Provider<Duration>((ref) => const Duration(seconds: 3));

/// Back from the bank page: poll until the bank confirms, then show the result.
class PaymentPendingScreen extends ConsumerStatefulWidget {
  const PaymentPendingScreen({super.key, required this.sessionId, this.chapterId});
  final String sessionId;
  final String? chapterId;

  @override
  ConsumerState<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends ConsumerState<PaymentPendingScreen> {
  Timer? _timer;
  bool _checking = false;
  bool _slow = false;
  late final DateTime _since = DateTime.now();

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(ref.read(paymentPollIntervalProvider), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_checking) return;
    _checking = true;
    try {
      final r = await ref.read(contentRepositoryProvider).paymentStatus(widget.sessionId);
      if (!mounted) return;
      if (r.status != PaymentStatus.pending) {
        _timer?.cancel();
        ref.invalidate(subscriptionProvider);
        final q = widget.chapterId == null ? '' : '?chapter=${widget.chapterId}';
        context.pushReplacement('/payment-result/${widget.sessionId}$q', extra: r);
        return;
      }
      // After 2 minutes stop promising a quick answer (UX copy).
      if (DateTime.now().difference(_since) > const Duration(minutes: 2)) setState(() => _slow = true);
    } catch (_) {
      // Keep polling; a transient network error must not lose the payment.
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final reduce = MediaQuery.disableAnimationsOf(context);
    Widget step(int n, String text, {required bool done, required bool active}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: done ? c.success.withValues(alpha: 0.9) : active ? c.red500 : c.switchOff),
              child: done ? Icon(Icons.check, size: 15, color: c.onBrand) : Text('$n', style: MRText.label.copyWith(color: c.onBrand)),
            ),
            const SizedBox(width: MRSpacing.space3),
            Text(text, style: MRText.body.copyWith(fontWeight: active || done ? FontWeight.w700 : FontWeight.w400, color: done || active ? c.textPrimary : c.textMuted)),
          ]),
        );

    // The payment is in flight: block accidental back navigation.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MRSpacing.space5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              Center(
                child: Semantics(
                  label: 'در حال بررسی پرداخت',
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: reduce
                        ? CircularProgressIndicator(value: 0.25, strokeWidth: 6, color: c.red500, backgroundColor: c.surface3)
                        : CircularProgressIndicator(strokeWidth: 6, color: c.red500, backgroundColor: c.surface3),
                  ),
                ),
              ),
              const SizedBox(height: MRSpacing.space5),
              Semantics(liveRegion: true, header: true, child: Text('در حال بررسی پرداخت', textAlign: TextAlign.center, style: MRText.h1.copyWith(fontSize: 24, color: c.textPrimary))),
              const SizedBox(height: MRSpacing.space3),
              Text('از درگاه بانک برگشتید. تأیید بانک معمولاً چند ثانیه طول می‌کشد؛ لطفاً اپ را نبندید.',
                  textAlign: TextAlign.center, style: MRText.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: MRSpacing.space5),
              Container(
                padding: const EdgeInsets.all(MRSpacing.space4),
                decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: c.border1)),
                child: Column(children: [
                  step(1, 'پرداخت در درگاه انجام شد', done: true, active: false),
                  step(2, 'در انتظار تأیید بانک…', done: false, active: true),
                  step(3, 'فعال‌سازی اشتراک', done: false, active: false),
                ]),
              ),
              const SizedBox(height: MRSpacing.space4),
              Text(
                _slow
                    ? 'هنوز تأیید نشده. اگر نتیجه نیامد، وضعیت را در «تاریخچه پرداخت‌ها» ببینید؛ در صورت ناموفق بودن، مبلغ کسرشده تا ۷۲ ساعت برمی‌گردد.'
                    : 'اگر تا ۲ دقیقه نتیجه نیامد، وضعیت در «تاریخچه پرداخت‌ها» به‌روز می‌شود و مبلغ کسرشده در صورت ناموفق بودن تا ۷۲ ساعت برمی‌گردد.',
                style: MRText.caption.copyWith(color: _slow ? c.warning : c.textMuted),
              ),
              const Spacer(),
              MikoButton(label: 'بررسی دوباره', kind: MikoButtonKind.secondary, onPressed: _poll),
              const SizedBox(height: MRSpacing.space2),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/payment-history'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(widthFactor: 1, child: Text('تاریخچه پرداخت‌ها', style: MRText.caption.copyWith(fontSize: 13, color: c.red300))),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
