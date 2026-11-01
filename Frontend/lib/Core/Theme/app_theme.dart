import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final p = isLight ? AppPalette.light : AppPalette.dark;

    // Start from a neutral baseline so no old teal leaks in.
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppPalette.lime,
      onPrimary: AppPalette.onLime,
      primaryContainer: p.elevated,
      onPrimaryContainer: p.text,
      secondary: p.text,
      onSecondary: p.background,
      secondaryContainer: p.elevated,
      onSecondaryContainer: p.text,
      tertiary: p.text,
      onTertiary: p.background,
      tertiaryContainer: p.elevated,
      onTertiaryContainer: p.text,
      error: p.error,
      onError: isLight ? p.surface : p.text,
      errorContainer: p.elevated,
      onErrorContainer: p.error,
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.elevated,
      surfaceContainerHighest: p.elevated,
      onSurfaceVariant: p.muted,
      outline: p.border,
      outlineVariant: p.border,
      inverseSurface: p.text,
      onInverseSurface: p.background,
      inversePrimary: AppPalette.lime,
    );

    final baseTextTheme = isLight
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final textTheme = _textTheme(baseTextTheme, p.text, p.muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      dividerColor: p.border,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: p.text),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        elevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(),
      ),
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          side: BorderSide(color: p.border),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.sm,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.focus, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: p.border),
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
        backgroundColor: p.surface,
        indicatorColor: p.elevated,
        elevation: AppElevation.medium,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(color: p.muted),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.elevated,
        contentTextStyle: TextStyle(
          color: p.text,
          fontFamily: AppFonts.body,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.elevated,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.muted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _buttonStyle() => ElevatedButton.styleFrom(
    backgroundColor: AppPalette.lime,
    foregroundColor: AppPalette.onLime,
    disabledBackgroundColor: AppPalette.lime.withValues(alpha: 0.4),
    disabledForegroundColor: AppPalette.onLime.withValues(alpha: 0.5),
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