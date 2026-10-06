import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_errors.dart';
import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'miko_button.dart';
import 'skeleton.dart';

/// Loading / error / data switch. Errors say cause + fix (no codes) with a retry.
class AsyncView<T> extends ConsumerStatefulWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  ConsumerState<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends ConsumerState<AsyncView<T>> {
  Object? _handled;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final builder = widget.builder;
    final onRetry = widget.onRetry;
    return value.when(
      data: builder,
      loading: () => const LoadingSkeleton(),
      error: (e, _) {
        // 401/402/426/503 are handled app-wide, once per error.
        if (!identical(_handled, e)) {
          _handled = e;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) handleApiError(ref, context, e);
          });
        }
        return _ErrorBody(error: e, onRetry: onRetry);
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MRSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              apiErrorText(error),
              textAlign: TextAlign.center,
              style: MRText.body.copyWith(color: c.textMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: MRSpacing.space4),
              MikoButton(
                label: 'تلاش دوباره',
                kind: MikoButtonKind.secondary,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Like [AsyncView] but sized to its content, for use inside a ListView.
class AsyncViewInline<T> extends StatelessWidget {
  const AsyncViewInline({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: MRSpacing.space6),
        child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(MRSpacing.space5),
        child: Column(children: [
          Text('بارگذاری نشد. اتصال اینترنت را بررسی کنید و دوباره امتحان کنید.', textAlign: TextAlign.center, style: MRText.body.copyWith(color: context.mr.textMuted)),
          if (onRetry != null) ...[
            const SizedBox(height: MRSpacing.space3),
            MikoButton(label: 'تلاش دوباره', kind: MikoButtonKind.secondary, expand: false, onPressed: onRetry),
          ],
        ]),
      ),
    );
  }
}
