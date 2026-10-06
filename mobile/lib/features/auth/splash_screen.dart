import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import 'auth_shell.dart';

/// Cover collage + logo. Routes on: signed in → home, intro seen → login, else intro.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.delay = const Duration(milliseconds: 1800),
  });
  final Duration delay;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (!mounted) return;
      final s = ref.read(sessionProvider);
      context.go(
        s.signedIn
            ? '/home'
            : (s.onboardingSeen ? '/auth-login' : '/onboarding'),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Scaffold(
      backgroundColor: c.bgBase,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CoverCollage(scrim: 0.35),
          Center(
            child: Semantics(
              label: 'میکو',
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: mrBrandGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                // [لوگو] placeholder until the final logo arrives.
                child: Text(
                  'م',
                  style: MRText.display.copyWith(color: c.onBrand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
