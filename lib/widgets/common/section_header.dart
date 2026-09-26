import 'package:flutter/material.dart';
import 'tap_scale.dart';

import '../../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailingBadge;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            if (trailingBadge != null) ...[
              const SizedBox(width: 8),
              trailingBadge!,
            ],
          ],
        ),
        if (actionLabel != null)
          TapScale(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}
