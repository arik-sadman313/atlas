import 'package:flutter/material.dart';

import '../../core/theme/atlas_colors.dart';
import '../../core/theme/atlas_spacing.dart';

class AtlasCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? customBorder;

  const AtlasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtlasSpacing.md),
    this.onTap,
    this.backgroundColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg =
        backgroundColor ??
        (isDark ? AtlasColors.darkSurface : AtlasColors.lightSurface);
    final border =
        customBorder ??
        Border.all(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          width: 1.0,
        );

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
        border: border,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
      hoverColor: isDark
          ? AtlasColors.darkElevated.withValues(alpha: 0.5)
          : AtlasColors.lightElevated,
      child: content,
    );
  }
}
