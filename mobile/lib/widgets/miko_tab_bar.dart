import 'package:flutter/material.dart';

import '../theme/miko_colors.dart';
import '../theme/miko_tokens.dart';
import 'pressable.dart';

class MikoTab {
  const MikoTab(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Bottom navigation, fixed visual order left→right:
/// profile · search · home (center) · library · add. Order does not flip in RTL.
class MikoTabBar extends StatelessWidget {
  const MikoTabBar({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const tabs = [
    MikoTab(Icons.person_outline, 'پروفایل'),
    MikoTab(Icons.search, 'جستجو'),
    MikoTab(Icons.home_outlined, 'خانه'),
    MikoTab(Icons.history, 'کتابخانه'),
    MikoTab(Icons.add, 'افزودن'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.mr;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 84 - 34 + (bottom > 0 ? bottom : 34),
      decoration: BoxDecoration(
        color: c.bgNav,
        border: Border(top: BorderSide(color: c.border1)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: Semantics(
                  selected: i == index,
                  child: Pressable(
                    semanticLabel: tabs[i].label,
                    onTap: () => onChanged(i),
                    child: SizedBox(
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tabs[i].icon,
                            size: 24,
                            color: i == index ? c.red400 : c.textPrimary,
                          ),
                          if (i == index) ...[
                            const SizedBox(height: 2),
                            Text(
                              tabs[i].label,
                              style: MRText.label.copyWith(color: c.red400),
                            ),
                          ],
                        ],
                      ),
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
