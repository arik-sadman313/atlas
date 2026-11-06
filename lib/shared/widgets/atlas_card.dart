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
    final borderSide =
        customBorder?.top ??
        BorderSide(
          color: isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder,
          width: 1.0,
        );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AtlasSpacing.radiusMd),
      side: borderSide,
    );

    return Material(
      color: bg,
      shape: cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: isDark
            ? AtlasColors.darkElevated.withValues(alpha: 0.5)
            : AtlasColors.lightElevated,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
