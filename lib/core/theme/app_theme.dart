import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 themes: Outfit for headings/numbers, Inter for body text,
/// rounded cards with soft shadows, light + dark.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    var scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: brightness,
    );
    scheme = scheme.copyWith(
      primary: isLight ? AppColors.teal : AppColors.tealLight,
      surface: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      onSurface: isLight ? AppColors.textPrimary : const Color(0xFFE4EAF0),
    );

    final textTheme = _textTheme(
      ThemeData(brightness: brightness, useMaterial3: true).textTheme,
      scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? Colors.white : const Color(0xFF171D23),
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : const Color(0xFF171D23),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    final inter = GoogleFonts.interTextTheme(base);
    TextStyle outfit(TextStyle? style, {FontWeight weight = FontWeight.w600}) =>
        GoogleFonts.outfit(textStyle: style, fontWeight: weight, color: onSurface);

    return inter
        .copyWith(
          displayLarge: outfit(base.displayLarge, weight: FontWeight.w700),
          displayMedium: outfit(base.displayMedium, weight: FontWeight.w700),
          displaySmall: outfit(base.displaySmall, weight: FontWeight.w700),
          headlineLarge: outfit(base.headlineLarge, weight: FontWeight.w700),
          headlineMedium: outfit(base.headlineMedium),
          headlineSmall: outfit(base.headlineSmall),
          titleLarge: outfit(base.titleLarge),
          titleMedium: outfit(base.titleMedium),
          titleSmall: outfit(base.titleSmall),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);
  }
}

/// Soft drop shadow used under white/dark cards.
List<BoxShadow> softShadow(BuildContext context) {
  final isLight = Theme.of(context).brightness == Brightness.light;
  return [
    BoxShadow(
      color: isLight ? const Color(0x141C2430) : Colors.black.withValues(alpha: .35),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
