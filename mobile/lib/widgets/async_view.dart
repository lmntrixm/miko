import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'miko_button.dart';

/// Loading / error / data switch. Errors say cause + fix (no codes) with a retry.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return value.when(
      data: builder,
      loading: () => Center(child: CircularProgressIndicator(color: c.red500, strokeWidth: 2.5)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(MRSpacing.space6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('بارگذاری نشد. اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.',
                textAlign: TextAlign.center, style: MRText.body.copyWith(color: c.textMuted)),
            if (onRetry != null) ...[
              const SizedBox(height: MRSpacing.space4),
              MikoButton(label: 'تلاش دوباره', kind: MikoButtonKind.secondary, expand: false, onPressed: onRetry),
            ],
          ]),
        ),
      ),
    );
  }
}
