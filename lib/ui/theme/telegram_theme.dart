import 'package:flutter/material.dart';

/// Telegram-inspired theme colors
class TelegramColors {
  // Light theme
  static const Color lightPrimary = Color(0xFF0088CC);
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightSurface = Colors.white;
  static const Color lightMessageOut = Color(0xFFEEFFDE);
  static const Color lightMessageIn = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF999999);
  static const Color lightDivider = Color(0xFFE5E5E5);
  static const Color lightAccent = Color(0xFF0088CC);

  // Dark theme
  static const Color darkPrimary = Color(0xFF0088CC);
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF212121);
  static const Color darkMessageOut = Color(0xFF2B5278);
  static const Color darkMessageIn = Color(0xFF212121);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF999999);
  static const Color darkDivider = Color(0xFF383838);
  static const Color darkAccent = Color(0xFF0088CC);
}

class TelegramTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: TelegramColors.lightPrimary,
      scaffoldBackgroundColor: TelegramColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: TelegramColors.lightPrimary,
        secondary: TelegramColors.lightAccent,
        surface: TelegramColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: TelegramColors.lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TelegramColors.lightSurface,
        foregroundColor: TelegramColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: TelegramColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: TelegramColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: TelegramColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TelegramColors.lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TelegramColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TelegramColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TelegramColors.lightPrimary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TelegramColors.lightDivider,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: TelegramColors.darkPrimary,
      scaffoldBackgroundColor: TelegramColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: TelegramColors.darkPrimary,
        secondary: TelegramColors.darkAccent,
        surface: TelegramColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: TelegramColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TelegramColors.darkSurface,
        foregroundColor: TelegramColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: TelegramColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: TelegramColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: TelegramColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TelegramColors.darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TelegramColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TelegramColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TelegramColors.darkPrimary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: TelegramColors.darkDivider,
        thickness: 1,
      ),
    );
  }
}
