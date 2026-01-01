import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/momentra_logo_appbar.dart';

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

class AppTheme {
  static const _seed = MomentraColors.warmOrange; // Use warm orange from logo

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return _base(cs);
  }

  static ThemeData dark() {
    // Dark charcoal theme matching momentra.png
    final cs = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark).copyWith(
      primary: MomentraColors.warmOrange,
      secondary: MomentraColors.warmYellow,
      surface: MomentraColors.surface,
      surfaceContainerHighest: MomentraColors.surfaceVariant,
      background: MomentraColors.charcoal,
      onPrimary: MomentraColors.black,
      onSecondary: MomentraColors.black,
      onSurface: MomentraColors.white,
      onSurfaceVariant: MomentraColors.lightGray,
      outline: MomentraColors.divider,
    );
    return _base(cs);
  }

  static ThemeData _base(ColorScheme cs) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.background ?? MomentraColors.charcoal,
      // fontFamily: 'Inter', // Uncomment when font files are added to assets/fonts/
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: cs.background ?? MomentraColors.charcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MomentraColors.white,
        centerTitle: true, // Center the title (logo)
        titleTextStyle: TextStyle(
          // fontFamily: 'Inter', // Uncomment when font files are added
          color: MomentraColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          height: 1.3,
        ),
        iconTheme: const IconThemeData(color: MomentraColors.white),
      ),
      cardTheme: CardThemeData(
        color: cs.surface ?? MomentraColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: MomentraColors.divider.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant ?? MomentraColors.lightGray,
        textColor: cs.onSurface ?? MomentraColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface ?? MomentraColors.white),
        side: BorderSide(color: cs.outlineVariant ?? MomentraColors.divider),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (cs.surfaceContainerHighest ?? MomentraColors.surfaceVariant).withValues(alpha: 0.6),
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MomentraColors.warmOrange,
          foregroundColor: MomentraColors.black,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: TextStyle(
            // fontFamily: 'Inter', // Uncomment when font files are added
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
            height: 1.4,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MomentraColors.warmOrange,
        foregroundColor: MomentraColors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: TextStyle(
          // fontFamily: 'Inter', // Uncomment when font files are added
          color: MomentraColors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.lightGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.lightGray,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          // fontFamily: 'Inter',
          color: MomentraColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
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

