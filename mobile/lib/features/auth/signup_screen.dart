import 'package:flutter/gestures.dart';
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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _nameError, _emailError, _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = validateName(_name.text);
      _emailError = validateEmail(_email.text);
      _passwordError = validatePassword(_password.text);
    });
    if (_nameError != null || _emailError != null || _passwordError != null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final email = _email.text.trim();
      await ref
          .read(authRepositoryProvider)
          .signup(_name.text.trim(), email, _password.text);
      if (mounted) context.push('/auth-otp', extra: email);
    } catch (e) {
      if (mounted) setState(() => _emailError = errorOf(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final small = MRText.caption.copyWith(color: c.textMuted);
    final link = MRText.caption.copyWith(
      color: c.red300,
      fontWeight: FontWeight.w700,
    );
    return AuthShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'برای استفاده از برنامه ابتدا ثبت‌نام کنید:',
            style: MRText.caption.copyWith(fontSize: 13, color: c.textPrimary),
          ),
          const SizedBox(height: 20),
          MikoTextField(
            label: 'نام و نام خانوادگی',
            icon: Icons.person_outline,
            controller: _name,
            errorText: _nameError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          MikoTextField(
            label: 'ایمیل',
            icon: Icons.mail_outline,
            ltr: true,
            hint: 'you@example.com',
            controller: _email,
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          MikoTextField(
            label: 'رمز عبور',
            icon: Icons.lock_outline,
            obscure: true,
            hint: 'حداقل ۸ کاراکتر',
            controller: _password,
            errorText: _passwordError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: small,
              children: [
                const TextSpan(text: 'ثبت‌نام یعنی '),
                TextSpan(
                  text: 'قوانین استفاده',
                  style: link,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/legal'),
                ),
                const TextSpan(text: ' و '),
                TextSpan(
                  text: 'حریم خصوصی',
                  style: link,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/legal'),
                ),
                const TextSpan(text: ' را پذیرفته‌اید.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MikoButton(
            label: 'ثبت نام',
            kind: MikoButtonKind.hero,
            loading: _loading,
            loadingLabel: 'در حال ثبت‌نام…',
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('حساب دارید؟ ', style: small.copyWith(fontSize: 13)),
              AuthLink(
                'وارد شوید',
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go('/auth-login'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
