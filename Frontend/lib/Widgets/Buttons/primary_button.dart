import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  // A custom button widget that can display a label, an optional icon, and a loading state
  final String label;
  final Color color;
  final VoidCallback?
  onTap; // The callback function to execute when the button is tapped (optional)
  final IconData? icon;
  final bool
  loading; // Indicates whether the button is in a loading state (default is false)
  const PrimaryButton(
    this.label, {
    super.key,
    required this.color,
    this.onTap,
    this.icon,
    this.loading = false,
  });
  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(
        milliseconds: 200,
      ), // Animates changes to the container's properties over 200 milliseconds
      height: 52,
      decoration: BoxDecoration(
        color: widget.onTap == null
            ? kTextLight
            : widget
                  .color, // Changes the button color based on whether it is disabled (onTap is null)
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.onTap == null
            ? [] // No shadow when the button is disabled
            : [
                // Adds a shadow when the button is enabled
                BoxShadow(
                  color: widget.color.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: widget.loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    // If an icon is provided, display it with some spacing
                    Icon(widget.icon, color: Colors.white, size: 17),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
