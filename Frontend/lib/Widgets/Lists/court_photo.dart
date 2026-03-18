import 'package:flutter/material.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';

class CourtPhoto extends StatefulWidget {
  final CourtModel
  court; // A widget that displays a photo of a court, with a placeholder if no photo is available, customizable height and border radius
  final double height;
  final BorderRadius? borderRadius;
  const CourtPhoto({
    super.key,
    required this.court,
    this.height = 130,
    this.borderRadius,
  });
  @override
  State<CourtPhoto> createState() => _CourtPhotoState();
}

class _CourtPhotoState extends State<CourtPhoto> {
  @override
  Widget build(BuildContext context) {
    final c = widget
        .court; // A local variable that holds the court data passed to the widget, for easier access and readability
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: c.imageUrl != null
            ? Image.network(
                c.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder:
                    (
                      _,
                      child,
                      prog,
                    ) => // A loading builder that shows a placeholder while the image is loading, and handles errors by showing the same placeholder
                    prog == null
                    ? child
                    : _placeholder(
                        c,
                      ), // If the image is still loading, show the placeholder; otherwise, show the loaded image
                errorBuilder: (_, __, ___) => _placeholder(c),
              )
            : _placeholder(
                c,
              ), // If there is no image URL, show the placeholder directly
      ),
    );
  }

  Widget _placeholder(CourtModel c) => Container(
    color: c.color.withOpacity(0.07),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          c.sport.icon,
          color: c.color.withOpacity(0.35),
          size: 36,
        ), // An icon that represents the sport of the court, using the color of the court with reduced opacity for a subtle effect
        const SizedBox(height: 6),
        Text(
          'No photo',
          style: TextStyle(
            fontSize: 11,
            color: c.color.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
