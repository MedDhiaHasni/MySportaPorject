import 'package:flutter/material.dart';
import 'package:sporta/Core/Constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final double
  heightFactor; // Proportion of screen height to use for the header
  final Widget? leading; // Optional leading widget (e.g., back button)
  final String? subtitle; // Optional subtitle text below the title

  const AuthHeader({
    super.key,
    this.heightFactor = 0.23, // Reduced from 0.24 to 0.22
    this.leading,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28), // Reduced from 32 to 28
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: leading != null
            ? Row(
                children: [
                  leading!,
                  Expanded(child: _center()),
                  const SizedBox(width: 56),
                ],
              )
            : _center(),
      ),
    );
  }

  Widget _center() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Logo without background container - clean and simple
      Image.asset(
        'assets/sportalogowhite.png',
        width: 60, // Reduced from 65 to 60
        height: 60,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 50),
      ),
      const SizedBox(height: 8), // Reduced from 12 to 8
      const Text(
        'Sporta',
        style: TextStyle(
          fontSize: 22, // Reduced from 24 to 22
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6), // Reduced from 8 to 6
      if (subtitle != null)
        Text(
          subtitle!,
          style: const TextStyle(
            fontSize: 11, // Reduced from 12 to 11
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ), // Reduced padding
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'BOOK · PLAY · WIN',
            style: TextStyle(
              fontSize: 9, // Reduced from 10 to 9
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 0.6,
            ),
          ),
        ),
    ],
  );
}
