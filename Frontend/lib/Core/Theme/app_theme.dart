import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final background = isLight
        ? NightMatchColors.lightBackground
        : NightMatchColors.background;
    final surface = isLight
        ? NightMatchColors.lightSurface
        : NightMatchColors.surface;
    final elevatedSurface = isLight
        ? NightMatchColors.lightElevatedSurface
        : NightMatchColors.elevatedSurface;
    final text = isLight ? NightMatchColors.lightText : NightMatchColors.text;
    final muted = isLight
        ? NightMatchColors.lightMutedText
        : NightMatchColors.mutedText;
    final accentText = isLight
        ? NightMatchColors.brandTeal
        : NightMatchColors.actionLime;
    final scheme = ColorScheme.fromSeed(
      seedColor: NightMatchColors.actionLime,
      brightness: brightness,
    ).copyWith(
      primary: NightMatchColors.actionLime,
      onPrimary: NightMatchColors.onAction,
      secondary: accentText,
      onSecondary: isLight
          ? NightMatchColors.lightSurface
          : NightMatchColors.onAction,
      tertiary: NightMatchColors.brandTeal,
      onTertiary: NightMatchColors.text,
      error: isLight
          ? NightMatchColors.lightError
          : NightMatchColors.error,
      onError: NightMatchColors.onAction,
      surface: surface,
      onSurface: text,
      surfaceContainerLow: surface,
      surfaceContainer: elevatedSurface,
      surfaceContainerHighest: elevatedSurface,
      onSurfaceVariant: muted,
      outline: isLight
          ? const Color(0xFFB7C7C4)
          : const Color(0xFF41615D),
      outlineVariant: isLight
          ? const Color(0xFFD8E1DF)
          : const Color(0xFF294542),
      primaryContainer: isLight
          ? const Color(0xFFE9F7B8)
          : const Color(0xFF354712),
      onPrimaryContainer: NightMatchColors.onAction,
      secondaryContainer: isLight
          ? const Color(0xFFDDEBE8)
          : const Color(0xFF1D4541),
      onSecondaryContainer: isLight
          ? NightMatchColors.brandTeal
          : NightMatchColors.text,
      errorContainer: isLight
          ? const Color(0xFFFFE2DE)
          : const Color(0xFF5C211E),
      onErrorContainer: isLight
          ? const Color(0xFF601A15)
          : const Color(0xFFFFDAD5),
      inverseSurface: isLight
          ? NightMatchColors.surface
          : NightMatchColors.lightSurface,
      onInverseSurface: isLight
          ? NightMatchColors.text
          : NightMatchColors.lightText,
      inversePrimary: NightMatchColors.brandTeal,
    );
    final baseTextTheme = isLight
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final textTheme = _textTheme(baseTextTheme, text, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      dividerColor: scheme.outlineVariant,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: accentText),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(isLight),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle(isLight)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          side: BorderSide(color: accentText),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: accentText,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: accentText, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        elevation: AppElevation.medium,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(color: muted),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight
            ? NightMatchColors.surface
            : NightMatchColors.lightSurface,
        contentTextStyle: TextStyle(
          color: isLight ? NightMatchColors.text : NightMatchColors.lightText,
          fontFamily: AppFonts.body,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _buttonStyle(bool isLight) => ElevatedButton.styleFrom(
    backgroundColor: NightMatchColors.actionLime,
    foregroundColor: NightMatchColors.onAction,
    disabledBackgroundColor: isLight
        ? const Color(0xFFDCE4D0)
        : const Color(0xFF35412B),
    disabledForegroundColor: isLight
        ? NightMatchColors.lightMutedText
        : NightMatchColors.mutedText,
    minimumSize: const Size(48, 52),
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.lg,
    ),
    elevation: AppElevation.none,
    shape: const StadiumBorder(),
  );

  static TextTheme _textTheme(TextTheme base, Color text, Color muted) {
    final body = base.apply(
      fontFamily: AppFonts.body,
      fontFamilyFallback: const [AppFonts.arabic],
      bodyColor: text,
      displayColor: text,
    );
    TextStyle headline(TextStyle? style, double size, FontWeight weight) =>
        (style ?? const TextStyle()).copyWith(
          fontFamily: AppFonts.headline,
          fontFamilyFallback: const [AppFonts.arabic, AppFonts.body],
          fontSize: size,
          fontWeight: weight,
          color: text,
          height: 1.12,
        );

    return body.copyWith(
      displayLarge: headline(
        base.displayLarge,
        AppTypeScale.displayLarge,
        FontWeight.w700,
      ),
      displayMedium: headline(
        base.displayMedium,
        AppTypeScale.displayMedium,
        FontWeight.w700,
      ),
      displaySmall: headline(
        base.displaySmall,
        AppTypeScale.displaySmall,
        FontWeight.w700,
      ),
      headlineLarge: headline(
        base.headlineLarge,
        AppTypeScale.headlineLarge,
        FontWeight.w700,
      ),
      headlineMedium: headline(
        base.headlineMedium,
        AppTypeScale.headlineMedium,
        FontWeight.w700,
      ),
      headlineSmall: headline(
        base.headlineSmall,
        AppTypeScale.headlineSmall,
        FontWeight.w600,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: AppTypeScale.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: AppTypeScale.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: AppTypeScale.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: AppTypeScale.bodyLarge,
        height: 1.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: AppTypeScale.bodyMedium,
        height: 1.5,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: AppTypeScale.bodySmall,
        height: 1.4,
        color: muted,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: AppTypeScale.labelLarge,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: AppTypeScale.labelMedium,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: AppTypeScale.labelSmall,
        color: muted,
      ),
    );
  }
}
