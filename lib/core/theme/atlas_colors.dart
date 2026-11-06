import 'package:flutter/material.dart';

abstract class AtlasColors {
  // Light Palette
  static const lightBg = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightElevated = Color(0xFFF4F4F5);
  static const lightBorder = Color(0x14000000); // 8% Black hairline
  static const lightBorderSubtle = Color(0x0A000000); // 4% Black
  static const lightTextPrimary = Color(0xFF18181B);
  static const lightTextSecondary = Color(0xFF71717A);
  static const lightTextMuted = Color(0xFFA1A1AA);

  // Dark Palette (OLED/Carbon - calm charcoal avoiding harsh contrast)
  static const darkBg = Color(0xFF0E0E10);
  static const darkSurface = Color(0xFF18181B);
  static const darkElevated = Color(0xFF27272A);
  static const darkBorder = Color(0x1AFFFFFF); // 10% White hairline
  static const darkBorderSubtle = Color(0x0DFFFFFF); // 5% White
  static const darkTextPrimary = Color(0xFFF4F4F5);
  static const darkTextSecondary = Color(0xFFA1A1AA);
  static const darkTextMuted = Color(0xFF71717A);

  // Accents & Semantics
  static const accentBlue = Color(0xFF3B82F6);
  static const accentBlueSubtle = Color(0x1A3B82F6);
  static const accentSage = Color(0xFF10B981);
  static const accentSageSubtle = Color(0x1A10B981);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentAmberSubtle = Color(0x1AF59E0B);
  static const accentRose = Color(0xFFF43F5E);
  static const accentRoseSubtle = Color(0x1AF43F5E);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentPurpleSubtle = Color(0x1A8B5CF6);

  // Priority Tokens
  static const priorityP1 = Color(0xFFEF4444);
  static const priorityP2 = Color(0xFFF97316);
  static const priorityP3 = Color(0xFF3B82F6);
  static const priorityP4 = Color(0xFF94A3B8);
}
