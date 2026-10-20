import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

/// Cấu hình ThemeData chuẩn Material 3 đồng bộ hệ thống Design System
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.primaryHover,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textHeading,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28.0,
          fontWeight: FontWeight.w800,
          color: AppColors.textHeading,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          color: AppColors.textHeading,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textHeading,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textBody,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textBody,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textHeading),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.radiusCard,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p16,
          vertical: AppDimens.p16,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimens.radiusInput,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.radiusInput,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.radiusInput,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.radiusInput,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50.0),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.radiusButton,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textHeading,
          minimumSize: const Size.fromHeight(50.0),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.radiusButton,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
