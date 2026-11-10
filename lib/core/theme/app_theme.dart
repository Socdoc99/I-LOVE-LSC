import 'package:flutter/material.dart';

/// Paleta de la app. Los pares de color texto/fondo cumplen contraste AA
/// (relación mínima 4.5:1 en texto normal), tomando como referencia WCAG 2.1.
class AppColors {
  const AppColors._();

  static const Color navy = Color(0xFF1F3A5F);
  static const Color gold = Color(0xFFF2B705);
  static const Color ink = Color(0xFF1B1B1F);
  static const Color mist = Color(0xFFEAF0F8);
  static const Color background = Color(0xFFF7F9FC);

  static const Color success = Color(0xFF1B6E3C);
  static const Color successSurface = Color(0xFFDFF3E5);
  static const Color danger = Color(0xFFB3261E);
  static const Color dangerSurface = Color(0xFFFBE4E2);
  static const Color locked = Color(0xFF5F6670);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}
