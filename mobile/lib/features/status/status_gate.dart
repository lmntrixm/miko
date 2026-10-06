import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/persian.dart';
import '../../data/api_errors.dart';
import '../../data/discovery_providers.dart';
import '../../data/discovery_repository.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/miko_button.dart';
import '../billing/subscription_screen.dart' show externalLauncherProvider;

/// Wraps the whole app: 503 → maintenance screen, 426 → forced update, optional update → one-time sheet.
class StatusGate extends ConsumerStatefulWidget {
  const StatusGate({super.key, required this.child, required this.onOpenDownloads});
  final Widget child;
  final VoidCallback onOpenDownloads;

  @override
  ConsumerState<StatusGate> createState() => _StatusGateState();
}

class _StatusGateState extends ConsumerState<StatusGate> {
  bool _bypass = false; // user chose to read downloaded chapters during maintenance

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(effectiveStatusProvider);
    if (status == null) return widget.child;
    if (status.maintenance && !_bypass) {
      return MaintenanceScreen(
        until: status.maintenanceUntil,
        onDownloads: () {
          setState(() => _bypass = true);
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onOpenDownloads());
        },
      );
    }
    if (status.update == UpdateKind.forced) return UpdateScreen(status: status, forced: true);
    final dismissed = ref.watch(dismissedUpdateProvider);
    if (status.update == UpdateKind.optional && dismissed != status.newVersion) {
      return Stack(children: [
        widget.child,
        Positioned.fill(child: UpdateScreen(status: status, forced: false, onLater: () => ref.read(dismissedUpdateProvider.notifier).dismiss(status.newVersion ?? ''))),
      ]);
    }
    return widget.child;
  }
}

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, this.until, required this.onDownloads});
  final String? until;
  final VoidCallback onDownloads;

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: c.bgBase,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(MRSpacing.space6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80,
                  height: 72,
                  decoration: BoxDecoration(color: c.surface1, borderRadius: BorderRadius.circular(MRRadius.radiusXl), border: Border.all(color: c.border2)),
                  child: Icon(Icons.close, size: 40, color: c.red500),
                ),
                const SizedBox(height: MRSpacing.space6),
                Semantics(header: true, liveRegion: true, child: Text('در حال به‌روزرسانی سرورها', textAlign: TextAlign.center, style: MRText.h1.copyWith(fontSize: 24, color: c.textPrimary))),
                const SizedBox(height: MRSpacing.space3),
                Text(
                  'برای بهتر شدن سرعت دانلود، اپ ${until == null ? 'برای مدتی کوتاه' : 'تا حدود ساعت ${faDigits(until!)}'} در دسترس نیست. اشتراک شما در این مدت تمدید می‌شود.',
                  textAlign: TextAlign.center,
                  style: MRText.body.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MRSpacing.space5),
                MikoButton(label: 'خواندن چپترهای دانلودشده', kind: MikoButtonKind.secondary, expand: false, onPressed: onDownloads),
                const SizedBox(height: MRSpacing.space4),
                // [کانال یا صفحه اطلاع‌رسانی] not provided yet.
                Text('اخبار وضعیت: [کانال یا صفحه اطلاع‌رسانی]', style: MRText.caption.copyWith(color: c.textMuted)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key, required this.status, required this.forced, this.onLater});
  final AppStatus status;
  final bool forced;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: forced ? c.bgBase : c.scrim,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(MRSpacing.space5, MRSpacing.space5, MRSpacing.space5, MediaQuery.paddingOf(context).bottom + MRSpacing.space4),
            decoration: BoxDecoration(color: c.surface1, borderRadius: const BorderRadius.vertical(top: Radius.circular(MRRadius.radiusSheet)), border: Border(top: BorderSide(color: c.red800))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: mrBrandGradient, borderRadius: BorderRadius.circular(20)),
                  child: Text('م', style: MRText.h1.copyWith(color: c.onBrand)),
                ),
              ),
              const SizedBox(height: MRSpacing.space3),
              Semantics(header: true, child: Text('نسخه جدید آماده است', textAlign: TextAlign.center, style: MRText.h2.copyWith(color: c.textPrimary))),
              const SizedBox(height: MRSpacing.space2),
              Text(forced ? 'برای ادامه باید اپ را به‌روز کنید.' : 'قابلیت‌های تازه و رفع چند مشکل. هر وقت خواستید به‌روز کنید.', textAlign: TextAlign.center, style: MRText.body.copyWith(color: c.textSecondary)),
              if (status.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: MRSpacing.space3),
                Container(
                  padding: const EdgeInsets.all(MRSpacing.space4),
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MRRadius.radiusLg)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('تازه‌های نسخه ${faDigits(status.newVersion ?? '')}', style: MRText.h3.copyWith(fontSize: 14, color: c.textPrimary)),
                    for (final n in status.releaseNotes) Text('· $n', style: MRText.body.copyWith(color: c.textSecondary)),
                  ]),
                ),
              ],
              const SizedBox(height: MRSpacing.space4),
              // [لینک فروشگاه] is not provided yet; the launcher is a no-op for the placeholder.
              MikoButton(label: 'به‌روزرسانی از [فروشگاه]', onPressed: () => ref.read(externalLauncherProvider).open('[لینک فروشگاه]')),
              if (!forced) ...[
                const SizedBox(height: MRSpacing.space2),
                MikoButton(label: 'بعداً', kind: MikoButtonKind.secondary, onPressed: onLater),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
