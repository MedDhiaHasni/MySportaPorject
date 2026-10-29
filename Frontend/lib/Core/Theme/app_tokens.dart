import 'package:flutter/material.dart';

abstract final class MatchdayColors {
  static const brand = Color(0xFF035C5B);
  static const onBrand = Color(0xFFFFFFFF);
  static const brandTint = Color(0xFF56C9B7);
  static const accent = Color(0xFFF4B942);

  static const lightBackground = Color(0xFFF3F7F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFE9F0EF);
  static const lightText = Color(0xFF122625);
  static const lightMutedText = Color(0xFF536765);
  static const lightBorder = Color(0xFFD8E2E0);

  static const darkBackground = Color(0xFF0B1716);
  static const darkSurface = Color(0xFF142321);
  static const darkSurfaceAlt = Color(0xFF1D302E);
  static const darkText = Color(0xFFF3F8F7);
  static const darkMutedText = Color(0xFFB4C7C4);
  static const darkBorder = Color(0xFF36504D);

  static const success = Color(0xFF166534);
  static const successDark = Color(0xFF74D3A3);
  static const warning = Color(0xFF8A4B08);
  static const warningDark = Color(0xFFF0C36A);
  static const error = Color(0xFFB42318);
  static const errorDark = Color(0xFFFF8A80);

  static const pendingBackground = Color(0xFFFFF1CC);
  static const pendingForeground = Color(0xFF704900);
  static const pendingBackgroundDark = Color(0xFF4A3512);
  static const pendingForegroundDark = Color(0xFFFFE08A);

  static const confirmedBackground = Color(0xFFDDF5E8);
  static const confirmedForeground = Color(0xFF14532D);
  static const confirmedBackgroundDark = Color(0xFF123B2B);
  static const confirmedForegroundDark = Color(0xFF8CE6AE);

  static const cancelledBackground = Color(0xFFFDE2E2);
  static const cancelledForeground = Color(0xFF7F1D1D);
  static const cancelledBackgroundDark = Color(0xFF4B2024);
  static const cancelledForegroundDark = Color(0xFFFFAAA5);

  static const refundedBackground = Color(0xFFE9E3FF);
  static const refundedForeground = Color(0xFF4C1D95);
  static const refundedBackgroundDark = Color(0xFF35264D);
  static const refundedForegroundDark = Color(0xFFD0B8FF);
}

abstract final class MatchdayFonts {
  static const headline = 'BarlowCondensed';
  static const body = 'Inter';
  static const arabic = 'NotoSansArabic';
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 3;
  static const double high = 8;

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0B1716), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x060B1716), blurRadius: 3, offset: Offset(0, 1)),
  ];
}
