import 'package:flutter/material.dart';

class AppHelpers { 
  AppHelpers._();

  /// Shows a floating snack bar
  static void showSnack(BuildContext context, String message, {bool error = false}) { // MATHALAN SUCCES MESSAG WALA ERROR MESSAGE  
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFF005D5E),
    ));
  }

  /// Pushes a page with a standard material route
  static Future<T?> push<T>(BuildContext context, Widget page) =>
      Navigator.push<T>(context, MaterialPageRoute(builder: (_) => page));

  /// Pushes and removes all previous routes
  static Future<T?> pushAndClearAll<T>(BuildContext context, Widget page) =>
      Navigator.pushAndRemoveUntil<T>(
        context,
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );

  /// Returns initials from a full name
  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  /// Formats price with DT suffix
  static String price(double amount) => '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1)} DT';
}
