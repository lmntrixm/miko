import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';
import 'auth_copy.dart';
import 'auth_shell.dart';
import 'code_field.dart';

/// Resend countdown, shared with the forgot-password code step.
class ResendTimer extends StatefulWidget {
  const ResendTimer({super.key, required this.onResend, this.seconds = 120});
  final Future<void> Function() onResend;
  final int seconds;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _left = widget.seconds);
    _start();
    await widget.onResend();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final done = _left <= 0;
    final mm = (_left ~/ 60).toString().padLeft(2, '0');
    final ss = (_left % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AuthLink(
          'ارسال دوباره کد',
          muted: !done,
          onTap: done ? _resend : () {},
        ),
        Semantics(
          liveRegion: false,
          label: done
              ? 'می‌توانید کد جدید بگیرید'
              : '$_left ثانیه تا ارسال دوباره',
          child: ExcludeSemantics(
            child: Text(
              done ? '' : faDigits('$mm:$ss'),
              style: MRText.caption.copyWith(fontSize: 13, color: c.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'کد ۶ رقمی را کامل وارد کنید');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .verify(widget.email, _code.text);
      await ref.read(sessionProvider.notifier).signIn(token);
      if (mounted) context.go('/onboarding-prefs');
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
          Text(
            'کد ارسال‌شده به ایمیل خود را وارد کنید',
            style: MRText.caption.copyWith(fontSize: 13, color: c.textPrimary),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              widget.email,
              style: MRText.caption.copyWith(color: c.textMuted),
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(height: 20),
          CodeField(
            controller: _code,
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
            onCompleted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          MikoButton(
            label: 'ورود',
            kind: MikoButtonKind.hero,
            loading: _loading,
            loadingLabel: 'در حال بررسی…',
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          ResendTimer(
            onResend: () =>
                ref.read(authRepositoryProvider).resendCode(widget.email),
          ),
        ],
      ),
    );
  }
}
