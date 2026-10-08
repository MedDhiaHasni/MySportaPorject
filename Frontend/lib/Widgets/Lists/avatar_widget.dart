import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class AvatarWidget extends StatefulWidget {
  final String initials; // el inisitals li tet7at blaset l'avatar
  final double
  size; // A widget that displays a circular avatar with initials, customizable size and background color
  final Color?
  bg; // An optional background color for the avatar, defaulting to a primary color if not provided
  const AvatarWidget({
    super.key,
    required this.initials,
    this.size = 36,
    this.bg,
  });
  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  @override
  Widget build(BuildContext context) => Container(
    width: widget.size,
    height: widget.size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          (widget.bg ?? kPrimary).withOpacity(
            0.8,
          ), 
          widget.bg ??
              kPrimary, // background color mta3 l'avatar 
        ],
      ),
      borderRadius: BorderRadius.circular(widget.size * 0.3),
    ),
    child: Center(
      child: Text(
        widget.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: widget.size * 0.33,
        ),
      ),
    ),
  );
}
