import 'package:flutter/material.dart';

class AppTextStyles {
  static const fontFamily = 'Inter';
  static const amountFontFamily = 'JetBrainsMono';

  static TextTheme textTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        height: 1.15,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface.withValues(alpha: 0.78),
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.64),
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: colorScheme.onSurface.withValues(alpha: 0.58),
      ),
    );
  }

  static TextStyle amountStyle({
    required Color color,
    double size = 16,
    FontWeight weight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: amountFontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.12,
      letterSpacing: -0.2,
    );
  }
}
