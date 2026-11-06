import 'package:flutter/material.dart';

import '../../core/theme/atlas_colors.dart';
import '../../core/theme/atlas_spacing.dart';

class AtlasCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? customBorder;
  final double? borderRadius;
  final bool hasGlow;

  const AtlasCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtlasSpacing.md),
    this.onTap,
    this.backgroundColor,
    this.customBorder,
    this.borderRadius,
    this.hasGlow = false,
  });

  @override
  State<AtlasCard> createState() => _AtlasCardState();
}

class _AtlasCardState extends State<AtlasCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius ?? AtlasSpacing.radiusCard;

    final defaultBaseColor =
        widget.backgroundColor ??
        (isDark ? AtlasColors.darkCard : AtlasColors.lightSurface);

    final hoverColor = isDark
        ? AtlasColors.darkHover
        : AtlasColors.lightElevated;

    final activeBg = (_isHovered && widget.onTap != null)
        ? hoverColor
        : defaultBaseColor;

    final borderSide =
        widget.customBorder?.top ??
        BorderSide(
          color: (_isHovered && widget.onTap != null)
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AtlasColors.accentBlue.withValues(alpha: 0.3))
              : (isDark ? AtlasColors.darkBorder : AtlasColors.lightBorder),
          width: 1.0,
        );

    final shadows = <BoxShadow>[
      if (isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.20),
          blurRadius: _isHovered ? 24 : 16,
          offset: const Offset(0, 4),
        )
      else
        BoxShadow(
          color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
          blurRadius: _isHovered ? 16 : 8,
          offset: const Offset(0, 2),
        ),
      if (widget.hasGlow && isDark)
        BoxShadow(
          color: AtlasColors.accentBlue.withValues(alpha: 0.15),
          blurRadius: 32,
          spreadRadius: -4,
        ),
    ];

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.onTap != null) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (widget.onTap != null) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.fromBorderSide(borderSide),
          boxShadow: shadows,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            splashColor: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
