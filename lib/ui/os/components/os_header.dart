import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class OSHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? subtitle;

  const OSHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: DreadmoorColors.surfaceAlt.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: DreadmoorColors.borderSubtle.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: leading != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: DreadmoorTheme.headingStyle.copyWith(
                        fontSize: 18,
                        letterSpacing: 2.0,
                        color: DreadmoorColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: DreadmoorTheme.bodyStyle.copyWith(
                          fontSize: 11,
                          color: DreadmoorColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
