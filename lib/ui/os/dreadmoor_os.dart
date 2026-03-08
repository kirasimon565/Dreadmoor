import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dreadmoor/ui/os/os_state.dart';
import 'package:dreadmoor/ui/os/dreadmoor_app_container.dart';
import 'package:dreadmoor/ui/os/dreadmoor_navigation_bar.dart';
import 'package:dreadmoor/ui/os/dreadmoor_status_bar.dart';
import 'package:dreadmoor/ui/theme/colors.dart';

class DreadmoorOS extends ConsumerWidget {
  const DreadmoorOS({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DreadmoorStatusBar(),
            const Expanded(
              child: DreadmoorAppContainer(),
            ),
            const DreadmoorNavigationBar(),
          ],
        ),
      ),
    );
  }
}
