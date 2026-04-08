import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class DreadmoorNavigationBar extends ConsumerWidget {
  const DreadmoorNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeApp  = ref.watch(activeAppProvider);
    final brightness = Theme.of(context).brightness;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: DreadmoorColors.surface(brightness),
        border: Border(
          top: BorderSide(
            color: DreadmoorColors.divider(brightness),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon:     Icons.chat_bubble_outline,
            label:    'Messenger',
            app:      PhoneApp.messenger,
            isActive: activeApp == PhoneApp.messenger,
          ),
          _NavItem(
            icon:     Icons.book,
            label:    'Diary',
            app:      PhoneApp.diary,
            isActive: activeApp == PhoneApp.diary,
          ),
          _NavItem(
            icon:     Icons.person_outline,
            label:    'Profile',
            app:      PhoneApp.profile,
            isActive: activeApp == PhoneApp.profile,
          ),
          _NavItem(
            icon:     Icons.apps,
            label:    'Apps',
            app:      PhoneApp.apps,
            isActive: activeApp == PhoneApp.apps,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon;
  final String   label;
  final PhoneApp app;
  final bool     isActive;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.app,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    Color color;
    if (isActive) {
      color = DreadmoorColors.investigatorCyan;
    } else {
      color = DreadmoorColors.text(brightness).withOpacity(0.7);
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(activeAppProvider.notifier).state = app,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: DreadmoorTheme.bodyStyle(brightness).copyWith(
                fontSize: 10,
                color:      color,
                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
