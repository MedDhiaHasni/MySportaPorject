import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class AppOutlineButton extends StatefulWidget {
  final String label; // The text to display on the button
  final VoidCallback
  onTap; // The callback function to execute when the button is tapped
  const AppOutlineButton(
    this.label, {
    super.key,
    required this.onTap,
  }); // Constructor to initialize the label and onTap callback
  @override
  State<AppOutlineButton> createState() => _AppOutlineButtonState();
}

class _AppOutlineButtonState extends State<AppOutlineButton> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    // Detects tap gestures on the button
    onTap:
        widget.onTap, // Executes the onTap callback when the button is tapped
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTextLight.withOpacity(0.6)),
      ), // Styles the button with a border and rounded corners
      child: Center(
        child: Text(
          widget.label,
          style: const TextStyle(
            color: kTextMid,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    ),
  );
}
