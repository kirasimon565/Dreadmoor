import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/os/os_state.dart';

import 'package:dreadmoor/features/messenger/ui/messenger_navigator.dart';
import 'package:dreadmoor/features/browser/ui/browser_navigator.dart';
import 'package:dreadmoor/features/phone/ui/phone_navigator.dart';
import 'package:dreadmoor/features/profile/ui/profile_navigator.dart';
import 'package:dreadmoor/features/apps/ui/screens/apps/apps_screen.dart';
import 'package:dreadmoor/features/diary/ui/diary_screen.dart';

class DreadmoorAppContainer extends ConsumerStatefulWidget {
  const DreadmoorAppContainer({super.key});

  @override
  ConsumerState<DreadmoorAppContainer> createState() =>
      _DreadmoorAppContainerState();
}

class _DreadmoorAppContainerState
    extends ConsumerState<DreadmoorAppContainer> {
  final List<PhoneApp> _appOrder = [
    PhoneApp.messenger,
    PhoneApp.browser,
    PhoneApp.phone,
    PhoneApp.apps,
    PhoneApp.diary,
    PhoneApp.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final activeApp    = ref.watch(activeAppProvider);
    final activeIndex  = _appOrder.indexOf(activeApp);

    return IndexedStack(
      index: activeIndex,
      children: const [
        MessengerNavigator(),
        BrowserNavigator(),
        PhoneNavigator(),
        AppsScreen(),
        DiaryScreen(),
        ProfileNavigator(),
      ],
    );
  }
}
