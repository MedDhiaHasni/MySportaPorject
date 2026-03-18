import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

InputDecoration appInputDecoration(String hint, IconData icon) {
  // A function that returns a customized InputDecoration for text fields, with a hint text and an icon
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    prefixIcon: Icon(icon, color: kPrimary, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kRed, width: 1.5),
    ),
  );
}
