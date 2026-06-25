import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF3D2DB5);
  static const Color primaryDark = Color(0xFF2A1F8F);
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color accentGreen = Color(0xFF00B897);
  static const Color accentOrange = Color(0xFFFF6B2C);
  static const Color aiTeal = Color(0xFF0ABFBC);
  static const Color background = Color(0xFFF4F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // Extended luxury palette
  static const Color cardGradientStart = Color(0xFF1E1B7B);
  static const Color cardGradientEnd = Color(0xFF3D2DB5);
  static const Color glassWhite = Color(0xFFF8F9FF);
  static const Color accentGold = Color(0xFFFFB347);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color shimmerBase = Color(0xFFE8EAF6);
  static const Color shimmerHighlight = Color(0xFFF5F5FF);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      scaffoldBackgroundColor: glassWhite,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: aiTeal,
        surface: surface,
        error: accentOrange,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      buttonTheme: const ButtonThemeData(
        shape: StadiumBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextStyle monoStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
    );
  }

  static BoxDecoration get primaryGradientDecoration => const BoxDecoration(
    gradient: LinearGradient(
      colors: [cardGradientStart, cardGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration cardGradientDecoration({double radius = 20}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [cardGradientStart, cardGradientEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: primary.withValues(alpha: 0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
