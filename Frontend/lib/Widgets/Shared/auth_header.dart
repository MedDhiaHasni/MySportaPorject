import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final double
  heightFactor; // Proportion of screen height to use for the header
  final Widget? leading; // Optional leading widget (e.g., back button)
  final String? subtitle; // Optional subtitle text below the title
  const AuthHeader({
    super.key,
    this.heightFactor = 0.27,
    this.leading,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003D3E), kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      // lahnee idha fama leading "back button" yemchi 3al lisar w lb9eya logo wala 7aja center
      child: SafeArea(
        child: leading != null
            ? Row(
                children: [
                  leading!, // Display the leading widget (e.g., back button) ! : means it's non-nullable
                  Expanded(
                    child:
                        _center(), // Display the logo and text in the center of the remaining space
                  ), // Center the logo and text in the remaining space
                  const SizedBox(width: 56),
                ],
              )
            : _center(), // If no leading widget, just display the logo and text centered
      ),
    );
  }

  Widget _center() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 2),
        ),
        child: ClipOval(
          // Clip the image to a circle
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset('assets/test1.png', fit: BoxFit.contain),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Sporta',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6),
      if (subtitle != null)
        Text(
          subtitle!,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white38),
          ),
          child: const Text(
            'BOOK · PLAY · WIN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
        ),
    ],
  );
}
