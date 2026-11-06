import 'package:flutter/material.dart';

import 'atlas_colors.dart';
import 'atlas_spacing.dart';
import 'atlas_typography.dart';

abstract class AtlasTheme {
  static ThemeData get lightTheme {
    final textTheme = AtlasTypography.createTextTheme(
      AtlasColors.lightTextPrimary,
      AtlasColors.lightTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AtlasColors.lightBg,
      colorScheme: const ColorScheme.light(
        surface: AtlasColors.lightSurface,
        onSurface: AtlasColors.lightTextPrimary,
        primary: AtlasColors.accentBlue,
        onPrimary: Colors.white,
        secondary: AtlasColors.accentSage,
        outline: AtlasColors.lightBorder,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AtlasColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          side: const BorderSide(color: AtlasColors.lightBorder, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AtlasColors.lightBorder,
        thickness: 1.0,
        space: 1.0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AtlasColors.lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: const IconThemeData(color: AtlasColors.lightTextPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AtlasColors.lightSurface,
        elevation: 0,
        indicatorColor: AtlasColors.accentBlueSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AtlasColors.accentBlue);
          }
          return const IconThemeData(color: AtlasColors.lightTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AtlasColors.accentBlue,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: AtlasColors.lightTextSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.lightElevated,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          borderSide: const BorderSide(
            color: AtlasColors.lightBorder,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          borderSide: const BorderSide(
            color: AtlasColors.lightBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          borderSide: const BorderSide(
            color: AtlasColors.accentBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = AtlasTypography.createTextTheme(
      AtlasColors.darkTextPrimary,
      AtlasColors.darkTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AtlasColors.darkBg,
      colorScheme: const ColorScheme.dark(
        surface: AtlasColors.darkSurface,
        onSurface: AtlasColors.darkTextPrimary,
        primary: AtlasColors.accentBlue,
        onPrimary: Colors.white,
        secondary: AtlasColors.accentSage,
        outline: AtlasColors.darkBorder,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AtlasColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          side: const BorderSide(color: AtlasColors.darkBorder, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AtlasColors.darkBorder,
        thickness: 1.0,
        space: 1.0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AtlasColors.darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: const IconThemeData(color: AtlasColors.darkTextPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AtlasColors.darkSurface,
        elevation: 0,
        indicatorColor: AtlasColors.accentBlueSubtle,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AtlasColors.accentBlue);
          }
          return const IconThemeData(color: AtlasColors.darkTextSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AtlasColors.accentBlue,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: AtlasColors.darkTextSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.darkElevated,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          borderSide: const BorderSide(
            color: AtlasColors.darkBorder,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          borderSide: const BorderSide(
            color: AtlasColors.darkBorder,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasSpacing.radiusCard),
          borderSide: const BorderSide(
            color: AtlasColors.accentBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
