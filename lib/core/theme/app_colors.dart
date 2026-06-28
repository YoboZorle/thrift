import 'package:flutter/material.dart';

/// Dark, Bumble-inspired palette.
class AppColors {
  AppColors._();

  // Brand accent (used sparingly — match celebration, highlights).
  static const Color primary = Color(0xFF20C9A6); // teal
  static const Color primaryDark = Color(0xFF15A487);

  // Swipe action colors
  static const Color like = Color(0xFF2BBE6A); // green pill
  static const Color nope = Color(0xFFE24B4B); // red pill
  static const Color superLike = Color(0xFF3D7BFF);
  static const Color accent = Color(0xFFFF6B6B); // badges

  // Dark surfaces
  static const Color background = Color(0xFF0B0C0F);
  static const Color surface = Color(0xFF16181D);
  static const Color surfaceAlt = Color(0xFF1F222A);
  static const Color card = Color(0xFF16181D);

  // Text
  static const Color textPrimary = Color(0xFFF4F5F7);
  static const Color textSecondary = Color(0xFFAAB0BA);
  static const Color textHint = Color(0xFF6C727C);

  static const Color border = Color(0xFF2A2D35);
  static const Color shimmer = Color(0xFF22252C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF20C9A6), Color(0xFF15A487)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle bottom-to-top scrim for legible text over images.
  static const LinearGradient cardScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x00000000),
      Color(0xE6000000),
    ],
    stops: [0.0, 0.42, 1.0],
  );
}
