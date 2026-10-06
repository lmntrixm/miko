import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/network.dart';
import '../../theme/miko_colors.dart';
import '../../theme/miko_tokens.dart';
import '../../widgets/pressable.dart';

/// Yellow "no connection" strip with a retry button.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mr;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(MRSpacing.space3),
        decoration: BoxDecoration(
          color: c.warningBg,
          borderRadius: BorderRadius.circular(MRRadius.radiusLg),
          border: Border.all(color: c.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: c.warning, size: 22),
            const SizedBox(width: MRSpacing.space3),
            Expanded(
              child: Text(
                'اتصال اینترنت قطع است',
                style: MRText.body.copyWith(color: c.warning),
              ),
            ),
            Pressable(
              onTap: () => ref.read(networkStatusProvider.notifier).recheck(),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: MRSpacing.space4,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.warning,
                  borderRadius: BorderRadius.circular(MRRadius.radiusMd),
                ),
                // Text color picked for contrast against the amber button in either theme.
                child: Text(
                  'تلاش دوباره',
                  style: MRText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        ThemeData.estimateBrightnessForColor(c.warning) ==
                            Brightness.dark
                        ? c.onBrand
                        : c.bgBase,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
