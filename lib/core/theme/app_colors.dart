import 'package:flutter/material.dart';

/// VitaPulse brand palette and per-metric accent colors.
abstract final class AppColors {
  // Core brand
  static const teal = Color(0xFF0FB5A6);
  static const tealLight = Color(0xFF17D0BE);
  static const tealDark = Color(0xFF098C81);

  static const surfaceLight = Color(0xFFF7F9FB);
  static const surfaceDark = Color(0xFF101418);
  static const textPrimary = Color(0xFF1C2430);

  // Per-metric accents
  static const steps = Color(0xFF34C77B);
  static const heartRate = Color(0xFFFF5C7A);
  static const sleep = Color(0xFF7C6BFF);
  static const bloodPressure = Color(0xFFFFA726);
  static const spo2 = Color(0xFF29B6F6);
  static const water = Color(0xFF4FC3F7);
  static const calories = Color(0xFFFF8A5C);
  static const weight = Color(0xFF9CCC65);

  /// Vertical brand gradient used by the splash and intro screens.
  static const brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [tealLight, tealDark],
  );

  /// Soft card gradient for a metric accent (light wash of the accent color).
  static LinearGradient metricWash(Color accent, {required Brightness brightness}) {
    final base = brightness == Brightness.light ? Colors.white : const Color(0xFF171D23);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(accent.withValues(alpha: brightness == Brightness.light ? .10 : .16), base),
        Color.alphaBlend(accent.withValues(alpha: brightness == Brightness.light ? .03 : .06), base),
      ],
    );
  }
}
