import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/validators.dart';
import '../../data/account_providers.dart';
import '../../data/account_repository.dart';
import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/snack.dart';
import '../../widgets/async_view.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_text_field.dart';
import '../../widgets/pressable.dart';
import 'account_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _seeded = false;
  bool _pwOpen = false;
  bool _saving = false;
  String? _nameError, _currentError, _nextError, _repeatError;

  @override
  void dispose() {
    for (final t in [_name, _current, _next, _repeat]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final changing = _pwOpen && (_current.text.isNotEmpty || _next.text.isNotEmpty || _repeat.text.isNotEmpty);
    setState(() {
      _nameError = validateName(_name.text);
      _currentError = changing && _current.text.isEmpty ? 'رمز فعلی را وارد کنید' : null;
      _nextError = changing ? validatePassword(_next.text) : null;
      _repeatError = changing && _repeat.text != _next.text ? 'تکرار رمز با رمز جدید یکی نیست' : null;
    });
    if ([_nameError, _currentError, _nextError, _repeatError].any((e) => e != null)) return;
    setState(() => _saving = true);
    final repo = ref.read(accountRepositoryProvider);
    try {
      await repo.updateName(_name.text.trim());
      if (changing) await repo.changePassword(_current.text, _next.text);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      showSnack(context, 'تغییرات ذخیره شد');
      context.pop();
    } on WrongPasswordException {
      if (mounted) setState(() => _currentError = 'رمز فعلی درست نیست');
    } catch (_) {
      if (mounted) showSnack(context, 'ذخیره نشد. اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'حذف دائمی حساب',
      body: 'همهٔ اطلاعات، نشان‌ها و دانلودهای شما پاک می‌شود و برگشت ندارد. اشتراک فعال هم بدون بازپرداخت از بین می‌رود.',
      confirm: 'حذف دائمی حساب',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(accountRepositoryProvider).deleteAccount();
    await ref.read(sessionProvider.notifier).signOut();
    if (mounted) context.go('/auth-login');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final profile = ref.watch(profileProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const SubHeader(title: 'ویرایش پروفایل'),
          Expanded(
            child: AsyncView(
              value: profile,
              onRetry: () => ref.invalidate(profileProvider),
              builder: (p) {
                if (!_seeded) {
                  _name.text = p.name;
                  _seeded = true;
                }
                return ListView(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                  Center(
                    child: Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(gradient: mrBrandGradient, borderRadius: BorderRadius.circular(MRRadius.radiusXl + 6)),
                        child: Icon(Icons.person_outline, size: 48, color: c.onBrand),
                      ),
                      PositionedDirectional(
                        bottom: -6,
                        start: -6,
                        child: MikoIconButton(
                          icon: Icons.edit_outlined,
                          semanticLabel: 'تغییر تصویر پروفایل',
                          size: 36,
                          // [تصویر پروفایل]: image picking/upload comes with the real backend.
                          onPressed: () => showSnack(context, 'تغییر تصویر به‌زودی فعال می‌شود'),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: MRSpacing.space6),
                  MikoTextField(label: 'نام و نام خانوادگی', controller: _name, errorText: _nameError, textInputAction: TextInputAction.next),
                  const SizedBox(height: MRSpacing.space5),
                  // Email is read-only (verified identity).
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: MRSpacing.space4),
                    decoration: BoxDecoration(border: Border.all(color: c.border2), borderRadius: BorderRadius.circular(MRRadius.radius2xl)),
                    child: Row(children: [
                      Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Text(p.email, style: MRText.body.copyWith(color: c.textMuted)))),
                      const SizedBox(width: MRSpacing.space3),
                      Text(p.emailVerified ? 'تاییدشده' : 'تأیید نشده', style: MRText.caption.copyWith(color: p.emailVerified ? c.success : c.warning)),
                    ]),
                  ),
                  const SizedBox(height: MRSpacing.space5),
                  SectionCard(padding: const EdgeInsets.all(MRSpacing.space4), children: [
                    Semantics(
                      button: true,
                      expanded: _pwOpen,
                      child: Pressable(
                        onTap: () => setState(() => _pwOpen = !_pwOpen),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(children: [
                            Icon(Icons.lock_outline, size: 20, color: c.textPrimary),
                            const SizedBox(width: MRSpacing.space2),
                            Expanded(child: Text('تغییر رمز عبور', style: MRText.bodyLg.copyWith(color: c.textPrimary))),
                            Icon(_pwOpen ? Icons.remove : Icons.add, color: c.textMuted),
                          ]),
                        ),
                      ),
                    ),
                    if (_pwOpen) ...[
                      const SizedBox(height: MRSpacing.space4),
                      MikoTextField(label: 'رمز فعلی', obscure: true, controller: _current, errorText: _currentError, labelBackground: c.surface1),
                      const SizedBox(height: MRSpacing.space5),
                      MikoTextField(label: 'رمز جدید (حداقل ۸ کاراکتر)', obscure: true, controller: _next, errorText: _nextError, labelBackground: c.surface1),
                      const SizedBox(height: MRSpacing.space5),
                      MikoTextField(label: 'تکرار رمز جدید', obscure: true, controller: _repeat, errorText: _repeatError, labelBackground: c.surface1),
                    ],
                  ]),
                  const SizedBox(height: MRSpacing.space4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pressable(
                      onTap: _delete,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(widthFactor: 1, child: Text('حذف دائمی حساب کاربری', style: MRText.body.copyWith(color: c.danger))),
                      ),
                    ),
                  ),
                  const SizedBox(height: MRSpacing.space6),
                  MikoButton(label: 'ذخیره تغییرات', loading: _saving, loadingLabel: 'در حال ذخیره…', onPressed: _save),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
