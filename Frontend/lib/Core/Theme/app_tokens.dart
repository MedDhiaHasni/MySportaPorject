import 'package:flutter/material.dart';

abstract final class NightMatchColors {
  static const background = Color(0xFF061A19);
  static const surface = Color(0xFF0D2928);
  static const elevatedSurface = Color(0xFF143634);
  static const brandTeal = Color(0xFF035C5B);
  static const actionLime = Color(0xFFC6F432);
  static const onAction = Color(0xFF0A1F1E);
  static const text = Color(0xFFF2F7F6);
  static const mutedText = Color(0xFF9DB5B2);
  static const error = Color(0xFFFF8A80);
  static const lightError = Color(0xFFB3261E);
  static const lightSuccess = Color(0xFF1D6A43);
  static const success = Color(0xFF74D3A3);
  static const heroScrimTop = Color(0x140A1F1E);
  static const heroScrimBottom = Color(0xE60A1F1E);

  static const lightBackground = Color(0xFFF4F7F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightElevatedSurface = Color(0xFFEBF1EF);
  static const lightText = Color(0xFF0A1F1E);
  static const lightMutedText = Color(0xFF49615E);

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

abstract final class AppFonts {
  static const headline = 'Sora';
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
  static const double xxxl = 64;
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double input = 16;
  static const double card = 28;
  static const double pill = 999;
}

abstract final class AppLayout {
  static const double heroHeight = 320;
  static const double bottomNavigationHeight = 76;
}

abstract final class AppTypeScale {
  static const double displayLarge = 48;
  static const double displayMedium = 40;
  static const double displaySmall = 36;
  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;
  static const double titleLarge = 20;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;
}

abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double medium = 4;
  static const double high = 8;

  static const List<BoxShadow> nightGlow = [
    BoxShadow(
      color: Color(0x332DDAAF),
      blurRadius: 28,
      spreadRadius: -10,
      offset: Offset(0, 8),
    ),
  ];
}
