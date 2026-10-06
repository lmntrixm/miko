import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../data/auth_repository.dart';
import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/snack.dart';
import '../../widgets/miko_button.dart';
import '../../widgets/miko_chip.dart';
import '../../widgets/pressable.dart';

class OnboardingPrefsScreen extends ConsumerStatefulWidget {
  const OnboardingPrefsScreen({super.key, this.edit = false});

  /// Opened from Profile: pre-filled, saves and goes back instead of continuing to home.
  final bool edit;

  @override
  ConsumerState<OnboardingPrefsScreen> createState() =>
      _OnboardingPrefsScreenState();
}

class _OnboardingPrefsScreenState extends ConsumerState<OnboardingPrefsScreen> {
  static const minGenres = 3;
  static const genres = [
    'اکشن',
    'فانتزی',
    'عاشقانه',
    'کمدی',
    'ترسناک',
    'ورزشی',
    'معمایی',
    'ابرقهرمانی',
    'زندگی روزمره',
    'تاریخی',
    'علمی‌تخیلی',
    'روان‌شناختی',
  ];
  static const langs = [
    (ReadingLanguage.fa, 'فارسی', 'پیش‌فرض'),
    (ReadingLanguage.en, 'English', 'انگلیسی'),
    (ReadingLanguage.both, 'هر دو', 'کنار هم'),
  ];

  final _picked = <String>{};
  ReadingLanguage _lang = ReadingLanguage.fa;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.edit) {
      ref.read(authRepositoryProvider).loadPreferences().then((p) {
        if (!mounted) return;
        setState(() {
          _picked
            ..clear()
            ..addAll(p.genres);
          _lang = p.language;
        });
      });
    }
  }

  Future<void> _finish({bool skip = false}) async {
    setState(() => _saving = true);
    try {
      if (!skip) {
        await ref.read(authRepositoryProvider).savePreferences(_picked, _lang);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    if (widget.edit) {
      if (!skip) {
        showSnack(context, 'علاقه‌مندی‌ها ذخیره شد');
      }
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final missing = minGenres - _picked.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                children: [
                  if (widget.edit)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: MikoIconButton(
                        icon: Icons.arrow_forward,
                        semanticLabel: 'بازگشت',
                        filled: false,
                        onPressed: () => context.pop(),
                      ),
                    )
                  else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                              width: 26,
                              height: 6,
                              margin: const EdgeInsetsDirectional.only(end: 6),
                              decoration: BoxDecoration(
                                color: i < 2 ? c.red500 : c.switchOff,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                      AuthSkip(onTap: () => _finish(skip: true)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      'چه چیزهایی دوست دارید؟',
                      style: MRText.h1.copyWith(
                        fontSize: 24,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'حداقل ${faDigits(minGenres)} ژانر انتخاب کنید تا صفحه خانه را برایتان بچینیم.',
                    style: MRText.body.copyWith(color: c.textMuted),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final g in genres)
                        MikoChip(
                          label: g,
                          selected: _picked.contains(g),
                          onTap: () => setState(
                            () => _picked.contains(g)
                                ? _picked.remove(g)
                                : _picked.add(g),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'زبان ترجیحی خواندن',
                    style: MRText.h3.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (v, title, sub) in langs)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: 10),
                            child: Semantics(
                              inMutuallyExclusiveGroup: true,
                              selected: _lang == v,
                              child: Pressable(
                                onTap: () => setState(() => _lang = v),
                                child: Container(
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: _lang == v ? c.red900 : c.surface2,
                                    borderRadius: BorderRadius.circular(
                                      MRRadius.radiusLg,
                                    ),
                                    border: Border.all(
                                      color: _lang == v ? c.red600 : c.border2,
                                      width: _lang == v ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        style: MRText.h3.copyWith(
                                          fontSize: 15,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        sub,
                                        style: MRText.caption.copyWith(
                                          color: c.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: c.bgNav,
                border: Border(top: BorderSide(color: c.border1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (missing > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          '${faDigits(missing)} ژانر دیگر انتخاب کنید',
                          style: MRText.caption.copyWith(color: c.textMuted),
                        ),
                      ),
                    ),
                  MikoButton(
                    label: widget.edit ? 'ذخیره' : 'ادامه',
                    loading: _saving,
                    loadingLabel: 'در حال ذخیره…',
                    onPressed: missing > 0 ? null : _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthSkip extends StatelessWidget {
  const AuthSkip({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            widthFactor: 1,
            child: Text(
              'رد شدن',
              style: MRText.caption.copyWith(fontSize: 13, color: c.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
