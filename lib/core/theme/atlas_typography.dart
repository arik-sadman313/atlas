import 'package:flutter/material.dart';

abstract class AtlasTypography {
  static const String? fontFamily = null; // Uses system native font fallback

  static TextTheme createTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 34.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
        color: primaryColor,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 26.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
        color: primaryColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 21.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 17.0,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        height: 1.35,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        height: 1.4,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.5,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.45,
        color: primaryColor,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
        color: secondaryColor,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.3,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.3,
        color: secondaryColor,
      ),
    );
  }
}
