import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Design Tokens: Typography chuẩn với Google Font Plus Jakarta Sans
class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28.0,
        fontWeight: FontWeight.w800,
        height: 34.0 / 28.0,
        color: AppColors.textHeading,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
        height: 28.0 / 22.0,
        color: AppColors.textHeading,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 22.0 / 16.0,
        color: AppColors.textHeading,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        height: 22.0 / 15.0,
        color: AppColors.textBody,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 20.0 / 14.0,
        color: AppColors.textBody,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        height: 16.0 / 12.0,
        color: AppColors.textSecondary,
      );

  static TextStyle get captionTiny => GoogleFonts.plusJakartaSans(
        fontSize: 10.0,
        fontWeight: FontWeight.w700,
        height: 12.0 / 10.0,
        color: AppColors.textMuted,
      );
}
