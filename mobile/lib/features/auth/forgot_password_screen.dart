import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/validators.dart';
import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_text_field.dart';
import 'auth_copy.dart';
import 'auth_shell.dart';
import 'code_field.dart';
import 'otp_screen.dart';

/// 3 steps: email → recovery code → new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0;
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  static const _titles = ['فراموشی رمز عبور', 'کد بازیابی', 'رمز عبور جدید'];

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _subtitle => switch (_step) {
    0 => 'ایمیل حساب خود را وارد کنید تا کد بازیابی برایتان ارسال شود.',
    1 => 'کد ۶ رقمی ارسال‌شده به ${_email.text.trim()} را وارد کنید.',
    _ => 'یک رمز عبور جدید با حداقل ۸ کاراکتر انتخاب کنید.',
  };

  String get _cta => ['ارسال کد بازیابی', 'تأیید کد', 'ثبت رمز جدید'][_step];

  Future<void> _next() async {
    final repo = ref.read(authRepositoryProvider);
    String? err = switch (_step) {
      0 => validateEmail(_email.text),
      1 => _code.text.length == 6 ? null : 'کد ۶ رقمی را کامل وارد کنید',
      _ => validatePassword(_password.text),
    };
    if (err != null) return setState(() => _error = err);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      switch (_step) {
        case 0:
          await repo.requestReset(email);
        case 1:
          await repo.checkResetCode(email, _code.text);
        default:
          await repo.confirmReset(email, _code.text, _password.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رمز عبور تغییر کرد. وارد شوید.')),
            );
            context.go('/auth-login');
          }
          return;
      }
      if (mounted) setState(() => _step++);
    } catch (e) {
      if (mounted) setState(() => _error = errorOf(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: mrBrandGradient,
              ),
              child: Icon(Icons.lock_reset, size: 30, color: c.onBrand),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              _titles[_step],
              textAlign: TextAlign.center,
              style: MRText.h2.copyWith(fontSize: 21, color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: MRText.caption.copyWith(
              fontSize: 13,
              height: 1.9,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'مرحله ${_step + 1} از ۳',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: MRMotion.base,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _step ? 26 : 6,
                    decoration: BoxDecoration(
                      color: i <= _step ? c.red500 : c.switchOff,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_step == 0)
            MikoTextField(
              label: 'ایمیل',
              icon: Icons.mail_outline,
              ltr: true,
              hint: 'you@example.com',
              controller: _email,
              errorText: _error,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
            )
          else if (_step == 1) ...[
            CodeField(
              label: 'کد بازیابی',
              controller: _code,
              errorText: _error,
              onCompleted: (_) => _next(),
            ),
            const SizedBox(height: 12),
            ResendTimer(
              onResend: () => ref
                  .read(authRepositoryProvider)
                  .requestReset(_email.text.trim()),
            ),
          ] else
            MikoTextField(
              label: 'رمز عبور جدید',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _password,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
            ),
          const SizedBox(height: 20),
          MikoButton(
            label: _cta,
            kind: MikoButtonKind.hero,
            loading: _loading,
            loadingLabel: 'لطفاً صبر کنید…',
            onPressed: _next,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AuthLink(
                'بازگشت به ورود',
                muted: true,
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go('/auth-login'),
              ),
              AuthLink('پشتیبانی', onTap: () => context.push('/help-center')),
            ],
          ),
        ],
      ),
    );
  }
}
