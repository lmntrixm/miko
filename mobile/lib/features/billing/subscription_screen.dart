import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/persian.dart';
import '../../data/content_providers.dart';
import '../../data/models.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/snack.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import 'billing_widgets.dart';
import '../../core/jalali.dart';

/// Opens the bank page outside the app. Replaced in tests; the real one uses url_launcher.
abstract class ExternalLauncher {
  Future<bool> open(String url);
}

/// Opens the bank in the system browser (payment must never run inside the app).
class UrlLauncher implements ExternalLauncher {
  @override
  Future<bool> open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// The mock backend returns no gateway URL, so nothing opens until the real one exists. [لینک درگاه]
final externalLauncherProvider = Provider<ExternalLauncher>((ref) => UrlLauncher());

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, this.initialPlan, this.chapterId});
  final String? initialPlan;
  final String? chapterId;

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  late String _plan = widget.initialPlan ?? 'month3';
  final _coupon = TextEditingController();
  String? _couponError;
  String? _appliedCoupon;
  bool _checkingCoupon = false;
  bool _paying = false;

  static const _benefits = ['همه چپترها', 'دانلود آفلاین', 'فارسی و انگلیسی', 'بدون تبلیغات'];

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _checkingCoupon = true;
      _couponError = null;
    });
    try {
      await ref.read(contentRepositoryProvider).validateCoupon(code, _plan);
      if (mounted) setState(() => _appliedCoupon = code);
    } on InvalidCouponException {
      if (mounted) setState(() => _couponError = 'این کد معتبر نیست یا منقضی شده. دوباره بررسی کنید.');
    } finally {
      if (mounted) setState(() => _checkingCoupon = false);
    }
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final session = await ref.read(contentRepositoryProvider).startCheckout(_plan, coupon: _appliedCoupon);
      final url = session.gatewayUrl;
      if (url != null) await ref.read(externalLauncherProvider).open(url);
      if (!mounted) return;
      final q = {if (widget.chapterId != null) 'chapter': widget.chapterId!};
      context.pushReplacement(Uri(path: '/payment-pending/${session.id}', queryParameters: q.isEmpty ? null : q).toString());
    } catch (_) {
      if (mounted) {
        showSnack(context, 'شروع پرداخت ممکن نشد. اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.');
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final plans = ref.watch(plansProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          BillingHeader(title: 'خرید اشتراک', onBack: () => context.canPop() ? context.pop() : context.go('/home')),
          Expanded(
            child: AsyncView<List<Plan>>(
              value: plans,
              onRetry: () => ref.invalidate(plansProvider),
              builder: (list) {
                final plan = list.firstWhere((p) => p.id == _plan, orElse: () => list.first);
                final endsAt = DateTime.now().add(Duration(days: plan.days)); // estimate; the backend's date wins after payment
                return ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                  Wrap(spacing: MRSpacing.space3, runSpacing: MRSpacing.space3, children: [
                    for (final b in _benefits)
                      Container(
                        width: (MediaQuery.sizeOf(context).width - MRSpacing.space4 * 2 - MRSpacing.space3) / 2,
                        padding: const EdgeInsets.all(MRSpacing.space3),
                        decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusMd), border: Border.all(color: c.border1)),
                        child: Row(children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(color: c.red900, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.check, size: 16, color: c.red400),
                          ),
                          const SizedBox(width: MRSpacing.space2),
                          Expanded(child: Text(b, style: MRText.caption.copyWith(fontSize: 13, color: c.textPrimary))),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: MRSpacing.space4),
                  for (final p in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MRSpacing.space3),
                      child: PlanRow(plan: p, selected: p.id == _plan, onTap: () => setState(() {
                            _plan = p.id;
                            _appliedCoupon = null;
                          })),
                    ),
                  const SizedBox(height: MRSpacing.space2),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MikoButton(label: 'اعمال', kind: MikoButtonKind.secondary, expand: false, height: 56, loading: _checkingCoupon, onPressed: _apply),
                    const SizedBox(width: MRSpacing.space3),
                    Expanded(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MRRadius.radiusLg), border: Border.all(color: _couponError != null ? c.danger : c.border2)),
                        child: TextField(
                          controller: _coupon,
                          textDirection: TextDirection.ltr,
                          cursorColor: c.red400,
                          onSubmitted: (_) => _apply(),
                          style: MRText.body.copyWith(color: c.textPrimary),
                          decoration: InputDecoration(border: InputBorder.none, hintText: 'کد تخفیف دارید؟', hintStyle: MRText.body.copyWith(color: c.textHint)),
                        ),
                      ),
                    ),
                  ]),
                  if (_couponError != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_couponError!, style: MRText.caption.copyWith(color: c.danger))),
                  if (_appliedCoupon != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('کد تخفیف اعمال شد', style: MRText.caption.copyWith(color: c.success))),
                  const SizedBox(height: MRSpacing.space4),
                  Row(children: [
                    Text('مبلغ قابل پرداخت', style: MRText.body.copyWith(color: c.textMuted)),
                    const Spacer(),
                    Text('${priceText(plan)} تومان', style: MRText.h3.copyWith(color: c.textPrimary)),
                  ]),
                  const SizedBox(height: MRSpacing.space4),
                  MikoButton(label: 'پرداخت از درگاه بانکی', loading: _paying, loadingLabel: 'در حال اتصال به درگاه…', onPressed: _pay),
                  const SizedBox(height: MRSpacing.space3),
                  // Money rule: amount, duration, renewal date and the way out sit next to the pay button.
                  Text(
                    'اشتراک ${plan.name} (${faDigits(plan.days)} روز) · تمدید خودکار در ${Jalali.fromDateTime(endsAt).format()} · لغو تمدید در هر زمان از «مدیریت اشتراک»',
                    textAlign: TextAlign.center,
                    style: MRText.caption.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: MRSpacing.space1),
                  Text('پرداخت امن از درگاه بانکی بیرون از اپ', textAlign: TextAlign.center, style: MRText.caption.copyWith(color: c.textMuted)),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
