import 'package:flutter/material.dart';

class AppColors {
  static const darkBg = Color(0xFF0A0A0A);
  static const darkSurface = Color(0xFF141414);
  static const darkSurfaceHigh = Color(0xFF1E1E1E);
  static const darkSurfaceLow = Color(0xFF0A0A0A);
  static const darkBorder = Color(0xFF2A2A2A);
  static const darkPrimary = Color(0xFF6366F1);
  static const darkPrimarySoft = Color(0xFF1E1B4B);
  static const darkAccent = Color(0xFF22D3EE);
  static const darkSuccess = Color(0xFF10B981);
  static const darkWarning = Color(0xFFF59E0B);
  static const darkError = Color(0xFFEF4444);
  static const darkText = Color(0xFFF5F5F5);
  static const darkTextMuted = Color(0xFF9CA3AF);

  // Aliases to support existing UI components
  static const darkBlue = darkAccent;
  static const darkMint = darkSuccess;
  static const darkOrange = darkWarning;
  static const darkPink = darkError;

  // Light-mode aliases (matching dark-mode semantics)
  static const lightBlue = lightAccent;
  static const lightMint = lightSuccess;
  static const lightOrange = lightWarning;
  static const lightPink = lightError;

  static const lightBg = Color(0xFFF6F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFF1F3F8);
  static const lightSurfaceLow = Color(0xFFF0F1F3);
  static const lightBorder = Color(0xFFDDE1EA);
  static const lightPrimary = Color(0xFF6366F1);
  static const lightPrimarySoft = Color(0xFFEEF2FF);
  static const lightAccent = Color(0xFF22D3EE);
  static const lightSuccess = Color(0xFF10B981);
  static const lightWarning = Color(0xFFF59E0B);
  static const lightError = Color(0xFFEF4444);
  static const lightText = Color(0xFF111827);
  static const lightTextMuted = Color(0xFF6B7280);

  // ── Hero gradient helpers (theme-aware) ──
  static const darkHeroGradientStart = darkPrimarySoft;
  static const darkHeroGradientEnd = darkSurfaceHigh;
  static const lightHeroGradientStart = Color(0xFFEEF2FF);
  static const lightHeroGradientEnd = Color(0xFFE0E7FF);

  // ── Glow helpers ──
  static const darkGlow = Color(0x1F6366F1);
  static const lightGlow = Color(0x146366F1);
}
