// unues 7atta lin nchouf chniya lprobleme
import 'package:flutter/material.dart';
import 'package:sporta/Models/app_enums.dart';
import 'package:sporta/Models/app_models.dart';

class CourtPhoto extends StatefulWidget {
  final CourtModel
  court; 
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
        .court; 
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
                    ) => 
                    prog == null
                    ? child
                    : _placeholder(
                        c,
                      ), 
              )
            : _placeholder(
                c,
              ), 
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
        ),
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
