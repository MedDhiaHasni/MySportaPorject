import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';
import 'package:sporta/Widgets/Inputs/app_input_field.dart';

/// Labeled text field — replaces the repeated _labelStyle + TextFormField pattern
class FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;

  const FormField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false, // Whether to obscure the text (e.g., for passwords)
    this.suffixIcon,
    this.validator, // Optional validator function for form validation
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, //
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: kTextDark,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: maxLines,
        decoration: appInputDecoration(
          hint,
          icon,
        ).copyWith(suffixIcon: suffixIcon), // Add suffix icon if provided
        validator: validator,
      ),
    ],
  );
}
