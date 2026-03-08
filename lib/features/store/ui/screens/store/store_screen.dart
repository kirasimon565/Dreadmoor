import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';
import 'package:dreadmoor/ui/os/components/os_header.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DreadmoorColors.background,
      body: Column(
        children: [
          const OSHeader(
            title: "APP STORE",
            subtitle: "SECURE MARKETPLACE",
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 64, color: DreadmoorColors.textMeta.withOpacity(0.5)),
                  const SizedBox(height: 24),
                  Text(
                    "STORE UNAVAILABLE",
                    style: DreadmoorTheme.headingStyle.copyWith(
                      color: DreadmoorColors.textMeta,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check your network connection.",
                    style: DreadmoorTheme.bodyStyle.copyWith(
                      color: DreadmoorColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
