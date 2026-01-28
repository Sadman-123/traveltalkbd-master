import 'package:flutter/material.dart';
class AppColors {
  static const Color primary = Color(0xFF93268F);   // Brand Purple
  static const Color accent = Color(0xFFE32BAA);    // Brand Pink
  static const Color secondary = Color(0xFFBB8AB3); // Soft Purple
  static const Color background = Color(0xFFFEFEFE);
  static const Color darkText = Color(0xFF2B2B2B);
}
class Traveltalktheme {
  static ThemeData get travelTheme {
    return ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.background,
          surface: AppColors.background,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        // Text
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            color: AppColors.darkText,
            fontFamily: 'traveltalk',
          ),
        ),

        // Buttons (very important for CTA like Book Now)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Input fields (search box, forms)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.secondary.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 2,
            ),
          ),
        ),

      );
  }
  static LinearGradient get primaryGradient {
    return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF4A1E6A), // purple
          Color(0xFFE10098), // pink
        ],
      );
  }
}