import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    background: MatchdayColors.lightBackground,
    surface: MatchdayColors.lightSurface,
    surfaceAlt: MatchdayColors.lightSurfaceAlt,
    text: MatchdayColors.lightText,
    mutedText: MatchdayColors.lightMutedText,
    border: MatchdayColors.lightBorder,
    secondary: MatchdayColors.brand,
    onSecondary: Colors.white,
    primaryContainer: const Color(0xFFD8EEEA),
    onPrimaryContainer: MatchdayColors.lightText,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    background: MatchdayColors.darkBackground,
    surface: MatchdayColors.darkSurface,
    surfaceAlt: MatchdayColors.darkSurfaceAlt,
    text: MatchdayColors.darkText,
    mutedText: MatchdayColors.darkMutedText,
    border: MatchdayColors.darkBorder,
    secondary: MatchdayColors.brandTint,
    onSecondary: MatchdayColors.darkBackground,
    primaryContainer: MatchdayColors.darkSurfaceAlt,
    onPrimaryContainer: MatchdayColors.brandTint,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color text,
    required Color mutedText,
    required Color border,
    required Color secondary,
    required Color onSecondary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
  }) {
    final isLight = brightness == Brightness.light;
    final textTheme = _textTheme(
      base: isLight
          ? ThemeData.light(useMaterial3: true).textTheme
          : ThemeData.dark(useMaterial3: true).textTheme,
      text: text,
      mutedText: mutedText,
    );
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? MatchdayColors.brand : MatchdayColors.brandTint,
      onPrimary: isLight ? Colors.white : MatchdayColors.darkBackground,
      secondary: secondary,
      onSecondary: onSecondary,
      error: isLight ? MatchdayColors.error : MatchdayColors.errorDark,
      onError: isLight ? Colors.white : MatchdayColors.darkBackground,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceAlt,
      onSurfaceVariant: mutedText,
      outline: border,
      outlineVariant: border,
      tertiary: MatchdayColors.accent,
      onTertiary: MatchdayColors.lightText,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondaryContainer: isLight
          ? const Color(0xFFD8EEEA)
          : const Color(0xFF1B4540),
      onSecondaryContainer: isLight
          ? MatchdayColors.lightText
          : MatchdayColors.brandTint,
      errorContainer: isLight
          ? const Color(0xFFFFE2DE)
          : const Color(0xFF5C211E),
      onErrorContainer: isLight
          ? const Color(0xFF601A15)
          : const Color(0xFFFFDAD5),
      surfaceTint: isLight ? MatchdayColors.brand : MatchdayColors.brandTint,
      inverseSurface: isLight
          ? MatchdayColors.darkSurface
          : MatchdayColors.lightSurface,
      onInverseSurface: isLight
          ? MatchdayColors.darkText
          : MatchdayColors.lightText,
      inversePrimary: MatchdayColors.brandTint,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      dividerColor: border,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: secondary),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(isLight: isLight),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(isLight: isLight),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
          side: BorderSide(color: secondary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: secondary,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: mutedText),
        hintStyle: TextStyle(color: mutedText),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: AppElevation.low,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        elevation: AppElevation.medium,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(color: mutedText),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight
            ? MatchdayColors.darkSurface
            : MatchdayColors.lightSurface,
        contentTextStyle: TextStyle(
          color: isLight ? MatchdayColors.darkText : MatchdayColors.lightText,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _filledButtonStyle({required bool isLight}) =>
      ElevatedButton.styleFrom(
        backgroundColor: MatchdayColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: isLight
            ? const Color(0xFFE0E7E5)
            : const Color(0xFF263936),
        disabledForegroundColor: isLight
            ? MatchdayColors.lightMutedText
            : MatchdayColors.darkMutedText,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        elevation: AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  static TextTheme _textTheme({
    required TextTheme base,
    required Color text,
    required Color mutedText,
  }) {
    final body = base.apply(
      fontFamily: MatchdayFonts.body,
      fontFamilyFallback: const [MatchdayFonts.arabic],
      bodyColor: text,
      displayColor: text,
    );
    TextStyle headline(TextStyle? style, double size, FontWeight weight) =>
        (style ?? const TextStyle()).copyWith(
          fontFamily: MatchdayFonts.headline,
          fontFamilyFallback: const [MatchdayFonts.arabic, MatchdayFonts.body],
          fontSize: size,
          fontWeight: weight,
          color: text,
          height: 1.1,
        );

    return body.copyWith(
      displayLarge: headline(base.displayLarge, 40, FontWeight.w700),
      displayMedium: headline(base.displayMedium, 36, FontWeight.w700),
      displaySmall: headline(base.displaySmall, 32, FontWeight.w700),
      headlineLarge: headline(base.headlineLarge, 32, FontWeight.w700),
      headlineMedium: headline(base.headlineMedium, 28, FontWeight.w700),
      headlineSmall: headline(base.headlineSmall, 24, FontWeight.w600),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: mutedText,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: body.labelSmall?.copyWith(fontSize: 11, color: mutedText),
    );
  }
}
