import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── COLORS (Light values — these ARE the light theme defaults) ───────────────
class AppColors {
  static const primary     = Color(0xFF1B4332);
  static const primary2    = Color(0xFF2D6A4F);
  static const primary3    = Color(0xFF40916C);
  static const primaryTint = Color(0xFFDCF0E3);

  static const gold        = Color(0xFFB7791F);
  static const goldLight   = Color(0xFFF6AD55);
  static const goldTint    = Color(0xFFFFFBEB);

  // AI/Diagnosa accent — terracotta earthy (replaces generic AI purple)
  static const accent      = Color(0xFFC2410C); // terracotta
  static const accentTint  = Color(0xFFFEF2EC);

  static const bg          = Color(0xFFF5F6F2);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF0F1ED);
  static const border      = Color(0xFFE4E1D8);
  static const borderDark  = Color(0xFFCDC9B8);

  static const danger      = Color(0xFFDC2626);
  static const dangerTint  = Color(0xFFFEF2F2);
  static const warn        = Color(0xFF92400E);
  static const warnTint    = Color(0xFFFFFBEB);

  static const success     = Color(0xFF166534);
  static const successTint = Color(0xFFF0FDF4);

  static const text        = Color(0xFF111714);
  static const textMid     = Color(0xFF2E3828);
  static const textMuted   = Color(0xFF72776A);
  static const textLight   = Color(0xFFADB5A0);

  // ── Context-aware helpers (use when BuildContext is available) ──────────────
  static bool _dark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color bgOf(BuildContext c) => _dark(c) ? _Dark.bg : bg;
  static Color surfaceOf(BuildContext c) => _dark(c) ? _Dark.surface : surface;
  static Color surfaceAltOf(BuildContext c) =>
      _dark(c) ? _Dark.surfaceAlt : surfaceAlt;
  static Color borderOf(BuildContext c) => _dark(c) ? _Dark.border : border;
  static Color borderDarkOf(BuildContext c) =>
      _dark(c) ? _Dark.borderStrong : borderDark;
  static Color textOf(BuildContext c) => _dark(c) ? _Dark.text : text;
  static Color textMidOf(BuildContext c) => _dark(c) ? _Dark.textMid : textMid;
  static Color textMutedOf(BuildContext c) =>
      _dark(c) ? _Dark.textMuted : textMuted;
  static Color textLightOf(BuildContext c) =>
      _dark(c) ? _Dark.textLight : textLight;
  static Color primaryTintOf(BuildContext c) =>
      _dark(c) ? _Dark.primaryTint : primaryTint;
  static Color goldTintOf(BuildContext c) =>
      _dark(c) ? _Dark.goldTint : goldTint;
  static Color dangerTintOf(BuildContext c) =>
      _dark(c) ? _Dark.dangerTint : dangerTint;
  static Color warnTintOf(BuildContext c) =>
      _dark(c) ? _Dark.warnTint : warnTint;
  static Color successTintOf(BuildContext c) =>
      _dark(c) ? _Dark.successTint : successTint;
  static Color accentTintOf(BuildContext c) =>
      _dark(c) ? _Dark.accentTint : accentTint;
}

// ─── DARK PALETTE ─────────────────────────────────────────────────────────────
class _Dark {
  static const bg          = Color(0xFF0F1411);
  static const surface     = Color(0xFF1B221E);
  static const surfaceAlt  = Color(0xFF252D29);
  static const border      = Color(0xFF2C342F);
  static const borderStrong = Color(0xFF3A443E);

  static const text        = Color(0xFFE5E9E7);
  static const textMid     = Color(0xFFB8C2BC);
  static const textMuted   = Color(0xFF8A938F);
  static const textLight   = Color(0xFF6F7872);

  // Tints — muted for dark backgrounds
  static const primaryTint = Color(0xFF1A2820);
  static const goldTint    = Color(0xFF2A2618);
  static const dangerTint  = Color(0xFF2A1818);
  static const warnTint    = Color(0xFF2A2418);
  static const successTint = Color(0xFF182418);
  static const accentTint  = Color(0xFF2A1C14);
}

// ─── SPACING (4/8 dp grid system) ─────────────────────────────────────────────
class Spacing {
  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

// ─── RADII ────────────────────────────────────────────────────────────────────
class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 99;
}

// ─── ELEVATION (Material 3 inspired tonal shadows) ────────────────────────────
class Elevations {
  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> primaryGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.18),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─── TYPOGRAPHY (Calistoga + Inter + JetBrains Mono) ──────────────────────────
//
// System rationale:
//  - hero()     Calistoga    — display moments only (splash, brand wordmark)
//                              Slab serif with humanist warmth; Indonesian-friendly.
//  - display()  Inter Bold   — section titles, card titles, screen headers
//                              Refined geometric, excellent for B2B/SaaS.
//  - body()     Inter        — all body copy, UI labels, descriptions.
//  - label()    Inter SemiBold uppercase tracked — section eyebrow labels.
//  - mono()     JetBrains Mono — numerical data, code, structured info.
//                              Tabular figures prevent layout shift.
class AppTextStyles {
  /// Hero brand text — Calistoga, used for splash, brand wordmarks only.
  static TextStyle hero(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.calistoga(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400, // Calistoga has only one weight
        color: color ?? AppColors.text,
        height: 1.1,
        letterSpacing: -0.5,
      );

  /// Section titles, card titles, screen headers. Inter Bold/ExtraBold.
  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w800,
        color: color ?? AppColors.text,
        height: 1.2,
        letterSpacing: -0.3,
      );

  /// Body copy, UI strings, descriptions. Inter regular/medium.
  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.text,
        height: 1.5,
      );

  /// Section eyebrow labels — uppercase, tracked, semibold.
  static TextStyle label({Color? color}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textMuted,
        letterSpacing: 1.2,
        height: 1.0,
      );

  /// Monospace for numbers, currency, codes, data labels.
  /// Tabular figures keep columns aligned.
  static TextStyle mono(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? AppColors.text,
        height: 1.3,
        letterSpacing: -0.2,
      );
}

// ─── THEME ────────────────────────────────────────────────────────────────────
class AppTheme {
  /// Legacy accessor — returns light theme. Use light()/dark() going forward.
  static ThemeData get theme => light();

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.surface,
          secondary: AppColors.gold,
          onSurface: AppColors.text,
          surfaceContainerHighest: AppColors.surfaceAlt,
          outline: AppColors.border,
        ),
        cardColor: AppColors.surface,
        dividerColor: AppColors.border,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(0),
            ),
          ),
        ),
        splashFactory: InkRipple.splashFactory,
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _Dark.bg,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary3,
          surface: _Dark.surface,
          secondary: AppColors.gold,
          onSurface: _Dark.text,
          onSurfaceVariant: _Dark.textMid,
          surfaceContainerHighest: _Dark.surfaceAlt,
          outline: _Dark.border,
          outlineVariant: _Dark.borderStrong,
        ),
        cardColor: _Dark.surface,
        dividerColor: _Dark.border,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _Dark.surface,
          foregroundColor: _Dark.text,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _Dark.text,
            letterSpacing: -0.2,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(0),
            ),
          ),
        ),
        splashFactory: InkRipple.splashFactory,
      );
}
