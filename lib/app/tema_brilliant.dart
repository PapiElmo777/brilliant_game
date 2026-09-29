import 'package:flutter/material.dart';

abstract final class ColoresBrilliant {
  static const fondo = Color(0xFF071226);
  static const superficie = Color(0xFF142844);
  static const cian = Color(0xFF72E9FF);
  static const texto = Color(0xFFF4FAFF);
  static const error = Color(0xFFFFB4AB);
}

abstract final class TemaBrilliant {
  static ThemeData get oscuro {
    const esquema = ColorScheme.dark(
      primary: ColoresBrilliant.cian,
      onPrimary: ColoresBrilliant.fondo,
      surface: ColoresBrilliant.superficie,
      onSurface: ColoresBrilliant.texto,
      error: ColoresBrilliant.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: ColoresBrilliant.fondo,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
