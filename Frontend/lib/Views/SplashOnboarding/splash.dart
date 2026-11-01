import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Views/SplashOnboarding/onboarding.dart';

const Duration _kSplashDuration = Duration(seconds: 4);

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Future.delayed(_kSplashDuration, () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Onboarding()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Respect accessibility settings
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final entranceDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 800);
    final progressDuration = reduceMotion ? Duration.zero : _kSplashDuration;

    // Force dark mode visually for the splash screen, as per the design system.
    final isLightMode = theme.brightness == Brightness.light;
    final backgroundColor = isLightMode ? const Color(0xFF0B0E0D) : scheme.surface;
    final textColor = isLightMode ? const Color(0xFFF4F6F5) : scheme.onSurface;
    final mutedColor = isLightMode ? const Color(0xFF9AA5A1) : scheme.onSurfaceVariant;
    final trackColor = isLightMode ? const Color(0xFF2A322F) : scheme.outlineVariant;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Wordmark & Tagline
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: entranceDuration,
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  // A smooth "breathing" pulse effect
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Big, bold Sporta wordmark (replacing logo)
                    Text(
                      'SPORTA',
                      style: textTheme.displayLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // 2. Tagline
                    Text(
                      'BORN TO PLAY',
                      style: textTheme.labelLarge?.copyWith(
                        color: mutedColor,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Minimalist bottom progress area
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: AppSpacing.xxl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tiny "Loading" label to give the progress bar context
                  Text(
                    'LOADING',
                    style: textTheme.labelSmall?.copyWith(
                      color: mutedColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    label: 'Loading',
                    child: SizedBox(
                      width: 100,
                      height: 2,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: progressDuration,
                        curve: Curves.easeInOut,
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: reduceMotion ? 1 : value,
                              backgroundColor: trackColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFC6F432), // Lime fill
                              ),
                              minHeight: 2,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}