import 'package:flutter/material.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Views/SplashOnboarding/onboarding.dart';

import 'dart:async';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Onboarding()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: ColoredBox(
        color: MatchdayColors.brand,
        child: SafeArea(
          child: Center(
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 220),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/sportawhite.png',
                    height: AppSpacing.xxl * 3,
                    width: AppSpacing.xxl * 3,
                    semanticLabel: 'Sporta',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sporta',
                    style: textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Born To Play',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
