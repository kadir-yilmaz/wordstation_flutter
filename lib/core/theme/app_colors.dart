import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Primary Accents
  static const Color turquoise = Color(0xFF12C6B2);
  static const Color turquoiseDark = Color(0xFF0EA897);
  static const Color turquoiseLight = Color(0xFFE2FAF6);

  static const Color pink = Color(0xFFE3719D);
  static const Color pinkDark = Color(0xFFC75581);
  static const Color pinkLight = Color(0xFFFDEEF4);

  static const Color orange = Color(0xFFFF9500);
  static const Color orangeDark = Color(0xFFE68500);
  static const Color orangeLight = Color(0xFFFFF4E5);

  static const Color blue = Color(0xFF007AFF);
  static const Color blueDark = Color(0xFF0056B3);
  static const Color blueLight = Color(0xFFE5F1FF);

  static const Color purple = Color(0xFF8E54E9);
  static const Color purpleDark = Color(0xFF6B3BC2);
  static const Color purpleLight = Color(0xFFF4EEFD);

  // System status colors
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFFCC00);
  static const Color info = Color(0xFF5AC8FA);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D0D12);
  static const Color darkSurface = Color(0xFF16161F);
  static const Color darkCard = Color(0xFF1F1F2C);
  static const Color darkCardElevated = Color(0xFF282838);
  static const Color darkBorder = Color(0xFF2E2E3E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9E9EA7);
  static const Color darkTextMuted = Color(0xFF636370);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF6F8FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE7ECF3);
  static const Color lightTextPrimary = Color(0xFF181820);
  static const Color lightTextSecondary = Color(0xFF6E7191);
  static const Color lightTextMuted = Color(0xFFA0A3BD);

  // Gradients
  static const LinearGradient turquoiseGradient = LinearGradient(
    colors: [turquoise, Color(0xFF0FB8A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [pink, Color(0xFFD65888)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orange, Color(0xFFFF7A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [blue, Color(0xFF0062CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF232332), Color(0xFF191924)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF12C6B2), Color(0xFF8E54E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
