import 'package:flutter/material.dart';

import '../../core/theme/atlas_colors.dart';
import '../../core/theme/atlas_spacing.dart';
import 'atlas_button.dart';

class AtlasEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AtlasEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AtlasSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AtlasColors.darkElevated
                    : AtlasColors.lightElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AtlasColors.darkBorder
                      : AtlasColors.lightBorder,
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 26,
                color: isDark
                    ? AtlasColors.darkTextSecondary
                    : AtlasColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AtlasSpacing.lg),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AtlasSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AtlasColors.darkTextSecondary
                      : AtlasColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AtlasSpacing.xl),
              AtlasButton.primary(
                label: actionLabel!,
                icon: Icons.add,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
