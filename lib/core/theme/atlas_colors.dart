import 'package:flutter/material.dart';

abstract class AtlasColors {
  // Light Palette
  static const lightBg = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightElevated = Color(0xFFF1F3F5);
  static const lightBorder = Color(0x14000000); // 8% Black hairline
  static const lightBorderSubtle = Color(0x0A000000); // 4% Black
  static const lightTextPrimary = Color(0xFF18181B);
  static const lightTextSecondary = Color(0xFF71717A);
  static const lightTextMuted = Color(0xFFA1A1AA);
  static const lightTextTertiary = lightTextMuted;

  // Dark Palette ("Quiet Craft" - Obsidian depth)
  // Canvas / Background: #0D0E12
  static const darkBg = Color(0xFF0D0E12);
  // Surface Level 1 (Sidebar / Structural): #12141A
  static const darkSurface = Color(0xFF12141A);
  // Surface Level 2 (Cards / Bento Containers): #181B24
  static const darkCard = Color(0xFF181B24);
  // Surface Level 3 (Hover / Elevated Modals / Inputs): #202430
  static const darkElevated = Color(0xFF202430);
  // Hover elevated highlight: #222634
  static const darkHover = Color(0xFF222634);
  // Borders: 6% White hairline
  static const darkBorder = Color(0x0FFFFFFF); // 6% White
  static const darkBorderSubtle = Color(0x08FFFFFF); // ~3% White
  static const darkTextPrimary = Color(0xFFF4F4F5);
  static const darkTextSecondary = Color(0xFFA1A1AA);
  static const darkTextMuted = Color(0xFF71717A);
  static const darkTextTertiary = darkTextMuted;

  // Accents & Semantics ("Quiet Craft" Refinements)
  // Indigo Slate replacing default Material blue
  static const accentBlue = Color(0xFF6366F1);
  static const accentBlueSubtle = Color(0x1A6366F1);
  // Sage Emerald replacing harsh neon green
  static const accentSage = Color(0xFF10B981);
  static const accentSageSubtle = Color(0x1A10B981);
  static const statusSuccess = Color(0xFF10B981);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentAmberSubtle = Color(0x1AF59E0B);
  static const accentRose = Color(0xFFF43F5E);
  static const accentRoseSubtle = Color(0x1AF43F5E);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentPurpleSubtle = Color(0x1A8B5CF6);

  // Priority Tokens (Refined Terracotta for P1)
  static const priorityP1 = Color(0xFFE07A5F);
  static const priorityP2 = Color(0xFFF97316);
  static const priorityP3 = Color(0xFF6366F1);
  static const priorityP4 = Color(0xFF94A3B8);
}
