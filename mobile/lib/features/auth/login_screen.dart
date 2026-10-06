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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError, _passwordError;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = validateEmail(_email.text);
      _passwordError = _password.text.isEmpty ? 'رمز عبور را وارد کنید' : null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _loading = true);
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .login(_email.text.trim(), _password.text);
      await ref.read(sessionProvider.notifier).signIn(token);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _passwordError = errorOf(e));
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
            'برای استفاده از برنامه ایمیل و رمز عبور خود را وارد کنید:',
            style: MRText.caption.copyWith(fontSize: 13, color: c.textPrimary),
          ),
          const SizedBox(height: 20),
          MikoTextField(
            label: 'ایمیل',
            icon: Icons.mail_outline,
            ltr: true,
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
            controller: _password,
            errorText: _passwordError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          MikoButton(
            label: 'ورود',
            kind: MikoButtonKind.hero,
            loading: _loading,
            loadingLabel: 'در حال ورود…',
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AuthLink(
                'رمز خود را فراموش کرده‌اید',
                muted: true,
                onTap: () => context.push('/forgot-password'),
              ),
              AuthLink('ثبت نام', onTap: () => context.push('/auth-signup')),
            ],
          ),
        ],
      ),
    );
  }
}
