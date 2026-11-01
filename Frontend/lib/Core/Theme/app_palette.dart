import 'package:flutter/material.dart';

/// Graphite + Lime palette. Lime is only ever a FILL with dark text
/// (onLime). Never use lime as text or icon color on light surfaces.
class AppPalette {
  const AppPalette._({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.focus,
    required this.text,
    required this.muted,
    required this.error,
    required this.success,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color focus;
  final Color text;
  final Color muted;
  final Color error;
  final Color success;
  final Color warning;

  static const Color lime = Color(0xFFC6F432);
  static const Color limePressed = Color(0xFFB2DC1F);
  static const Color onLime = Color(0xFF0E1412);

  static const AppPalette dark = AppPalette._(
    background: Color(0xFF0B0E0D),
    surface: Color(0xFF151A18),
    elevated: Color(0xFF1E2522),
    border: Color(0xFF2A322F),
    focus: Color(0xFFC6F432),
    text: Color(0xFFF4F6F5),
    muted: Color(0xFF9AA5A1),
    error: Color(0xFFFF8A80),
    success: Color(0xFF74D3A3),
    warning: Color(0xFFF5A524),
  );

  static const AppPalette light = AppPalette._(
    background: Color(0xFFF5F6F4),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    border: Color(0xFFE3E7E4),
    focus: Color(0xFF0E1412),
    text: Color(0xFF0E1412),
    muted: Color(0xFF5B6661),
    error: Color(0xFFE5484D),
    success: Color(0xFF1F9D55),
    warning: Color(0xFFB7791F),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}