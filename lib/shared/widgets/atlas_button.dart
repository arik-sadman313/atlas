import 'package:flutter/material.dart';

import '../../core/theme/atlas_colors.dart';
import '../../core/theme/atlas_spacing.dart';

enum AtlasButtonVariant { primary, secondary, ghost, danger }

class AtlasButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AtlasButtonVariant variant;
  final bool isLoading;
  final double? width;

  const AtlasButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AtlasButtonVariant.secondary,
    this.isLoading = false,
    this.width,
  });

  const AtlasButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  }) : variant = AtlasButtonVariant.primary;

  const AtlasButton.ghost({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  }) : variant = AtlasButtonVariant.ghost;

  const AtlasButton.danger({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  }) : variant = AtlasButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border;

    switch (variant) {
      case AtlasButtonVariant.primary:
        bg = AtlasColors.accentBlue;
        fg = Colors.white;
        border = BorderSide.none;
        break;
      case AtlasButtonVariant.secondary:
        bg = isDark ? AtlasColors.darkElevated : AtlasColors.lightElevated;
        fg = isDark
            ? AtlasColors.darkTextPrimary
            : AtlasColors.lightTextPrimary;
        border = BorderSide(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          width: 1.0,
        );
        break;
      case AtlasButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark
            ? AtlasColors.darkTextPrimary
            : AtlasColors.lightTextPrimary;
        border = BorderSide.none;
        break;
      case AtlasButtonVariant.danger:
        bg = isDark ? const Color(0x33EF4444) : const Color(0x1AEF4444);
        fg = AtlasColors.priorityP1;
        border = BorderSide(
          color: AtlasColors.priorityP1.withValues(alpha: 0.3),
          width: 1.0,
        );
        break;
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: AtlasSpacing.sm),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: 34.0,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: border,
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasSpacing.radiusSm),
          ),
          elevation: 0,
        ),
        child: buttonChild,
      ),
    );
  }
}
