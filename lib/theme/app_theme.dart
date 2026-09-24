import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0D0C0A);
  static const surface = Color(0xFF171512);
  static const surfaceHigh = Color(0xFF211E19);
  static const gold = Color(0xFFC49A3C);
  static const text = Color(0xFFF4EFE5);
  static const muted = Color(0xFFAAA195);
  static const green = Color(0xFF8EB69B);
  static const rust = Color(0xFFB45D4C);
  static const dim = Color(0xFF77736C);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final sans = base.textTheme.apply(
      fontFamily: 'DM Sans',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.rust,
      ),
      textTheme: sans,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cormorant Garamond',
          fontWeight: FontWeight.w500,
          color: AppColors.text,
          fontSize: 24,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          side: BorderSide(color: Color(0x22FFFFFF)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: AppColors.gold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
        side: const BorderSide(color: Color(0x33FFFFFF)),
        selectedColor: AppColors.gold.withValues(alpha: .2),
      ),
      dividerColor: const Color(0x22FFFFFF),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static const TextStyle mono = TextStyle(fontFamily: 'DM Mono');
  static const TextStyle serif = TextStyle(
    fontFamily: 'Cormorant Garamond',
    fontWeight: FontWeight.w500,
  );
}
