import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sporta/Core/Theme/app_tokens.dart';
import 'package:sporta/Views/Auth/login_page.dart';
import 'package:sporta/Widgets/Buttons/app_buttons.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final PageController controlleronboard = PageController();
  int _currentPage = 0;

  static const _pages = [
    (
      image: 'assets/onb1.png',
      headline: 'Book matches instantly',
      benefit: 'Find an open slot and get your game on.',
    ),
    (
      image: 'assets/onb2.png',
      headline: 'Find your team',
      benefit: 'Meet players and join games near you.',
    ),
    (
      image: 'assets/onb3.png',
      headline: 'Your game, made easier',
      benefit: 'Get help with bookings whenever you need it.',
    ),
  ];

  @override
  void dispose() {
    controlleronboard.dispose();
    super.dispose();
  }

  void _goToLogin() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.selectionClick();
      controlleronboard.nextPage(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _currentPage < _pages.length - 1
                    ? AppTextButton(
                        label: 'Skip',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _goToLogin,
                      )
                    : const SizedBox(height: 48),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controlleronboard,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: Image.asset(
                              page.image,
                              fit: BoxFit.contain,
                              semanticLabel: page.headline,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            padding: const EdgeInsetsDirectional.only(
                              top: AppSpacing.md,
                              bottom: AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SPORTA • ${index + 1} / ${_pages.length}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  page.headline,
                                  style: theme.textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  page.benefit,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        label: 'Page ${_currentPage + 1} of ${_pages.length}',
                        child: SmoothPageIndicator(
                          controller: controlleronboard,
                          count: _pages.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: scheme.secondary,
                            dotColor: scheme.outlineVariant,
                            dotHeight: AppSpacing.xs,
                            dotWidth: AppSpacing.xs,
                            expansionFactor: 3,
                            spacing: AppSpacing.xs,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AppPrimaryButton(
                      label: _currentPage == _pages.length - 1
                          ? 'Get started'
                          : 'Continue',
                      icon: _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                      expand: false,
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
