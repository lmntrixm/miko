import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/cover_placeholder.dart';

class _Page {
  const _Page(this.title, this.body);
  final String title, body;
}

const _pages = [
  _Page(
    'کاملترین آرشیو',
    'دسترسی به تمام چپترهای مانگای مورد نظر خود و دانلود آن',
  ),
  _Page(
    'دانلود و تماشا',
    'دانلود و تماشای برترین مانگاها با اپ و باخبر شدن از آخرین قسمت مانگای محبوب خود',
  ),
  _Page('فارسی و انگلیسی', 'وجود مانگاها به دو زبان فارسی و انگلیسی'),
];

/// Three intro pages: cover on top, slanted red panel with title/body/dots below.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(sessionProvider.notifier).markOnboardingSeen();
    if (mounted) context.go('/auth-login');
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      final reduce = MediaQuery.disableAnimationsOf(context);
      _controller.nextPage(
        duration: reduce ? Duration.zero : MRMotion.slow,
        curve: MRMotion.emphasized,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  children: [
                    // [کاور] licensed artwork goes here.
                    const Expanded(child: CoverPlaceholder(radius: 28)),
                    const SizedBox(height: 0),
                    ClipPath(
                      clipper: _SlantClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 190,
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        decoration: const BoxDecoration(
                          gradient: mrHeroGradient,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(26),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                _pages[i].title,
                                style: MRText.h1.copyWith(
                                  fontSize: 24,
                                  color: c.onBrand,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pages[i].body,
                              style: MRText.caption.copyWith(
                                fontSize: 13,
                                color: c.onBrand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),
            // Dots + next live above the pager so they don't swipe away.
            PositionedDirectional(
              start: 44,
              end: 44,
              bottom: 96,
              child: Row(
                children: [
                  Semantics(
                    label: 'صفحه ${_index + 1} از ${_pages.length}',
                    child: Row(
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: MRMotion.base,
                            margin: const EdgeInsetsDirectional.only(end: 6),
                            width: i == _index ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: c.onBrand.withValues(
                                alpha: i == _index ? 1 : 0.6,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!last)
                    GestureDetector(
                      onTap: _finish,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            'رد شدن',
                            style: MRText.caption.copyWith(color: c.onBrand),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _next,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: last ? 'شروع' : 'بعدی',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.onBrand,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: 22,
                          color: c.red500,
                        ),
                      ),
                    ),
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

/// Panel whose top edge rises toward the start (right) side at ~12°.
class _SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final drop = s.width * 0.21; // tan(12°)
    return Path()
      ..moveTo(0, drop)
      ..lineTo(s.width, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
  }

  @override
  bool shouldReclip(_SlantClipper old) => false;
}
