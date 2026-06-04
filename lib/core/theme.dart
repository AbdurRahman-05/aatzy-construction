import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Backwards compatibility colors
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryGreen = Color(0xFF43A047);
  static const Color backgroundWhite = Color(0xFFF5F7FA);

  // Curated deep teal/whatsapp forest green construction palette
  static const Color primaryTeal = Color(0xFF075E54);
  static const Color secondaryTeal = Color(0xFF128C7E);
  static const Color accentGreen = Color(0xFF25D366);
  static const Color textDark = Color(0xFF1F2C33);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: secondaryTeal,
        background: const Color(0xFFF4EFE6), // Matches wallpaper base
        surface: Colors.white.withOpacity(0.92), // Translucent cards
      ),
      scaffoldBackgroundColor: const Color(0xFFF4EFE6), // Let wallpaper show through
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withOpacity(0.92), // Translucent card background
        margin: const EdgeInsets.only(bottom: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
