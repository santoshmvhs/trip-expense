import 'package:flutter/material.dart';

/// Momentra Brand Colors
/// Extracted from momentra.png: Black background, white text, warm orange/yellow glow
class MomentraColors {
  // Primary colors from logo
  static const Color charcoal = Color(0xFF1A1A1A); // Dark charcoal background
  static const Color black = Color(0xFF000000); // Pure black from logo
  static const Color white = Color(0xFFFFFFFF); // White text
  static const Color lightGray = Color(0xFFE5E5E5); // Light gray for secondary text
  
  // Accent colors from the warm glow on the 'E'
  static const Color warmOrange = Color(0xFFFF8C42); // Warm orange glow
  static const Color warmYellow = Color(0xFFFFD93D); // Warm yellow glow
  static const Color accentGradientStart = Color(0xFFFFA500); // Orange start
  static const Color accentGradientEnd = Color(0xFFFFD700); // Yellow end
  
  // Semantic colors
  static const Color surface = Color(0xFF2A2A2A); // Slightly lighter than charcoal for cards
  static const Color surfaceVariant = Color(0xFF3A3A3A); // Even lighter for elevated surfaces
  static const Color divider = Color(0xFF404040); // Subtle dividers
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MomentraColors.charcoal,
      
      colorScheme: ColorScheme.dark(
        primary: MomentraColors.warmOrange,
        secondary: MomentraColors.warmYellow,
        surface: MomentraColors.surface,
        surfaceContainerHighest: MomentraColors.surfaceVariant,
        error: const Color(0xFFEF4444),
        onPrimary: MomentraColors.black,
        onSecondary: MomentraColors.black,
        onSurface: MomentraColors.white,
        onSurfaceVariant: MomentraColors.lightGray,
        onError: MomentraColors.white,
        outline: MomentraColors.divider,
      ),
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: MomentraColors.charcoal,
        foregroundColor: MomentraColors.white,
        titleTextStyle: const TextStyle(
          color: MomentraColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        iconTheme: const IconThemeData(color: MomentraColors.white),
      ),
      
      cardTheme: CardThemeData(
        elevation: 0,
        color: MomentraColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: MomentraColors.divider.withOpacity(0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MomentraColors.warmOrange,
          foregroundColor: MomentraColors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MomentraColors.warmOrange,
        foregroundColor: MomentraColors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MomentraColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MomentraColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MomentraColors.divider.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MomentraColors.warmOrange, width: 2),
        ),
        labelStyle: const TextStyle(color: MomentraColors.lightGray),
        hintStyle: TextStyle(color: MomentraColors.lightGray.withValues(alpha: 0.6)),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: MomentraColors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
        displayMedium: TextStyle(
          color: MomentraColors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        displaySmall: TextStyle(
          color: MomentraColors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
        headlineMedium: TextStyle(
          color: MomentraColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: MomentraColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: MomentraColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: MomentraColors.white,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: MomentraColors.lightGray,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: MomentraColors.lightGray,
          fontSize: 12,
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: MomentraColors.divider.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      
      iconTheme: const IconThemeData(
        color: MomentraColors.white,
      ),
    );
  }
}

class HealthColors {
  static const Color green = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  
  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return green;
      case 'yellow':
        return yellow;
      case 'red':
        return red;
      default:
        return MomentraColors.lightGray;
    }
  }
}

