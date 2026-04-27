import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary — deep forest green
  static const primary     = Color(0xFF1B4332);
  static const primary2    = Color(0xFF2D6A4F);
  static const primary3    = Color(0xFF40916C);
  static const primaryTint = Color(0xFFD8F3DC);

  // Gold — harvest premium
  static const gold        = Color(0xFFB7791F);
  static const goldLight   = Color(0xFFF6AD55);
  static const goldTint    = Color(0xFFFFFBEB);

  // Backgrounds — warm white
  static const bg          = Color(0xFFFAFAF7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF4F4F0);
  static const border      = Color(0xFFE8E5DC);
  static const borderDark  = Color(0xFFD4CFC0);

  // Semantic
  static const danger      = Color(0xFF9B1C1C);
  static const dangerTint  = Color(0xFFFEF2F2);
  static const warn        = Color(0xFF92400E);
  static const warnTint    = Color(0xFFFFFBEB);

  // Text
  static const text        = Color(0xFF1A1A14);
  static const textMid     = Color(0xFF3D3D2E);
  static const textMuted   = Color(0xFF8A8A72);
  static const textLight   = Color(0xFFB8B89A);
}

class AppTextStyles {
  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? AppColors.text,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.text,
      );

  static TextStyle label({Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textMuted,
        letterSpacing: 1.2,
      );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}
