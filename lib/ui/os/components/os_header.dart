import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dreadmoor/ui/theme/colors.dart';
import 'package:dreadmoor/ui/theme/dreadmoor_theme.dart';

class OSHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTitleTap;
  final VoidCallback? onBackPressed;

  const OSHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.onTitleTap,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: DreadmoorColors.surface(Theme.of(context).brightness),
        border: Border(
          bottom: BorderSide(
            color: DreadmoorColors.divider(Theme.of(context).brightness).withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBackPressed != null) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBackPressed,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 4.0, bottom: 4.0),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: DreadmoorColors.text(Theme.of(context).brightness),
                ),
              ),
            ),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTitleTap,
              child: Column(
                crossAxisAlignment: leading != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: DreadmoorTheme.headingStyle(Theme.of(context).brightness).copyWith(
                      fontSize: 18,
                      letterSpacing: 2.0,
                      color: DreadmoorColors.text(Theme.of(context).brightness),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: DreadmoorTheme.bodyStyle(Theme.of(context).brightness).copyWith(
                        fontSize: 11,
                        color: DreadmoorColors.text(Theme.of(context).brightness).withOpacity(0.7),
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}
