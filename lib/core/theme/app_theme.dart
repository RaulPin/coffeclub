import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tema de la app, inspirados en el branding minimalista
/// blanco/negro de "The Club Coffe".
class AppTheme {
  const AppTheme._();

  static const Color ink = Color(0xFF0A0A0A);
  static const Color paper = Color(0xFFF7F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF6B6B6B);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: ink,
        onPrimary: Colors.white,
        surface: surface,
        onSurface: ink,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ink,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
