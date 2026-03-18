import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class SectionTitle extends StatefulWidget {
  final String title;
  final String? sub;
  const SectionTitle(this.title, {super.key, this.sub});
  @override
  State<SectionTitle> createState() => _SectionTitleState();
}

class _SectionTitleState extends State<SectionTitle> {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        widget
            .title, // The main title of the section, styled with a larger font size, bold weight, and a specific color for emphasis
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: kTextDark,
          letterSpacing:
              -0.3, // A slight negative letter spacing to tighten the spacing between characters for a more compact and cohesive look
        ),
      ),
      if (widget.sub != null) ...[
        const SizedBox(width: 8),
        Text(
          widget.sub!,
          style: const TextStyle(fontSize: 12, color: kTextMid),
        ),
      ],
    ],
  );
}
